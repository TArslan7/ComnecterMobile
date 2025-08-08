import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sound_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final StreamController<NotificationData> _notificationController = StreamController<NotificationData>.broadcast();
  Stream<NotificationData> get notificationStream => _notificationController.stream;

  bool _isInitialized = false;
  NotificationSettings _settings = const NotificationSettings();

  // Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load settings
      await _loadSettings();
      
      _isInitialized = true;
    } catch (e) {
      print('Error initializing notification service: $e');
    }
  }

  // Send local notification (simulated)
  Future<void> sendLocalNotification({
    required String title,
    required String body,
    NotificationType type = NotificationType.general,
    Map<String, dynamic>? data,
  }) async {
    if (!_settings.enabled) return;

    // Emit notification data
    _notificationController.add(NotificationData(
      type: type,
      title: title,
      body: body,
      data: data ?? {},
      timestamp: DateTime.now(),
    ));

    // Play sound if enabled
    if (_settings.soundEnabled) {
      SoundService().playNotificationSound();
    }

    // Show a simple dialog for now (in a real app, this would be a system notification)
    print('Notification: $title - $body');
  }

  // Send friend request notification
  Future<void> sendFriendRequestNotification(String fromUserName) async {
    if (!_settings.friendRequests) return;
    
    await sendLocalNotification(
      title: 'New Friend Request',
      body: '$fromUserName wants to be your friend!',
      type: NotificationType.friendRequest,
      data: {'from_user': fromUserName},
    );
  }

  // Send message notification
  Future<void> sendMessageNotification(String fromUserName, String message) async {
    if (!_settings.messages) return;
    
    await sendLocalNotification(
      title: 'New Message from $fromUserName',
      body: message,
      type: NotificationType.message,
      data: {'from_user': fromUserName, 'message': message},
    );
  }

  // Send radar detection notification
  Future<void> sendRadarDetectionNotification(String userName, double distance) async {
    if (!_settings.radarDetections) return;
    
    await sendLocalNotification(
      title: 'User Detected Nearby',
      body: '$userName is ${(distance * 1000).round()}m away!',
      type: NotificationType.radarDetection,
      data: {'user_name': userName, 'distance': distance},
    );
  }

  // Send system notification
  Future<void> sendSystemNotification(String title, String body) async {
    if (!_settings.systemUpdates) return;
    
    await sendLocalNotification(
      title: title,
      body: body,
      type: NotificationType.system,
    );
  }

  // Update notification settings
  Future<void> updateSettings(NotificationSettings settings) async {
    _settings = settings;
    await _saveSettings();
  }

  // Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _settings = NotificationSettings(
      enabled: prefs.getBool('notifications_enabled') ?? true,
      soundEnabled: prefs.getBool('notifications_sound_enabled') ?? true,
      vibrationEnabled: prefs.getBool('notifications_vibration_enabled') ?? true,
      friendRequests: prefs.getBool('notifications_friend_requests') ?? true,
      messages: prefs.getBool('notifications_messages') ?? true,
      radarDetections: prefs.getBool('notifications_radar_detections') ?? true,
      systemUpdates: prefs.getBool('notifications_system_updates') ?? true,
    );
  }

  // Save settings to SharedPreferences
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', _settings.enabled);
    await prefs.setBool('notifications_sound_enabled', _settings.soundEnabled);
    await prefs.setBool('notifications_vibration_enabled', _settings.vibrationEnabled);
    await prefs.setBool('notifications_friend_requests', _settings.friendRequests);
    await prefs.setBool('notifications_messages', _settings.messages);
    await prefs.setBool('notifications_radar_detections', _settings.radarDetections);
    await prefs.setBool('notifications_system_updates', _settings.systemUpdates);
  }

  // Get current settings
  NotificationSettings get settings => _settings;

  // Check if initialized
  bool get isInitialized => _isInitialized;

  // Dispose resources
  void dispose() {
    _notificationController.close();
  }
}

// Notification types
enum NotificationType {
  friendRequest,
  message,
  radarDetection,
  system,
  general,
}

// Notification data
class NotificationData {
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  NotificationData({
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.timestamp,
  });
}

// Notification settings
class NotificationSettings {
  final bool enabled;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool friendRequests;
  final bool messages;
  final bool radarDetections;
  final bool systemUpdates;

  const NotificationSettings({
    this.enabled = true,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.friendRequests = true,
    this.messages = true,
    this.radarDetections = true,
    this.systemUpdates = true,
  });

  NotificationSettings copyWith({
    bool? enabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? friendRequests,
    bool? messages,
    bool? radarDetections,
    bool? systemUpdates,
  }) {
    return NotificationSettings(
      enabled: enabled ?? this.enabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      friendRequests: friendRequests ?? this.friendRequests,
      messages: messages ?? this.messages,
      radarDetections: radarDetections ?? this.radarDetections,
      systemUpdates: systemUpdates ?? this.systemUpdates,
    );
  }
}
