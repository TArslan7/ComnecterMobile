import 'dart:math';

class NearbyUser {
  final String id;
  final String name;
  final double distanceKm;
  final String avatar;
  final String status;
  final List<String> interests;
  final DateTime lastSeen;
  final double angleDegrees;
  final bool isOnline;
  final bool isDetected;
  final bool isSelected;
  final double signalStrength; // 0.0 to 1.0
  final String userId; // Real user ID for backend
  final Map<String, dynamic> metadata;

  const NearbyUser({
    required this.id,
    required this.name,
    required this.distanceKm,
    required this.avatar,
    required this.status,
    required this.interests,
    required this.lastSeen,
    required this.angleDegrees,
    this.isOnline = true,
    this.isDetected = false,
    this.isSelected = false,
    this.signalStrength = 1.0,
    this.userId = '',
    this.metadata = const {},
  });

  NearbyUser copyWith({
    String? id,
    String? name,
    double? distanceKm,
    String? avatar,
    String? status,
    List<String>? interests,
    DateTime? lastSeen,
    double? angleDegrees,
    bool? isOnline,
    bool? isDetected,
    bool? isSelected,
    double? signalStrength,
    String? userId,
    Map<String, dynamic>? metadata,
  }) {
    return NearbyUser(
      id: id ?? this.id,
      name: name ?? this.name,
      distanceKm: distanceKm ?? this.distanceKm,
      avatar: avatar ?? this.avatar,
      status: status ?? this.status,
      interests: interests ?? this.interests,
      lastSeen: lastSeen ?? this.lastSeen,
      angleDegrees: angleDegrees ?? this.angleDegrees,
      isOnline: isOnline ?? this.isOnline,
      isDetected: isDetected ?? this.isDetected,
      isSelected: isSelected ?? this.isSelected,
      signalStrength: signalStrength ?? this.signalStrength,
      userId: userId ?? this.userId,
      metadata: metadata ?? this.metadata,
    );
  }

  // Calculate signal strength based on distance
  double calculateSignalStrength(double maxRangeKm) {
    if (distanceKm > maxRangeKm) return 0.0;
    return 1.0 - (distanceKm / maxRangeKm);
  }

  // Check if user is within range
  bool isWithinRange(double rangeKm) {
    return distanceKm <= rangeKm;
  }

  // Get distance category
  String get distanceCategory {
    if (distanceKm < 0.05) return 'Very Close';
    if (distanceKm < 0.1) return 'Close';
    if (distanceKm < 0.2) return 'Nearby';
    if (distanceKm < 0.5) return 'Moderate';
    return 'Far';
  }

  // Get signal strength color
  String get signalStrengthColor {
    if (signalStrength > 0.8) return 'strong';
    if (signalStrength > 0.5) return 'medium';
    if (signalStrength > 0.2) return 'weak';
    return 'very_weak';
  }
}

class RadarSettings {
  final double detectionRangeKm;
  final bool enableSound;
  final bool enableVibration;
  final bool autoDetect;
  final int scanIntervalMs;
  final bool showSignalStrength;
  final bool enableManualDetection;

  const RadarSettings({
    this.detectionRangeKm = 0.5,
    this.enableSound = true,
    this.enableVibration = true,
    this.autoDetect = true,
    this.scanIntervalMs = 2000,
    this.showSignalStrength = true,
    this.enableManualDetection = true,
  });

  RadarSettings copyWith({
    double? detectionRangeKm,
    bool? enableSound,
    bool? enableVibration,
    bool? autoDetect,
    int? scanIntervalMs,
    bool? showSignalStrength,
    bool? enableManualDetection,
  }) {
    return RadarSettings(
      detectionRangeKm: detectionRangeKm ?? this.detectionRangeKm,
      enableSound: enableSound ?? this.enableSound,
      enableVibration: enableVibration ?? this.enableVibration,
      autoDetect: autoDetect ?? this.autoDetect,
      scanIntervalMs: scanIntervalMs ?? this.scanIntervalMs,
      showSignalStrength: showSignalStrength ?? this.showSignalStrength,
      enableManualDetection: enableManualDetection ?? this.enableManualDetection,
    );
  }
}

class RadarDetection {
  final String userId;
  final double distanceKm;
  final double angleDegrees;
  final double signalStrength;
  final DateTime detectedAt;
  final bool isManual;

  const RadarDetection({
    required this.userId,
    required this.distanceKm,
    required this.angleDegrees,
    required this.signalStrength,
    required this.detectedAt,
    this.isManual = false,
  });
} 