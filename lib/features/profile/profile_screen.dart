import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../services/sound_service.dart';
import '../../services/profile_service.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends HookWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProfile = useState<Map<String, dynamic>>({});
    final isLoading = useState(true);
    final soundService = useMemoized(() => SoundService());
    final profileService = useMemoized(() => ProfileService.instance);

    // Load user profile on initialization
    Future<void> loadUserProfile() async {
      try {
        isLoading.value = true;
        final profile = await profileService.getCurrentUserProfile();
        if (profile != null) {
          userProfile.value = profile;
        } else {
          // Fallback to default profile if loading fails
          userProfile.value = {
            'name': 'User',
            'username': '@user',
            'avatar': '👤',
          };
        }
      } catch (e) {
        // Use fallback profile
        userProfile.value = {
          'name': 'User',
          'username': '@user',
          'avatar': '👤',
        };
      } finally {
        isLoading.value = false;
      }
    }

    useEffect(() {
      loadUserProfile();
      return null;
    }, []);

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
          : _buildCleanProfileContent(context, userProfile.value, soundService),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  // Clean and minimal profile content
  Widget _buildCleanProfileContent(BuildContext context, Map<String, dynamic> profile, SoundService soundService) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Avatar
          Container(
            width: 120,
            height: 120,
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
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Center(
              child: Text(
                profile['avatar'] ?? '👤',
                style: const TextStyle(fontSize: 50),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Name
          Text(
            profile['name'] ?? 'User',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Username
          Text(
            profile['username'] ?? '@user',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Coming Soon Message
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.construction,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                ),
                const SizedBox(height: 16),
                Text(
                  'Profile Features Coming Soon',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'We\'re working on exciting new profile features. Stay tuned!',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
