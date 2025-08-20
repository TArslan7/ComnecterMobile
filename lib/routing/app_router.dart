import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/radar/radar_screen.dart';
import '../features/radar/user_profile_screen.dart';
import '../features/chat/chat_screen.dart';
import '../features/community/community_screen.dart';
import '../features/friends/friends_screen.dart';
import '../features/subscription/subscription_screen.dart';
import '../features/event/event_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/settings/settings_screen.dart';

GoRouter createRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) => RootNavigation(child: child),
        routes: [
          GoRoute(
            path: '/',
            name: 'radar',
            builder: (context, state) => const RadarScreen(),
          ),
          GoRoute(
            path: '/chat',
            name: 'chat',
            builder: (context, state) => const ChatScreen(),
          ),
          GoRoute(
            path: '/community',
            name: 'community',
            builder: (context, state) => const CommunityScreen(),
          ),
          GoRoute(
            path: '/friends',
            name: 'friends',
            builder: (context, state) => const FriendsScreen(),
          ),
          GoRoute(
            path: '/event',
            name: 'event',
            builder: (context, state) => const EventScreen(),
          ),
          GoRoute(
            path: '/subscription',
            name: 'subscription',
            builder: (context, state) => const SubscriptionScreen(),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/user-profile/:userId',
            name: 'user-profile',
            builder: (context, state) {
              final user = state.extra as Map<String, dynamic>;
              return UserProfileScreen(user: user['user']);
            },
          ),
          GoRoute(
            path: '/user_content_feed/:username',
            name: 'user-content-feed',
            builder: (context, state) => ProfileScreen.buildUserContentFeedScreen(
              context,
              state.pathParameters['username']!,
            ),
          ),
        ],
      ),
    ],
  );
}

class RootNavigation extends StatelessWidget {
  final Widget child;
  const RootNavigation({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouter.of(context).routerDelegate.currentConfiguration.uri.toString(); // ✅ werkt altijd
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 80,
            child: NavigationBar(
              selectedIndex: _calculateSelectedIndex(location),
              onDestinationSelected: (index) {
                switch (index) {
                  case 0:
                    context.go('/');
                    break;
                  case 1:
                    context.go('/chat');
                    break;
                  case 2:
                    context.go('/community');
                    break;
                  case 3:
                    context.go('/profile');
                    break;
                  case 4:
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'This feature is coming soon!',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                    context.go('/event');
                    break;
                }
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.radar), 
                  label: 'Radar',
                  tooltip: 'Radar',
                ),
                NavigationDestination(
                  icon: Icon(Icons.chat_bubble), 
                  label: 'Chat',
                  tooltip: 'Chat',
                ),
                NavigationDestination(
                  icon: Icon(Icons.people), 
                  label: 'Community',
                  tooltip: 'Community',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person), 
                  label: 'Profile',
                  tooltip: 'Profile',
                ),
                NavigationDestination(
                  icon: Icon(Icons.event), 
                  label: 'Event',
                  tooltip: 'Event',
                ),
              ],
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              height: 80,
              elevation: 0,
            ),
          ),
        ),
      ),
    );
  }

  int _calculateSelectedIndex(String location) {
    if (location.startsWith('/chat')) return 1;
    if (location.startsWith('/community')) return 2;
    if (location.startsWith('/profile')) return 3;
    if (location.startsWith('/event')) return 4;
    return 0;
  }
}
