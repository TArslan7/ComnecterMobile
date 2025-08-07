import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import '../../services/sound_service.dart';
import '../../theme/app_theme.dart';
import 'dart:async'; // Added for Timer

class ChatScreen extends HookWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final conversations = useState<List<Map<String, dynamic>>>([]);
    final isLoading = useState(true);
    final searchQuery = useState('');
    final isSearching = useState(false);
    final soundService = useMemoized(() => SoundService());

    // Mock conversations data
    final mockConversations = [
      {
        'id': '1',
        'name': 'Sarah Johnson',
        'lastMessage': 'Hey! How are you doing?',
        'timestamp': '2 min ago',
        'unreadCount': 2,
        'avatar': '👩‍🦰',
        'isOnline': true,
      },
      {
        'id': '2',
        'name': 'Mike Chen',
        'lastMessage': 'Thanks for the connection!',
        'timestamp': '1 hour ago',
        'unreadCount': 0,
        'avatar': '👨‍💼',
        'isOnline': false,
      },
      {
        'id': '3',
        'name': 'Emma Wilson',
        'lastMessage': 'Let\'s meet up soon!',
        'timestamp': '3 hours ago',
        'unreadCount': 1,
        'avatar': '👩‍🎨',
        'isOnline': true,
      },
      {
        'id': '4',
        'name': 'David Brown',
        'lastMessage': 'Great to connect with you!',
        'timestamp': '1 day ago',
        'unreadCount': 0,
        'avatar': '👨‍🎓',
        'isOnline': false,
      },
      {
        'id': '5',
        'name': 'Lisa Garcia',
        'lastMessage': 'Love your profile!',
        'timestamp': '2 days ago',
        'unreadCount': 0,
        'avatar': '👩‍💻',
        'isOnline': true,
      },
    ];

    // Filter conversations based on search query
    final filteredConversations = useMemoized(() {
      if (searchQuery.value.isEmpty) {
        return mockConversations;
      }
      return mockConversations.where((conversation) {
        return (conversation['name'] as String).toLowerCase().contains(searchQuery.value.toLowerCase()) ||
               (conversation['lastMessage'] as String).toLowerCase().contains(searchQuery.value.toLowerCase());
      }).toList();
    }, [searchQuery.value]);

    // Simulate loading
    useEffect(() {
      final timer = Timer(const Duration(milliseconds: 1500), () {
        conversations.value = mockConversations;
        isLoading.value = false;
      });
      
      return () => timer.cancel();
    }, []);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: _buildAppBar(context, searchQuery, isSearching, soundService),
      body: isLoading.value
          ? _buildLoadingState(context)
          : filteredConversations.isEmpty
              ? _buildEmptyState(context)
              : _buildConversationsList(context, filteredConversations, soundService),
      floatingActionButton: _buildFloatingActionButton(context, soundService),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    ValueNotifier<String> searchQuery,
    ValueNotifier<bool> isSearching,
    SoundService soundService,
  ) {
    return AppBar(
      title: Row(
        children: [
          Icon(
            Icons.chat_bubble_outline,
            color: AppTheme.electricAurora,
            size: 28,
          ),
          const SizedBox(width: 8),
          const Text(
            'Chats',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      actions: [
        IconButton(
          icon: Icon(
            isSearching.value ? Icons.close : Icons.search,
            color: AppTheme.electricAurora,
          ),
          onPressed: () async {
            await soundService.playButtonClickSound();
            isSearching.value = !isSearching.value;
            if (!isSearching.value) {
              searchQuery.value = '';
            }
          },
        ),
        IconButton(
          icon: Icon(
            Icons.more_vert,
            color: AppTheme.electricAurora,
          ),
          onPressed: () async {
            await soundService.playButtonClickSound();
            _showMoreOptionsDialog(context);
          },
        ),
      ],
      bottom: isSearching.value
          ? PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  onChanged: (value) => searchQuery.value = value,
                  decoration: InputDecoration(
                    hintText: 'Search conversations...',
                    prefixIcon: Icon(Icons.search, color: AppTheme.electricAurora),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.electricAurora, width: 2),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: AppTheme.auroraGradient,
              borderRadius: BorderRadius.circular(60),
            ),
            child: const Icon(
              Icons.chat_bubble_outline,
              color: Colors.white,
              size: 60,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No conversations yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start connecting with people nearby!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationsList(
    BuildContext context,
    List<Map<String, dynamic>> conversations,
    SoundService soundService,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: conversations.length,
      itemBuilder: (context, index) {
        final conversation = conversations[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: _buildConversationTile(context, conversation, soundService),
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

  Widget _buildConversationTile(
    BuildContext context,
    Map<String, dynamic> conversation,
    SoundService soundService,
  ) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.electricAurora.withOpacity(0.3),
              blurRadius: 12,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: AppTheme.purpleAurora.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: InkWell(
          onTap: () async {
            await soundService.playTapSound();
            _showConversationDetail(context, conversation);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar with online indicator
                Stack(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: AppTheme.oceanGradient,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.tealAurora.withOpacity(0.5),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                          BoxShadow(
                            color: AppTheme.electricAurora.withOpacity(0.3),
                            blurRadius: 25,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          conversation['avatar'],
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                    if (conversation['isOnline'])
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: AppTheme.greenAurora,
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.greenAurora.withOpacity(0.6),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              conversation['name'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            conversation['timestamp'],
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              conversation['lastMessage'],
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (conversation['unreadCount'] > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                gradient: AppTheme.auroraGradient,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.electricAurora.withOpacity(0.4),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Text(
                                conversation['unreadCount'].toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context, SoundService soundService) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppTheme.electricAurora.withOpacity(0.4),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: AppTheme.purpleAurora.withOpacity(0.3),
            blurRadius: 25,
            spreadRadius: 1,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () async {
          await soundService.playButtonClickSound();
          _showNewChatDialog(context);
        },
        backgroundColor: AppTheme.electricAurora,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    ).animate().scale(duration: const Duration(milliseconds: 200));
  }

  void _showConversationDetail(BuildContext context, Map<String, dynamic> conversation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: AppTheme.oceanGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  conversation['avatar'],
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conversation['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    conversation['isOnline'] ? 'Online' : 'Offline',
                    style: TextStyle(
                      fontSize: 12,
                      color: conversation['isOnline'] ? AppTheme.greenAurora : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: const Text('Chat interface will be available soon!'),
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
              backgroundColor: AppTheme.electricAurora,
              foregroundColor: Colors.white,
            ),
            child: const Text('Start Chat'),
          ),
        ],
      ),
    );
  }

  void _showMoreOptionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('More Options'),
        content: const Text('Additional chat options will be available soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showNewChatDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Chat'),
        content: const Text('Start a new conversation. This feature will be available soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement new chat functionality
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.electricAurora,
              foregroundColor: Colors.white,
            ),
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }
}
