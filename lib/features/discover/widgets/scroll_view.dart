import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import '../../radar/models/user_model.dart';
import '../../friends/services/friend_service.dart';

class ScrollView extends HookWidget {
  final List<NearbyUser> detectedUsers;
  final List<Map<String, dynamic>> friends;
  final List<Map<String, dynamic>> communities;
  final List<Map<String, dynamic>> events;
  final FriendService friendService;

  const ScrollView({
    super.key,
    required this.detectedUsers,
    required this.friends,
    required this.communities,
    required this.events,
    required this.friendService,
  });

  @override
  Widget build(BuildContext context) {
    final selectedTab = useState(0);
    final tabs = ['All', 'Detected Users', 'Communities', 'Events', 'Saved'];

    return Column(
      children: [
        // Tab selector
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Row(
              children: tabs.asMap().entries.map((entry) {
                final index = entry.key;
                final tab = entry.value;
                final isSelected = selectedTab.value == index;
                
                return Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => selectedTab.value = index,
                      borderRadius: BorderRadius.circular(8),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tab,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: isSelected 
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context).colorScheme.onSurface,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        
        // Content
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: IndexedStack(
              index: selectedTab.value,
              children: [
                _buildAllFeedView(context),
                _buildDetectedUsersList(context),
                _buildCommunitiesList(context),
                _buildEventsList(context),
                _buildSavedList(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAllFeedView(BuildContext context) {
    // Check if we have any content
    final hasContent = detectedUsers.isNotEmpty || communities.isNotEmpty || events.isNotEmpty;
    
    if (!hasContent) {
      return _buildEmptyState(
        context,
        'Nothing detected yet',
        'Start exploring to discover nearby content',
        Icons.explore_off,
      );
    }
    
    return Column(
      children: [
        // Open All Feed Button (full screen TikTok-style)
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                context.push('/discover/all');
              },
              icon: const Icon(Icons.fullscreen),
              label: const Text('Open All Detected Feed'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
        ),
        
        // Mixed list showing ALL content
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(top: 8),
            children: [
              // Show ALL detected users
              if (detectedUsers.isNotEmpty) ...[
                _buildSectionHeader(context, 'Users Nearby (${detectedUsers.length})', Icons.person),
                ...detectedUsers.map((user) => _buildUserCard(context, user)),
              ],
              
              // Show ALL communities
              if (communities.isNotEmpty) ...[
                _buildSectionHeader(context, 'Communities (${communities.length})', Icons.groups),
                ...communities.map((community) => _buildCommunityCard(context, community)),
              ],
              
              // Show ALL events
              if (events.isNotEmpty) ...[
                _buildSectionHeader(context, 'Events (${events.length})', Icons.event),
                ...events.map((event) => _buildEventCard(context, event)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetectedUsersList(BuildContext context) {
    return Column(
      children: [
        // Users Feed Button - Always visible
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                context.push('/discover/users');
              },
              icon: const Icon(Icons.person_search),
              label: const Text('Open Users Feed'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
        ),
        
        // List of detected users or empty state
        Expanded(
          child: detectedUsers.isEmpty
              ? _buildEmptyState(
                  context,
                  'No users detected',
                  'Start scanning to discover people nearby',
                  Icons.radar,
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 8),
                  itemCount: detectedUsers.length,
                  itemBuilder: (context, index) {
                    final user = detectedUsers[index];
                    return _buildUserCard(context, user);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCommunitiesList(BuildContext context) {
    if (communities.isEmpty) {
      return _buildEmptyState(
        context,
        'No communities',
        'Join communities to connect with like-minded people',
        Icons.groups,
      );
    }

    return Column(
      children: [
        // Communities Feed Button
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                context.push('/discover/communities');
              },
              icon: const Icon(Icons.groups),
              label: const Text('Open Communities Feed'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
        ),
        
        // List of communities
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 8),
            itemCount: communities.length,
            itemBuilder: (context, index) {
              final community = communities[index];
              return _buildCommunityCard(context, community);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEventsList(BuildContext context) {
    if (events.isEmpty) {
      return _buildEmptyState(
        context,
        'No events',
        'Discover local events and meetups happening around you',
        Icons.event,
      );
    }

    return Column(
      children: [
        // Events Feed Button
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Events Feed: Screen file needs to be created. Feature is 85% ready!'),
                    duration: Duration(seconds: 3),
                  ),
                );
                // context.push('/discover/events'); // Uncomment when events_feed_screen.dart is created
              },
              icon: const Icon(Icons.event),
              label: const Text('Open Events Feed (Coming Soon)'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Theme.of(context).colorScheme.onSecondary,
              ),
            ),
          ),
        ),
        
        // List of events
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 8),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return _buildEventCard(context, event);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUserCard(BuildContext context, NearbyUser user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: () {
          // Navigate to Users Feed when tapping a user in scroll view
          context.push('/discover/users');
        },
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Text(
            user.avatar,
            style: const TextStyle(fontSize: 20),
          ),
        ),
        title: Text(
          user.name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${user.distanceKm.toStringAsFixed(1)} km away'),
            if (user.interests.isNotEmpty)
              Wrap(
                spacing: 4,
                children: user.interests.take(3).map((interest) => Chip(
                  label: Text(interest),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                )).toList(),
              ),
          ],
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          size: 16,
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildCommunityCard(BuildContext context, Map<String, dynamic> community) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: () {
          // Navigate to Communities Feed when tapping a community in scroll view
          context.push('/discover/communities');
        },
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: Theme.of(context).colorScheme.tertiary,
          child: Text(
            community['avatar'] ?? community['image'] ?? '👥',
            style: const TextStyle(fontSize: 20),
          ),
        ),
        title: Text(
          community['name'],
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(community['description']),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.people,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
                const SizedBox(width: 4),
                Text(
                  '${community['memberCount']} members',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          size: 16,
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, Map<String, dynamic> event) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: () {
          // Navigate to Events Feed when tapping an event in scroll view
          // Show message since events feed is not complete yet
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Events Feed coming soon! Feature is 85% ready.'),
              duration: Duration(seconds: 2),
            ),
          );
          // context.push('/discover/events'); // Uncomment when events feed screen is ready
        },
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: Theme.of(context).colorScheme.error,
          child: Text(
            event['image'] ?? '🎉',
            style: const TextStyle(fontSize: 20),
          ),
        ),
        title: Text(
          event['title'],
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(event['description']),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    event['location'],
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(
                  Icons.people,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
                const SizedBox(width: 4),
                Text(
                  '${event['attendeeCount'] ?? event['attendees'] ?? 0} attending',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          size: 16,
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildSavedList(BuildContext context) {
    // This would show saved/favorited items (users, communities, events)
    // For now, show a placeholder since we don't have saved items yet
    return Column(
      children: [
        // Info about saved items
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.bookmark,
                    size: 32,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Saved Items',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Save users, communities, and events to view them later',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Saved items list (currently empty)
        Expanded(
          child: _buildEmptyState(
            context,
            'No saved items yet',
            'Tap the bookmark icon on any card to save it for later',
            Icons.bookmark_border,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
