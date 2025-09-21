import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'dart:math';
import '../friends/services/friend_service.dart';
import 'services/radar_service.dart';
import 'models/user_model.dart';
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

    useEffect(() {
      // Initialize radar service
      radarService.initialize();
      
      // Listen to detected users
      final subscription = radarService.usersStream.listen((users) {
        detectedUsers.value = users.where((user) => user.isDetected).toList();
      });

      // Start scanning initially
      if (isScanning.value) {
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
      if (isScanning.value) {
        radarService.startScanning();
        heartbeatController.repeat();
        radarController.repeat();
      } else {
        radarService.stopScanning();
        heartbeatController.stop();
        radarController.stop();
      }
      return null;
    }, [isScanning.value]);

    void toggleScanning() {
      isScanning.value = !isScanning.value;
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
            onPressed: toggleScanning,
            icon: Icon(
              isScanning.value ? Icons.pause : Icons.play_arrow,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            tooltip: isScanning.value ? 'Pause Radar' : 'Start Radar',
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
                isScanning.value ? 'Scanning for connections...' : 'Radar paused',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface,
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
                        color: isScanning.value 
                          ? Theme.of(context).colorScheme.primary 
                          : Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isScanning.value ? 'Active' : 'Inactive',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
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
              
              // Detected Users List
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
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
                    Row(
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
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // User List
                    ...List.generate(detectedUsers.value.length, (index) {
                      final user = detectedUsers.value[index];
                      
                      return GestureDetector(
                        onTap: () {
                          context.push('/user-profile/${user.id}', extra: {'user': user});
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              // Avatar
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
                                onTap: () => sendFriendRequest(user),
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
                              isScanning.value 
                                ? 'Scanning for nearby users...' 
                                : 'No users detected in range',
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
