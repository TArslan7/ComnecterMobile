// TODO: Voeg lokale notificatiepreview toe bij nieuwe berichten
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/notification_model.dart';
import '../models/user_model.dart';
import '../models/message_model.dart';
import '../models/community_model.dart';

class NotificationService extends ChangeNotifier {
  static const String _notificationsKey = 'user_notifications';
  
  // In-memory cache
  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  
  // Getters
  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  
  // Initialize service
  Future<void> initialize() async {
    await loadNotifications();
  }
  
  // Load all notifications from storage
  Future<void> loadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getString(_notificationsKey);
      
      if (notificationsJson != null) {
        final List<dynamic> decodedList = jsonDecode(notificationsJson);
        _notifications = decodedList.map((item) => AppNotification.fromJson(item)).toList();
        
        // Sort by timestamp (newest first)
        _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        
        // Count unread
        _unreadCount = _notifications.where((notification) => !notification.isRead).length;
        
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    }
  }
  
  // Get all notifications
  Future<List<AppNotification>> getAllNotifications() async {
    await loadNotifications(); // Ensure we have the latest
    return _notifications;
  }
  
  // Save notifications to storage
  Future<void> _saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _notificationsKey,
        jsonEncode(_notifications.map((notification) => notification.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('Error saving notifications: $e');
    }
  }
  
  // Add a new notification
  Future<AppNotification> addNotification({
    required String title,
    required String body,
    required NotificationType type,
    Map<String, dynamic>? data,
    String? imageUrl,
  }) async {
    final notification = AppNotification(
      id: const Uuid().v4(),
      title: title,
      body: body,
      timestamp: DateTime.now(),
      type: type,
      isRead: false,
      data: data,
      imageUrl: imageUrl,
    );
    
    _notifications.insert(0, notification); // Add to beginning of list
    _unreadCount++;
    
    await _saveNotifications();
    notifyListeners();
    
    return notification;
  }
  
  // Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere((notification) => notification.id == notificationId);
    
    if (index != -1) {
      final notification = _notifications[index];
      
      if (!notification.isRead) {
        _notifications[index] = notification.copyWith(isRead: true);
        _unreadCount = Math.max(0, _unreadCount - 1);
        
        await _saveNotifications();
        notifyListeners();
      }
    }
  }
  
  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    bool hasChanges = false;
    
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
        hasChanges = true;
      }
    }
    
    if (hasChanges) {
      _unreadCount = 0;
      await _saveNotifications();
      notifyListeners();
    }
  }
  
  // Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    final index = _notifications.indexWhere((notification) => notification.id == notificationId);
    
    if (index != -1) {
      final wasUnread = !_notifications[index].isRead;
      _notifications.removeAt(index);
      
      if (wasUnread) {
        _unreadCount = Math.max(0, _unreadCount - 1);
      }
      
      await _saveNotifications();
      notifyListeners();
    }
  }
  
  // Clear all notifications
  Future<void> clearAllNotifications() async {
    _notifications = [];
    _unreadCount = 0;
    
    await _saveNotifications();
    notifyListeners();
  }
  
  // Factory methods for creating common notification types
  
  // New message notification
  Future<AppNotification> createMessageNotification({
    required String senderName,
    required String senderId,
    required String chatId,
    required String messageContent,
    bool isCommunityMessage = false,
    String? communityName,
  }) async {
    final title = isCommunityMessage 
        ? 'New message in $communityName' 
        : 'New message from $senderName';
        
    return await addNotification(
      title: title,
      body: messageContent,
      type: NotificationType.message,
      data: {
        'chatId': chatId,
        'senderId': senderId,
        'isCommunityMessage': isCommunityMessage,
        'communityName': communityName,
      },
    );
  }
  
  // Friend request notification
  Future<AppNotification> createFriendRequestNotification({
    required String userName,
    required String userId,
  }) async {
    return await addNotification(
      title: 'New Friend Request',
      body: '$userName sent you a friend request',
      type: NotificationType.friendRequest,
      data: {
        'userId': userId,
      },
    );
  }
  
  // Friend request accepted notification
  Future<AppNotification> createFriendAcceptedNotification({
    required String userName,
    required String userId,
  }) async {
    return await addNotification(
      title: 'Friend Request Accepted',
      body: '$userName accepted your friend request',
      type: NotificationType.friendAccepted,
      data: {
        'userId': userId,
      },
    );
  }
  
  // Nearby user notification
  Future<AppNotification> createNearbyUserNotification({
    required String userName,
    required String userId,
    required double distance,
    List<String>? commonInterests,
  }) async {
    String body;
    if (commonInterests != null && commonInterests.isNotEmpty) {
      body = '$userName is ${distance.toStringAsFixed(1)}km away and shares interests in ${commonInterests.join(', ')}';
    } else {
      body = '$userName is ${distance.toStringAsFixed(1)}km away';
    }
    
    return await addNotification(
      title: 'New User Nearby',
      body: body,
      type: NotificationType.nearbyUser,
      data: {
        'userId': userId,
        'distance': distance,
        'commonInterests': commonInterests,
      },
    );
  }
  
  // Community invitation notification
  Future<AppNotification> createCommunityInviteNotification({
    required String communityName,
    required String communityId,
    required String inviterName,
    String? description,
  }) async {
    return await addNotification(
      title: 'Community Invitation',
      body: '$inviterName invited you to join $communityName',
      type: NotificationType.community,
      data: {
        'communityId': communityId,
        'inviterId': inviterName,
        'action': 'invite',
        'description': description,
      },
    );
  }
  
  // System notification
  Future<AppNotification> createSystemNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    return await addNotification(
      title: title,
      body: body,
      type: NotificationType.system,
      data: data,
    );
  }
}

// Just for the Math.max function
class Math {
  static int max(int a, int b) => a > b ? a : b;
}