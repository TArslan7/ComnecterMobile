
import 'package:flutter/material.dart';

class NearbyUser {
  final String id;
  final String name;
  final String avatar;
  final double distanceKm;
  final double angleDegrees;
  final double signalStrength;
  final bool isOnline;
  final bool isDetected;
  final bool isSelected;
  final List<String> interests;
  final DateTime lastSeen;
  final Map<String, dynamic> metadata;

  NearbyUser({
    required this.id,
    required this.name,
    required this.avatar,
    required this.distanceKm,
    required this.angleDegrees,
    required this.signalStrength,
    required this.isOnline,
    this.isDetected = false,
    this.isSelected = false,
    this.interests = const [],
    required this.lastSeen,
    this.metadata = const {},
  });

  NearbyUser copyWith({
    String? id,
    String? name,
    String? avatar,
    double? distanceKm,
    double? angleDegrees,
    double? signalStrength,
    bool? isOnline,
    bool? isDetected,
    bool? isSelected,
    List<String>? interests,
    DateTime? lastSeen,
    Map<String, dynamic>? metadata,
  }) {
    return NearbyUser(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      distanceKm: distanceKm ?? this.distanceKm,
      angleDegrees: angleDegrees ?? this.angleDegrees,
      signalStrength: signalStrength ?? this.signalStrength,
      isOnline: isOnline ?? this.isOnline,
      isDetected: isDetected ?? this.isDetected,
      isSelected: isSelected ?? this.isSelected,
      interests: interests ?? this.interests,
      lastSeen: lastSeen ?? this.lastSeen,
      metadata: metadata ?? this.metadata,
    );
  }

  // Calculate signal strength based on distance
  double calculateSignalStrength(double maxRangeKm) {
    if (distanceKm > maxRangeKm) return 0.0;
    return (1.0 - (distanceKm / maxRangeKm)).clamp(0.0, 1.0);
  }

  // Check if user is within detection range
  bool isWithinRange(double maxRangeKm) {
    return distanceKm <= maxRangeKm;
  }

  // Get distance category
  String get distanceCategory {
    if (distanceKm < 0.1) return 'Very Close';
    if (distanceKm < 0.5) return 'Close';
    if (distanceKm < 1.0) return 'Nearby';
    if (distanceKm < 2.0) return 'Medium Range';
    return 'Far Away';
  }

  // Get signal strength color
  Color get signalStrengthColor {
    if (signalStrength > 0.8) return const Color(0xFF10B981); // Green
    if (signalStrength > 0.5) return const Color(0xFFF59E0B); // Orange
    if (signalStrength > 0.2) return const Color(0xFFEF4444); // Red
    return const Color(0xFF6B7280); // Gray
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'distanceKm': distanceKm,
      'angleDegrees': angleDegrees,
      'signalStrength': signalStrength,
      'isOnline': isOnline,
      'isDetected': isDetected,
      'isSelected': isSelected,
      'interests': interests,
      'lastSeen': lastSeen.toIso8601String(),
      'metadata': metadata,
    };
  }

  // Create from JSON
  factory NearbyUser.fromJson(Map<String, dynamic> json) {
    return NearbyUser(
      id: json['id'],
      name: json['name'],
      avatar: json['avatar'],
      distanceKm: json['distanceKm'].toDouble(),
      angleDegrees: json['angleDegrees'].toDouble(),
      signalStrength: json['signalStrength'].toDouble(),
      isOnline: json['isOnline'],
      isDetected: json['isDetected'] ?? false,
      isSelected: json['isSelected'] ?? false,
      interests: List<String>.from(json['interests'] ?? []),
      lastSeen: DateTime.parse(json['lastSeen']),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }
}

class RadarSettings {
  final double detectionRangeKm;
  final int scanIntervalMs;
  final bool enableAutoDetection;
  final bool enableManualDetection;
  final bool enableSound;
  final bool enableVibration;
  final bool showSignalStrength;
  final bool showOnlineStatus;
  final bool showInterests;

  const RadarSettings({
    this.detectionRangeKm = 2.0,
    this.scanIntervalMs = 3000,
    this.enableAutoDetection = true,
    this.enableManualDetection = true,
    this.enableSound = true,
    this.enableVibration = true,
    this.showSignalStrength = true,
    this.showOnlineStatus = true,
    this.showInterests = true,
  });

  RadarSettings copyWith({
    double? detectionRangeKm,
    int? scanIntervalMs,
    bool? enableAutoDetection,
    bool? enableManualDetection,
    bool? enableSound,
    bool? enableVibration,
    bool? showSignalStrength,
    bool? showOnlineStatus,
    bool? showInterests,
  }) {
    return RadarSettings(
      detectionRangeKm: detectionRangeKm ?? this.detectionRangeKm,
      scanIntervalMs: scanIntervalMs ?? this.scanIntervalMs,
      enableAutoDetection: enableAutoDetection ?? this.enableAutoDetection,
      enableManualDetection: enableManualDetection ?? this.enableManualDetection,
      enableSound: enableSound ?? this.enableSound,
      enableVibration: enableVibration ?? this.enableVibration,
      showSignalStrength: showSignalStrength ?? this.showSignalStrength,
      showOnlineStatus: showOnlineStatus ?? this.showOnlineStatus,
      showInterests: showInterests ?? this.showInterests,
    );
  }
}

class RadarDetection {
  final String userId;
  final DateTime timestamp;
  final bool isManual;
  final double signalStrength;
  final double distanceKm;

  RadarDetection({
    required this.userId,
    required this.timestamp,
    required this.isManual,
    required this.signalStrength,
    required this.distanceKm,
  });
}

enum RadarView {
  radar,
  list,
  map,
}
