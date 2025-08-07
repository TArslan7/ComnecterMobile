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

    // Load data on first build
    useEffect(() {
      // Simulate loading with a simple timer
      Timer(const Duration(milliseconds: 1500), () {
        conversations.value = mockConversations;
        isLoading.value = false;
        // Play success sound
        soundService.playSuccessSound();
      });
      
      return null;
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
            onPressed: () {
              soundService.playButtonClickSound();
              isSearching.value = true;
            },
          ),
          IconButton(
            icon: Icon(
              Icons.more_vert,
              color: AppTheme.primaryBlue,
            ),
            onPressed: () {
              soundService.playButtonClickSound();
              _showMoreOptions(context, soundService);
            },
          ),
        ] else ...[
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              soundService.playButtonClickSound();
              isSearching.value = false;
              searchQuery.value = '';
            },
          ),
        ],
      ],
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 16,
                        width: double.infinity,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 12,
                        width: 200,
                        color: Colors.grey[300],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isSearch) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearch ? Icons.search_off : Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            isSearch ? 'No conversations found' : 'No conversations yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isSearch 
                ? 'Try adjusting your search terms'
                : 'Start a conversation to connect with others',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
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
        ).animate().fadeIn(delay: Duration(milliseconds: index * 100));
      },
    );
  }

  Widget _buildConversationTile(
    BuildContext context,
    Map<String, dynamic> conversation,
    SoundService soundService,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Stack(
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
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(6),
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
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
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
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    conversation['lastMessage'],
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
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
                      color: AppTheme.primaryBlue,
                      borderRadius: BorderRadius.circular(10),
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
        onTap: () {
          soundService.playTapSound();
          _openConversation(context, conversation);
        },
      ),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context, SoundService soundService) {
    return FloatingActionButton(
      onPressed: () {
        soundService.playButtonClickSound();
        _showNewConversationDialog(context, soundService);
      },
      backgroundColor: AppTheme.primaryBlue,
      child: const Icon(Icons.add, color: Colors.white),
    ).animate().scale(duration: const Duration(milliseconds: 200));
  }

  void _openConversation(BuildContext context, Map<String, dynamic> conversation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _ConversationDetailScreen(conversation: conversation),
      ),
    );
  }

  void _showMoreOptions(BuildContext context, SoundService soundService) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('New Conversation'),
              onTap: () {
                soundService.playButtonClickSound();
                Navigator.pop(context);
                _showNewConversationDialog(context, soundService);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Chat Settings'),
              onTap: () {
                soundService.playButtonClickSound();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showNewConversationDialog(BuildContext context, SoundService soundService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Conversation'),
        content: const Text('This feature will be available soon!'),
        actions: [
          TextButton(
            onPressed: () {
              soundService.playButtonClickSound();
              Navigator.pop(context);
            },
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
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
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
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    conversation['isOnline'] ? 'Online' : 'Offline',
                    style: TextStyle(
                      fontSize: 12,
                      color: conversation['isOnline'] ? Colors.green : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => soundService.playButtonClickSound(),
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
                return _buildMessageBubble(context, message, soundService);
              },
            ),
          ),
          _buildMessageInput(context, textController, messages, soundService),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
    BuildContext context,
    Map<String, dynamic> message,
    SoundService soundService,
  ) {
    final isMe = message['isMe'] as bool;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  conversation['avatar'],
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: isMe ? AppTheme.primaryGradient : AppTheme.secondaryGradient,
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(4),
                  bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(20),
                ),
              ),
              child: Text(
                message['text'],
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black87,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    ).animate().fadeIn(duration: const Duration(milliseconds: 300));
  }

  Widget _buildMessageInput(
    BuildContext context,
    TextEditingController textController,
    ValueNotifier<List<Map<String, dynamic>>> messages,
    SoundService soundService,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: textController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(25),
            ),
            child: IconButton(
              onPressed: () {
                if (textController.text.trim().isNotEmpty) {
                  soundService.playMessageSound();
                  messages.value = [
                    ...messages.value,
                    {
                      'id': DateTime.now().toString(),
                      'text': textController.text.trim(),
                      'isMe': true,
                      'timestamp': DateTime.now(),
                    },
                  ];
                  textController.clear();
                }
              },
              icon: const Icon(Icons.send, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
