import 'package:flutter/material.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _chatService = ChatService();
  
  List<ChatModel> _chats = [];
  Map<String, List<MessageModel>> _messages = {};
  String? _activeChatId;
  bool _isLoading = false;

  List<ChatModel> get chats => _chats;
  Map<String, List<MessageModel>> get messages => _messages;
  String? get activeChatId => _activeChatId;
  bool get isLoading => _isLoading;

  List<MessageModel>? get activeMessages => 
    _activeChatId != null ? _messages[_activeChatId] : null;

  Future<void> loadChats(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _chats = await _chatService.getChatsForUser(userId);
      
      // Pre-load messages for all chats
      for (final chat in _chats) {
        await loadMessages(chat.chatId);
      }
    } catch (e) {
      print('Error loading chats: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMessages(String chatId) async {
    try {
      final loadedMessages = await _chatService.getMessagesForChat(chatId);
      _messages[chatId] = loadedMessages;
      notifyListeners();
    } catch (e) {
      print('Error loading messages: $e');
    }
  }

  void setActiveChat(String chatId) {
    _activeChatId = chatId;
    if (!_messages.containsKey(chatId)) {
      loadMessages(chatId);
    }
    notifyListeners();
  }

  Future<ChatModel> createChat(List<String> participantIds, {String? communityId}) async {
    final newChat = await _chatService.createChat(participantIds, communityId: communityId);
    _chats.add(newChat);
    _messages[newChat.chatId] = [];
    notifyListeners();
    return newChat;
  }

  Future<void> sendMessage(String chatId, String content, String senderId) async {
    if (!_messages.containsKey(chatId)) {
      _messages[chatId] = [];
    }

    final messageId = 'msg_${DateTime.now().millisecondsSinceEpoch}';
    final newMessage = MessageModel(
      messageId: messageId,
      senderId: senderId,
      content: content,
      timestamp: DateTime.now(),
    );

    await _chatService.addMessage(chatId, newMessage);
    _messages[chatId]!.add(newMessage);

    // Update the chat's last message info
    final chatIndex = _chats.indexWhere((chat) => chat.chatId == chatId);
    if (chatIndex != -1) {
      _chats[chatIndex] = _chats[chatIndex].copyWith(
        lastMessageContent: content,
        lastMessageTime: DateTime.now(),
      );
    }
    
    notifyListeners();
  }

  List<ChatModel> getDirectChats() {
    return _chats.where((chat) => !chat.isCommunityChat).toList();
  }

  List<ChatModel> getCommunityChats() {
    return _chats.where((chat) => chat.isCommunityChat).toList();
  }

  Future<List<ChatModel>> getAllChats() async {
    try {
      return await _chatService.getAllChats();
    } catch (e) {
      print('Error getting all chats: $e');
      return [];
    }
  }
}