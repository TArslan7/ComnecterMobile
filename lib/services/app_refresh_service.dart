import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/community_provider.dart';
import '../services/notification_service.dart';

/// A service that centralizes app-wide refresh operations
class AppRefreshService {
  /// Refreshes all data in the app
  /// Returns true if all refreshes were successful, false otherwise
  static Future<bool> refreshAll(BuildContext context) async {
    bool success = true;
    
    try {
      // Get all providers
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      final communityProvider = Provider.of<CommunityProvider>(context, listen: false);
      final notificationService = Provider.of<NotificationService>(context, listen: false);
      
      // Get current user
      final currentUser = userProvider.currentUser;
      if (currentUser == null) {
        debugPrint('Cannot refresh: No current user found');
        return false;
      }
      
      // Execute refreshes in parallel
      await Future.wait([
        // Refresh nearby users
        userProvider.refreshNearbyUsers().catchError((e) {
          debugPrint('Error refreshing nearby users: $e');
          success = false;
        }),
        
        // Refresh chats
        chatProvider.loadChats(currentUser.userId).catchError((e) {
          debugPrint('Error refreshing chats: $e');
          success = false;
        }),
        
        // Refresh communities
        communityProvider.loadAllCommunities().catchError((e) {
          debugPrint('Error refreshing communities: $e');
          success = false;
        }),
        
        // Refresh user communities
        communityProvider.loadUserCommunities(currentUser.userId).catchError((e) {
          debugPrint('Error refreshing user communities: $e');
          success = false;
        }),
        
        // Refresh notifications
        notificationService.loadNotifications().catchError((e) {
          debugPrint('Error refreshing notifications: $e');
          success = false;
        }),
      ]);
      
      return success;
    } catch (e) {
      debugPrint('Error during app refresh: $e');
      return false;
    }
  }
}