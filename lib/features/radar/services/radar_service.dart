import 'dart:async';
import 'dart:math';
import 'package:flutter/services.dart';
import '../models/user_model.dart';
import '../services/detection_history_service.dart';
import '../../../services/sound_service.dart';

class RadarService {
  static final RadarService _instance = RadarService._internal();
  factory RadarService() => _instance;
  RadarService._internal();

  final StreamController<List<NearbyUser>> _usersController = StreamController<List<NearbyUser>>.broadcast();
  final StreamController<RadarDetection> _detectionController = StreamController<RadarDetection>.broadcast();
  
  Stream<List<NearbyUser>> get usersStream => _usersController.stream;
  Stream<RadarDetection> get detectionStream => _detectionController.stream;

  Timer? _scanTimer;
  bool _isScanning = false;
  RadarSettings _settings = const RadarSettings();
  RadarRangeSettings _rangeSettings = const RadarRangeSettings();
  List<NearbyUser> _currentUsers = [];
  final Random _random = Random();
  final DetectionHistoryService _detectionHistoryService = DetectionHistoryService();

  // Initialize the radar service
  Future<void> initialize() async {
    // Initialize detection history service
    await _detectionHistoryService.initialize();
    
    // Generate initial mock users
    _currentUsers = _generateMockUsers();
    _usersController.add(_currentUsers);
  }

  // Start scanning for users
  Future<void> startScanning() async {
    if (_isScanning) return;
    
    _isScanning = true;
    
    // Start periodic scanning
    _scanTimer = Timer.periodic(Duration(milliseconds: _settings.scanIntervalMs), (timer) {
      if (_isScanning) {
        _performScan();
      }
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
  void updateSettings(RadarSettings newSettings) {
    _settings = newSettings;
    
    // Restart scanning if currently scanning
    if (_isScanning) {
      stopScanning().then((_) => startScanning());
    }
  }

  // Update range settings
  void updateRangeSettings(RadarRangeSettings newRangeSettings) {
    _rangeSettings = newRangeSettings;
    
    // Restart scanning if currently scanning
    if (_isScanning) {
      stopScanning().then((_) => startScanning());
    }
  }

  // Perform a scan for nearby users
  void _performScan() {
    if (!_settings.enableAutoDetection) return;

    final newUsers = <NearbyUser>[];
    final detectedUsers = <String>{};

    // Simulate user movement and new detections
    for (int i = 0; i < _currentUsers.length; i++) {
      final user = _currentUsers[i];
      
      // Simulate user movement with privacy jitter
      final baseDistance = (user.distanceKm + (_random.nextDouble() - 0.5) * 0.2).clamp(0.1, _rangeSettings.rangeKm);
      final newDistance = _rangeSettings.applyJitter(baseDistance);
      final newAngle = (user.angleDegrees + (_random.nextDouble() - 0.5) * 10) % 360;
      final newSignalStrength = user.calculateSignalStrength(_rangeSettings.rangeKm);
      
      final updatedUser = user.copyWith(
        distanceKm: newDistance,
        angleDegrees: newAngle,
        signalStrength: newSignalStrength,
        isDetected: newSignalStrength > 0,
        lastSeen: DateTime.now(),
      );

      if (updatedUser.isWithinRange(_rangeSettings.rangeKm)) {
        newUsers.add(updatedUser);
        if (updatedUser.isDetected && !user.isDetected) {
          detectedUsers.add(updatedUser.id);
        }
      }
    }

    // Add some new random users occasionally
    if (_random.nextDouble() < 0.3) {
      final newUser = _generateRandomUser();
      if (newUser.isWithinRange(_rangeSettings.rangeKm)) {
        newUsers.add(newUser);
        detectedUsers.add(newUser.id);
      }
    }

    _currentUsers = newUsers;
    _usersController.add(_currentUsers);

    // Emit detection events and save to history
    for (final userId in detectedUsers) {
      final user = _currentUsers.firstWhere((u) => u.id == userId);
      _emitDetection(user, false);
      
      // Save to detection history
      if (_settings.enableAutoDetection) {
        print('RadarService: Saving detection for user ${user.name} to history');
        _detectionHistoryService.addDetection(user);
      } else {
        print('RadarService: Auto detection disabled, not saving to history');
      }
    }
  }

  // Manually detect a specific user
  Future<void> manuallyDetectUser(String userId) async {
    final user = _currentUsers.firstWhere(
      (u) => u.id == userId,
      orElse: () => throw Exception('User not found'),
    );

    if (!user.isWithinRange(_rangeSettings.rangeKm)) {
      throw Exception('User is out of range');
    }

    final updatedUser = user.copyWith(isDetected: true);
    final index = _currentUsers.indexWhere((u) => u.id == userId);
    _currentUsers[index] = updatedUser;
    
    _usersController.add(_currentUsers);
    _emitDetection(updatedUser, true);
    
    // Save to detection history
    print('RadarService: Manually detecting user ${updatedUser.name} and saving to history');
    _detectionHistoryService.addDetection(updatedUser);
  }

  // Toggle user selection
  void toggleUserSelection(String userId) {
    final index = _currentUsers.indexWhere((u) => u.id == userId);
    if (index != -1) {
      final user = _currentUsers[index];
      _currentUsers[index] = user.copyWith(isSelected: !user.isSelected);
      _usersController.add(_currentUsers);
    }
  }

  // Emit detection event
  void _emitDetection(NearbyUser user, bool isManual) {
    final detection = RadarDetection(
      userId: user.id,
      timestamp: DateTime.now(),
      isManual: isManual,
      signalStrength: user.signalStrength,
      distanceKm: user.distanceKm,
    );

    _detectionController.add(detection);

    // Play sound and vibrate if enabled
    if (_settings.enableSound) {
      _playDetectionSound(isManual);
    }

    if (_settings.enableVibration) {
      _vibrate(isManual);
    }
  }

  // Play detection sound
  void _playDetectionSound(bool isManual) {
    if (isManual) {
      SoundService().playSuccessSound();
    } else {
      SoundService().playRadarPingSound();
    }
  }

  // Vibrate device
  void _vibrate(bool isManual) {
    if (isManual) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.lightImpact();
    }
  }

  // Generate mock users for testing
  List<NearbyUser> _generateMockUsers() {
    final names = [
      'Sarah Johnson', 'Mike Chen', 'Emma Wilson', 'Alex Rodriguez',
      'Lisa Park', 'David Kim', 'Maria Garcia', 'James Thompson',
      'Sophie Brown', 'Ryan Davis', 'Olivia White', 'Daniel Lee',
      'Ava Miller', 'Ethan Taylor', 'Isabella Anderson', 'Noah Martinez'
    ];

    final avatars = ['👩', '👨', '👩‍🦰', '👨‍🦱', '👩‍🦳', '👨‍🦳', '👩‍🦲', '👨‍🦲'];
    final interests = [
      ['Music', 'Travel'], ['Sports', 'Gaming'], ['Art', 'Photography'],
      ['Technology', 'Coding'], ['Food', 'Cooking'], ['Fitness', 'Health'],
      ['Reading', 'Writing'], ['Dancing', 'Fashion'], ['Nature', 'Hiking'],
      ['Movies', 'TV Shows'], ['Science', 'Space'], ['History', 'Culture']
    ];

    return List.generate(8, (index) {
      final distance = 0.1 + _random.nextDouble() * (_rangeSettings.rangeKm - 0.1);
      final angle = _random.nextDouble() * 360;
      final signalStrength = (1.0 - (distance / _rangeSettings.rangeKm)).clamp(0.0, 1.0);
      
      return NearbyUser(
        id: 'user_$index',
        name: names[index % names.length],
        avatar: avatars[index % avatars.length],
        distanceKm: distance,
        angleDegrees: angle,
        signalStrength: signalStrength,
        isOnline: _random.nextBool(),
        isDetected: signalStrength > 0.3,
        interests: interests[index % interests.length],
        lastSeen: DateTime.now().subtract(Duration(minutes: _random.nextInt(60))),
      );
    });
  }

  // Generate a random user
  NearbyUser _generateRandomUser() {
    final names = ['New User', 'Anonymous', 'User${_random.nextInt(1000)}'];
    final avatars = ['👤', '👥', '👤'];
    
    final distance = 0.1 + _random.nextDouble() * (_rangeSettings.rangeKm - 0.1);
    final angle = _random.nextDouble() * 360;
    final signalStrength = (1.0 - (distance / _rangeSettings.rangeKm)).clamp(0.0, 1.0);
    
    return NearbyUser(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: names[_random.nextInt(names.length)],
      avatar: avatars[_random.nextInt(avatars.length)],
      distanceKm: distance,
      angleDegrees: angle,
      signalStrength: signalStrength,
      isOnline: _random.nextBool(),
      isDetected: signalStrength > 0.3,
      interests: ['New', 'User'],
      lastSeen: DateTime.now(),
    );
  }

  // Get current users
  List<NearbyUser> get currentUsers => List.unmodifiable(_currentUsers);

  // Get current settings
  RadarSettings get settings => _settings;
  
  // Get current range settings
  RadarRangeSettings get rangeSettings => _rangeSettings;

  // Check if scanning
  bool get isScanning => _isScanning;

  // Dispose resources
  void dispose() {
    stopScanning();
    _usersController.close();
    _detectionController.close();
  }
}
