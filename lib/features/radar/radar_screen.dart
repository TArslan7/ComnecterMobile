import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:async';
import 'dart:math';
import '../../services/sound_service.dart';
import '../../theme/app_theme.dart';
import 'models/user_model.dart';
import 'widgets/radar_widget.dart';
import 'widgets/empty_state_widget.dart';
import 'widgets/loading_widget.dart';

class RadarScreen extends HookWidget {
  const RadarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final nearbyUsers = useState<List<NearbyUser>>([]);
    final isLoading = useState(true);
    final isRefreshing = useState(false);
    final confettiController = useMemoized(() => ConfettiController(duration: const Duration(seconds: 2)));
    final soundService = useMemoized(() => SoundService());
    final pulseController = useAnimationController(duration: const Duration(seconds: 2));
    final fadeController = useAnimationController(duration: const Duration(milliseconds: 300));

    // Mock data for nearby users
    final mockUsers = [
      NearbyUser(
        id: '1',
        name: 'Sarah Johnson',
        distanceKm: 0.05,
        avatar: '👩‍🦰',
        status: 'Online',
        interests: ['Music', 'Travel', 'Photography'],
        lastSeen: DateTime.now(),
        angleDegrees: 45,
      ),
      NearbyUser(
        id: '2',
        name: 'Mike Chen',
        distanceKm: 0.12,
        avatar: '👨‍💼',
        status: 'Away',
        interests: ['Technology', 'Gaming', 'Coffee'],
        lastSeen: DateTime.now().subtract(const Duration(minutes: 30)),
        angleDegrees: 120,
      ),
      NearbyUser(
        id: '3',
        name: 'Emma Wilson',
        distanceKm: 0.08,
        avatar: '👩‍🎨',
        status: 'Online',
        interests: ['Art', 'Design', 'Fashion'],
        lastSeen: DateTime.now(),
        angleDegrees: 200,
      ),
    ];

    Future<void> fetchNearbyUsers() async {
      try {
        // Simulate network delay
        await Future.delayed(const Duration(milliseconds: 2000));
        
        // Simulate finding users
        soundService.playRadarPingSound();
        
        // Add users gradually for better UX
        for (int i = 0; i < mockUsers.length; i++) {
          await Future.delayed(const Duration(milliseconds: 500));
          nearbyUsers.value = [...nearbyUsers.value, mockUsers[i]];
          soundService.playUserFoundSound();
          confettiController.play();
        }
        
        soundService.playNotificationSound();
      } catch (e) {
        soundService.playErrorSound();
      }
    }

    Future<void> handleRefresh() async {
      if (isRefreshing.value) return;
      
      isRefreshing.value = true;
      soundService.playSwipeSound();
      
      // Clear existing users
      nearbyUsers.value = [];
      
      // Fetch new users
      await fetchNearbyUsers();
      
      isRefreshing.value = false;
    }

    void handleUserTap(NearbyUser user) {
      soundService.playTapSound();
      _buildUserDetailsDialog(context, user);
    }

    // Initial load
    useEffect(() {
      fetchNearbyUsers();
      
             // Auto-refresh every 5 seconds
       final timer = Timer.periodic(const Duration(seconds: 5), (timer) {
         if (!isRefreshing.value) {
           handleRefresh();
         }
       });
      
      return () {
        timer.cancel();
      };
    }, []);

    // Start pulse animation
    useEffect(() {
      pulseController.repeat();
      return null;
    }, []);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: _buildAppBar(context, soundService, handleRefresh, isRefreshing),
      body: Stack(
        children: [
          // Main content with smooth transitions
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: isLoading.value
                ? _buildLoadingState(context)
                : nearbyUsers.value.isEmpty
                    ? _buildEmptyState(context)
                    : _buildUserList(context, nearbyUsers.value, handleUserTap),
          ),
          
          // Status indicator
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: _buildStatusIndicator(context, isLoading.value, nearbyUsers.value.length, isRefreshing.value),
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
    SoundService soundService,
    VoidCallback onRefresh,
    ValueNotifier<bool> isRefreshing,
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
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      actions: [
        // Animated refresh button
        AnimatedBuilder(
          animation: isRefreshing.value ? const AlwaysStoppedAnimation(1.0) : const AlwaysStoppedAnimation(0.0),
          builder: (context, child) {
            return Transform.rotate(
              angle: isRefreshing.value ? 2 * pi : 0,
              child: IconButton(
                icon: Icon(
                  isRefreshing.value ? Icons.refresh : Icons.refresh,
                  color: AppTheme.primaryBlue,
                ),
                onPressed: isRefreshing.value ? null : () async {
                  soundService.playButtonClickSound();
                  onRefresh();
                },
              ),
            );
          },
        ),
        IconButton(
          icon: Icon(
            Icons.settings,
            color: AppTheme.primaryBlue,
          ),
          onPressed: () {
            soundService.playButtonClickSound();
            Navigator.pushNamed(context, '/settings');
          },
        ),
      ],
    );
  }

  Widget _buildStatusIndicator(
    BuildContext context,
    bool isLoading,
    int userCount,
    bool isRefreshing,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLoading || isRefreshing) ...[
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              isRefreshing ? 'Refreshing...' : 'Scanning for users...',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ] else ...[
            Icon(
              Icons.people,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              '$userCount users nearby',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: const Duration(milliseconds: 300));
  }

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Radar animation
          Container(
            width: 200,
            height: 200,
            child: RadarWidget(
              onUserTap: (user) {},
              users: [],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Scanning for nearby users...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This may take a few seconds',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return const EmptyStateWidget();
  }

  Widget _buildUserList(
    BuildContext context,
    List<NearbyUser> users,
    Function(NearbyUser) onUserTap,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 80, 16, 16),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: _buildUserCard(context, user, onUserTap),
        ).animate().fadeIn(
          delay: Duration(milliseconds: index * 100),
          duration: const Duration(milliseconds: 300),
        ).slideY(
          begin: 0.3,
          duration: const Duration(milliseconds: 300),
        );
      },
    );
  }

  Widget _buildUserCard(
    BuildContext context,
    NearbyUser user,
    Function(NearbyUser) onUserTap,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => onUserTap(user),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar with online indicator
              Stack(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Center(
                      child: Text(
                        user.avatar,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  if (user.isOnline)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                                                 Text(
                           '${(user.distanceKm * 1000).round()}m',
                           style: TextStyle(
                             fontSize: 14,
                             color: Colors.grey[600],
                             fontWeight: FontWeight.w500,
                           ),
                         ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.interests.join(' • '),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _buildUserDetailsDialog(BuildContext context, NearbyUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Center(
                child: Text(
                  user.avatar,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                                     Text(
                     '${(user.distanceKm * 1000).round()}m away',
                     style: TextStyle(
                       fontSize: 12,
                       color: Colors.grey[600],
                     ),
                   ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Interests:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: user.interests.map((interest) => Chip(
                label: Text(interest),
                backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
              )).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement chat functionality
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Start Chat'),
          ),
        ],
      ),
    );
  }
}
