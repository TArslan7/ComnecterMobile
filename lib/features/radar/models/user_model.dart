
import 'package:flutter/material.dart';
import 'dart:math';

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

enum RadarRangeMode {
  local,    // ≤50 km
  regional, // ≤2000 km  
  global,   // >2000 km, up to 20,000 km
}

class RadarRangeSettings {
  final double rangeKm;
  final RadarRangeMode mode;
  final bool useClusters;
  final bool useHeatmap;
  final double minRadiusKm;
  final bool enableJitter;
  final bool useMiles;

  const RadarRangeSettings({
    this.rangeKm = 5.0,
    this.mode = RadarRangeMode.local,
    this.useClusters = false,
    this.useHeatmap = false,
    this.minRadiusKm = 1.0,
    this.enableJitter = true,
    this.useMiles = false,
  });

  // Smart step calculation based on range
  double get stepSize {
    if (rangeKm <= 100) return 1.0;
    if (rangeKm <= 1000) return 10.0;
    return 100.0;
  }

  // Get range mode based on current range
  RadarRangeMode getRangeMode(double range) {
    if (range <= 50) return RadarRangeMode.local;
    if (range <= 2000) return RadarRangeMode.regional;
    return RadarRangeMode.global;
  }

  // Check if should use clusters for current range
  bool shouldUseClusters() {
    return rangeKm > 1000 || mode == RadarRangeMode.global;
  }

  // Check if should use heatmap for current range
  bool shouldUseHeatmap() {
    return rangeKm > 5000 || mode == RadarRangeMode.global;
  }

  // Apply privacy jitter to distance
  double applyJitter(double distanceKm) {
    if (!enableJitter) return distanceKm;
    
    final jitter = (distanceKm * 0.05).clamp(0.1, 2.0); // 5% jitter, max 2km
    final random = Random();
    final jitterValue = (random.nextDouble() - 0.5) * 2 * jitter;
    return (distanceKm + jitterValue).clamp(minRadiusKm, double.infinity);
  }

  // Convert km to miles
  double toMiles(double km) => km * 0.621371;
  
  // Convert miles to km
  double toKm(double miles) => miles * 1.60934;

  // Get display value with unit
  String getDisplayValue() {
    final value = useMiles ? toMiles(rangeKm) : rangeKm;
    final unit = useMiles ? 'mi' : 'km';
    return '${value.toStringAsFixed(value % 1 == 0 ? 0 : 1)} $unit';
  }

  // Get range description
  String get rangeDescription {
    switch (mode) {
      case RadarRangeMode.local:
        return 'Local Area';
      case RadarRangeMode.regional:
        return 'Regional';
      case RadarRangeMode.global:
        return 'Global';
    }
  }

  // Get range color based on mode
  Color get rangeColor {
    switch (mode) {
      case RadarRangeMode.local:
        return const Color(0xFF3B82F6); // Blue - matches radar
      case RadarRangeMode.regional:
        return const Color(0xFF3B82F6); // Blue - matches radar
      case RadarRangeMode.global:
        return const Color(0xFF3B82F6); // Blue - matches radar
    }
  }

  RadarRangeSettings copyWith({
    double? rangeKm,
    RadarRangeMode? mode,
    bool? useClusters,
    bool? useHeatmap,
    double? minRadiusKm,
    bool? enableJitter,
    bool? useMiles,
  }) {
    final newRange = rangeKm ?? this.rangeKm;
    final newMode = mode ?? getRangeMode(newRange);
    
    return RadarRangeSettings(
      rangeKm: newRange,
      mode: newMode,
      useClusters: useClusters ?? shouldUseClusters(),
      useHeatmap: useHeatmap ?? shouldUseHeatmap(),
      minRadiusKm: minRadiusKm ?? this.minRadiusKm,
      enableJitter: enableJitter ?? this.enableJitter,
      useMiles: useMiles ?? this.useMiles,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rangeKm': rangeKm,
      'mode': mode.index,
      'useClusters': useClusters,
      'useHeatmap': useHeatmap,
      'minRadiusKm': minRadiusKm,
      'enableJitter': enableJitter,
      'useMiles': useMiles,
    };
  }

  factory RadarRangeSettings.fromJson(Map<String, dynamic> json) {
    return RadarRangeSettings(
      rangeKm: json['rangeKm']?.toDouble() ?? 5.0,
      mode: RadarRangeMode.values[json['mode'] ?? 0],
      useClusters: json['useClusters'] ?? false,
      useHeatmap: json['useHeatmap'] ?? false,
      minRadiusKm: json['minRadiusKm']?.toDouble() ?? 1.0,
      enableJitter: json['enableJitter'] ?? true,
      useMiles: json['useMiles'] ?? false,
    );
  }
}
