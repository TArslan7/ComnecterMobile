import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import '../providers/user_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/community_provider.dart';
import '../models/notification_model.dart';
import '../models/user_model.dart';
import '../services/notification_service.dart';
import '../services/sound_service.dart';
import 'home_screen.dart';
import 'chat_detail_screen.dart';
import 'profile_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  List<AppNotification> _allNotifications = [];
  
  // Categorized notifications
  List<AppNotification> _messageNotifications = [];
  List<AppNotification> _friendNotifications = [];
  List<AppNotification> _nearbyNotifications = [];
  List<AppNotification> _communityNotifications = [];
  List<AppNotification> _systemNotifications = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadNotifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    
    try {
      final notificationService = Provider.of<NotificationService>(context, listen: false);
      final notifications = await notificationService.getAllNotifications();
      
      // Categorize notifications
      _allNotifications = notifications;
      _messageNotifications = notifications.where((n) => n.type == NotificationType.message).toList();
      _friendNotifications = notifications.where((n) => n.type == NotificationType.friendRequest ||
                                                        n.type == NotificationType.friendAccepted).toList();
      _nearbyNotifications = notifications.where((n) => n.type == NotificationType.nearbyUser).toList();
      _communityNotifications = notifications.where((n) => n.type == NotificationType.community).toList();
      _systemNotifications = notifications.where((n) => n.type == NotificationType.system).toList();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading notifications: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _markAllAsRead() async {
    setState(() => _isLoading = true);
    
    try {
      final notificationService = Provider.of<NotificationService>(context, listen: false);
      await notificationService.markAllAsRead();
      await _loadNotifications(); // Reload to reflect changes
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All notifications marked as read'))
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _markAsRead(AppNotification notification) async {
    try {
      final notificationService = Provider.of<NotificationService>(context, listen: false);
      await notificationService.markAsRead(notification.id);
      
      // Update local state
      setState(() {
        final index = _allNotifications.indexWhere((n) => n.id == notification.id);
        if (index != -1) {
          _allNotifications[index] = notification.copyWith(isRead: true);
          
          // Update categorized lists too
          _updateCategorizedLists();
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
  
  void _updateCategorizedLists() {
    _messageNotifications = _allNotifications.where((n) => n.type == NotificationType.message).toList();
    _friendNotifications = _allNotifications.where((n) => n.type == NotificationType.friendRequest ||
                                                      n.type == NotificationType.friendAccepted).toList();
    _nearbyNotifications = _allNotifications.where((n) => n.type == NotificationType.nearbyUser).toList();
    _communityNotifications = _allNotifications.where((n) => n.type == NotificationType.community).toList();
    _systemNotifications = _allNotifications.where((n) => n.type == NotificationType.system).toList();
  }

  Future<void> _deleteNotification(AppNotification notification) async {
    try {
      final notificationService = Provider.of<NotificationService>(context, listen: false);
      await notificationService.deleteNotification(notification.id);
      
      // Update local state
      setState(() {
        _allNotifications.removeWhere((n) => n.id == notification.id);
        _updateCategorizedLists();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification deleted'))
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _clearAllNotifications() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications?'),
        content: const Text('This will delete all your notifications. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              
              try {
                final notificationService = Provider.of<NotificationService>(context, listen: false);
                await notificationService.clearAllNotifications();
                
                // Update local state
                setState(() {
                  _allNotifications = [];
                  _messageNotifications = [];
                  _friendNotifications = [];
                  _nearbyNotifications = [];
                  _communityNotifications = [];
                  _systemNotifications = [];
                });
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All notifications cleared'))
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              } finally {
                if (mounted) {
                  setState(() => _isLoading = false);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _handleNotificationAction(AppNotification notification) async {
    // Mark as read when interacted with
    if (!notification.isRead) {
      await _markAsRead(notification);
    }
    
    // Handle different notification types
    switch (notification.type) {
      case NotificationType.message:
        // Navigate to chat detail
        if (notification.data != null && notification.data!.containsKey('chatId')) {
          final chatId = notification.data!['chatId'];
          final otherUserId = notification.data!['senderId'];
          
          // Find user from provider
          final userProvider = Provider.of<UserProvider>(context, listen: false);
          UserModel? otherUser;
          try {
            otherUser = userProvider.nearbyUsers.firstWhere(
              (user) => user.userId == otherUserId,
            );
          } catch (e) {
            otherUser = null;
          }
          
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatDetailScreen(
                chatId: chatId,
                otherUser: otherUser,
              ),
            ),
          );
        }
        break;
        
      case NotificationType.friendRequest:
        // Show friend request detail and actions
        if (notification.data != null && notification.data!.containsKey('userId')) {
          _showFriendRequestDetail(notification);
        }
        break;
        
      case NotificationType.friendAccepted:
        // Navigate to that user's profile
        if (notification.data != null && notification.data!.containsKey('userId')) {
          // In a full implementation, would navigate to user profile
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Would navigate to user profile'))
          );
        }
        break;
        
      case NotificationType.nearbyUser:
        // Navigate to radar screen
        HomeScreen.navigateToTab(context, 0); // Radar tab index
        break;
        
      case NotificationType.community:
        // Navigate to community detail or handle invitation
        if (notification.data != null && notification.data!.containsKey('communityId')) {
          // In a full implementation, would navigate to community detail
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Would navigate to community detail'))
          );
        }
        break;
        
      case NotificationType.system:
        // Handle system notifications (usually just display info)
        break;
    }
  }

  void _showFriendRequestDetail(AppNotification notification) {
    final userId = notification.data?['userId'];
    if (userId == null) return;
    
    // Find user from provider
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    UserModel? user;
    try {
      user = userProvider.nearbyUsers.firstWhere(
        (user) => user.userId == userId,
      );
    } catch (e) {
      // User not found
      user = null;
    }
    
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not found'))
      );
      return;
    }
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(bottom: 24),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            // Title
            const Text(
              'Friend Request',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            
            const SizedBox(height: 24),
            
            // User info
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppTheme.accentColor,
                  child: Text(
                    user?.userName?.substring(0, 1).toUpperCase() ?? '?',
                    style: const TextStyle(color: Colors.white, fontSize: 24),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.userName ?? 'Unknown User',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('@${user?.username ?? 'unknown'}'),
                      if (user?.interests.isNotEmpty ?? false) ...
                      [
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 4,
                          children: (user?.interests ?? []).map((interest) => Chip(
                            label: Text(interest, style: const TextStyle(fontSize: 12)),
                            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                            labelStyle: TextStyle(color: AppTheme.primaryColor),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          )).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            
            const Spacer(),
            
            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Reject friend request
                      // Would implement in a full app
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Friend request declined'))
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Accept friend request
                      // Would implement in a full app
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Friend request accepted'))
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all as read',
            onPressed: _markAllAsRead,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear_all') {
                _clearAllNotifications();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'clear_all',
                child: ListTile(
                  leading: Icon(Icons.delete_sweep),
                  title: Text('Clear all'),
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            _buildTab('All', _allNotifications.where((n) => !n.isRead).length),
            _buildTab('Messages', _messageNotifications.where((n) => !n.isRead).length),
            _buildTab('Friends', _friendNotifications.where((n) => !n.isRead).length),
            _buildTab('Nearby', _nearbyNotifications.where((n) => !n.isRead).length),
            _buildTab('Communities', _communityNotifications.where((n) => !n.isRead).length),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildNotificationList(_allNotifications),
                _buildNotificationList(_messageNotifications),
                _buildNotificationList(_friendNotifications),
                _buildNotificationList(_nearbyNotifications),
                _buildNotificationList(_communityNotifications),
              ],
            ),
    );
  }

  Widget _buildTab(String title, int count) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title),
          if (count > 0) ...
          [
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotificationList(List<AppNotification> notifications) {
    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'No notifications',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'You\'re all caught up!',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        // Add haptic feedback
        HapticFeedback.mediumImpact();
        
        // Add sound effect
        final SoundService soundService = SoundService();
        soundService.playTapSound();
        
        // Reload notifications
        await _loadNotifications();
        
        // Play success sound
        soundService.playSuccessSound();
      },
      color: AppTheme.primaryColor,
      backgroundColor: Theme.of(context).brightness == Brightness.dark 
          ? Colors.grey[800] 
          : Colors.white,
      strokeWidth: 3.0,
      displacement: 40.0,
      child: ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return Dismissible(
            key: Key(notification.id),
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 16),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            direction: DismissDirection.endToStart,
            onDismissed: (direction) {
              _deleteNotification(notification);
            },
            child: _buildNotificationTile(notification),
          );
        },
      ),
    );
  }

  Widget _buildNotificationTile(AppNotification notification) {
    // Icon and color based on notification type
    IconData icon;
    Color color;
    
    switch (notification.type) {
      case NotificationType.message:
        icon = Icons.chat_bubble_outline;
        color = Colors.blue;
        break;
      case NotificationType.friendRequest:
        icon = Icons.person_add_alt;
        color = AppTheme.primaryColor;
        break;
      case NotificationType.friendAccepted:
        icon = Icons.people_outline;
        color = Colors.green;
        break;
      case NotificationType.nearbyUser:
        icon = Icons.radar;
        color = AppTheme.accentColor;
        break;
      case NotificationType.community:
        icon = Icons.group_outlined;
        color = Colors.purple;
        break;
      case NotificationType.system:
        icon = Icons.info_outline;
        color = Colors.orange;
        break;
    }

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(
        notification.title,
        style: TextStyle(
          fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(notification.body),
          const SizedBox(height: 4),
          Text(
            _formatTimestamp(notification.timestamp),
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
      isThreeLine: true,
      onTap: () => _handleNotificationAction(notification),
      trailing: !notification.isRead
          ? Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            )
          : null,
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, yyyy').format(timestamp);
    }
  }
}