import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';
import '../models/notification_model.dart';

class NotificationBadge extends StatelessWidget {
  final Widget child;
  final Color badgeColor;
  final double badgeSize;
  final EdgeInsets padding;
  
  const NotificationBadge({
    Key? key,
    required this.child,
    this.badgeColor = Colors.red,
    this.badgeSize = 16,
    this.padding = const EdgeInsets.only(right: 8, top: 8),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationService>(
      builder: (context, notificationService, _) {
        final unreadCount = notificationService.unreadCount;
        
        if (unreadCount == 0) {
          return child;
        }
        
        return Stack(
          clipBehavior: Clip.none,
          children: [
            child,
            Positioned(
              right: padding.right,
              top: padding.top,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: badgeColor,
                  shape: BoxShape.circle,
                ),
                constraints: BoxConstraints(
                  minWidth: badgeSize,
                  minHeight: badgeSize,
                ),
                child: Center(
                  child: Text(
                    unreadCount > 9 ? '9+' : unreadCount.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: badgeSize * 0.7,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class CategoryNotificationBadge extends StatelessWidget {
  final Widget child;
  final NotificationType type;
  final Color badgeColor;
  final double badgeSize;
  final EdgeInsets padding;
  
  const CategoryNotificationBadge({
    Key? key,
    required this.child,
    required this.type,
    this.badgeColor = Colors.red,
    this.badgeSize = 16,
    this.padding = const EdgeInsets.only(right: 8, top: 8),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationService>(
      builder: (context, notificationService, _) {
        // Filter notifications by type
        final notifications = notificationService.notifications;
        final filteredCount = notifications.where((n) => !n.isRead && n.type == type).length;
        
        if (filteredCount == 0) {
          return child;
        }
        
        return Stack(
          clipBehavior: Clip.none,
          children: [
            child,
            Positioned(
              right: padding.right,
              top: padding.top,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: badgeColor,
                  shape: BoxShape.circle,
                ),
                constraints: BoxConstraints(
                  minWidth: badgeSize,
                  minHeight: badgeSize,
                ),
                child: Center(
                  child: Text(
                    filteredCount > 9 ? '9+' : filteredCount.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: badgeSize * 0.7,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}