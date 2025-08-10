import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import '../../services/sound_service.dart';
import '../../theme/app_theme.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends HookWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProfile = useState<Map<String, dynamic>>({
      'name': 'Alex Johnson',
      'username': '@alexjohnson',
      'bio': 'Tech enthusiast and coffee lover ☕️',
      'location': 'Amsterdam, Netherlands',
      'joinedDate': 'March 2024',
      'friendsCount': 127,
      'postsCount': 42,
      'avatar': '👨‍💻',
      'isOnline': true,
      'lastSeen': '2 minutes ago',
      'email': 'alex.johnson@email.com',
      'phone': '+31 6 12345678',
      'interests': ['Technology', 'Coffee', 'Travel', 'Music'],
      'badges': ['Early Adopter', 'Verified', 'Premium'],
    });

    final isLoading = useState(false);
    final isEditing = useState(false);
    final confettiController = useMemoized(() => ConfettiController(duration: const Duration(seconds: 2)));
    final soundService = useMemoized(() => SoundService());

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: _buildAppBar(context, isEditing, soundService),
      body: isLoading.value
          ? _buildLoadingState(context)
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildProfileHeader(context, userProfile.value, confettiController, soundService),
                  const SizedBox(height: 16),
                  _buildProfileStats(context, userProfile.value),
                  const SizedBox(height: 16),
                  _buildProfileActions(context, isEditing, soundService),
                  const SizedBox(height: 16),
                  _buildProfileSections(context, soundService),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    ValueNotifier<bool> isEditing,
    SoundService soundService,
  ) {
    return AppBar(
      leading: IconButton(
        icon: Icon(Icons.settings, color: Theme.of(context).colorScheme.primary),
        onPressed: () => context.push('/settings'),
        tooltip: 'Settings',
      ),
      // no title per request
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      actions: [
        IconButton(
          icon: Icon(
            isEditing.value ? Icons.save : Icons.edit,
            color: Theme.of(context).colorScheme.primary,
          ),
          onPressed: () async {
            await soundService.playButtonClickSound();
            isEditing.value = !isEditing.value;
            if (!isEditing.value) {
              // Save changes
              await soundService.playSuccessSound();
            }
          },
          tooltip: isEditing.value ? 'Save' : 'Edit',
        ),
      ],
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    Map<String, dynamic> profile,
    ConfettiController confettiController,
    SoundService soundService,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Avatar and online status
          Stack(
            children: [
              GestureDetector(
                onTap: () async {
                  await soundService.playTapSound();
                  _showAvatarOptions(context);
                },
                child: Container(
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
                      profile['avatar'],
                      style: const TextStyle(fontSize: 50),
                    ),
                  ),
                ),
              ),
              if (profile['isOnline'])
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppTheme.success, // Keep custom success color
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.success.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Name and username
          Text(
            profile['name'],
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            profile['username'],
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          
          // Bio
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              profile['bio'],
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Location and joined date
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_on, size: 16, color: Theme.of(context).colorScheme.onSurface),
              const SizedBox(width: 4),
              Text(
                profile['location'],
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              ),
              const SizedBox(width: 16),
              Icon(Icons.calendar_today, size: 16, color: Theme.of(context).colorScheme.onSurface),
              const SizedBox(width: 4),
              Text(
                'Joined ${profile['joinedDate']}',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Badges
          if (profile['badges'] != null)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (profile['badges'] as List<String>).map((badge) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    ).animate().fadeIn(duration: const Duration(milliseconds: 600));
  }

  Widget _buildProfileStats(BuildContext context, Map<String, dynamic> profile) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(context, 'Friends', profile['friendsCount'].toString(), Icons.people),
          _buildDivider(),
          _buildStatItem(context, 'Posts', profile['postsCount'].toString(), Icons.post_add),
          _buildDivider(),
          _buildStatItem(context, 'Online', profile['isOnline'] ? 'Now' : 'Offline', Icons.circle),
        ],
      ),
    ).animate().slideY(begin: 0.3, duration: const Duration(milliseconds: 600));
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 40,
                      color: Colors.white.withValues(alpha: 0.3),
    );
  }

  Widget _buildProfileActions(
    BuildContext context,
    ValueNotifier<bool> isEditing,
    SoundService soundService,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () async {
                await soundService.playButtonClickSound();
                _showEditProfileDialog(context);
              },
              icon: const Icon(Icons.edit),
              label: const Text('Edit Profile'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async {
                await soundService.playButtonClickSound();
                _showShareProfileDialog(context);
              },
              icon: const Icon(Icons.share),
              label: const Text('Share'),
            ),
          ),
        ],
      ),
    ).animate().slideY(begin: 0.2, duration: const Duration(milliseconds: 600), delay: const Duration(milliseconds: 200));
  }

  Widget _buildProfileSections(BuildContext context, SoundService soundService) {
    return Column(
      children: [
        _buildSectionCard(
          context,
          'Friends',
          Icons.people,
          'Manage your friends and connections',
          () async {
            await soundService.playButtonClickSound();
            _showFriendsBottomSheet(context);
          },
        ),
      ],
    ).animate().fadeIn(duration: const Duration(milliseconds: 800), delay: const Duration(milliseconds: 400));
  }

  Widget _buildSectionCard(
    BuildContext context,
    String title,
    IconData icon,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  void _showAvatarOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Camera functionality coming soon!')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement gallery functionality
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Avatar'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement avatar editor
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: const Text('Profile editing feature coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showShareProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Profile'),
        content: const Text('Share your profile with others!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement share functionality
            },
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }

  void _showFriendsDialog(BuildContext context) {
    // Deprecated by _showFriendsBottomSheet
  }

  void _showFriendsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('Add Friend'),
              subtitle: const Text('Send a friend request'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Add Friend is coming soon!')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Search Friends'),
              subtitle: const Text('Find people to connect with'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Search Friends is coming soon!')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Text('Contact support or browse help articles.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement help functionality
            },
            child: const Text('Contact Support'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Comnecter'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version: 1.0.0'),
            Text('Build: 2024.1.0'),
            SizedBox(height: 8),
            Text('Comnecter is a radar-based social app that helps you discover and connect with people nearby.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
