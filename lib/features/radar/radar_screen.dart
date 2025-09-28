import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'dart:math';
import '../friends/services/friend_service.dart';
import 'services/radar_service.dart';
import 'services/detection_history_service.dart';
import 'models/user_model.dart';
import 'models/detection_model.dart';
import 'widgets/radar_range_slider.dart';

class RadarScreen extends HookWidget {
  const RadarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isScanning = useState(true);
    final heartbeatController = useAnimationController(
      duration: const Duration(milliseconds: 800),
    );
    final radarController = useAnimationController(
      duration: const Duration(milliseconds: 1200),
    );
    
    // Radar service integration
    final radarService = useMemoized(() => RadarService(), []);
    final detectedUsers = useState<List<NearbyUser>>([]);
    final friendService = useMemoized(() => FriendService(), []);
    final rangeSettings = useState<RadarRangeSettings>(const RadarRangeSettings());
    
    // Detection history service - use the same instance as RadarService
    final detectionHistoryService = useMemoized(() => DetectionHistoryService(), []);
    
    // Foldable state for detected users list
    final isUsersListExpanded = useState(true);
    
    // Real-time privacy settings feedback
    final currentRange = useState(2.0);
    final isDetectable = useState(true);

    useEffect(() {
      // Initialize services (RadarService will initialize DetectionHistoryService)
      radarService.initialize().then((_) {
        // Initialize privacy settings
        currentRange.value = radarService.getCurrentRange();
        isDetectable.value = radarService.getDetectabilityStatus();
        // Initialize range settings with current range
        rangeSettings.value = rangeSettings.value.copyWith(rangeKm: currentRange.value);
      });
      
      // Listen to detected users
      final subscription = radarService.usersStream.listen((users) {
        detectedUsers.value = users.where((user) => user.isDetected).toList();
        // Update privacy settings from radar service
        currentRange.value = radarService.getCurrentRange();
        isDetectable.value = radarService.getDetectabilityStatus();
        // Update range settings to reflect current state
        rangeSettings.value = rangeSettings.value.copyWith(rangeKm: currentRange.value);
      });


      // Start scanning initially if visible
      if (isDetectable.value) {
        radarService.startScanning();
      }

      return () {
        subscription.cancel();
        radarService.stopScanning();
      };
    }, []);

    // Update range settings when changed
    useEffect(() {
      radarService.updateRangeSettings(rangeSettings.value);
      return null;
    }, [rangeSettings.value]);

    useEffect(() {
      if (isDetectable.value) {
        radarService.startScanning();
        heartbeatController.repeat();
        radarController.repeat();
      } else {
        radarService.stopScanning();
        heartbeatController.stop();
        radarController.stop();
      }
      return null;
    }, [isDetectable.value]);

    void toggleRadarVisibility() {
      isDetectable.value = !isDetectable.value;
      radarService.toggleRadarVisibility(isDetectable.value);
    }

    void sendFriendRequest(NearbyUser user) async {
      try {
        await friendService.sendFriendRequest(
          user.id,
          user.name,
          user.avatar,
          message: 'Hey! I detected you on radar. Would you like to connect?',
        );
        
        // Show success message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Friend request sent to ${user.name}!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        // Show error message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to send friend request: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    return Scaffold(
              backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            context.push('/settings');
          },
          icon: Icon(
            Icons.settings,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
          tooltip: 'Settings',
        ),
        actions: [
          IconButton(
            onPressed: () {
              context.push('/detection-history');
            },
            icon: Icon(
              Icons.favorite,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            tooltip: 'Saved Favorites',
          ),
          IconButton(
            onPressed: () {
              context.push('/notifications');
            },
            icon: Icon(
              Icons.notifications,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            tooltip: 'Notifications',
          ),
          IconButton(
            onPressed: () {
              context.push('/friends');
            },
            icon: Icon(
              Icons.people,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            tooltip: 'Friends',
          ),
          IconButton(
            onPressed: toggleRadarVisibility,
            icon: Icon(
              isDetectable.value ? Icons.visibility : Icons.visibility_off,
              color: isDetectable.value ? Colors.green.shade600 : Colors.grey.shade600,
              size: 24,
            ),
            tooltip: isDetectable.value ? 'Hide from Radar' : 'Show on Radar',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
                        colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surface.withValues(alpha: 0.3),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Main Radar Circle
              Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Stack(
                  children: [
                    // Expanding radar rings
                    ...List.generate(3, (index) {
                      return AnimatedBuilder(
                        animation: radarController,
                        builder: (context, child) {
                          final progress = (radarController.value + index * 0.3) % 1.0;
                          final radius = 140 * progress;
                          final opacity = (1.0 - progress) * 0.8;
                          
                          return Positioned(
                            left: 140 - radius,
                            top: 140 - radius,
                            child: Container(
                              width: radius * 2,
                              height: radius * 2,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.primary.withValues(alpha: opacity),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    }),
                    
                    // Central pulsing radar core
                    Center(
                      child: AnimatedBuilder(
                        animation: heartbeatController,
                        builder: (context, child) {
                          final opacity = 0.7 + (heartbeatController.value * 0.3);
                          
                          return Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Theme.of(context).colorScheme.primary.withValues(alpha: opacity),
                                  Theme.of(context).colorScheme.primary.withValues(alpha: opacity * 0.5),
                                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.radar,
                              color: Theme.of(context).colorScheme.onPrimary,
                              size: 25,
                            ),
                          );
                        },
                      ),
                    ),
                    
                    // Scanning indicator dots
                    ...List.generate(8, (index) {
                      return AnimatedBuilder(
                        animation: radarController,
                        builder: (context, child) {
                          final progress = (radarController.value + index * 0.125) % 1.0;
                          final angle = index * (3.14159 / 4); // 45 degrees apart
                          final radius = 110 * progress;
                          final x = 140 + (radius * cos(angle));
                          final y = 140 + (radius * sin(angle));
                          final opacity = (1.0 - progress) * 0.9;
                          
                          return Positioned(
                            left: x - 3,
                            top: y - 3,
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Theme.of(context).colorScheme.secondary.withValues(alpha: opacity),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context).colorScheme.secondary.withValues(alpha: opacity * 0.5),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    }),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Status text
              Text(
                isDetectable.value ? 'Scanning for connections...' : 'Radar hidden - not detecting others',
                style: TextStyle(
                  fontSize: 16,
                  color: isDetectable.value 
                      ? Theme.of(context).colorScheme.onSurface
                      : Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Connection status
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDetectable.value 
                          ? Colors.green.shade600 
                          : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isDetectable.value ? 'Visible' : 'Hidden',
                      style: TextStyle(
                        color: isDetectable.value 
                          ? Colors.green.shade700 
                          : Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Real-time Privacy Settings Feedback
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Range Display
                    Row(
                      children: [
                        Icon(
                          Icons.radar,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          rangeSettings.value.getDisplayValue(),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    
                    // Divider
                    Container(
                      width: 1,
                      height: 20,
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                    ),
                    
                    // Detection Ability Status
                    Row(
                      children: [
                        Icon(
                          isDetectable.value ? Icons.radar : Icons.radar_outlined,
                          size: 16,
                          color: isDetectable.value 
                              ? Colors.blue.shade600 
                              : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isDetectable.value ? 'Detecting' : 'Not Detecting',
                          style: TextStyle(
                            color: isDetectable.value 
                                ? Colors.blue.shade700 
                                : Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 25),
              
              // Range Slider
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: RadarRangeSlider(
                  settings: rangeSettings.value,
                  onChanged: (newSettings) {
                    rangeSettings.value = newSettings;
                  },
                  userCount: detectedUsers.value.length,
                ),
              ),
              
              const SizedBox(height: 25),
              
              // Detected Users List - Foldable
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header - clickable to expand/collapse
                    GestureDetector(
                      onTap: () {
                        isUsersListExpanded.value = !isUsersListExpanded.value;
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.people,
                              color: Theme.of(context).colorScheme.primary,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Detected Users',
                              style: TextStyle(
                                fontSize: 15,
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${detectedUsers.value.length}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            AnimatedRotation(
                              turns: isUsersListExpanded.value ? 0.0 : 0.5,
                              duration: const Duration(milliseconds: 300),
                              child: Icon(
                                Icons.expand_less,
                                color: Theme.of(context).colorScheme.primary,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Expandable content
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      height: isUsersListExpanded.value ? null : 0,
                      child: isUsersListExpanded.value ? Container(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          children: [
                    
                    // User List with Swipe-to-Save
                    ...List.generate(detectedUsers.value.length, (index) {
                      final user = detectedUsers.value[index];
                      
                      return _SwipeableUserCard(
                        user: user,
                        isFavorite: false, // We're not showing favorites section, so always false
                        onTap: () {
                          context.push('/user-profile/${user.id}', extra: {'user': user});
                        },
                        onSaveToFavorites: () {
                          // Convert NearbyUser to UserDetection and save
                          final detection = UserDetection.fromNearbyUser(user);
                          detectionHistoryService.addToFavorites(detection);
                        },
                        onRemoveFromFavorites: () {
                          detectionHistoryService.removeFromFavorites(user.id);
                        },
                        onConnect: () => sendFriendRequest(user),
                      );
                    }),
                    
                            // Empty state when no users detected
                            if (detectedUsers.value.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.radar_outlined,
                                      size: 32,
                                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      isDetectable.value 
                                        ? 'Scanning for nearby users...' 
                                        : 'Radar hidden - cannot detect others',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ) : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A swipeable user card with save-to-favorites functionality
class _SwipeableUserCard extends HookWidget {
  final NearbyUser user;
  final bool isFavorite;
  final VoidCallback? onTap;
  final VoidCallback? onSaveToFavorites;
  final VoidCallback? onRemoveFromFavorites;
  final VoidCallback? onConnect;

  const _SwipeableUserCard({
    required this.user,
    this.isFavorite = false,
    this.onTap,
    this.onSaveToFavorites,
    this.onRemoveFromFavorites,
    this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    final swipeOffset = useState(0.0);
    final isSwipeActive = useState(false);
    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 200),
    );

    // Handle swipe gestures
    void handlePanUpdate(DragUpdateDetails details) {
      if (isFavorite) return; // Don't allow swiping for favorites
      
      final delta = details.delta.dx;
      final newOffset = (swipeOffset.value + delta).clamp(-200.0, 200.0);
      swipeOffset.value = newOffset;
      
      if (newOffset.abs() > 50) {
        isSwipeActive.value = true;
        animationController.forward();
      } else {
        isSwipeActive.value = false;
        animationController.reverse();
      }
    }

    void handlePanEnd(DragEndDetails details) {
      if (isFavorite) return;
      
      if (swipeOffset.value > 100) {
        // Swipe right - save to favorites with glow animation
        animationController.forward().then((_) {
          animationController.reverse();
        });
        onSaveToFavorites?.call();
        HapticFeedback.mediumImpact();
      } else {
        // Reset position
        animationController.reverse();
      }
      
      swipeOffset.value = 0.0;
      isSwipeActive.value = false;
    }

    return GestureDetector(
      onPanUpdate: handlePanUpdate,
      onPanEnd: handlePanEnd,
      onTap: onTap,
      child: AnimatedBuilder(
        animation: animationController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(swipeOffset.value, 0),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                  // Glow effect when swiping
                  if (isSwipeActive.value)
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.3 + (animationController.value * 0.4)),
                      blurRadius: 20 + (animationController.value * 30),
                      spreadRadius: 5 + (animationController.value * 15),
                    ),
                ],
              ),
              child: Stack(
                children: [
                  // Main card content
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isFavorite 
                            ? Colors.red.withValues(alpha: 0.3)
                            : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Avatar
                        Stack(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context).colorScheme.primary,
                                    Theme.of(context).colorScheme.secondary,
                                  ],
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  user.name[0],
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            // Favorite indicator
                            if (isFavorite)
                              Positioned(
                                right: -2,
                                top: -2,
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(
                                    Icons.favorite,
                                    color: Colors.white,
                                    size: 8,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        
                        const SizedBox(width: 10),
                        
                        // User Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: user.isOnline 
                                        ? Theme.of(context).colorScheme.primary 
                                        : Theme.of(context).colorScheme.outline,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    user.isOnline ? 'Online' : 'Offline',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '• ${(user.distanceKm * 1000).round()}m',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        // Connect Button
                        GestureDetector(
                          onTap: onConnect,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              'Connect',
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Swipe action indicators
                  if (!isFavorite) _buildSwipeActions(context, animationController, swipeOffset.value),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSwipeActions(BuildContext context, AnimationController animationController, double swipeOffset) {
    return Positioned.fill(
      child: Row(
        children: [
          // Right side - save action
          if (swipeOffset > 50)
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                ),
                child: AnimatedBuilder(
                  animation: animationController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1.0 + (animationController.value * 0.2),
                      child: const Center(
                        child: Icon(
                          Icons.favorite,
                          color: Colors.green,
                          size: 20,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
