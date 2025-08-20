

enum FriendStatus {
  pending,
  accepted,
  rejected,
  blocked,
  removed,
}

enum FriendRequestType {
  sent,
  received,
}

class Friend {
  final String id;
  final String userId;
  final String friendId;
  final String name;
  final String avatar;
  final String? bio;
  final List<String> interests;
  final bool isOnline;
  final DateTime lastSeen;
  final FriendStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic> metadata;

  Friend({
    required this.id,
    required this.userId,
    required this.friendId,
    required this.name,
    required this.avatar,
    this.bio,
    this.interests = const [],
    required this.isOnline,
    required this.lastSeen,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.metadata = const {},
  });

  Friend copyWith({
    String? id,
    String? userId,
    String? friendId,
    String? name,
    String? avatar,
    String? bio,
    List<String>? interests,
    bool? isOnline,
    DateTime? lastSeen,
    FriendStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return Friend(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      friendId: friendId ?? this.friendId,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      bio: bio ?? this.bio,
      interests: interests ?? this.interests,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'friendId': friendId,
      'name': name,
      'avatar': avatar,
      'bio': bio,
      'interests': interests,
      'isOnline': isOnline,
      'lastSeen': lastSeen.toIso8601String(),
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  // Create from JSON
  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      id: json['id'],
      userId: json['userId'],
      friendId: json['friendId'],
      name: json['name'],
      avatar: json['avatar'],
      bio: json['bio'],
      interests: List<String>.from(json['interests'] ?? []),
      isOnline: json['isOnline'],
      lastSeen: DateTime.parse(json['lastSeen']),
      status: FriendStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => FriendStatus.pending,
      ),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }
}

class FriendRequest {
  final String id;
  final String fromUserId;
  final String toUserId;
  final String fromUserName;
  final String fromUserAvatar;
  final String? message;
  final FriendRequestType type;
  final DateTime createdAt;
  final DateTime? respondedAt;
  final FriendStatus? response;

  FriendRequest({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.fromUserName,
    required this.fromUserAvatar,
    this.message,
    required this.type,
    required this.createdAt,
    this.respondedAt,
    this.response,
  });

  FriendRequest copyWith({
    String? id,
    String? fromUserId,
    String? toUserId,
    String? fromUserName,
    String? fromUserAvatar,
    String? message,
    FriendRequestType? type,
    DateTime? createdAt,
    DateTime? respondedAt,
    FriendStatus? response,
  }) {
    return FriendRequest(
      id: id ?? this.id,
      fromUserId: fromUserId ?? this.fromUserId,
      toUserId: toUserId ?? this.toUserId,
      fromUserName: fromUserName ?? this.fromUserName,
      fromUserAvatar: fromUserAvatar ?? this.fromUserAvatar,
      message: message ?? this.message,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
      response: response ?? this.response,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'fromUserName': fromUserName,
      'fromUserAvatar': fromUserAvatar,
      'message': message,
      'type': type.name,
      'createdAt': createdAt.toIso8601String(),
      'respondedAt': respondedAt?.toIso8601String(),
      'response': response?.name,
    };
  }

  // Create from JSON
  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      id: json['id'],
      fromUserId: json['fromUserId'],
      toUserId: json['toUserId'],
      fromUserName: json['fromUserName'],
      fromUserAvatar: json['fromUserAvatar'],
      message: json['message'],
      type: FriendRequestType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => FriendRequestType.sent,
      ),
      createdAt: DateTime.parse(json['createdAt']),
      respondedAt: json['respondedAt'] != null ? DateTime.parse(json['respondedAt']) : null,
      response: json['response'] != null 
          ? FriendStatus.values.firstWhere(
              (e) => e.name == json['response'],
              orElse: () => FriendStatus.pending,
            )
          : null,
    );
  }
}

class FriendStats {
  final int totalFriends;
  final int onlineFriends;
  final int pendingRequests;
  final int sentRequests;

  const FriendStats({
    required this.totalFriends,
    required this.onlineFriends,
    required this.pendingRequests,
    required this.sentRequests,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'totalFriends': totalFriends,
      'onlineFriends': onlineFriends,
      'pendingRequests': pendingRequests,
      'sentRequests': sentRequests,
    };
  }

  // Create from JSON
  factory FriendStats.fromJson(Map<String, dynamic> json) {
    return FriendStats(
      totalFriends: json['totalFriends'] ?? 0,
      onlineFriends: json['onlineFriends'] ?? 0,
      pendingRequests: json['pendingRequests'] ?? 0,
      sentRequests: json['sentRequests'] ?? 0,
    );
  }
}
