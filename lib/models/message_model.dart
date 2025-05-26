enum MessageType { text, image }

class MessageModel {
  final String messageId;
  final String senderId;
  final String content;
  final DateTime timestamp;
  final MessageType messageType;

  MessageModel({
    required this.messageId,
    required this.senderId,
    required this.content,
    required this.timestamp,
    this.messageType = MessageType.text,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      messageId: json['messageId'],
      senderId: json['senderId'],
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
      messageType: MessageType.values.byName(json['messageType']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'senderId': senderId,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'messageType': messageType.name,
    };
  }
}