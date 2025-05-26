// TODO: Implementeer scroll-naar-laatste-bericht na verzenden
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/sound_service.dart';
import '../providers/user_provider.dart';
import '../providers/chat_provider.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../theme.dart';
import '../screens/call_screen.dart';

class ChatDetailScreen extends StatefulWidget {
  final String chatId;
  final UserModel? otherUser;
  final bool isCommunityChat;
  final String? communityName;

  const ChatDetailScreen({
    Key? key,
    required this.chatId,
    this.otherUser,
    this.isCommunityChat = false,
    this.communityName,
  }) : super(key: key);

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // Keep state when navigating away
  
  // Sound service for sound effects
  final SoundService _soundService = SoundService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  late AnimationController _sendButtonController;
  bool _isComposing = false;
  late AnimationController _typingIndicatorController;
  
  // Animation for typing indicator
  late List<Animation<double>> _typingAnimations;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    
    _sendButtonController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _messageController.addListener(_onTextChanged);
    
    // Set up typing indicator animation
    _typingIndicatorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    
    _typingAnimations = List.generate(
      3,
      (index) => Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(
        CurvedAnimation(
          parent: _typingIndicatorController,
          curve: Interval(
            (index * 0.2),
            0.6 + (index * 0.2),
            curve: Curves.easeInOut,
          ),
        ),
      ),
    );
  }
  
  void _onTextChanged() {
    final isCurrentlyComposing = _messageController.text.isNotEmpty;
    if (isCurrentlyComposing != _isComposing) {
      setState(() {
        _isComposing = isCurrentlyComposing;
      });
      
      if (_isComposing) {
        HapticFeedback.selectionClick();
        _sendButtonController.forward();
      } else {
        _sendButtonController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    _sendButtonController.dispose();
    _typingIndicatorController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);

    try {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      chatProvider.setActiveChat(widget.chatId);
      await chatProvider.loadMessages(widget.chatId);
      
      // Scroll to bottom on initial load
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollToBottom();
        }
      });
    } catch (e) {
      print('Error loading messages: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading messages. Please try again.'))
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.currentUser;
    
    if (currentUser == null) {
      // Play error sound
      _soundService.playErrorSound();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not found. Please try again later.'))
      );
      return;
    }

    _messageController.clear();
    // Provide haptic feedback
    HapticFeedback.lightImpact();
    
    // Play message send sound
    _soundService.playTapSound();

    try {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      await chatProvider.sendMessage(
        widget.chatId,
        message,
        currentUser.userId,
      );
      
      // Play successful message sound
      _soundService.playMessageSound();
      
      // Scroll to the newly added message
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      print('Error sending message: $e');
      if (mounted) {
        // Play error sound
        _soundService.playErrorSound();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: $e'))
        );
      }
    }
  }

  String _getTitle() {
    if (widget.isCommunityChat) {
      return widget.communityName ?? 'Community Chat';
    } else {
      return widget.otherUser?.userName ?? 'Chat';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            if (!widget.isCommunityChat && widget.otherUser != null)
              Hero(
                tag: 'avatar_${widget.otherUser!.userId}',
                child: Container(
                  width: 40,
                  height: 40,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    gradient: AppTheme.accentGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      widget.otherUser!.userName.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              )
            else if (widget.isCommunityChat)
              Hero(
                tag: 'community_${widget.chatId}',
                child: Container(
                  width: 40,
                  height: 40,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.people_outline,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getTitle(),
                    style: const TextStyle(fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!widget.isCommunityChat && widget.otherUser != null)
                    Text(
                      '@${widget.otherUser!.username}',
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (!widget.isCommunityChat && widget.otherUser != null) ...[  
            IconButton(
              icon: const Icon(Icons.phone),
              tooltip: 'Voice Call',
              onPressed: _startVoiceCall,
            ),
            IconButton(
              icon: const Icon(Icons.videocam),
              tooltip: 'Video Call',
              onPressed: _startVideoCall,
            ),
          ],
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // Show chat options
              _showChatOptions();
            },
          ),
        ],
      ),
      body: Consumer2<ChatProvider, UserProvider>(
        builder: (context, chatProvider, userProvider, _) {
          final messages = chatProvider.activeMessages;
          final currentUser = userProvider.currentUser;
          
          if (currentUser == null) {
            return const Center(child: Text('User not found'));
          }
          
          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (messages == null || messages.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.chat_bubble_outline,
                      size: 64,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No messages yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'Start the conversation by sending a message',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 48),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Focus on the text field
                      FocusScope.of(context).requestFocus(FocusNode());
                      Future.delayed(const Duration(milliseconds: 100), () {
                        // Show keyboard with the message input
                        _showKeyboard();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    icon: const Icon(Icons.message),
                    label: const Text('Type a message'),
                  ),
                ],
              ),
            );
          }
          
          return Column(
            children: [
              // Simulated typing indicator (would be shown based on real typing status in a full app)
              // _buildTypingIndicator(),
              
              // Messages list
              Expanded(
                child: AnimationLimiter(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isCurrentUser = message.senderId == currentUser.userId;
                      
                      final isConsecutive = index > 0 && 
                                         messages[index - 1].senderId == message.senderId;
                      
                      String? senderName;
                      if (widget.isCommunityChat && !isCurrentUser) {
                        final sender = userProvider.nearbyUsers.firstWhere(
                          (user) => user.userId == message.senderId,
                          orElse: () => UserModel(
                            userId: message.senderId,
                            userName: 'User',
                            username: 'unknown',
                            latitude: 0,
                            longitude: 0,
                            interests: [],
                          ),
                        );
                        senderName = sender.userName;
                      }
                      
                      // Use staggered animations for messages
                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 375),
                        child: SlideAnimation(
                          horizontalOffset: isCurrentUser ? 50.0 : -50.0,
                          child: FadeInAnimation(
                            child: _buildMessageBubble(
                              context,
                              message,
                              isCurrentUser,
                              isConsecutive,
                              senderName,
                            )
                            // Apply animation to newest message
                            // We'll handle this animation separately to avoid Flutter build issues
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              
              // Message input
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      // Attachment button (for future implementation)
                      Container(
                        height: 45,
                        width: 45,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[800]
                              : Colors.grey[200],
                          shape: BoxShape.circle,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          shape: const CircleBorder(),
                          clipBehavior: Clip.hardEdge,
                          child: InkWell(
                            onTap: () {
                              // Show attachment options
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Attachment options coming soon'))
                              );
                            },
                            child: Center(
                              child: Icon(
                                Icons.add,
                                size: 22,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      // Text input field
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[800]
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: TextField(
                            controller: _messageController,
                            decoration: InputDecoration(
                              hintText: 'Type a message...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.emoji_emotions_outlined),
                                onPressed: () {
                                  // Show emoji picker
                                },
                              ),
                            ),
                            textInputAction: TextInputAction.send,
                            keyboardType: TextInputType.multiline,
                            maxLines: null,
                            textCapitalization: TextCapitalization.sentences,
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                      ),
                      
                      // Send button with animation
                      AnimatedBuilder(
                        animation: _sendButtonController,
                        builder: (context, child) {
                          return Container(
                            margin: const EdgeInsets.only(left: 8),
                            height: 45,
                            width: 45,
                            child: Transform.rotate(
                              angle: _sendButtonController.value * 1.57, // 90 degrees in radians
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: AppTheme.primaryGradient,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primaryColor.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: IconButton(
                                    icon: Icon(
                                      _isComposing ? Icons.send : Icons.mic,
                                      color: Colors.white,
                                    ),
                                    onPressed: _isComposing ? _sendMessage : () {
                                      // Voice recording would be implemented here
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Voice messages coming soon'))
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  
  void _showKeyboard() {
    FocusScope.of(context).requestFocus(FocusNode());
    Future.delayed(const Duration(milliseconds: 100), () {
      FocusScope.of(context).requestFocus(FocusNode());
      FocusManager.instance.primaryFocus?.unfocus();
      // This would show the keyboard with a message input field
      // full implementation would use a focusNode
    });
  }
  
  // Start a video call
  void _startVideoCall() {
    if (widget.isCommunityChat) {
      // Community calls would require different logic
      _soundService.playErrorSound();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Community video calls will be available soon'))
      );
      return;
    }
    
    if (widget.otherUser == null) return;
    
    HapticFeedback.mediumImpact();
    
    // Play call initiated sound
    _soundService.playCallInitiatedSound();
    
    // Generate a unique channel name using the chat ID
    final channelName = widget.chatId;
    // In a real app, you would generate a token using your server
    const token = '';
    // Use a unique ID for the local user
    const localUid = 1;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CallScreen(
          channelName: channelName,
          token: token,
          uid: localUid,
          remoteUserName: widget.otherUser?.userName ?? 'User',
          isVideoCall: true,
        ),
      ),
    );
  }
  
  // Start a voice call
  void _startVoiceCall() {
    if (widget.isCommunityChat) {
      // Community calls would require different logic
      _soundService.playErrorSound();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Community voice calls will be available soon'))
      );
      return;
    }
    
    if (widget.otherUser == null) return;
    
    HapticFeedback.mediumImpact();
    
    // Play call initiated sound
    _soundService.playCallInitiatedSound();
    
    // Generate a unique channel name using the chat ID
    final channelName = widget.chatId;
    // In a real app, you would generate a token using your server
    const token = '';
    // Use a unique ID for the local user
    const localUid = 1;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CallScreen(
          channelName: channelName,
          token: token,
          uid: localUid,
          remoteUserName: widget.otherUser?.userName ?? 'User',
          isVideoCall: false,
        ),
      ),
    );
  }

  void _showChatOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle indicator
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Options list
            if (!widget.isCommunityChat) ...[  
              ListTile(
                leading: const Icon(Icons.videocam, color: Colors.green),
                title: const Text('Video Call'),
                onTap: () {
                  Navigator.pop(context);
                  _startVideoCall();
                },
              ),
              ListTile(
                leading: const Icon(Icons.phone, color: Colors.blue),
                title: const Text('Voice Call'),
                onTap: () {
                  Navigator.pop(context);
                  _startVoiceCall();
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Search in conversation'),
              onTap: () {
                Navigator.pop(context);
                // Implement search
              },
            ),
            if (!widget.isCommunityChat)
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('View profile'),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to profile
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Clear chat history', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showClearChatDialog();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
  
  void _showClearChatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat History'),
        content: const Text('This will delete all messages in this conversation. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement clear chat
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chat history cleared'))
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 24, bottom: 12),
      child: Row(
        children: [
          Text(
            'Someone is typing',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(width: 8),
          // Animated dots
          Row(
            children: List.generate(
              3,
              (index) => AnimatedBuilder(
                animation: _typingAnimations[index],
                builder: (context, child) {
                  return Container(
                    width: 4,
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey[600],
                      shape: BoxShape.circle,
                      // Transform the dot based on the animation value
                      // to create a bouncing effect
                    ),
                    transform: Matrix4.translationValues(
                      0,
                      -4 * _typingAnimations[index].value * math.sin(math.pi * _typingAnimations[index].value),
                      0,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
    BuildContext context,
    MessageModel message,
    bool isCurrentUser,
    bool isConsecutive,
    String? senderName,
  ) {
    return Padding(
      padding: EdgeInsets.only(
        top: isConsecutive ? 4 : 12,
        bottom: 4,
        left: 12,
        right: 12,
      ),
      child: Row(
        mainAxisAlignment: isCurrentUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isCurrentUser && !isConsecutive)
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                gradient: AppTheme.accentGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentColor.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  senderName?.substring(0, 1).toUpperCase() ?? '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          else if (!isCurrentUser && isConsecutive)
            const SizedBox(width: 40),
          
          Flexible(
            child: Column(
              crossAxisAlignment: isCurrentUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (widget.isCommunityChat && !isCurrentUser && !isConsecutive && senderName != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 12, bottom: 4),
                    child: Text(
                      senderName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[400]
                            : Colors.grey[700],
                      ),
                    ),
                  ),
                
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isCurrentUser
                        ? AppTheme.primaryColor
                        : Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[800]
                            : Colors.grey[200],
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(
                        isCurrentUser || isConsecutive ? 16 : 4),
                      topRight: Radius.circular(
                        !isCurrentUser || isConsecutive ? 16 : 4),
                      bottomLeft: const Radius.circular(16),
                      bottomRight: const Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    message.content,
                    style: TextStyle(
                      color: isCurrentUser ? Colors.white : null,
                    ),
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                  child: Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[500]
                          : Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(time.year, time.month, time.day);

    final hours = time.hour.toString().padLeft(2, '0');
    final minutes = time.minute.toString().padLeft(2, '0');
    final timeString = '$hours:$minutes';

    if (messageDate == today) {
      return timeString;
    } else if (messageDate == yesterday) {
      return 'Yesterday, $timeString';
    } else {
      return '${time.day}/${time.month}, $timeString';
    }
  }
}