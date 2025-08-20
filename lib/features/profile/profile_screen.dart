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
      'followersCount': 45,
      'followingCount': 38,
      'achievementPoints': 1250,
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
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: IconButton(
                  icon: Icon(Icons.settings, color: Theme.of(context).colorScheme.primary, size: 22),
                  onPressed: () => context.push('/settings'),
                  tooltip: 'Settings',
                  padding: const EdgeInsets.all(8),
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: IconButton(
                  icon: Icon(Icons.people, color: Theme.of(context).colorScheme.primary, size: 22),
                  onPressed: () => context.push('/friends'),
                  tooltip: 'Friends',
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ],
          ),
        ),
        actions: [
          Flexible(
            child: IconButton(
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
              padding: const EdgeInsets.all(8),
            ),
          ),
        ],
      ),
      body: isLoading.value
          ? _buildLoadingState(context)
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildProfileHeader(context, userProfile.value, confettiController, soundService),
                  const SizedBox(height: 16),
                  _buildProfileStats(context, userProfile.value),
                  const SizedBox(height: 16),
                  _buildProfileActions(context, isEditing, soundService, userProfile),
                  const SizedBox(height: 16),
                  // _buildPostedContentSlider(context, soundService), // Temporarily disabled
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
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.settings, color: Theme.of(context).colorScheme.primary, size: 22),
            onPressed: () => context.push('/settings'),
            tooltip: 'Settings',
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
              maxWidth: 32,
              maxHeight: 32,
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(Icons.people, color: Theme.of(context).colorScheme.primary, size: 22),
            onPressed: () => context.push('/friends'),
            tooltip: 'Friends',
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
              maxWidth: 32,
              maxHeight: 32,
            ),
          ),
        ],
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
          
          // Name and username with tap to view content
          GestureDetector(
            onTap: () async {
              await soundService.playTapSound();
              _navigateToUserContentFeed(context, profile);
            },
            child: Column(
              children: [
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
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.play_circle_outline,
                        color: Theme.of(context).colorScheme.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'View Content',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
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
          
          const SizedBox(height: 16),
          
          // Interests
          if (profile['interests'] != null && (profile['interests'] as List<String>).isNotEmpty)
            Column(
              children: [
                Text(
                  'Interests',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (profile['interests'] as List<String>).map((interest) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getInterestIcon(interest),
                            size: 16,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            interest,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.secondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
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
      child: Column(
        children: [
          Text(
            'Profile Overview',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your social connections and achievements',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(context, '${profile['friendsCount']}', 'Friends', Icons.people),
              _buildDivider(),
              _buildStatItem(context, '${profile['postsCount']}', 'Posts', Icons.grid_on),
              _buildDivider(),
              _buildStatItem(context, '${profile['achievementPoints'] ?? 1250}', 'Points', Icons.stars),
            ],
          ),
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

  Widget _buildFilterChip(BuildContext context, String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        // TODO: Implement filter functionality
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected 
            ? Theme.of(context).colorScheme.primary 
            : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
              ? Theme.of(context).colorScheme.primary 
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isSelected 
              ? Colors.white 
              : Theme.of(context).colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedTextPostGridItem(BuildContext context, Map<String, dynamic> post) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          // Text post icon with category badge
          Stack(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.text_fields,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
              if (post['category'] != null)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      post['category'],
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // Post content
          Expanded(
            child: Text(
              post['content'],
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 4),
          // Engagement indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Icon(
                post['isLiked'] ? Icons.favorite : Icons.favorite_border,
                color: post['isLiked'] ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                size: 12,
              ),
              Text(
                '${post['likes']}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                ),
              ),
              Icon(
                post['isBookmarked'] ? Icons.bookmark : Icons.bookmark_border,
                color: post['isBookmarked'] ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                size: 12,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedMediaPostGridItem(BuildContext context, Map<String, dynamic> post) {
    return Stack(
      children: [
        // Media thumbnail
        Container(
          width: double.infinity,
          height: double.infinity,
          color: Theme.of(context).colorScheme.surfaceVariant,
          child: Icon(
            post['type'] == 'image' ? Icons.image : Icons.video_library,
            color: Theme.of(context).colorScheme.primary,
            size: 32,
          ),
        ),
        // Category badge
        if (post['category'] != null)
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                post['category'],
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        // Engagement overlay
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.8),
                ],
              ),
            ),
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post['content'],
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      post['isLiked'] ? Icons.favorite : Icons.favorite_border,
                      color: post['isLiked'] ? Colors.red : Colors.white,
                      size: 12,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${post['likes']}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      post['isBookmarked'] ? Icons.bookmark : Icons.bookmark_border,
                      color: post['isBookmarked'] ? Theme.of(context).colorScheme.primary : Colors.white,
                      size: 12,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileActions(
    BuildContext context,
    ValueNotifier<bool> isEditing,
    SoundService soundService,
    ValueNotifier<Map<String, dynamic>> userProfile,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () async {
                await soundService.playButtonClickSound();
                _showEditProfileDialog(context, userProfile);
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

  Widget _buildPostedContentSlider(BuildContext context, SoundService soundService) {
    // Sample post data - in a real app this would come from your data source
    final List<Map<String, dynamic>> samplePosts = [
      {
        'type': 'image',
        'thumbnail': 'assets/images/post1.jpg',
        'content': 'Beautiful sunset at the beach! 🌅',
        'likes': 24,
        'comments': 5,
        'timestamp': '2h ago',
        'views': 156,
        'shares': 3,
        'isLiked': false,
        'isBookmarked': false,
        'category': 'Nature',
        'engagement': 0.85,
      },
      {
        'type': 'video',
        'thumbnail': 'assets/images/post2.jpg',
        'content': 'Amazing drone footage of the city skyline',
        'likes': 18,
        'comments': 3,
        'timestamp': '5h ago',
        'views': 89,
        'shares': 1,
        'isLiked': true,
        'isBookmarked': false,
        'category': 'Travel',
        'engagement': 0.72,
      },
      {
        'type': 'text',
        'thumbnail': null,
        'content': 'Just had the most incredible experience today! Sometimes the best moments in life are the unexpected ones. #grateful #life',
        'likes': 31,
        'comments': 8,
        'timestamp': '1d ago',
        'views': 203,
        'shares': 7,
        'isLiked': false,
        'isBookmarked': true,
        'category': 'Inspiration',
        'engagement': 0.91,
      },
      {
        'type': 'image',
        'thumbnail': 'assets/images/post4.jpg',
        'content': 'Coffee and good vibes ☕️',
        'likes': 15,
        'comments': 2,
        'timestamp': '2d ago',
        'views': 67,
        'shares': 0,
        'isLiked': false,
        'isBookmarked': false,
        'category': 'Lifestyle',
        'engagement': 0.68,
      },
      {
        'type': 'video',
        'thumbnail': 'assets/images/post5.jpg',
        'content': 'Weekend adventures with friends! 🚀',
        'likes': 42,
        'comments': 12,
        'timestamp': '3d ago',
        'views': 178,
        'shares': 4,
        'isLiked': true,
        'isBookmarked': false,
        'category': 'Adventure',
        'engagement': 0.88,
      },
      {
        'type': 'text',
        'thumbnail': null,
        'content': 'New goals, new beginnings. Time to make things happen! 💪',
        'likes': 28,
        'comments': 6,
        'timestamp': '4d ago',
        'views': 134,
        'shares': 2,
        'isLiked': false,
        'isBookmarked': false,
        'category': 'Motivation',
        'engagement': 0.76,
      },
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enhanced header with stats and achievements - Temporarily disabled
          // Container(
          //   padding: const EdgeInsets.all(16),
          //   decoration: BoxDecoration(
          //     gradient: LinearGradient(
          //       begin: Alignment.topLeft,
          //       end: Alignment.bottomRight,
          //       colors: [
          //         Theme.of(context).colorScheme.primary.withOpacity(0.1),
          //         Theme.of(context).colorScheme.secondary.withOpacity(0.1),
          //       ],
          //     ),
          //     borderRadius: BorderRadius.circular(16),
          //     border: Border.all(
          //       color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
          //       width: 1,
          //     ),
          //   ),
          //   child: Column(
          //     children: [
          //       Row(
          //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //         children: [
          //           Text(
          //             'Posted Content',
          //             style: Theme.of(context).textTheme.titleLarge?.copyWith(
          //               fontWeight: FontWeight.bold,
          //             ),
          //           ),
          //           Row(
          //             children: [
          //               // Achievement badge
          //               Container(
          //                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          //                 decoration: BoxDecoration(
          //                   color: Theme.of(context).colorScheme.primary,
          //                   borderRadius: BorderRadius.circular(12),
          //                 ),
          //                 child: Row(
          //                   mainAxisSize: MainAxisSize.min,
          //                   children: [
          //                     Icon(
          //                       Icons.star,
          //                       color: Colors.white,
          //                       size: 16,
          //                     ),
          //                     const SizedBox(width: 4),
          //                     Text(
          //                       'Creator',
          //                       style: Theme.of(context).textTheme.bodySmall?.copyWith(
          //                         color: Colors.white,
          //                         fontWeight: FontWeight.bold,
          //                       ),
          //                     ),
          //                   ],
          //                 ),
          //               ),
          //               const SizedBox(width: 12),
          //               IconButton(
          //                 onPressed: () async {
          //                   await soundService.playButtonClickSound();
          //                   _showManageContentDialog(context, soundService);
          //                 },
          //                 icon: Icon(
          //                   Icons.add_circle_outline,
          //                   color: Theme.of(context).colorScheme.primary,
          //                   size: 24,
          //                 ),
          //                 tooltip: 'Manage Content',
          //                 style: IconButton.styleFrom(
          //                   backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          //                   padding: const EdgeInsets.all(8),
          //                 ),
          //               ),
          //             ],
          //           ),
          //         ],
          //       ),
          //       const SizedBox(height: 16),
          //       // Enhanced stats row
          //       Row(
          //         children: [
          //           _buildStatItem(context, '${samplePosts.length}', 'Posts', Icons.grid_on),
          //           _buildDivider(),
          //           _buildStatifier(context, '${samplePosts.fold<int>(0, (sum, post) => sum + (post['likes'] as int))}', 'Likes', Icons.favorite),
          //           _buildDivider(),
          //           _buildStatItem(context, '${samplePosts.fold<int>(0, (sum, post) => sum + (post['views'] as int))}', 'Views', Icons.visibility),
          //           _buildDivider(),
          //           _buildStatItem(context, '${samplePosts.fold<int>(0, (sum, post) => sum + (post['shares'] as int))}', 'Shares', Icons.share),
          //         ],
          //       ),
          //     ],
          //   ),
          // ),
          const SizedBox(height: 20),
          // Content filters and sorting - Temporarily disabled
          // Row(
          //   children: [
          //     _buildFilterChip(context, 'All', true),
          //     const SizedBox(width: 8),
          //     _buildFilterChip(context, 'Images', false),
          //     const SizedBox(width: 8),
          //     _buildFilterChip(context, 'Videos', false),
          //     const SizedBox(width: 8),
          //     _buildFilterChip(context, 'Text', false),
          //     const Spacer(),
          //     IconButton(
          //       onPressed: () async {
          //     await soundService.playButtonClickSound();
          //     _showSortOptionsDialog(context, soundService);
          //   },
          //       icon: Icon(
          //         Icons.sort,
          //         color: Theme.of(context).colorScheme.primary,
          //         size: 20,
          //       ),
          //       tooltip: 'Sort Posts',
          //     ),
          //   ],
          // ),
          // const SizedBox(height: 16),
          // Enhanced TikTok-style post grid (3 columns) - Temporarily disabled
          // SizedBox(
          //   height: 450, // Increased height for enhanced grid
          //   child: GridView.builder(
          //     gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          //       crossAxisCount: 3, // 3 columns like TikTok
          //       crossAxisSpacing: 3, // Slightly increased spacing
          //       mainAxisSpacing: 3, // Slightly increased spacing
          //       childAspectRatio: 0.75, // Slightly taller for more content
          //     ),
          //     itemCount: samplePosts.length,
          //     itemBuilder: (context, index) {
          //       final post = samplePosts[index];
          //       return GestureDetector(
          //         onTap: () async {
          //           await soundService.playButtonClickSound();
          //           _showExpandedPost(context, post, soundService);
          //         },
          //         onLongPress: () async {
          //           await soundService.playButtonClickSound();
          //           _showQuickActionsBottomSheet(context, post, soundService);
          //         },
          //         child: Container(
          //           decoration: BoxDecoration(
          //             borderRadius: BorderRadius.circular(12),
          //             border: Border.all(
          //               color: post['isLiked'] || post['isBookmarked'] 
          //                 ? Theme.of(context).colorScheme.primary.withOpacity(0.5)
          //                 : Theme.of(context).colorScheme.outline.withOpacity(0.2),
          //               width: post['isLiked'] || post['isBookmarked'] ? 2 : 1,
          //             ),
          //             boxShadow: [
          //               BoxShadow(
          //                 color: post['isLiked'] || post['isBookmarked']
          //                 ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
          //                 : Colors.black.withOpacity(0.1),
          //                 blurRadius: post['isLiked'] || post['isBookmarked'] ? 12 : 8,
          //                 offset: const Offset(0, 4),
          //             ),
          //           ),
          //           child: ClipRRect(
          //             borderRadius: BorderRadius.circular(12),
          //             child: post['type'] == 'text' 
          //               ? _buildEnhancedTextPostGridItem(context, post)
          //               : _buildEnhancedMediaPostGridItem(context, post),
          //           ),
          //         ),
          //       );
          //     },
          //   ),
          // ),
          // const SizedBox(height: 16),
          // Engagement insights - Temporarily disabled
          // Container(
          //   padding: const EdgeInsets.all(16),
          //   decoration: BoxDecoration(
          //     color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          //     borderRadius: BorderRadius.circular(12),
          //     border: Border.all(
          //       color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          //       width: 1,
          //   ),
          // ),
          //   child: Row(
          //     children: [
          //       Icon(
          //         Icons.insights,
          //         color: Theme.of(context).colorScheme.primary,
          //         size: 24,
          //       ),
          //       const SizedBox(width: 12),
          //       Expanded(
          //         child: Column(
          //           crossAxisAlignment: CrossAxisAlignment.start,
          //           children: [
          //             Text(
          //               'Engagement Insights',
          //               style: Theme.of(context).textTheme.titleSmall?.copyWith(
          //                 fontWeight: FontWeight.bold,
          //               ),
          //             ),
          //             Text(
          //               'Your posts are performing great! Keep creating amazing content.',
          //               style: Theme.of(context).textTheme.bodySmall?.copyWith(
          //                 color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          //               ),
          //           ),
          //         ),
          //       ),
          //       IconButton(
          //         onPressed: () async {
          //           await soundService.playButtonClickSound();
          //           _showEngagementInsightsDialog(context, soundService);
          //         },
          //         icon: Icon(
          //           Icons.arrow_forward_ios,
          //           color: Theme.of(context).colorScheme.primary,
          //           size: 16,
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
        ],
      ),
    ).animate().slideY(begin: 0.3, duration: const Duration(milliseconds: 600), delay: const Duration(milliseconds: 400));
  }

  Widget _buildTextPostGridItem(BuildContext context, Map<String, dynamic> post) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          // Text post icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.text_fields,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          // Post content
          Text(
            post['content'],
            style: Theme.of(context).textTheme.bodySmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.favorite,
                color: Theme.of(context).colorScheme.error,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                '${post['likes']}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.comment_outlined,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                '${post['comments']}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMediaPostGridItem(BuildContext context, Map<String, dynamic> post) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          // Media thumbnail
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              post['type'] == 'image' ? Icons.image : Icons.video_library,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          // Post content
          Text(
            post['content'],
            style: Theme.of(context).textTheme.bodySmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.favorite,
                color: Theme.of(context).colorScheme.error,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                '${post['likes']}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.comment_outlined,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                '${post['comments']}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showExpandedPost(BuildContext context, Map<String, dynamic> post, SoundService soundService) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Post content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Post header
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your Profile',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                post['timestamp'],
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.more_vert),
                          onPressed: () {
                            // TODO: Implement post options
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Post content
                    if (post['type'] == 'text')
                      Text(
                        post['content'],
                        style: Theme.of(context).textTheme.bodyLarge,
                      )
                    else
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          post['type'] == 'image' ? Icons.image : Icons.video_library,
                          color: Theme.of(context).colorScheme.primary,
                          size: 48,
                        ),
                      ),
                    const SizedBox(height: 16),
                    // Post actions
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.favorite_border,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          onPressed: () async {
                            await soundService.playButtonClickSound();
                            // TODO: Implement like functionality
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.comment_outlined,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          onPressed: () async {
                            await soundService.playButtonClickSound();
                            // TODO: Implement comment functionality
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.share_outlined,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          onPressed: () async {
                            await soundService.playButtonClickSound();
                            // TODO: Implement share functionality
                          },
                        ),
                        const Spacer(),
                        Text(
                          '${post['likes']} likes',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${post['comments']} comments',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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

  void _showEditProfileDialog(BuildContext context, ValueNotifier<Map<String, dynamic>> userProfile) {
    // Create controllers for form fields with current values
    final nameController = TextEditingController(text: userProfile.value['name']);
    final usernameController = TextEditingController(text: userProfile.value['username']);
    final bioController = TextEditingController(text: userProfile.value['bio']);
    final locationController = TextEditingController(text: userProfile.value['location']);
    final emailController = TextEditingController(text: userProfile.value['email']);
    final phoneController = TextEditingController(text: userProfile.value['phone']);
    
    // Create a copy of current interests for editing
    final List<String> editableInterests = List.from(userProfile.value['interests']);
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.edit,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text('Edit Profile'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: MediaQuery.of(context).size.height * 0.7,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Update your profile information:'),
                  const SizedBox(height: 20),
                  
                  // Profile Picture Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Profile Picture',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () {
                            // TODO: Implement avatar selection
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Avatar selection coming soon!')),
                            );
                          },
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(40),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                userProfile.value['avatar'],
                                style: const TextStyle(fontSize: 32),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap to change',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Basic Information
                  Text(
                    'Basic Information',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Name Field
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      hintText: 'Enter your full name',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Username Field
                  TextFormField(
                    controller: usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      hintText: 'Enter your username',
                      prefixIcon: Icon(Icons.alternate_email),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Bio Field
                  TextFormField(
                    controller: bioController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Bio',
                      hintText: 'Tell us about yourself',
                      prefixIcon: Icon(Icons.info),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Location Field
                  TextFormField(
                    controller: locationController,
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      hintText: 'Where are you located?',
                      prefixIcon: Icon(Icons.location_on),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Contact Information
                  Text(
                    'Contact Information',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Email Field
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'Enter your email address',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Phone Field
                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone',
                      hintText: 'Enter your phone number',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Interests Section
                  Text(
                    'Interests',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Current Interests Display
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: editableInterests.map((interest) => Chip(
                      label: Text(interest),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () {
                        setState(() {
                          editableInterests.remove(interest);
                        });
                      },
                    )).toList(),
                  ),
                  const SizedBox(height: 16),
                  
                  // Add New Interest
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Add Interest',
                            hintText: 'Enter a new interest',
                            border: OutlineInputBorder(),
                          ),
                          onFieldSubmitted: (value) {
                            if (value.trim().isNotEmpty && !editableInterests.contains(value.trim())) {
                              setState(() {
                                editableInterests.add(value.trim());
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          // TODO: Show interest suggestions
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Interest suggestions coming soon!')),
                          );
                        },
                        icon: const Icon(Icons.lightbulb_outline),
                        tooltip: 'Get Suggestions',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Validate required fields
                if (nameController.text.trim().isEmpty || 
                    usernameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Name and username are required!'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                // Update user profile with new values
                userProfile.value = {
                  ...userProfile.value,
                  'name': nameController.text.trim(),
                  'username': usernameController.text.trim(),
                  'bio': bioController.text.trim(),
                  'location': locationController.text.trim(),
                  'email': emailController.text.trim(),
                  'phone': phoneController.text.trim(),
                  'interests': editableInterests,
                };
                
                // Close dialog
                Navigator.pop(context);
                
                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text('Profile updated successfully!'),
                      ],
                    ),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 3),
                  ),
                );
                
                // Play success sound
                final soundService = SoundService();
                await soundService.playSuccessSound();
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
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

  void _showManageContentDialog(BuildContext context, SoundService soundService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.manage_accounts,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text('Manage Content'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Choose an action to manage your posted content:'),
              const SizedBox(height: 20),
              // Add new content button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await soundService.playButtonClickSound();
                    Navigator.pop(context);
                    _showAddNewContentDialog(context, soundService);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add New Content'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Edit existing content button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await soundService.playButtonClickSound();
                    Navigator.pop(context);
                    _showEditContentDialog(context, soundService);
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Content'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Remove content button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await soundService.playButtonClickSound();
                    Navigator.pop(context);
                    _showRemoveContentDialog(context, soundService);
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Remove Content'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                    side: BorderSide(color: Theme.of(context).colorScheme.error),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showAddNewContentDialog(BuildContext context, SoundService soundService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.add_circle,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text('Add New Content'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Choose the type of content to add:'),
              const SizedBox(height: 20),
              // Add text post
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await soundService.playButtonClickSound();
                    Navigator.pop(context);
                    _showAddTextPostDialog(context, soundService);
                  },
                  icon: const Icon(Icons.text_fields),
                  label: const Text('Text Post'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Add image post
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await soundService.playButtonClickSound();
                    Navigator.pop(context);
                    _showAddImagePostDialog(context, soundService);
                  },
                  icon: const Icon(Icons.image),
                  label: const Text('Image Post'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.tertiary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Add video post
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await soundService.playButtonClickSound();
                    Navigator.pop(context);
                    _showAddVideoPostDialog(context, soundService);
                  },
                  icon: const Icon(Icons.video_library),
                  label: const Text('Video Post'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showAddTextPostDialog(BuildContext context, SoundService soundService) {
    final TextEditingController contentController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Text Post'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Write your post content:'),
            const SizedBox(height: 16),
            TextField(
              controller: contentController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'What\'s on your mind?',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (contentController.text.trim().isNotEmpty) {
                await soundService.playButtonClickSound();
                // TODO: Implement adding text post to data source
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Text post added successfully!')),
                );
              }
            },
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }

  void _showAddImagePostDialog(BuildContext context, SoundService soundService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Image Post'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Image post functionality coming soon!'),
            SizedBox(height: 16),
            Icon(
              Icons.image,
              size: 48,
              color: Colors.grey,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAddVideoPostDialog(BuildContext context, SoundService soundService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Video Post'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Video post functionality coming soon!'),
            SizedBox(height: 16),
            Icon(
              Icons.video_library,
              size: 48,
              color: Colors.grey,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showEditContentDialog(BuildContext context, SoundService soundService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Content'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Content editing functionality coming soon!'),
            SizedBox(height: 16),
            Icon(
              Icons.edit,
              size: 48,
              color: Colors.grey,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showRemoveContentDialog(BuildContext context, SoundService soundService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Content'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Content removal functionality coming soon!'),
            SizedBox(height: 16),
            Icon(
              Icons.delete_outline,
              size: 48,
              color: Colors.grey,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
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

  void _showSortOptionsDialog(BuildContext context, SoundService soundService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sort Posts'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Sort your posts by different criteria:'),
            SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.trending_up),
              title: Text('Most Popular'),
              subtitle: Text('Sort by likes and engagement'),
            ),
            ListTile(
              leading: Icon(Icons.schedule),
              title: Text('Recent'),
              subtitle: Text('Sort by posting date'),
            ),
            ListTile(
              leading: Icon(Icons.visibility),
              title: Text('Most Viewed'),
              subtitle: Text('Sort by view count'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement sorting functionality
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showQuickActionsBottomSheet(BuildContext context, Map<String, dynamic> post, SoundService soundService) {
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
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(
                post['isLiked'] ? Icons.favorite : Icons.favorite_border,
                color: post['isLiked'] ? Theme.of(context).colorScheme.error : null,
              ),
              title: Text(post['isLiked'] ? 'Unlike' : 'Like'),
              onTap: () async {
                await soundService.playButtonClickSound();
                // TODO: Implement like/unlike functionality
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(
                post['isBookmarked'] ? Icons.bookmark : Icons.bookmark_border,
                color: post['isBookmarked'] ? Theme.of(context).colorScheme.primary : null,
              ),
              title: Text(post['isBookmarked'] ? 'Remove Bookmark' : 'Bookmark'),
              onTap: () async {
                await soundService.playButtonClickSound();
                // TODO: Implement bookmark functionality
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share'),
              onTap: () async {
                await soundService.playButtonClickSound();
                // TODO: Implement share functionality
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () async {
                await soundService.playButtonClickSound();
                Navigator.pop(context);
                _showEditContentDialog(context, soundService);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () async {
                await soundService.playButtonClickSound();
                Navigator.pop(context);
                _showRemoveContentDialog(context, soundService);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEngagementInsightsDialog(BuildContext context, SoundService soundService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.insights,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text('Engagement Insights'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Your content performance metrics:'),
            SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.trending_up, color: Colors.green),
              title: Text('Overall Engagement: 82%'),
              subtitle: Text('Above average for your niche'),
            ),
            ListTile(
              leading: Icon(Icons.favorite, color: Colors.red),
              title: Text('Most Liked Post'),
              subtitle: Text('"Just had the most incredible experience..."'),
            ),
            ListTile(
              leading: Icon(Icons.visibility, color: Colors.blue),
              title: Text('Highest Views'),
              subtitle: Text('203 views on your latest text post'),
            ),
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

  void _navigateToUserContentFeed(BuildContext context, Map<String, dynamic> profile) {
    context.push('/user_content_feed/${profile['username']}');
  }

  IconData _getInterestIcon(String interest) {
    // Convert interest to lowercase for case-insensitive matching
    final lowerInterest = interest.toLowerCase();
    
    if (lowerInterest.contains('tech') || lowerInterest.contains('technology')) {
      return Icons.computer;
    } else if (lowerInterest.contains('coffee')) {
      return Icons.coffee;
    } else if (lowerInterest.contains('travel')) {
      return Icons.flight;
    } else if (lowerInterest.contains('music')) {
      return Icons.music_note;
    } else if (lowerInterest.contains('sport') || lowerInterest.contains('fitness')) {
      return Icons.fitness_center;
    } else if (lowerInterest.contains('food') || lowerInterest.contains('cooking')) {
      return Icons.restaurant;
    } else if (lowerInterest.contains('art') || lowerInterest.contains('design')) {
      return Icons.palette;
    } else if (lowerInterest.contains('book') || lowerInterest.contains('reading')) {
      return Icons.book;
    } else if (lowerInterest.contains('game') || lowerInterest.contains('gaming')) {
      return Icons.games;
    } else if (lowerInterest.contains('photo') || lowerInterest.contains('photography')) {
      return Icons.camera_alt;
    } else if (lowerInterest.contains('movie') || lowerInterest.contains('film')) {
      return Icons.movie;
    } else if (lowerInterest.contains('nature') || lowerInterest.contains('outdoor')) {
      return Icons.nature;
    } else if (lowerInterest.contains('business') || lowerInterest.contains('work')) {
      return Icons.business;
    } else if (lowerInterest.contains('health') || lowerInterest.contains('wellness')) {
      return Icons.favorite;
    } else if (lowerInterest.contains('education') || lowerInterest.contains('learning')) {
      return Icons.school;
    } else if (lowerInterest.contains('fashion') || lowerInterest.contains('style')) {
      return Icons.style;
    } else if (lowerInterest.contains('car') || lowerInterest.contains('automotive')) {
      return Icons.directions_car;
    } else if (lowerInterest.contains('pet') || lowerInterest.contains('animal')) {
      return Icons.pets;
    } else {
      // Default icon for unknown interests
      return Icons.star;
    }
  }

  // TikTok-style User Content Feed Screen
  static Widget buildUserContentFeedScreen(BuildContext context, String username) {
    return _UserContentFeedScreen(username: username);
  }
}

class _UserContentFeedScreen extends StatefulWidget {
  final String username;
  
  const _UserContentFeedScreen({required this.username});
  
  @override
  State<_UserContentFeedScreen> createState() => _UserContentFeedScreenState();
}

class _UserContentFeedScreenState extends State<_UserContentFeedScreen> {
  late PageController _pageController;
  int _currentIndex = 0;
  bool _isLiked = false;
  bool _isBookmarked = false;
  
  // Sample user content data - in a real app this would come from your data source
  final List<Map<String, dynamic>> _userContent = [
    {
      'id': '1',
      'type': 'video',
      'content': 'Amazing sunset at the beach! 🌅',
      'description': 'Just captured this beautiful moment during my evening walk. Nature is truly amazing!',
      'likes': 1247,
      'comments': 89,
      'shares': 23,
      'views': 15420,
      'timestamp': '2h ago',
      'location': 'Amsterdam Beach',
      'music': 'Sunset Vibes - Chill Mix',
      'isLiked': false,
      'isBookmarked': false,
      'hashtags': ['#sunset', '#beach', '#nature', '#amsterdam'],
    },
    {
      'id': '2',
      'type': 'image',
      'content': 'Coffee and good vibes ☕️',
      'description': 'Perfect morning with my favorite coffee blend. Ready to tackle the day!',
      'likes': 892,
      'comments': 45,
      'shares': 12,
      'views': 8765,
      'timestamp': '5h ago',
      'location': 'Home Sweet Home',
      'music': 'Morning Coffee - Acoustic',
      'isLiked': true,
      'isBookmarked': false,
      'hashtags': ['#coffee', '#morning', '#vibes', '#home'],
    },
    {
      'id': '3',
      'type': 'text',
      'content': 'Just had the most incredible experience today! Sometimes the best moments in life are the unexpected ones. #grateful #life',
      'description': 'Reflecting on today\'s amazing experiences and feeling grateful for all the little moments.',
      'likes': 2156,
      'comments': 156,
      'shares': 67,
      'views': 23450,
      'timestamp': '1d ago',
      'location': 'Amsterdam, Netherlands',
      'music': 'Grateful - Uplifting',
      'isLiked': false,
      'isBookmarked': true,
      'hashtags': ['#grateful', '#life', '#experience', '#reflection'],
    },
    {
      'id': '4',
      'type': 'video',
      'content': 'Weekend adventures with friends! 🚀',
      'description': 'Exploring the city with amazing people. Life is better when shared!',
      'likes': 3421,
      'comments': 234,
      'shares': 89,
      'views': 45670,
      'timestamp': '3d ago',
      'location': 'City Center',
      'music': 'Adventure Time - Energetic',
      'isLiked': true,
      'isBookmarked': false,
      'hashtags': ['#adventure', '#friends', '#weekend', '#explore'],
    },
    {
      'id': '5',
      'type': 'image',
      'content': 'New goals, new beginnings. Time to make things happen! 💪',
      'description': 'Setting new goals and working towards them. Every step counts!',
      'likes': 1567,
      'comments': 98,
      'shares': 34,
      'views': 18920,
      'timestamp': '4d ago',
      'location': 'Gym',
      'music': 'Motivation - Power Mix',
      'isLiked': false,
      'isBookmarked': false,
      'hashtags': ['#goals', '#motivation', '#fitness', '#growth'],
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Full-screen content viewer
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
                _isLiked = _userContent[index]['isLiked'];
                _isBookmarked = _userContent[index]['isBookmarked'];
              });
            },
            itemCount: _userContent.length,
            itemBuilder: (context, index) {
              final content = _userContent[index];
              return _buildContentItem(context, content, index);
            },
          ),
          
          // Top navigation bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 10,
                left: 20,
                right: 20,
                bottom: 10,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '@${widget.username}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      // TODO: Implement more options
                    },
                    icon: const Icon(
                      Icons.more_vert,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Bottom action bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).padding.bottom + 20,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
              child: Row(
                children: [
                  // Content info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _userContent[_currentIndex]['content'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _userContent[_currentIndex]['description'],
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.music_note,
                              color: Colors.white.withOpacity(0.8),
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _userContent[_currentIndex]['music'],
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Action buttons
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Profile avatar
                      GestureDetector(
                        onTap: () {
                          // TODO: Navigate to profile
                        },
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Center(
                            child: Text(
                              '👨‍💻',
                              style: TextStyle(fontSize: 24),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Like button
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isLiked = !_isLiked;
                            _userContent[_currentIndex]['isLiked'] = _isLiked;
                            if (_isLiked) {
                              _userContent[_currentIndex]['likes']++;
                            } else {
                              _userContent[_currentIndex]['likes']--;
                            }
                          });
                        },
                        child: Column(
                          children: [
                            Icon(
                              _isLiked ? Icons.favorite : Icons.favorite_border,
                              color: _isLiked ? Colors.red : Colors.white,
                              size: 32,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_userContent[_currentIndex]['likes']}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Comment button
                      GestureDetector(
                        onTap: () {
                          // TODO: Show comments
                        },
                        child: Column(
                          children: [
                            const Icon(
                              Icons.comment_outlined,
                              color: Colors.white,
                              size: 32,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_userContent[_currentIndex]['comments']}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Share button
                      GestureDetector(
                        onTap: () {
                          // TODO: Implement share
                        },
                        child: Column(
                          children: [
                            const Icon(
                              Icons.share_outlined,
                              color: Colors.white,
                              size: 32,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_userContent[_currentIndex]['shares']}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Bookmark button
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isBookmarked = !_isBookmarked;
                            _userContent[_currentIndex]['isBookmarked'] = _isBookmarked;
                          });
                        },
                        child: Column(
                          children: [
                            Icon(
                              _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                              color: _isBookmarked ? Colors.white : Colors.white.withOpacity(0.8),
                              size: 32,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Save',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Content counter
          Positioned(
            right: 20,
            top: MediaQuery.of(context).size.height * 0.4,
            child: Column(
              children: [
                for (int i = 0; i < _userContent.length; i++)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == _currentIndex 
                        ? Colors.white 
                        : Colors.white.withOpacity(0.3),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentItem(BuildContext context, Map<String, dynamic> content, int index) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: Stack(
        children: [
          // Content display
          Center(
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                color: content['type'] == 'text' 
                  ? Colors.grey[900] 
                  : Colors.grey[800],
              ),
              child: content['type'] == 'text'
                ? _buildTextContent(content)
                : _buildMediaContent(content),
            ),
          ),
          
          // Hashtags overlay
          if (content['hashtags'] != null)
            Positioned(
              left: 20,
              bottom: 120,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: (content['hashtags'] as List<String>).map((hashtag) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      hashtag,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextContent(Map<String, dynamic> content) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.text_fields,
              color: Colors.white.withOpacity(0.6),
              size: 64,
            ),
            const SizedBox(height: 24),
            Text(
              content['content'],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaContent(Map<String, dynamic> content) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            content['type'] == 'image' ? Icons.image : Icons.video_library,
            color: Colors.white.withOpacity(0.6),
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            content['type'] == 'image' ? 'Image Content' : 'Video Content',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content['content'],
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
