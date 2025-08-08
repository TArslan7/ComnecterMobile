import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sound_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  final StreamController<NotificationData> _notificationController = StreamController<NotificationData>.broadcast();
  Stream<NotificationData> get notificationStream => _notificationController.stream;

  bool _isInitialized = false;
  String? _fcmToken;
  NotificationSettings _settings = const NotificationSettings();

  // Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize Firebase
      await Firebase.initializeApp();
      
      // Initialize local notifications
      await _initializeLocalNotifications();
      
      // Request permissions
      await _requestPermissions();
      
      // Get FCM token
      await _getFCMToken();
      
      // Set up message handlers
      await _setupMessageHandlers();
      
      // Load settings
      await _loadSettings();
      
      _isInitialized = true;
    } catch (e) {
      print('Error initializing notification service: $e');
    }
  }

  // Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings();
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  // Request notification permissions
  Future<void> _requestPermissions() async {
    // Request FCM permissions
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    // Request local notification permissions
    await _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestPermission();
    await _localNotifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.requestPermission();

    print('User granted permission: ${settings.authorizationStatus}');
  }

  // Get FCM token
  Future<void> _getFCMToken() async {
    _fcmToken = await _firebaseMessaging.getToken();
    print('FCM Token: $_fcmToken');
    
    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen((token) {
      _fcmToken = token;
      print('FCM Token refreshed: $token');
    });
  }

  // Set up message handlers
  Future<void> _setupMessageHandlers() async {
    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Handle messages when app is opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
    
    // Handle initial message when app is opened from terminated state
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleBackgroundMessage(initialMessage);
    }
  }

  // Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');

    if (message.notification != null) {
      print('Message also contained a notification: ${message.notification}');
      
      // Show local notification
      _showLocalNotification(
        title: message.notification!.title ?? 'New Message',
        body: message.notification!.body ?? '',
        payload: json.encode(message.data),
      );
      
      // Emit notification data
      _notificationController.add(NotificationData(
        type: _getNotificationType(message.data),
        title: message.notification!.title ?? '',
        body: message.notification!.body ?? '',
        data: message.data,
        timestamp: DateTime.now(),
      ));
    }
  }

  // Handle background messages
  void _handleBackgroundMessage(RemoteMessage message) {
    print('Got a message whilst in the background!');
    print('Message data: ${message.data}');
    
    // Emit notification data
    _notificationController.add(NotificationData(
      type: _getNotificationType(message.data),
      title: message.notification?.title ?? '',
      body: message.notification?.body ?? '',
      data: message.data,
      timestamp: DateTime.now(),
    ));
  }

  // Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'comnecter_channel',
      'Comnecter Notifications',
      channelDescription: 'Notifications for Comnecter app',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  // Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    
    if (response.payload != null) {
      try {
        final data = json.decode(response.payload!);
        _notificationController.add(NotificationData(
          type: _getNotificationType(data),
          title: data['title'] ?? '',
          body: data['body'] ?? '',
          data: data,
          timestamp: DateTime.now(),
        ));
      } catch (e) {
        print('Error parsing notification payload: $e');
      }
    }
  }

  // Get notification type from data
  NotificationType _getNotificationType(Map<String, dynamic> data) {
    final type = data['type']?.toString().toLowerCase();
    switch (type) {
      case 'friend_request':
        return NotificationType.friendRequest;
      case 'message':
        return NotificationType.message;
      case 'radar_detection':
        return NotificationType.radarDetection;
      case 'system':
        return NotificationType.system;
      default:
        return NotificationType.general;
    }
  }

  // Send local notification
  Future<void> sendLocalNotification({
    required String title,
    required String body,
    NotificationType type = NotificationType.general,
    Map<String, dynamic>? data,
  }) async {
    if (!_settings.enabled) return;

    await _showLocalNotification(
      title: title,
      body: body,
      payload: json.encode({
        'type': type.name,
        'title': title,
        'body': body,
        ...?data,
      }),
    );

    // Play sound if enabled
    if (_settings.soundEnabled) {
      SoundService().playNotificationSound();
    }
  }

  // Send friend request notification
  Future<void> sendFriendRequestNotification(String fromUserName) async {
    await sendLocalNotification(
      title: 'New Friend Request',
      body: '$fromUserName wants to be your friend!',
      type: NotificationType.friendRequest,
      data: {'from_user': fromUserName},
    );
  }

  // Send message notification
  Future<void> sendMessageNotification(String fromUserName, String message) async {
    await sendLocalNotification(
      title: 'New Message from $fromUserName',
      body: message,
      type: NotificationType.message,
      data: {'from_user': fromUserName, 'message': message},
    );
  }

  // Send radar detection notification
  Future<void> sendRadarDetectionNotification(String userName, double distance) async {
    await sendLocalNotification(
      title: 'User Detected Nearby',
      body: '$userName is ${(distance * 1000).round()}m away!',
      type: NotificationType.radarDetection,
      data: {'user_name': userName, 'distance': distance},
    );
  }

  // Send system notification
  Future<void> sendSystemNotification(String title, String body) async {
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

  // Get FCM token
  String? get fcmToken => _fcmToken;

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
