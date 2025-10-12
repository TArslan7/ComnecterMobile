/// Represents a single item in the discover feed
class FeedItem {
  final String id;
  final FeedItemType type;
  final bool isBoosted;
  final double distance; // in meters
  final dynamic payload; // UserCard, CommunityCard, or EventCard
  final DateTime detectedAt;

  const FeedItem({
    required this.id,
    required this.type,
    required this.isBoosted,
    required this.distance,
    required this.payload,
    required this.detectedAt,
  });

  factory FeedItem.fromJson(Map<String, dynamic> json) {
    final type = FeedItemType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => FeedItemType.user,
    );

    dynamic payload;
    switch (type) {
      case FeedItemType.user:
        payload = UserCard.fromJson(json['payload']);
        break;
      case FeedItemType.community:
        payload = CommunityCard.fromJson(json['payload']);
        break;
      case FeedItemType.event:
        payload = EventCard.fromJson(json['payload']);
        break;
    }

    return FeedItem(
      id: json['id'],
      type: type,
      isBoosted: json['isBoosted'] ?? false,
      distance: (json['distance'] ?? 0).toDouble(),
      payload: payload,
      detectedAt: DateTime.parse(json['detectedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'isBoosted': isBoosted,
      'distance': distance,
      'payload': payload.toJson(),
      'detectedAt': detectedAt.toIso8601String(),
    };
  }

  FeedItem copyWith({
    String? id,
    FeedItemType? type,
    bool? isBoosted,
    double? distance,
    dynamic payload,
    DateTime? detectedAt,
  }) {
    return FeedItem(
      id: id ?? this.id,
      type: type ?? this.type,
      isBoosted: isBoosted ?? this.isBoosted,
      distance: distance ?? this.distance,
      payload: payload ?? this.payload,
      detectedAt: detectedAt ?? this.detectedAt,
    );
  }

  /// Get human-readable distance
  String get formattedDistance {
    if (distance < 1000) {
      return '${distance.toStringAsFixed(0)}m away';
    } else {
      final km = distance / 1000;
      return '${km.toStringAsFixed(1)}km away';
    }
  }
}

enum FeedItemType {
  user,
  community,
  event,
}

/// Represents a user card in the feed
class UserCard {
  final String id;
  final String name;
  final String avatar;
  final String? bio;
  final List<String> interests;
  final int mutualFriendsCount;
  final bool isOnline;
  final DateTime? lastSeen;
  final String? profileImageUrl;

  const UserCard({
    required this.id,
    required this.name,
    required this.avatar,
    this.bio,
    this.interests = const [],
    this.mutualFriendsCount = 0,
    this.isOnline = false,
    this.lastSeen,
    this.profileImageUrl,
  });

  factory UserCard.fromJson(Map<String, dynamic> json) {
    return UserCard(
      id: json['id'],
      name: json['name'],
      avatar: json['avatar'],
      bio: json['bio'],
      interests: List<String>.from(json['interests'] ?? []),
      mutualFriendsCount: json['mutualFriendsCount'] ?? 0,
      isOnline: json['isOnline'] ?? false,
      lastSeen: json['lastSeen'] != null 
          ? DateTime.parse(json['lastSeen']) 
          : null,
      profileImageUrl: json['profileImageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'bio': bio,
      'interests': interests,
      'mutualFriendsCount': mutualFriendsCount,
      'isOnline': isOnline,
      'lastSeen': lastSeen?.toIso8601String(),
      'profileImageUrl': profileImageUrl,
    };
  }
}

/// Represents a community card in the feed
class CommunityCard {
  final String id;
  final String name;
  final String description;
  final String avatar;
  final int memberCount;
  final List<String> tags;
  final bool isJoined;
  final bool isVerified;
  final String? coverImageUrl;

  const CommunityCard({
    required this.id,
    required this.name,
    required this.description,
    required this.avatar,
    required this.memberCount,
    this.tags = const [],
    this.isJoined = false,
    this.isVerified = false,
    this.coverImageUrl,
  });

  factory CommunityCard.fromJson(Map<String, dynamic> json) {
    return CommunityCard(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      avatar: json['avatar'],
      memberCount: json['memberCount'] ?? 0,
      tags: List<String>.from(json['tags'] ?? []),
      isJoined: json['isJoined'] ?? false,
      isVerified: json['isVerified'] ?? false,
      coverImageUrl: json['coverImageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'avatar': avatar,
      'memberCount': memberCount,
      'tags': tags,
      'isJoined': isJoined,
      'isVerified': isVerified,
      'coverImageUrl': coverImageUrl,
    };
  }

  /// Get formatted member count
  String get formattedMemberCount {
    if (memberCount < 1000) {
      return '$memberCount members';
    } else if (memberCount < 1000000) {
      final k = memberCount / 1000;
      return '${k.toStringAsFixed(1)}K members';
    } else {
      final m = memberCount / 1000000;
      return '${m.toStringAsFixed(1)}M members';
    }
  }
}

/// Represents an event card in the feed
class EventCard {
  final String id;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime? endTime;
  final String location;
  final String? venue;
  final int attendeeCount;
  final int maxAttendees;
  final bool isAttending;
  final String? coverImageUrl;
  final List<String> tags;
  final String organizerId;
  final String organizerName;

  const EventCard({
    required this.id,
    required this.title,
    required this.description,
    required this.startTime,
    this.endTime,
    required this.location,
    this.venue,
    required this.attendeeCount,
    this.maxAttendees = 0,
    this.isAttending = false,
    this.coverImageUrl,
    this.tags = const [],
    required this.organizerId,
    required this.organizerName,
  });

  factory EventCard.fromJson(Map<String, dynamic> json) {
    return EventCard(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null 
          ? DateTime.parse(json['endTime']) 
          : null,
      location: json['location'],
      venue: json['venue'],
      attendeeCount: json['attendeeCount'] ?? 0,
      maxAttendees: json['maxAttendees'] ?? 0,
      isAttending: json['isAttending'] ?? false,
      coverImageUrl: json['coverImageUrl'],
      tags: List<String>.from(json['tags'] ?? []),
      organizerId: json['organizerId'],
      organizerName: json['organizerName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'location': location,
      'venue': venue,
      'attendeeCount': attendeeCount,
      'maxAttendees': maxAttendees,
      'isAttending': isAttending,
      'coverImageUrl': coverImageUrl,
      'tags': tags,
      'organizerId': organizerId,
      'organizerName': organizerName,
    };
  }

  /// Check if event is happening soon (within 24 hours)
  bool get isHappeningSoon {
    final now = DateTime.now();
    final difference = startTime.difference(now);
    return difference.isNegative == false && difference.inHours <= 24;
  }

  /// Check if event is full
  bool get isFull {
    return maxAttendees > 0 && attendeeCount >= maxAttendees;
  }

  /// Get formatted attendee count
  String get formattedAttendeeCount {
    if (maxAttendees > 0) {
      return '$attendeeCount/$maxAttendees attending';
    } else {
      return '$attendeeCount attending';
    }
  }

  /// Get formatted time until event
  String get timeUntilEvent {
    final now = DateTime.now();
    final difference = startTime.difference(now);
    
    if (difference.isNegative) {
      return 'Started';
    } else if (difference.inDays > 0) {
      return 'in ${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return 'in ${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return 'in ${difference.inMinutes}m';
    } else {
      return 'Starting now';
    }
  }
}

/// Pagination response model
class FeedResponse {
  final List<FeedItem> items;
  final String? cursor;
  final bool hasMore;

  const FeedResponse({
    required this.items,
    this.cursor,
    this.hasMore = false,
  });

  factory FeedResponse.fromJson(Map<String, dynamic> json) {
    return FeedResponse(
      items: (json['items'] as List)
          .map((item) => FeedItem.fromJson(item))
          .toList(),
      cursor: json['cursor'],
      hasMore: json['hasMore'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((item) => item.toJson()).toList(),
      'cursor': cursor,
      'hasMore': hasMore,
    };
  }
}

