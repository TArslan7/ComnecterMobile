import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:async';
import 'dart:math';
import 'models/user_model.dart';
import 'widgets/radar_widget.dart';
import 'widgets/empty_state_widget.dart';
import 'widgets/loading_widget.dart';
import 'widgets/user_list_widget.dart';
import '../../services/sound_service.dart';
import '../../theme/app_theme.dart';

class RadarScreen extends HookWidget {
  const RadarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final nearbyUsers = useState<List<NearbyUser>>([]);
    final isLoading = useState<bool>(false);
    final isRefreshing = useState<bool>(false);
    final refreshController = useMemoized(() => RefreshController());
    final isMounted = useRef(true);
    final confettiController = useMemoized(() => ConfettiController(duration: const Duration(seconds: 2)));
    final soundService = useMemoized(() => SoundService());

    // Animation controllers
    final pulseController = useAnimationController(duration: const Duration(milliseconds: 1500));
    final fadeController = useAnimationController(duration: const Duration(milliseconds: 800));

    // Function to fetch nearby users (simulated)
    Future<void> fetchNearbyUsers({bool isManualRefresh = false}) async {
      if (!isMounted.value) return;
      
      try {
        if (isManualRefresh) {
          isRefreshing.value = true;
        } else {
          isLoading.value = true;
        }
        
        // Simulate network delay
        await Future.delayed(const Duration(milliseconds: 1500));
        
        // Check if still mounted before updating state
        if (!isMounted.value) return;
        
        // Generate random number of users (0-8)
        final random = Random();
        final userCount = random.nextInt(9);
        final newUsers = NearbyUser.generateMockUsers(userCount);
        
        if (isMounted.value) {
          // Play sound effects based on results
          if (newUsers.isNotEmpty) {
            if (newUsers.length > nearbyUsers.value.length) {
              await soundService.playUserFoundSound();
              confettiController.play();
            } else {
              await soundService.playRadarPingSound();
            }
          } else {
            await soundService.playNotificationSound();
          }
          
          nearbyUsers.value = newUsers;
          isLoading.value = false;
          isRefreshing.value = false;
          
          // Trigger animations
          pulseController.repeat();
          fadeController.forward();
        }
      } catch (e) {
        // Handle any errors and ensure we don't update state if disposed
        if (isMounted.value) {
          isLoading.value = false;
          isRefreshing.value = false;
          await soundService.playErrorSound();
        }
      }
    }

    // Auto-refresh timer every 5 seconds
    useEffect(() {
      // Initial load
      fetchNearbyUsers();
      
      // Set up periodic refresh
      final timer = Timer.periodic(const Duration(seconds: 5), (_) {
        // Check if the widget is still mounted before updating state
        if (isMounted.value && !isLoading.value && !isRefreshing.value) {
          fetchNearbyUsers();
        }
      });
      
      return () {
        isMounted.value = false;
        timer.cancel();
      };
    }, []);

    // Manual refresh handler
    Future<void> handleRefresh() async {
      await soundService.playSwipeSound();
      await fetchNearbyUsers(isManualRefresh: true);
      refreshController.refreshCompleted();
    }

    // Handle user tap
    void handleUserTap(NearbyUser user) async {
      await soundService.playTapSound();
      
      // Show enhanced user details dialog
      showDialog(
        context: context,
        builder: (context) => _buildUserDetailsDialog(context, user),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: _buildAppBar(context, isLoading.value, fetchNearbyUsers, soundService),
      body: Stack(
        children: [
          // Main content
          SmartRefresher(
            controller: refreshController,
            enablePullDown: true,
            onRefresh: handleRefresh,
            header: WaterDropMaterialHeader(
              backgroundColor: AppTheme.primaryBlue,
              color: Colors.white,
            ),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  
                  // Status indicator
                  _buildStatusIndicator(context, nearbyUsers.value.length, isLoading.value),
                  
                  const SizedBox(height: 20),
                  
                  // Loading state
                  if (isLoading.value && nearbyUsers.value.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(40),
                      child: LoadingWidget(),
                                         ).animate().fadeIn(duration: const Duration(milliseconds: 300)),
                  
                  // Empty state
                  if (!isLoading.value && nearbyUsers.value.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(40),
                      child: EmptyStateWidget(),
                    ).animate().fadeIn(duration: const Duration(milliseconds: 500)),
                  
                  // Radar display with users
                  if (nearbyUsers.value.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: RadarWidget(
                        users: nearbyUsers.value,
                        isLoading: isLoading.value,
                        size: 320,
                        onUserTap: handleUserTap,
                      ),
                    ).animate().scale(duration: const Duration(milliseconds: 600), curve: Curves.elasticOut),
                  
                  const SizedBox(height: 20),
                  
                  // User list
                  if (nearbyUsers.value.isNotEmpty)
                    UserListWidget(
                      users: nearbyUsers.value,
                      onUserTap: handleUserTap,
                    ).animate().slideY(begin: 0.3, duration: const Duration(milliseconds: 400), delay: const Duration(milliseconds: 200)),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          
          // Confetti overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: confettiController,
              blastDirection: pi / 2,
              maxBlastForce: 5,
              minBlastForce: 2,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              gravity: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    bool isLoading,
    Future<void> Function() onRefresh,
    SoundService soundService,
  ) {
    return AppBar(
      title: Row(
        children: [
          Icon(
            Icons.radar,
            color: AppTheme.primaryBlue,
            size: 28,
          ),
          const SizedBox(width: 8),
          const Text(
            'Radar',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      actions: [
        // Settings button
        IconButton(
          icon: Icon(
            Icons.settings,
            color: AppTheme.primaryBlue,
          ),
          onPressed: () async {
            await soundService.playButtonClickSound();
            // Navigate to settings
            if (context.mounted) {
              Navigator.pushNamed(context, '/settings');
            }
          },
          tooltip: 'Settings',
        ),
        
        // Refresh button
        IconButton(
          icon: AnimatedRotation(
            turns: isLoading ? 1 : 0,
            duration: const Duration(seconds: 1),
            child: Icon(
              Icons.refresh,
              color: AppTheme.primaryBlue,
            ),
          ),
          onPressed: isLoading ? null : () async {
            await soundService.playButtonClickSound();
            onRefresh();
          },
          tooltip: 'Refresh',
        ),
      ],
    );
  }

  Widget _buildStatusIndicator(BuildContext context, int userCount, bool isLoading) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: userCount > 0 ? AppTheme.successGradient : AppTheme.secondaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            userCount > 0 ? Icons.people : Icons.search,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            isLoading
                ? 'Scanning for users...'
                : userCount > 0
                    ? '$userCount user${userCount == 1 ? '' : 's'} nearby'
                    : 'No users found nearby',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
             ),
     ).animate().fadeIn(duration: const Duration(milliseconds: 400)).slideY(begin: 0.2, duration: const Duration(milliseconds: 400));
  }

  Widget _buildUserDetailsDialog(BuildContext context, NearbyUser user) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // User avatar
            CircleAvatar(
              radius: 50,
              backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
              child: Text(
                user.name[0].toUpperCase(),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // User name
            Text(
              user.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Distance
            Text(
              '${user.distanceKm.toStringAsFixed(1)} km away',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.neutralGrey,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await SoundService().playButtonClickSound();
                      Navigator.pop(context);
                      // TODO: Implement message functionality
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Message ${user.name}'),
                            backgroundColor: AppTheme.accentGreen,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.message),
                    label: const Text('Message'),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await SoundService().playButtonClickSound();
                      Navigator.pop(context);
                      // TODO: Implement connect functionality
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Connected with ${user.name}!'),
                            backgroundColor: AppTheme.accentGreen,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.person_add),
                    label: const Text('Connect'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Close button
            TextButton(
              onPressed: () async {
                await SoundService().playButtonClickSound();
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        ),
             ),
     ).animate().scale(duration: const Duration(milliseconds: 300), curve: Curves.elasticOut);
  }
}
