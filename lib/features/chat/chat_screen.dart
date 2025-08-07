import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import '../../services/sound_service.dart';
import '../../theme/app_theme.dart';

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
        'isOnline': true,
        'avatar': '👩‍🦰',
        'status': 'online',
      },
      {
        'id': '2',
        'name': 'Mike Chen',
        'lastMessage': 'Thanks for the help!',
        'timestamp': '1 hour ago',
        'unreadCount': 0,
        'isOnline': false,
        'avatar': '👨‍💼',
        'status': 'offline',
      },
      {
        'id': '3',
        'name': 'Emma Wilson',
        'lastMessage': 'See you tomorrow!',
        'timestamp': '3 hours ago',
        'unreadCount': 1,
        'isOnline': true,
        'avatar': '👩‍🎨',
        'status': 'online',
      },
      {
        'id': '4',
        'name': 'David Brown',
        'lastMessage': 'Great meeting you!',
        'timestamp': '1 day ago',
        'unreadCount': 0,
        'isOnline': false,
        'avatar': '👨‍🔬',
        'status': 'offline',
      },
      {
        'id': '5',
        'name': 'Lisa Garcia',
        'lastMessage': 'Can you help me with the project?',
        'timestamp': '2 days ago',
        'unreadCount': 3,
        'isOnline': true,
        'avatar': '👩‍💻',
        'status': 'online',
      },
    ];

    useEffect(() {
      bool mounted = true;
      
      // Simulate loading
      Future.delayed(const Duration(milliseconds: 1500), () async {
        if (mounted) {
          try {
            await soundService.playSuccessSound();
            if (mounted) {
              conversations.value = mockConversations;
              isLoading.value = false;
            }
          } catch (e) {
            // Handle error silently
          }
        }
      });
      
      return () {
        mounted = false;
      };
    }, []);

    // Filter conversations based on search
    final filteredConversations = useMemoized(() {
      if (searchQuery.value.isEmpty) {
        return conversations.value;
      }
      return conversations.value.where((conv) =>
        conv['name'].toLowerCase().contains(searchQuery.value.toLowerCase()) ||
        conv['lastMessage'].toLowerCase().contains(searchQuery.value.toLowerCase())
      ).toList();
    }, [conversations.value, searchQuery.value]);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: _buildAppBar(context, searchQuery, isSearching, soundService),
      body: isLoading.value
          ? _buildLoadingState(context)
          : filteredConversations.isEmpty
              ? _buildEmptyState(context, searchQuery.value.isNotEmpty)
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
      title: isSearching.value
          ? TextField(
              onChanged: (value) => searchQuery.value = value,
              decoration: InputDecoration(
                hintText: 'Search conversations...',
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.grey[400]),
              ),
              style: const TextStyle(fontSize: 18),
              autofocus: true,
            )
          : Row(
              children: [
                Icon(
                  Icons.chat_bubble,
                  color: AppTheme.primaryBlue,
                  size: 28,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Chat',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      actions: [
        if (!isSearching.value) ...[
          IconButton(
            icon: Icon(
              Icons.search,
              color: AppTheme.primaryBlue,
            ),
            onPressed: () async {
              await soundService.playButtonClickSound();
              isSearching.value = true;
            },
            tooltip: 'Search',
          ),
          IconButton(
            icon: Icon(
              Icons.more_vert,
              color: AppTheme.primaryBlue,
            ),
            onPressed: () async {
              await soundService.playButtonClickSound();
              _showMoreOptions(context);
            },
            tooltip: 'More options',
          ),
        ] else ...[
          IconButton(
            icon: Icon(
              Icons.close,
              color: AppTheme.primaryBlue,
            ),
            onPressed: () async {
              await soundService.playButtonClickSound();
              isSearching.value = false;
              searchQuery.value = '';
            },
            tooltip: 'Close search',
          ),
        ],
      ],
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: const CircleAvatar(radius: 25),
            ),
            title: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                height: 16,
                width: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            subtitle: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                height: 12,
                width: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isSearching) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearching ? Icons.search_off : Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            isSearching ? 'No conversations found' : 'No conversations yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isSearching
                ? 'Try adjusting your search terms'
                : 'Start chatting with people you meet!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: const Duration(milliseconds: 500));
  }

  Widget _buildConversationsList(
    BuildContext context,
    List<Map<String, dynamic>> conversations,
    SoundService soundService,
  ) {
    return ListView.builder(
      itemCount: conversations.length,
      itemBuilder: (context, index) {
        final conversation = conversations[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: Stack(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                  child: Text(
                    conversation['avatar'],
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                if (conversation['isOnline'])
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppTheme.accentGreen,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    conversation['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
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
            subtitle: Text(
              conversation['lastMessage'],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: conversation['unreadCount'] > 0
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      conversation['unreadCount'].toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : null,
            onTap: () async {
              await soundService.playTapSound();
              _openConversation(context, conversation);
            },
          ),
        ).animate().fadeIn(
          duration: const Duration(milliseconds: 300),
          delay: Duration(milliseconds: index * 100),
        );
      },
    );
  }

  Widget _buildFloatingActionButton(BuildContext context, SoundService soundService) {
    return FloatingActionButton(
      onPressed: () async {
        await soundService.playButtonClickSound();
        _showNewConversationDialog(context);
      },
      backgroundColor: AppTheme.primaryBlue,
      child: const Icon(Icons.chat, color: Colors.white),
    ).animate().scale(duration: const Duration(milliseconds: 300));
  }

  void _openConversation(BuildContext context, Map<String, dynamic> conversation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _ConversationDetailScreen(conversation: conversation),
      ),
    );
  }

  void _showMoreOptions(BuildContext context) {
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
              leading: const Icon(Icons.archive),
              title: const Text('Archive all'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement archive functionality
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Clear all'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement clear functionality
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Chat settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/settings');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showNewConversationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Conversation'),
        content: const Text('This feature is coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _ConversationDetailScreen extends HookWidget {
  final Map<String, dynamic> conversation;

  const _ConversationDetailScreen({required this.conversation});

  @override
  Widget build(BuildContext context) {
    final messages = useState<List<Map<String, dynamic>>>([]);
    final textController = useTextEditingController();
    final soundService = useMemoized(() => SoundService());

    useEffect(() {
      // Load mock messages
      messages.value = [
        {
          'id': '1',
          'text': 'Hey! How are you doing?',
          'isMe': false,
          'timestamp': DateTime.now().subtract(const Duration(minutes: 5)),
        },
        {
          'id': '2',
          'text': 'I\'m doing great, thanks! How about you?',
          'isMe': true,
          'timestamp': DateTime.now().subtract(const Duration(minutes: 4)),
        },
        {
          'id': '3',
          'text': 'Pretty good! Want to grab coffee sometime?',
          'isMe': false,
          'timestamp': DateTime.now().subtract(const Duration(minutes: 3)),
        },
      ];
      
      return null;
    }, []);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
              child: Text(
                conversation['avatar'],
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  conversation['name'],
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  conversation['isOnline'] ? 'Online' : 'Offline',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () async {
              await soundService.playButtonClickSound();
              // TODO: Implement call functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.video_call),
            onPressed: () async {
              await soundService.playButtonClickSound();
              // TODO: Implement video call functionality
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: messages.value.length,
              itemBuilder: (context, index) {
                final message = messages.value[index];
                return _buildMessageBubble(context, message);
              },
            ),
          ),
          _buildMessageInput(context, textController, messages, soundService),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context, Map<String, dynamic> message) {
    final isMe = message['isMe'] as bool;
    
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isMe ? AppTheme.primaryGradient : AppTheme.secondaryGradient,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          message['text'],
          style: const TextStyle(color: Colors.white),
        ),
      ),
    ).animate().fadeIn(duration: const Duration(milliseconds: 300));
  }

  Widget _buildMessageInput(
    BuildContext context,
    TextEditingController controller,
    ValueNotifier<List<Map<String, dynamic>>> messages,
    SoundService soundService,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await soundService.playMessageSound();
                messages.value = [
                  ...messages.value,
                  {
                    'id': DateTime.now().millisecondsSinceEpoch.toString(),
                    'text': controller.text,
                    'isMe': true,
                    'timestamp': DateTime.now(),
                  },
                ];
                controller.clear();
              }
            },
            backgroundColor: AppTheme.primaryBlue,
            child: const Icon(Icons.send, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
