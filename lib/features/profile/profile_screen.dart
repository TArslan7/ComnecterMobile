import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter/services.dart';
import '../../services/sound_service.dart';
import '../../services/profile_service.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends HookWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProfile = useState<Map<String, dynamic>>({});
    final isLoading = useState(true);
    final refreshTrigger = useState(0);
    final soundService = useMemoized(() => SoundService());
    final profileService = useMemoized(() => ProfileService.instance);

    // Load user profile on initialization and when refresh is triggered
    Future<void> loadUserProfile() async {
      try {
        isLoading.value = true;
        print('🔄 Loading profile data (trigger: ${refreshTrigger.value})');
        final profile = await profileService.getCurrentUserProfile();
        if (profile != null) {
          print('✅ Profile loaded: $profile');
          userProfile.value = profile;
        } else {
          // Fallback to default profile if loading fails
          userProfile.value = {
            'name': 'User',
            'username': '@user',
            'avatar': '👤',
            'bio': '',
            'interests': [],
          };
        }
      } catch (e) {
        print('❌ Error loading profile: $e');
        // Use fallback profile
        userProfile.value = {
          'name': 'User',
          'username': '@user',
          'avatar': '👤',
          'bio': '',
          'interests': [],
        };
      } finally {
        isLoading.value = false;
      }
    }

    useEffect(() {
      loadUserProfile();
      return null;
    }, [refreshTrigger.value]);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.settings, color: Theme.of(context).colorScheme.primary, size: 22),
          onPressed: () => context.push('/settings'),
          tooltip: 'Settings',
          padding: const EdgeInsets.all(8),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications, color: Theme.of(context).colorScheme.primary, size: 22),
            onPressed: () => context.push('/notifications'),
            tooltip: 'Notifications',
            padding: const EdgeInsets.all(8),
          ),
          IconButton(
            icon: Icon(Icons.people, color: Theme.of(context).colorScheme.primary, size: 22),
            onPressed: () => context.push('/friends'),
            tooltip: 'Friends',
            padding: const EdgeInsets.all(8),
          ),
        ],
      ),
      body: isLoading.value
          ? _buildLoadingState(context)
          : _buildCleanProfileContent(context, userProfile.value, soundService, refreshTrigger),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  // Hero section with animated profile photo and radar status
  Widget _buildCleanProfileContent(BuildContext context, Map<String, dynamic> profile, SoundService soundService, ValueNotifier<int> refreshTrigger) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          
          // Hero Section (Profile Photo + Name + Username)
          _buildHeroSection(context, profile, soundService),
          
          const SizedBox(height: 20),
          
          // Bio Section
          if (profile['bio'] != null && profile['bio'].toString().trim().isNotEmpty) ...[
            _buildBioSection(context, profile),
            const SizedBox(height: 16),
          ],
          
          // Interests Section
          if (profile['interests'] != null && (profile['interests'] as List).isNotEmpty) ...[
            _buildInterestsDisplay(context, profile),
            const SizedBox(height: 16),
          ],
          
          const SizedBox(height: 28),
          
          // Radar Visibility Status - Tertiary hierarchy
          _buildRadarStatus(context, {
            'isVisible': true,
            'range': 5,
            'isBoosted': false,
          }),
          
          const SizedBox(height: 32),
          
          // Edit Profile Button
          _buildEditProfileButton(context, refreshTrigger),
          
          const SizedBox(height: 40),
          
          // Stat Cards Section
          _buildStatCards(context, profile),
        ],
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, Map<String, dynamic> profile, SoundService soundService) {
    // Heartbeat-like pulsing animation with addictive rhythm
    final heartbeatController = useAnimationController(
      duration: const Duration(milliseconds: 800), // Faster heartbeat
    );
    final glowAnimation = useAnimationController(
      duration: const Duration(milliseconds: 600), // Quicker glow
    );
    final scaleAnimation = useAnimationController(
      duration: const Duration(milliseconds: 400), // Quick scale pulse
    );
    final radarStatus = useState<Map<String, dynamic>>({
      'isVisible': true,
      'range': 5,
      'isBoosted': false,
    });

    // Start addictive heartbeat animations
    useEffect(() {
      // Heartbeat pattern: quick pulse, pause, quick pulse, longer pause
      void startHeartbeat() {
        heartbeatController.forward().then((_) {
          heartbeatController.reverse().then((_) {
            Future.delayed(const Duration(milliseconds: 200), () {
              heartbeatController.forward().then((_) {
                heartbeatController.reverse().then((_) {
                  Future.delayed(const Duration(milliseconds: 400), () {
                    startHeartbeat(); // Repeat the pattern
                  });
                });
              });
            });
          });
        });
      }
      
      // Continuous glow animation
      glowAnimation.repeat(reverse: true);
      
      // Quick scale pulses
      scaleAnimation.repeat(reverse: true);
      
      startHeartbeat();
      
      return null;
    }, []);

    // Simulate radar status changes
    useEffect(() {
      final timer = Stream.periodic(const Duration(seconds: 3), (i) => i).listen((_) {
        radarStatus.value = {
          'isVisible': !radarStatus.value['isVisible'],
          'range': radarStatus.value['isVisible'] ? 100 : 5,
          'isBoosted': !radarStatus.value['isVisible'],
        };
      });
      return timer.cancel;
    }, []);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Animated Profile Photo with Heartbeat Pulsing
          _buildAnimatedProfilePhoto(context, profile, heartbeatController, glowAnimation, scaleAnimation),
          
          const SizedBox(height: 32),
          
          // User Name - Primary hierarchy
          Text(
            profile['name'] ?? 'User',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 12),
          
          // Copyable and Shareable Username - Secondary hierarchy
          _buildCopyableUsername(context, profile),
        ],
      ),
    );
  }

  Widget _buildAnimatedProfilePhoto(BuildContext context, Map<String, dynamic> profile, 
      AnimationController heartbeatController, AnimationController glowAnimation, AnimationController scaleAnimation) {
    return AnimatedBuilder(
      animation: Listenable.merge([heartbeatController, glowAnimation, scaleAnimation]),
      builder: (context, child) {
        final heartbeatValue = heartbeatController.value;
        final glowValue = glowAnimation.value;
        final scaleValue = scaleAnimation.value;
        
        // Create addictive heartbeat effect with multiple layers
        final pulseScale = 1.0 + (heartbeatValue * 0.15); // Stronger pulse
        final glowIntensity = 0.4 + (glowValue * 0.3) + (heartbeatValue * 0.2);
        final scalePulse = 1.0 + (scaleValue * 0.05); // Subtle scale variation
        
        return Transform.scale(
          scale: pulseScale * scalePulse,
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                // Outer heartbeat glow - most intense
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: glowIntensity),
                  blurRadius: 25 + (heartbeatValue * 15) + (glowValue * 8),
                  spreadRadius: 3 + (heartbeatValue * 4) + (glowValue * 2),
                ),
                // Secondary glow layer
                BoxShadow(
                  color: Theme.of(context).colorScheme.secondary.withValues(alpha: glowIntensity * 0.7),
                  blurRadius: 15 + (heartbeatValue * 10) + (glowValue * 5),
                  spreadRadius: 2 + (heartbeatValue * 3) + (glowValue * 1),
                ),
                // Tertiary glow for depth
                BoxShadow(
                  color: Theme.of(context).colorScheme.tertiary.withValues(alpha: glowIntensity * 0.5),
                  blurRadius: 8 + (heartbeatValue * 5) + (glowValue * 3),
                  spreadRadius: 1 + (heartbeatValue * 2),
                ),
                // Inner shadow for depth
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 5,
                  spreadRadius: -1,
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                    Theme.of(context).colorScheme.tertiary,
                    Theme.of(context).colorScheme.primary,
                  ],
                  stops: [0.0, 0.3, 0.7, 1.0],
                ),
                shape: BoxShape.circle,
              ),
              child: Container(
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    // Inner glow effect
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1 + (heartbeatValue * 0.05)),
                      blurRadius: 3,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    child: Text(
                      profile['avatar'] ?? '👤',
                      style: TextStyle(
                        fontSize: 60 + (heartbeatValue * 5), // Subtle text size pulse
                        shadows: [
                          Shadow(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCopyableUsername(BuildContext context, Map<String, dynamic> profile) {
    final username = profile['username'] ?? '@user';
    
    return GestureDetector(
      onTap: () async {
        await HapticFeedback.lightImpact();
        await Clipboard.setData(ClipboardData(text: username));
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Username copied: $username'),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      },
      onLongPress: () async {
        await HapticFeedback.mediumImpact();
        await Share.share(
          'Check out my profile on Comnecter: $username',
          subject: 'My Comnecter Profile',
        );
      },
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                username,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                Icons.copy,
                size: 18,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRadarStatus(BuildContext context, Map<String, dynamic> status) {
    final isVisible = status['isVisible'] as bool;
    final range = status['range'] as int;
    final isBoosted = status['isBoosted'] as bool;
    
    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: isVisible 
            ? (isBoosted 
              ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.2)
              : Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.2))
            : Theme.of(context).colorScheme.surfaceContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isVisible 
              ? (isBoosted 
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)
                : Theme.of(context).colorScheme.secondary.withValues(alpha: 0.5))
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              child: Icon(
                isVisible 
                  ? (isBoosted ? Icons.rocket_launch : Icons.radar)
                  : Icons.visibility_off,
                size: 20,
                color: isVisible 
                  ? (isBoosted 
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.secondary)
                  : Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(width: 10),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 500),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isVisible 
                  ? (isBoosted 
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.secondary)
                  : Theme.of(context).colorScheme.outline,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ) ?? const TextStyle(),
              child: Text(
                isVisible 
                  ? (isBoosted 
                    ? '🚀 Boosted to $range km'
                    : '🔵 Visible in $range km')
                  : '⚫ Hidden from radar',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCards(BuildContext context, Map<String, dynamic> profile) {
    final friendsCount = useState<int>(profile['friendsCount'] ?? 0);
    final detectionsCount = useState<int>(profile['detectionsCount'] ?? 0);
    final communitiesCount = useState<int>(profile['communitiesCount'] ?? 0);
    
    // Simulate data updates for demo purposes
    useEffect(() {
      final timer = Stream.periodic(const Duration(seconds: 5), (i) => i).listen((count) {
        friendsCount.value = (friendsCount.value + (count % 3)).clamp(0, 999);
        detectionsCount.value = (detectionsCount.value + (count % 2)).clamp(0, 999);
        communitiesCount.value = (communitiesCount.value + (count % 4)).clamp(0, 99);
      });
      return timer.cancel;
    }, []);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Stats',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  icon: '👥',
                  count: friendsCount.value,
                  label: 'Friends',
                  onTap: () => context.push('/friends'),
                  isEmpty: friendsCount.value == 0,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context,
                  icon: '📡',
                  count: detectionsCount.value,
                  label: 'Detections',
                  onTap: () => _showDetectionsHistory(context, detectionsCount.value),
                  isEmpty: detectionsCount.value == 0,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context,
                  icon: '🏘️',
                  count: communitiesCount.value,
                  label: 'Communities',
                  onTap: () => _showCommunities(context, communitiesCount.value),
                  isEmpty: communitiesCount.value == 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, {
    required String icon,
    required int count,
    required String label,
    required VoidCallback onTap,
    required bool isEmpty,
  }) {
    return GestureDetector(
      onTap: () async {
        await HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isEmpty
                ? [
                    Theme.of(context).colorScheme.surfaceContainer.withValues(alpha: 0.3),
                    Theme.of(context).colorScheme.surfaceContainer.withValues(alpha: 0.1),
                  ]
                : [
                    Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.2),
                    Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.1),
                  ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isEmpty
                ? Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)
                : Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: isEmpty
              ? []
              : [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Text(
              icon,
              style: TextStyle(
                fontSize: 24,
                color: isEmpty
                    ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            
            // Animated Counter
            isEmpty
                ? Text(
                    '0',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  )
                : AnimatedCounter(
                    count: count,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
            
            const SizedBox(height: 4),
            
            // Label
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isEmpty
                    ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            
            // Empty state message
            if (isEmpty) ...[
              const SizedBox(height: 4),
              Text(
                _getEmptyStateMessage(label),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getEmptyStateMessage(String label) {
    switch (label.toLowerCase()) {
      case 'friends':
        return 'No friends yet 👀\nStart connecting!';
      case 'detections':
        return 'No detections yet 👀\nTry boosting your radar!';
      case 'communities':
        return 'No communities yet 👀\nJoin groups nearby!';
      default:
        return 'No data yet 👀';
    }
  }

  void _showDetectionsHistory(BuildContext context, int detectionsCount) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            
            Text(
              '📡 Detection History',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Check if user has detections
            if (detectionsCount == 0) ...[
              Icon(
                Icons.radar_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
              ),
              const SizedBox(height: 16),
              Text(
                'No detections yet 👀',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Try boosting your radar!\nTurn on your radar and start scanning for nearby users.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  // TODO: Navigate to radar screen
                },
                icon: const Icon(Icons.radar),
                label: const Text('Open Radar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ] else ...[
              // Show detections list (placeholder for MVP)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.radar,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'You\'ve made $detectionsCount detections!',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Detection history features coming soon!\nYou\'ll be able to view detailed logs of all your radar scans.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showCommunities(BuildContext context, int communitiesCount) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            
            Text(
              '🏘️ Joined Communities',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Check if user has communities
            if (communitiesCount == 0) ...[
              Icon(
                Icons.groups_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
              ),
              const SizedBox(height: 16),
              Text(
                'No communities yet 👀',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Join groups nearby!\nConnect with like-minded people in your area.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  // TODO: Navigate to communities discovery
                },
                icon: const Icon(Icons.explore),
                label: const Text('Explore Communities'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ] else ...[
              // Show joined communities list (placeholder for MVP)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.groups,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'You\'re in $communitiesCount communities!',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Community management features coming soon!\nYou\'ll be able to view and manage all your joined groups.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBioSection(BuildContext context, Map<String, dynamic> profile) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.description_outlined,
                size: 18,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 8),
              Text(
                'Bio',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            profile['bio'] ?? '',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              height: 1.4,
            ),
            textAlign: TextAlign.left,
          ),
        ],
      ),
    );
  }

  Widget _buildInterestsDisplay(BuildContext context, Map<String, dynamic> profile) {
    final interests = List<String>.from(profile['interests'] ?? []);
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.interests_outlined,
                size: 18,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 8),
              Text(
                'Interests',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: interests.map((interest) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  interest.trim(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEditProfileButton(BuildContext context, ValueNotifier<int> refreshTrigger) {
    return Center(
      child: ElevatedButton.icon(
        onPressed: () => _openEditProfile(context, refreshTrigger),
        icon: const Icon(Icons.edit, size: 18),
        label: const Text('Edit Profile'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  void _openEditProfile(BuildContext context, ValueNotifier<int> refreshTrigger) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EditProfileScreen(),
        fullscreenDialog: true,
      ),
    );
    
    // Refresh profile if changes were saved
    if (result == true && context.mounted) {
      print('🔄 Refreshing profile after edit...');
      refreshTrigger.value = refreshTrigger.value + 1;
    }
  }
}

class EditProfileScreen extends HookWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profileService = useMemoized(() => ProfileService.instance);
    final isLoading = useState(false);
    final isSaving = useState(false);
    final showSuccess = useState(false);
    
    // Form controllers
    final nameController = useTextEditingController();
    final bioController = useTextEditingController();
    final interestsController = useTextEditingController();
    
    // Form state
    final selectedAvatar = useState<String>('👤');
    final interests = useState<List<String>>([]);
    final hasChanges = useState(false);
    
    // Available avatars
    final availableAvatars = [
      '👤', '👨', '👩', '🧑', '👨‍💼', '👩‍💼', '👨‍🎓', '👩‍🎓',
      '👨‍🎨', '👩‍🎨', '👨‍🚀', '👩‍🚀', '👨‍💻', '👩‍💻', '👨‍🔬', '👩‍🔬',
      '🦸', '🦸‍♀️', '🦸‍♂️', '🧙', '🧙‍♀️', '🧙‍♂️', '🧚', '🧚‍♀️',
      '🧚‍♂️', '🎭', '🎨', '🎪', '🎯', '🏆', '🌟', '💫'
    ];

    // Load profile data
    useEffect(() {
      Future<void> loadProfile() async {
        isLoading.value = true;
        try {
          print('🔄 Loading profile data...');
          print('🔄 ProfileService instance: $profileService');
          
          // Check if user is authenticated
          final auth = FirebaseAuth.instance;
          final user = auth.currentUser;
          print('🔄 Current user: ${user?.uid}');
          print('🔄 User email: ${user?.email}');
          
          final profile = await profileService.getCurrentUserProfile();
          if (profile != null) {
            print('✅ Profile loaded: $profile');
            nameController.text = profile['name'] ?? '';
            bioController.text = profile['bio'] ?? '';
            selectedAvatar.value = profile['avatar'] ?? '👤';
            interests.value = List<String>.from(profile['interests'] ?? []);
            interestsController.text = interests.value.join(', ');
          } else {
            print('❌ No profile data found');
            // Set default values if no profile exists
            nameController.text = '';
            bioController.text = '';
            selectedAvatar.value = '👤';
            interests.value = [];
            interestsController.text = '';
          }
        } catch (e) {
          print('❌ Error loading profile: $e');
          // Set default values on error
          nameController.text = '';
          bioController.text = '';
          selectedAvatar.value = '👤';
          interests.value = [];
          interestsController.text = '';
        } finally {
          isLoading.value = false;
        }
      }
      loadProfile();
      return null;
    }, []);

    // Track changes
    useEffect(() {
      void checkChanges() {
        final hasNameChanges = nameController.text.trim().isNotEmpty;
        final hasBioChanges = bioController.text.trim().isNotEmpty;
        final hasInterestsChanges = interestsController.text.trim().isNotEmpty;
        
        hasChanges.value = hasNameChanges || hasBioChanges || hasInterestsChanges;
        
        print('🔍 Change detection: name=$hasNameChanges, bio=$hasBioChanges, interests=$hasInterestsChanges, hasChanges=${hasChanges.value}');
      }
      
      nameController.addListener(checkChanges);
      bioController.addListener(checkChanges);
      interestsController.addListener(checkChanges);
      
      // Initial check
      checkChanges();
      
      return () {
        nameController.removeListener(checkChanges);
        bioController.removeListener(checkChanges);
        interestsController.removeListener(checkChanges);
      };
    }, []);

    // Parse interests from text
    void updateInterests() {
      final text = interestsController.text.trim();
      if (text.isEmpty) {
        interests.value = [];
      } else {
        interests.value = text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      }
    }

    // Save profile
    Future<void> saveProfile() async {
      if (isSaving.value) return;
      
      // Validate required fields
      final name = nameController.text.trim();
      if (name.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Please enter a display name'),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
      
      isSaving.value = true;
      updateInterests();
      
      try {
        final profileData = {
          'name': name,
          'bio': bioController.text.trim(),
          'avatar': selectedAvatar.value,
          'interests': interests.value,
        };
        
        print('🔄 Attempting to save profile data: $profileData');
        
        final success = await profileService.updateUserProfile(profileData);
        
        print('💾 Save result: $success');
        
        if (success) {
          showSuccess.value = true;
          await Future.delayed(const Duration(milliseconds: 1500));
          if (context.mounted) {
            Navigator.pop(context, true); // Return true to indicate success
          }
        } else {
          // Show error message
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Failed to save profile. Please try again.'),
                backgroundColor: Theme.of(context).colorScheme.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } catch (e) {
        print('❌ Error saving profile: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        isSaving.value = false;
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Profile',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          // Debug indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: hasChanges.value ? Colors.green : Colors.grey,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              hasChanges.value ? 'CHANGES' : 'NO CHANGES',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (hasChanges.value)
            TextButton(
              onPressed: isSaving.value ? null : saveProfile,
              child: isSaving.value
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    )
                  : Text(
                      'Save',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
        ],
      ),
      body: showSuccess.value
          ? _buildSuccessAnimation(context)
          : isLoading.value
              ? const Center(child: CircularProgressIndicator())
              : _buildEditForm(context, selectedAvatar, availableAvatars, nameController, bioController, interestsController, updateInterests),
    );
  }

  Widget _buildSuccessAnimation(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check,
              size: 60,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Profile Updated!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your changes have been saved successfully',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm(
    BuildContext context,
    ValueNotifier<String> selectedAvatar,
    List<String> availableAvatars,
    TextEditingController nameController,
    TextEditingController bioController,
    TextEditingController interestsController,
    VoidCallback updateInterests,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Photo Section
          _buildAvatarSection(context, selectedAvatar, availableAvatars),
          
          const SizedBox(height: 32),
          
          // Display Name Section
          _buildTextField(
            context,
            controller: nameController,
            label: 'Display Name',
            hint: 'Enter your display name',
            icon: Icons.person,
            maxLines: 1,
          ),
          
          const SizedBox(height: 24),
          
          // Bio Section
          _buildTextField(
            context,
            controller: bioController,
            label: 'Bio',
            hint: 'Tell us about yourself...',
            icon: Icons.description,
            maxLines: 3,
          ),
          
          const SizedBox(height: 24),
          
          // Interests Section
          _buildInterestsSection(context, interestsController, updateInterests),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildAvatarSection(BuildContext context, ValueNotifier<String> selectedAvatar, List<String> availableAvatars) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profile Photo',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        
        // Selected Avatar Preview
        Center(
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  selectedAvatar.value,
                  style: const TextStyle(fontSize: 40),
                ),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Avatar Selection Grid
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose an avatar',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: availableAvatars.map((avatar) {
                  final isSelected = selectedAvatar.value == avatar;
                  return GestureDetector(
                    onTap: () => selectedAvatar.value = avatar,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          avatar,
                          style: TextStyle(
                            fontSize: 20,
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainer.withValues(alpha: 0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInterestsSection(BuildContext context, TextEditingController interestsController, VoidCallback updateInterests) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Interests',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: interestsController,
          maxLines: 2,
          onChanged: (_) => updateInterests(),
          decoration: InputDecoration(
            hintText: 'Enter your interests separated by commas (e.g., 🎵 Music, 📚 Reading, 🏃‍♂️ Running)',
            prefixIcon: Icon(
              Icons.interests,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainer.withValues(alpha: 0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '💡 Tip: Use emojis to make your interests more fun and expressive!',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

class AnimatedCounter extends HookWidget {
  final int count;
  final TextStyle? style;

  const AnimatedCounter({
    super.key,
    required this.count,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 800),
    );
    final previousCount = useRef<int>(count);

    useEffect(() {
      if (previousCount.value != count) {
        animationController.forward(from: 0);
        previousCount.value = count;
      }
      return null;
    }, [count]);

    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        final animatedValue = Tween<double>(
          begin: previousCount.value.toDouble(),
          end: count.toDouble(),
        ).animate(CurvedAnimation(
          parent: animationController,
          curve: Curves.easeOutCubic,
        ));

        return Text(
          animatedValue.value.round().toString(),
          style: style,
        );
      },
    );
  }
}
