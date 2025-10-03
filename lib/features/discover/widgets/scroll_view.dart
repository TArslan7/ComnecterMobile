import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
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
    final tabs = ['Detected Users', 'Friends', 'Communities', 'Events'];

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
                _buildDetectedUsersList(context),
                _buildFriendsList(context),
                _buildCommunitiesList(context),
                _buildEventsList(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetectedUsersList(BuildContext context) {
    if (detectedUsers.isEmpty) {
      return _buildEmptyState(
        context,
        'No users detected',
        'Start scanning to discover people nearby',
        Icons.radar,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8),
      itemCount: detectedUsers.length,
      itemBuilder: (context, index) {
        final user = detectedUsers[index];
        return _buildUserCard(context, user);
      },
    );
  }

  Widget _buildFriendsList(BuildContext context) {
    if (friends.isEmpty) {
      return _buildEmptyState(
        context,
        'No friends yet',
        'Connect with people you meet to build your network',
        Icons.people,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8),
      itemCount: friends.length,
      itemBuilder: (context, index) {
        final friend = friends[index];
        return _buildFriendCard(context, friend);
      },
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

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8),
      itemCount: communities.length,
      itemBuilder: (context, index) {
        final community = communities[index];
        return _buildCommunityCard(context, community);
      },
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

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return _buildEventCard(context, event);
      },
    );
  }

  Widget _buildUserCard(BuildContext context, NearbyUser user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
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
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => _sendFriendRequest(context, user),
              icon: const Icon(Icons.person_add),
              tooltip: 'Send friend request',
            ),
            IconButton(
              onPressed: () => _startChat(context, user),
              icon: const Icon(Icons.chat),
              tooltip: 'Start chat',
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildFriendCard(BuildContext context, Map<String, dynamic> friend) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: Theme.of(context).colorScheme.secondary,
          child: Text(
            friend['avatar'] ?? '👤',
            style: const TextStyle(fontSize: 20),
          ),
        ),
        title: Text(
          friend['name'] ?? 'Unknown',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          friend['status'] ?? 'Online',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: friend['status'] == 'Online' 
                ? Colors.green 
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        trailing: IconButton(
          onPressed: () => _startChat(context, friend),
          icon: const Icon(Icons.chat),
          tooltip: 'Start chat',
        ),
      ),
    );
  }

  Widget _buildCommunityCard(BuildContext context, Map<String, dynamic> community) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: Theme.of(context).colorScheme.tertiary,
          child: Text(
            community['image'] ?? '👥',
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
        trailing: ElevatedButton(
          onPressed: () => _joinCommunity(context, community),
          child: const Text('Join'),
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, Map<String, dynamic> event) {
    final eventDate = event['date'] as DateTime;
    final isUpcoming = eventDate.isAfter(DateTime.now());
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
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
                  '${event['attendees']} attending',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: isUpcoming ? () => _attendEvent(context, event) : null,
          child: Text(isUpcoming ? 'Attend' : 'Past'),
        ),
        isThreeLine: true,
      ),
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

  void _sendFriendRequest(BuildContext context, NearbyUser user) async {
    try {
      await friendService.sendFriendRequest(
        user.id,
        user.name,
        user.avatar,
        message: 'Hey! I detected you on radar. Would you like to connect?',
      );
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Friend request sent to ${user.name}!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
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

  void _startChat(BuildContext context, dynamic user) {
    // Navigate to chat screen
    // This would typically navigate to a chat screen with the selected user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Starting chat with ${user.name ?? user['name']}'),
      ),
    );
  }

  void _joinCommunity(BuildContext context, Map<String, dynamic> community) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Joining ${community['name']}...'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _attendEvent(BuildContext context, Map<String, dynamic> event) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Attending ${event['title']}...'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
