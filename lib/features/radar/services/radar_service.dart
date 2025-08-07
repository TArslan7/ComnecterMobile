import 'dart:async';
import 'dart:math';
import 'package:flutter/services.dart';
import '../models/user_model.dart';

class RadarService {
  static final RadarService _instance = RadarService._internal();
  factory RadarService() => _instance;
  RadarService._internal();

  Timer? _scanTimer;
  final StreamController<List<NearbyUser>> _usersController = StreamController<List<NearbyUser>>.broadcast();
  final StreamController<RadarDetection> _detectionController = StreamController<RadarDetection>.broadcast();
  
  RadarSettings _settings = const RadarSettings();
  List<NearbyUser> _allUsers = [];
  List<NearbyUser> _detectedUsers = [];
  bool _isScanning = false;

  // Getters
  Stream<List<NearbyUser>> get usersStream => _usersController.stream;
  Stream<RadarDetection> get detectionStream => _detectionController.stream;
  List<NearbyUser> get detectedUsers => List.unmodifiable(_detectedUsers);
  bool get isScanning => _isScanning;
  RadarSettings get settings => _settings;

  // Initialize with mock data
  Future<void> initialize() async {
    _allUsers = _generateMockUsers();
    _detectedUsers = [];
    _isScanning = false;
  }

  // Start real-time scanning
  Future<void> startScanning() async {
    if (_isScanning) return;
    
    _isScanning = true;
    _detectedUsers.clear();
    _usersController.add(_detectedUsers);

    // Start periodic scanning
    _scanTimer = Timer.periodic(Duration(milliseconds: _settings.scanIntervalMs), (timer) {
      _performScan();
    });

    // Perform initial scan
    _performScan();
  }

  // Stop scanning
  Future<void> stopScanning() async {
    _isScanning = false;
    _scanTimer?.cancel();
    _scanTimer = null;
  }

  // Update radar settings
  Future<void> updateSettings(RadarSettings newSettings) async {
    _settings = newSettings;
    
    // Restart scanning if currently active
    if (_isScanning) {
      await stopScanning();
      await startScanning();
    }
  }

  // Manual detection of a specific user
  Future<void> manuallyDetectUser(String userId) async {
    final user = _allUsers.firstWhere(
      (u) => u.id == userId,
      orElse: () => throw Exception('User not found'),
    );

    if (!user.isWithinRange(_settings.detectionRangeKm)) {
      throw Exception('User is out of range');
    }

    final detection = RadarDetection(
      userId: user.id,
      distanceKm: user.distanceKm,
      angleDegrees: user.angleDegrees,
      signalStrength: user.calculateSignalStrength(_settings.detectionRangeKm),
      detectedAt: DateTime.now(),
      isManual: true,
    );

    // Add to detected users if not already present
    if (!_detectedUsers.any((u) => u.id == user.id)) {
      final detectedUser = user.copyWith(
        isDetected: true,
        signalStrength: detection.signalStrength,
      );
      _detectedUsers.add(detectedUser);
      _usersController.add(_detectedUsers);
    }

    _detectionController.add(detection);

    // Play detection sound and vibrate
    if (_settings.enableSound) {
      await _playDetectionSound();
    }
    if (_settings.enableVibration) {
      await _vibrate();
    }
  }

  // Select/deselect a user
  Future<void> toggleUserSelection(String userId) async {
    final index = _detectedUsers.indexWhere((u) => u.id == userId);
    if (index != -1) {
      final user = _detectedUsers[index];
      final updatedUser = user.copyWith(isSelected: !user.isSelected);
      _detectedUsers[index] = updatedUser;
      _usersController.add(_detectedUsers);
    }
  }

  // Get selected users
  List<NearbyUser> get selectedUsers {
    return _detectedUsers.where((u) => u.isSelected).toList();
  }

  // Perform a scan for nearby users
  void _performScan() {
    if (!_settings.autoDetect) return;

    final newDetections = <RadarDetection>[];
    final updatedUsers = <NearbyUser>[];

    for (final user in _allUsers) {
      if (user.isWithinRange(_settings.detectionRangeKm)) {
        final signalStrength = user.calculateSignalStrength(_settings.detectionRangeKm);
        
        // Simulate signal strength variation
        final randomFactor = 0.8 + (Random().nextDouble() * 0.4); // 0.8 to 1.2
        final adjustedSignalStrength = (signalStrength * randomFactor).clamp(0.0, 1.0);

        final detection = RadarDetection(
          userId: user.id,
          distanceKm: user.distanceKm,
          angleDegrees: user.angleDegrees,
          signalStrength: adjustedSignalStrength,
          detectedAt: DateTime.now(),
          isManual: false,
        );

        newDetections.add(detection);

        // Update or add user to detected list
        final existingIndex = _detectedUsers.indexWhere((u) => u.id == user.id);
        final detectedUser = user.copyWith(
          isDetected: true,
          signalStrength: adjustedSignalStrength,
        );

        if (existingIndex != -1) {
          _detectedUsers[existingIndex] = detectedUser;
        } else {
          _detectedUsers.add(detectedUser);
        }

        updatedUsers.add(detectedUser);
      }
    }

    // Remove users that are no longer in range
    _detectedUsers.removeWhere((user) => !user.isWithinRange(_settings.detectionRangeKm));

    // Emit updates
    _usersController.add(_detectedUsers);
    
    for (final detection in newDetections) {
      _detectionController.add(detection);
    }

    // Play detection sounds and vibrate for new detections
    if (newDetections.isNotEmpty) {
      if (_settings.enableSound) {
        _playDetectionSound();
      }
      if (_settings.enableVibration) {
        _vibrate();
      }
    }
  }

  // Generate mock users with realistic data
  List<NearbyUser> _generateMockUsers() {
    final random = Random();
    final names = [
      'Alex Johnson', 'Sarah Chen', 'Mike Rodriguez', 'Emma Wilson',
      'David Kim', 'Lisa Thompson', 'Tom Anderson', 'Anna Garcia',
      'John Smith', 'Maria Lopez', 'Chris Davis', 'Sophie Brown',
      'Mark Taylor', 'Julia White', 'Paul Miller', 'Nina Clark',
    ];

    final avatars = [
      '👨‍💼', '👩‍💼', '👨‍🎨', '👩‍🎨', '👨‍⚕️', '👩‍⚕️', '👨‍🏫', '👩‍🏫',
      '👨‍💻', '👩‍💻', '👨‍🎓', '👩‍🎓', '👨‍🔬', '👩‍🔬', '👨‍🚀', '👩‍🚀',
    ];

    final interests = [
      'Music', 'Sports', 'Travel', 'Cooking', 'Gaming', 'Reading',
      'Photography', 'Art', 'Technology', 'Fitness', 'Movies', 'Dancing',
      'Coffee', 'Wine', 'Hiking', 'Cycling', 'Yoga', 'Meditation',
      'Startups', 'Innovation', 'Design', 'Fashion', 'Beauty', 'Food',
    ];

    return List.generate(20, (index) {
      final name = names[random.nextInt(names.length)];
      final avatar = avatars[random.nextInt(avatars.length)];
      final distance = 0.02 + random.nextDouble() * 0.48; // 0.02 to 0.5 km
      final angle = random.nextDouble() * 360;
      final isOnline = random.nextBool();
      
      // Generate 2-4 random interests
      final userInterests = <String>[];
      final interestCount = 2 + random.nextInt(3);
      final shuffledInterests = List<String>.from(interests)..shuffle(random);
      for (int i = 0; i < interestCount && i < shuffledInterests.length; i++) {
        userInterests.add(shuffledInterests[i]);
      }

      return NearbyUser(
        id: 'user_${index + 1}',
        name: name,
        avatar: avatar,
        distanceKm: distance,
        status: isOnline ? 'Online' : 'Offline',
        interests: userInterests,
        lastSeen: DateTime.now().subtract(Duration(minutes: random.nextInt(60))),
        angleDegrees: angle,
        isOnline: isOnline,
        userId: 'real_user_${index + 1}',
      );
    });
  }

  // Play detection sound
  Future<void> _playDetectionSound() async {
    try {
      await SystemSound.play(SystemSoundType.click);
    } catch (e) {
      // Fallback if system sound fails
    }
  }

  // Vibrate device
  Future<void> _vibrate() async {
    try {
      await HapticFeedback.lightImpact();
    } catch (e) {
      // Fallback if haptic feedback fails
    }
  }

  // Get users within a specific range
  List<NearbyUser> getUsersInRange(double rangeKm) {
    return _allUsers.where((user) => user.isWithinRange(rangeKm)).toList();
  }

  // Get users by signal strength
  List<NearbyUser> getUsersBySignalStrength(double minStrength) {
    return _detectedUsers.where((user) => user.signalStrength >= minStrength).toList();
  }

  // Get users by distance category
  List<NearbyUser> getUsersByDistanceCategory(String category) {
    return _detectedUsers.where((user) => user.distanceCategory == category).toList();
  }

  // Dispose resources
  void dispose() {
    stopScanning();
    _usersController.close();
    _detectionController.close();
  }
}
