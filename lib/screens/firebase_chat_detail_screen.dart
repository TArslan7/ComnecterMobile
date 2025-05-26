import 'package:flutter/material.dart';
import '../theme.dart';

class FirebaseChatDetailScreen extends StatelessWidget {
  final String chatId;
  final dynamic otherUser;
  final bool isCommunityChat;
  final String? communityName;

  const FirebaseChatDetailScreen({
    Key? key,
    required this.chatId,
    this.otherUser,
    this.isCommunityChat = false,
    this.communityName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 100,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 24),
            const Text(
              'Firebase Chat Coming Soon',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'This feature will be available in a future update.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getTitle() {
    if (isCommunityChat) {
      return communityName ?? 'Community Chat';
    } else {
      return otherUser?.userName ?? 'Chat';
    }
  }
}