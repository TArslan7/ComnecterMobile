import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';

class ChatScreen extends HookWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final conversations = useState<List<ChatConversation>>([
      ChatConversation(
        id: '1',
        name: 'Sarah Johnson',
        avatar: '👩',
        lastMessage: 'That sounds awesome! I\'ve been working on some new projects.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        unreadCount: 2,
        isOnline: true,
      ),
      ChatConversation(
        id: '2',
        name: 'Mike Chen',
        avatar: '👨',
        lastMessage: 'Great! Let\'s meet up tomorrow for coffee.',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        unreadCount: 0,
        isOnline: false,
      ),
      ChatConversation(
        id: '3',
        name: 'Emma Wilson',
        avatar: '👩‍🦰',
        lastMessage: 'Thanks for the help with the project!',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        unreadCount: 1,
        isOnline: true,
      ),
      ChatConversation(
        id: '4',
        name: 'Alex Rodriguez',
        avatar: '👨‍🦱',
        lastMessage: 'The meeting is scheduled for 3 PM.',
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        unreadCount: 0,
        isOnline: false,
      ),
      ChatConversation(
        id: '5',
        name: 'Lisa Park',
        avatar: '👩‍🦳',
        lastMessage: 'Can you send me the files?',
        timestamp: DateTime.now().subtract(const Duration(days: 3)),
        unreadCount: 3,
        isOnline: true,
      ),
    ]);

    void openConversation(ChatConversation conversation) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatConversationScreen(conversation: conversation),
        ),
      );
    }

    void startNewChat() {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Start New Chat'),
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

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Chats',
          style: TextStyle(
            color: AppTheme.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.surfaceLight,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              Icons.search,
              color: AppTheme.primary,
            ),
            onPressed: () {
              // TODO: Implement search
            },
          ),
          IconButton(
            icon: Icon(
              Icons.more_vert,
              color: AppTheme.primary,
            ),
            onPressed: () {
              // TODO: Show more options
            },
          ),
        ],
      ),
      body: conversations.value.isEmpty
          ? _buildEmptyState(context)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: conversations.value.length,
              itemBuilder: (context, index) {
                final conversation = conversations.value[index];
                return _buildConversationTile(context, conversation, openConversation);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: startNewChat,
        backgroundColor: AppTheme.primary,
        child: const Icon(
          Icons.chat,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildConversationTile(
    BuildContext context,
    ChatConversation conversation,
    Function(ChatConversation) onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTap(conversation),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.primary.withOpacity(0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.05),
                  blurRadius: 8,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Avatar with online indicator
                Stack(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withOpacity(0.3),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          conversation.avatar,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                    if (conversation.isOnline)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: AppTheme.success,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.success.withOpacity(0.5),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              conversation.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                              ),
                            ),
                          ),
                          Text(
                            _formatTime(conversation.timestamp),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textMedium,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              conversation.lastMessage,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.textMedium,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (conversation.unreadCount > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                conversation.unreadCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
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
    ).animate().fadeIn(
      duration: const Duration(milliseconds: 300),
    ).slideX(
      begin: 0.3,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
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
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(60),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.chat_bubble_outline,
              color: Colors.white,
              size: 60,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No conversations yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Start chatting with people you meet!',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textMedium,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement start new chat
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Start New Chat',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${time.day}/${time.month}';
    } else if (difference.inHours > 0) {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

class ChatConversation {
  final String id;
  final String name;
  final String avatar;
  final String lastMessage;
  final DateTime timestamp;
  final int unreadCount;
  final bool isOnline;

  ChatConversation({
    required this.id,
    required this.name,
    required this.avatar,
    required this.lastMessage,
    required this.timestamp,
    required this.unreadCount,
    required this.isOnline,
  });
}

class ChatConversationScreen extends HookWidget {
  final ChatConversation conversation;

  const ChatConversationScreen({
    super.key,
    required this.conversation,
  });

  @override
  Widget build(BuildContext context) {
    final messages = useState<List<ChatMessage>>([
      ChatMessage(
        id: '1',
        text: 'Hey! How are you doing?',
        isMe: false,
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        senderName: conversation.name,
        senderAvatar: conversation.avatar,
      ),
      ChatMessage(
        id: '2',
        text: 'I\'m doing great! Just finished a workout. How about you?',
        isMe: true,
        timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
        senderName: 'You',
        senderAvatar: '👤',
      ),
      ChatMessage(
        id: '3',
        text: 'That sounds awesome! I\'ve been working on some new projects.',
        isMe: false,
        timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
        senderName: conversation.name,
        senderAvatar: conversation.avatar,
      ),
      ChatMessage(
        id: '4',
        text: 'What kind of projects? I\'d love to hear about them!',
        isMe: true,
        timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
        senderName: 'You',
        senderAvatar: '👤',
      ),
      ChatMessage(
        id: '5',
        text: 'Mostly mobile app development. I\'m learning Flutter right now!',
        isMe: false,
        timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
        senderName: conversation.name,
        senderAvatar: conversation.avatar,
      ),
    ]);

    final textController = useTextEditingController();
    final scrollController = useScrollController();

    void sendMessage() {
      if (textController.text.trim().isNotEmpty) {
        final newMessage = ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: textController.text.trim(),
          isMe: true,
          timestamp: DateTime.now(),
          senderName: 'You',
          senderAvatar: '👤',
        );

        messages.value = [...messages.value, newMessage];
        textController.clear();

        // Auto-scroll to bottom
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (scrollController.hasClients) {
            scrollController.animateTo(
              scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.5),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  conversation.avatar,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  conversation.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  conversation.isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    fontSize: 12,
                    color: conversation.isOnline ? AppTheme.success : AppTheme.textMedium,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: AppTheme.surfaceLight,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              Icons.video_call,
              color: AppTheme.primary,
            ),
            onPressed: () {
              // TODO: Implement video call
            },
          ),
          IconButton(
            icon: Icon(
              Icons.call,
              color: AppTheme.primary,
            ),
            onPressed: () {
              // TODO: Implement voice call
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.value.length,
              itemBuilder: (context, index) {
                final message = messages.value[index];
                return _buildMessageBubble(context, message);
              },
            ),
          ),
          _buildMessageInput(context, textController, sendMessage),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context, ChatMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: message.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isMe) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  message.senderAvatar,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: message.isMe 
                    ? AppTheme.primaryGradient
                    : LinearGradient(
                        colors: [
                          AppTheme.surfaceLight,
                          AppTheme.surfaceLight.withOpacity(0.8),
                        ],
                      ),
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomLeft: message.isMe ? const Radius.circular(20) : const Radius.circular(4),
                  bottomRight: message.isMe ? const Radius.circular(4) : const Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: message.isMe 
                        ? AppTheme.primary.withOpacity(0.3)
                        : Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    spreadRadius: 1,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: message.isMe ? Colors.white : AppTheme.textDark,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      color: message.isMe 
                          ? Colors.white.withOpacity(0.7)
                          : AppTheme.textMedium,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (message.isMe) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  '👤',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(
      duration: const Duration(milliseconds: 300),
    ).slideX(
      begin: message.isMe ? 0.3 : -0.3,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  Widget _buildMessageInput(BuildContext context, TextEditingController controller, VoidCallback onSend) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: AppTheme.primary.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.1),
                    blurRadius: 8,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              onPressed: onSend,
              icon: const Icon(
                Icons.send,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${time.day}/${time.month}/${time.year}';
    } else if (difference.inHours > 0) {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

class ChatMessage {
  final String id;
  final String text;
  final bool isMe;
  final DateTime timestamp;
  final String senderName;
  final String senderAvatar;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isMe,
    required this.timestamp,
    required this.senderName,
    required this.senderAvatar,
  });
}
