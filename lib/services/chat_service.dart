import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';

class ChatService {
  static const String _chatsKey = 'chats';
  static const String _messagesPrefix = 'messages_';

  // Get all chats from local storage
  Future<List<ChatModel>> getAllChats() async {
    final prefs = await SharedPreferences.getInstance();
    final chatsJson = prefs.getString(_chatsKey);
    if (chatsJson == null) return [];
    
    final List<dynamic> chatsList = jsonDecode(chatsJson);
    return chatsList.map((chat) => ChatModel.fromJson(chat)).toList();
  }

  // Save all chats to local storage
  Future<void> saveAllChats(List<ChatModel> chats) async {
    final prefs = await SharedPreferences.getInstance();
    final chatsJson = jsonEncode(chats.map((chat) => chat.toJson()).toList());
    await prefs.setString(_chatsKey, chatsJson);
  }

  // Create a new chat
  Future<ChatModel> createChat(List<String> participantIds, {String? communityId}) async {
    final chatId = 'chat_${DateTime.now().millisecondsSinceEpoch}';
    final newChat = ChatModel(
      chatId: chatId,
      participantIds: participantIds,
      isCommunityChat: communityId != null,
      communityId: communityId,
    );
    
    final chats = await getAllChats();
    chats.add(newChat);
    await saveAllChats(chats);
    return newChat;
  }

  // Get a chat by ID
  Future<ChatModel?> getChatById(String chatId) async {
    final chats = await getAllChats();
    return chats.firstWhere((chat) => chat.chatId == chatId, orElse: () => throw Exception('Chat not found'));
  }

  // Get messages for a specific chat
  Future<List<MessageModel>> getMessagesForChat(String chatId) async {
    final prefs = await SharedPreferences.getInstance();
    final messagesJson = prefs.getString('${_messagesPrefix}$chatId');
    if (messagesJson == null) return [];
    
    final List<dynamic> messagesList = jsonDecode(messagesJson);
    return messagesList.map((msg) => MessageModel.fromJson(msg)).toList();
  }

  // Add a message to a chat
  Future<void> addMessage(String chatId, MessageModel message) async {
    final prefs = await SharedPreferences.getInstance();
    final messages = await getMessagesForChat(chatId);
    messages.add(message);
    
    final messagesJson = jsonEncode(messages.map((msg) => msg.toJson()).toList());
    await prefs.setString('${_messagesPrefix}$chatId', messagesJson);
    
    // Update chat with last message info
    final chats = await getAllChats();
    final chatIndex = chats.indexWhere((chat) => chat.chatId == chatId);
    if (chatIndex != -1) {
      chats[chatIndex] = chats[chatIndex].copyWith(
        lastMessageContent: message.content,
        lastMessageTime: message.timestamp,
      );
      await saveAllChats(chats);
    }
  }

  // Get chats for a user
  Future<List<ChatModel>> getChatsForUser(String userId) async {
    final chats = await getAllChats();
    return chats.where((chat) => chat.participantIds.contains(userId)).toList();
  }
  
  // Get community chats
  Future<List<ChatModel>> getCommunityChats() async {
    final chats = await getAllChats();
    return chats.where((chat) => chat.isCommunityChat).toList();
  }
}