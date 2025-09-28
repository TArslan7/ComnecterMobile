import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/detection_model.dart';
import '../models/user_model.dart';

/// Service for managing detection history and favorites
class DetectionHistoryService {
  static final DetectionHistoryService _instance = DetectionHistoryService._internal();
  factory DetectionHistoryService() => _instance;
  DetectionHistoryService._internal();

  // Stream controllers for real-time updates
  final StreamController<List<UserDetection>> _detectionsController = 
      StreamController<List<UserDetection>>.broadcast();
  final StreamController<List<FavoriteUser>> _favoritesController = 
      StreamController<List<FavoriteUser>>.broadcast();

  // Streams
  Stream<List<UserDetection>> get detectionsStream => _detectionsController.stream;
  Stream<List<FavoriteUser>> get favoritesStream => _favoritesController.stream;

  // In-memory storage
  List<UserDetection> _detections = [];
  List<FavoriteUser> _favorites = [];
  DetectionHistorySettings _settings = const DetectionHistorySettings();

  // Storage keys
  static const String _detectionsKey = 'detection_history';
  static const String _favoritesKey = 'favorite_users';
  static const String _settingsKey = 'detection_history_settings';

  /// Initialize the service and load data from storage
  Future<void> initialize() async {
    await _loadFromStorage();
  }

  /// Add a new detection to history
  Future<void> addDetection(NearbyUser user) async {
    final detection = UserDetection.fromNearbyUser(user);
    
    // Remove any existing detection for the same user to avoid duplicates
    _detections.removeWhere((d) => d.userId == user.id);
    
    // Add new detection at the beginning
    _detections.insert(0, detection);
    
    // Limit the number of detections
    if (_detections.length > _settings.maxDetections) {
      _detections = _detections.take(_settings.maxDetections).toList();
    }
    
    // Clean up old detections
    await _cleanupOldDetections();
    
    // Save to storage
    await _saveToStorage();
    
    // Emit update
    _detectionsController.add(List.unmodifiable(_detections));
  }

  /// Add a user to favorites
  Future<void> addToFavorites(UserDetection detection, {String? notes}) async {
    // Check if already in favorites
    if (_favorites.any((f) => f.userId == detection.userId)) {
      return; // Already in favorites
    }
    
    final favorite = FavoriteUser.fromDetection(detection, notes: notes);
    _favorites.insert(0, favorite);
    
    // Save to storage
    await _saveToStorage();
    
    // Emit update
    _favoritesController.add(List.unmodifiable(_favorites));
  }

  /// Remove a user from favorites
  Future<void> removeFromFavorites(String userId) async {
    _favorites.removeWhere((f) => f.userId == userId);
    
    // Save to storage
    await _saveToStorage();
    
    // Emit update
    _favoritesController.add(List.unmodifiable(_favorites));
  }

  /// Check if a user is in favorites
  bool isFavorite(String userId) {
    return _favorites.any((f) => f.userId == userId);
  }

  /// Get detections with optional filtering and sorting
  List<UserDetection> getDetections({
    DetectionFilter? filter,
    DetectionSort? sort,
    int? limit,
  }) {
    List<UserDetection> filtered = List.from(_detections);
    
    // Apply filter
    if (filter != null) {
      filtered = _applyFilter(filtered, filter);
    }
    
    // Apply sort
    if (sort != null) {
      filtered = _applySort(filtered, sort);
    }
    
    // Apply limit
    if (limit != null && limit > 0) {
      filtered = filtered.take(limit).toList();
    }
    
    return filtered;
  }

  /// Get favorites with optional sorting
  List<FavoriteUser> getFavorites({DetectionSort? sort, int? limit}) {
    List<FavoriteUser> sorted = List.from(_favorites);
    
    // Apply sort
    if (sort != null) {
      sorted = _applySortToFavorites(sorted, sort);
    }
    
    // Apply limit
    if (limit != null && limit > 0) {
      sorted = sorted.take(limit).toList();
    }
    
    return sorted;
  }

  /// Clear all detections
  Future<void> clearDetections() async {
    _detections.clear();
    await _saveToStorage();
    _detectionsController.add(List.unmodifiable(_detections));
  }

  /// Clear all favorites
  Future<void> clearFavorites() async {
    _favorites.clear();
    await _saveToStorage();
    _favoritesController.add(List.unmodifiable(_favorites));
  }

  /// Update settings
  Future<void> updateSettings(DetectionHistorySettings newSettings) async {
    _settings = newSettings;
    await _saveToStorage();
  }

  /// Get current settings
  DetectionHistorySettings get settings => _settings;

  /// Get detection count
  int get detectionCount => _detections.length;

  /// Get favorites count
  int get favoritesCount => _favorites.length;

  /// Apply filter to detections
  List<UserDetection> _applyFilter(List<UserDetection> detections, DetectionFilter filter) {
    final now = DateTime.now();
    
    switch (filter) {
      case DetectionFilter.all:
        return detections;
      case DetectionFilter.recent:
        final yesterday = now.subtract(const Duration(hours: 24));
        return detections.where((d) => d.detectedAt.isAfter(yesterday)).toList();
      case DetectionFilter.today:
        final today = DateTime(now.year, now.month, now.day);
        return detections.where((d) => d.detectedAt.isAfter(today)).toList();
      case DetectionFilter.thisWeek:
        final weekAgo = now.subtract(const Duration(days: 7));
        return detections.where((d) => d.detectedAt.isAfter(weekAgo)).toList();
      case DetectionFilter.thisMonth:
        final monthAgo = now.subtract(const Duration(days: 30));
        return detections.where((d) => d.detectedAt.isAfter(monthAgo)).toList();
    }
  }

  /// Apply sort to detections
  List<UserDetection> _applySort(List<UserDetection> detections, DetectionSort sort) {
    switch (sort) {
      case DetectionSort.newest:
        return detections..sort((a, b) => b.detectedAt.compareTo(a.detectedAt));
      case DetectionSort.oldest:
        return detections..sort((a, b) => a.detectedAt.compareTo(b.detectedAt));
      case DetectionSort.distance:
        return detections..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
      case DetectionSort.name:
        return detections..sort((a, b) => a.name.compareTo(b.name));
      case DetectionSort.signalStrength:
        return detections..sort((a, b) => b.signalStrength.compareTo(a.signalStrength));
    }
  }

  /// Apply sort to favorites
  List<FavoriteUser> _applySortToFavorites(List<FavoriteUser> favorites, DetectionSort sort) {
    switch (sort) {
      case DetectionSort.newest:
        return favorites..sort((a, b) => b.savedAt.compareTo(a.savedAt));
      case DetectionSort.oldest:
        return favorites..sort((a, b) => a.savedAt.compareTo(b.savedAt));
      case DetectionSort.name:
        return favorites..sort((a, b) => a.name.compareTo(b.name));
      case DetectionSort.distance:
      case DetectionSort.signalStrength:
        // These don't apply to favorites, use newest
        return favorites..sort((a, b) => b.savedAt.compareTo(a.savedAt));
    }
  }

  /// Clean up old detections based on settings
  Future<void> _cleanupOldDetections() async {
    if (_settings.autoDeleteAfter.inDays <= 0) return;
    
    final cutoff = DateTime.now().subtract(_settings.autoDeleteAfter);
    _detections.removeWhere((d) => d.detectedAt.isBefore(cutoff));
  }

  /// Load data from SharedPreferences
  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load detections
      final detectionsJson = prefs.getString(_detectionsKey);
      if (detectionsJson != null) {
        final List<dynamic> detectionsList = json.decode(detectionsJson);
        _detections = detectionsList
            .map((json) => UserDetectionJson.fromJson(json))
            .toList();
      }
      
      // Load favorites
      final favoritesJson = prefs.getString(_favoritesKey);
      if (favoritesJson != null) {
        final List<dynamic> favoritesList = json.decode(favoritesJson);
        _favorites = favoritesList
            .map((json) => FavoriteUserJson.fromJson(json))
            .toList();
      }
      
      // Load settings
      final settingsJson = prefs.getString(_settingsKey);
      if (settingsJson != null) {
        final settingsMap = json.decode(settingsJson);
        _settings = DetectionHistorySettingsJson.fromJson(settingsMap);
      }
      
      // Emit current data
      _detectionsController.add(List.unmodifiable(_detections));
      _favoritesController.add(List.unmodifiable(_favorites));
    } catch (e) {
      print('Error loading detection history: $e');
      // Initialize with empty data
      _detections = [];
      _favorites = [];
    }
  }

  /// Save data to SharedPreferences
  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save detections
      final detectionsJson = json.encode(_detections.map((d) => d.toJson()).toList());
      await prefs.setString(_detectionsKey, detectionsJson);
      
      // Save favorites
      final favoritesJson = json.encode(_favorites.map((f) => f.toJson()).toList());
      await prefs.setString(_favoritesKey, favoritesJson);
      
      // Save settings
      final settingsJson = json.encode(_settings.toJson());
      await prefs.setString(_settingsKey, settingsJson);
    } catch (e) {
      print('Error saving detection history: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _detectionsController.close();
    _favoritesController.close();
  }
}

/// Extension methods for JSON serialization
extension UserDetectionJson on UserDetection {
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'avatar': avatar,
      'distanceKm': distanceKm,
      'signalStrength': signalStrength,
      'detectedAt': detectedAt.toIso8601String(),
      'isOnline': isOnline,
      'interests': interests,
      'metadata': metadata,
    };
  }

  static UserDetection fromJson(Map<String, dynamic> json) {
    return UserDetection(
      id: json['id'],
      userId: json['userId'],
      name: json['name'],
      avatar: json['avatar'],
      distanceKm: json['distanceKm'].toDouble(),
      signalStrength: json['signalStrength'].toDouble(),
      detectedAt: DateTime.parse(json['detectedAt']),
      isOnline: json['isOnline'],
      interests: List<String>.from(json['interests'] ?? []),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }
}

extension FavoriteUserJson on FavoriteUser {
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'avatar': avatar,
      'savedAt': savedAt.toIso8601String(),
      'interests': interests,
      'metadata': metadata,
      'notes': notes,
    };
  }

  static FavoriteUser fromJson(Map<String, dynamic> json) {
    return FavoriteUser(
      id: json['id'],
      userId: json['userId'],
      name: json['name'],
      avatar: json['avatar'],
      savedAt: DateTime.parse(json['savedAt']),
      interests: List<String>.from(json['interests'] ?? []),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      notes: json['notes'],
    );
  }
}

extension DetectionHistorySettingsJson on DetectionHistorySettings {
  Map<String, dynamic> toJson() {
    return {
      'maxDetections': maxDetections,
      'defaultFilter': defaultFilter.name,
      'defaultSort': defaultSort.name,
      'enableAutoSave': enableAutoSave,
      'enableNotifications': enableNotifications,
      'autoDeleteAfterDays': autoDeleteAfter.inDays,
    };
  }

  static DetectionHistorySettings fromJson(Map<String, dynamic> json) {
    return DetectionHistorySettings(
      maxDetections: json['maxDetections'] ?? 1000,
      defaultFilter: DetectionFilter.values.firstWhere(
        (f) => f.name == json['defaultFilter'],
        orElse: () => DetectionFilter.recent,
      ),
      defaultSort: DetectionSort.values.firstWhere(
        (s) => s.name == json['defaultSort'],
        orElse: () => DetectionSort.newest,
      ),
      enableAutoSave: json['enableAutoSave'] ?? true,
      enableNotifications: json['enableNotifications'] ?? true,
      autoDeleteAfter: Duration(days: json['autoDeleteAfterDays'] ?? 30),
    );
  }
}
