class ChatModel {
  final String chatId;
  final List<String> participantIds;
  final String? lastMessageContent;
  final DateTime? lastMessageTime;
  final bool isCommunityChat;
  final String? communityId;

  ChatModel({
    required this.chatId,
    required this.participantIds,
    this.lastMessageContent,
    this.lastMessageTime,
    this.isCommunityChat = false,
    this.communityId,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      chatId: json['chatId'],
      participantIds: List<String>.from(json['participantIds']),
      lastMessageContent: json['lastMessageContent'],
      lastMessageTime: json['lastMessageTime'] != null
          ? DateTime.parse(json['lastMessageTime'])
          : null,
      isCommunityChat: json['isCommunityChat'] ?? false,
      communityId: json['communityId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chatId': chatId,
      'participantIds': participantIds,
      'lastMessageContent': lastMessageContent,
      'lastMessageTime': lastMessageTime?.toIso8601String(),
      'isCommunityChat': isCommunityChat,
      'communityId': communityId,
    };
  }

  ChatModel copyWith({
    String? chatId,
    List<String>? participantIds,
    String? lastMessageContent,
    DateTime? lastMessageTime,
    bool? isCommunityChat,
    String? communityId,
  }) {
    return ChatModel(
      chatId: chatId ?? this.chatId,
      participantIds: participantIds ?? this.participantIds,
      lastMessageContent: lastMessageContent ?? this.lastMessageContent,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      isCommunityChat: isCommunityChat ?? this.isCommunityChat,
      communityId: communityId ?? this.communityId,
    );
  }
}