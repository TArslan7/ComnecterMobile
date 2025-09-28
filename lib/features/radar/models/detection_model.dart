import 'user_model.dart';

/// Represents a user detection event with timestamp and metadata
class UserDetection {
  final String id;
  final String userId;
  final String name;
  final String avatar;
  final double distanceKm;
  final double signalStrength;
  final DateTime detectedAt;
  final bool isOnline;
  final List<String> interests;
  final Map<String, dynamic> metadata;

  UserDetection({
    required this.id,
    required this.userId,
    required this.name,
    required this.avatar,
    required this.distanceKm,
    required this.signalStrength,
    required this.detectedAt,
    required this.isOnline,
    this.interests = const [],
    this.metadata = const {},
  });

  /// Create a UserDetection from a NearbyUser
  factory UserDetection.fromNearbyUser(NearbyUser user) {
    return UserDetection(
      id: 'detection_${user.id}_${DateTime.now().millisecondsSinceEpoch}',
      userId: user.id,
      name: user.name,
      avatar: user.avatar,
      distanceKm: user.distanceKm,
      signalStrength: user.signalStrength,
      detectedAt: DateTime.now(),
      isOnline: user.isOnline,
      interests: user.interests,
      metadata: user.metadata,
    );
  }

  /// Convert to NearbyUser for compatibility
  NearbyUser toNearbyUser() {
    return NearbyUser(
      id: userId,
      name: name,
      avatar: avatar,
      distanceKm: distanceKm,
      angleDegrees: 0, // Not relevant for detection history
      signalStrength: signalStrength,
      isOnline: isOnline,
      isDetected: true,
      isSelected: false,
      interests: interests,
      lastSeen: detectedAt,
      metadata: metadata,
    );
  }

  UserDetection copyWith({
    String? id,
    String? userId,
    String? name,
    String? avatar,
    double? distanceKm,
    double? signalStrength,
    DateTime? detectedAt,
    bool? isOnline,
    List<String>? interests,
    Map<String, dynamic>? metadata,
  }) {
    return UserDetection(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      distanceKm: distanceKm ?? this.distanceKm,
      signalStrength: signalStrength ?? this.signalStrength,
      detectedAt: detectedAt ?? this.detectedAt,
      isOnline: isOnline ?? this.isOnline,
      interests: interests ?? this.interests,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserDetection && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'UserDetection(id: $id, name: $name, detectedAt: $detectedAt)';
  }
}

/// Represents a favorite user saved from detections
class FavoriteUser {
  final String id;
  final String userId;
  final String name;
  final String avatar;
  final DateTime savedAt;
  final List<String> interests;
  final Map<String, dynamic> metadata;
  final String? notes; // Optional user notes

  FavoriteUser({
    required this.id,
    required this.userId,
    required this.name,
    required this.avatar,
    required this.savedAt,
    this.interests = const [],
    this.metadata = const {},
    this.notes,
  });

  /// Create a FavoriteUser from a UserDetection
  factory FavoriteUser.fromDetection(UserDetection detection, {String? notes}) {
    return FavoriteUser(
      id: 'favorite_${detection.userId}_${DateTime.now().millisecondsSinceEpoch}',
      userId: detection.userId,
      name: detection.name,
      avatar: detection.avatar,
      savedAt: DateTime.now(),
      interests: detection.interests,
      metadata: detection.metadata,
      notes: notes,
    );
  }

  FavoriteUser copyWith({
    String? id,
    String? userId,
    String? name,
    String? avatar,
    DateTime? savedAt,
    List<String>? interests,
    Map<String, dynamic>? metadata,
    String? notes,
  }) {
    return FavoriteUser(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      savedAt: savedAt ?? this.savedAt,
      interests: interests ?? this.interests,
      metadata: metadata ?? this.metadata,
      notes: notes ?? this.notes,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FavoriteUser && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'FavoriteUser(id: $id, name: $name, savedAt: $savedAt)';
  }
}

/// Detection history filter options
enum DetectionFilter {
  all,
  recent, // Last 24 hours
  today,
  thisWeek,
  thisMonth,
}

/// Sort options for detection history
enum DetectionSort {
  newest,
  oldest,
  distance,
  name,
  signalStrength,
}

/// Detection history settings
class DetectionHistorySettings {
  final int maxDetections;
  final DetectionFilter defaultFilter;
  final DetectionSort defaultSort;
  final bool enableAutoSave;
  final bool enableNotifications;
  final Duration autoDeleteAfter;

  const DetectionHistorySettings({
    this.maxDetections = 1000,
    this.defaultFilter = DetectionFilter.recent,
    this.defaultSort = DetectionSort.newest,
    this.enableAutoSave = true,
    this.enableNotifications = true,
    this.autoDeleteAfter = const Duration(days: 30),
  });

  DetectionHistorySettings copyWith({
    int? maxDetections,
    DetectionFilter? defaultFilter,
    DetectionSort? defaultSort,
    bool? enableAutoSave,
    bool? enableNotifications,
    Duration? autoDeleteAfter,
  }) {
    return DetectionHistorySettings(
      maxDetections: maxDetections ?? this.maxDetections,
      defaultFilter: defaultFilter ?? this.defaultFilter,
      defaultSort: defaultSort ?? this.defaultSort,
      enableAutoSave: enableAutoSave ?? this.enableAutoSave,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      autoDeleteAfter: autoDeleteAfter ?? this.autoDeleteAfter,
    );
  }
}
