// TIP: Breid model uit met premium flags, laatste activiteit, locatie
import 'package:flutter/foundation.dart';

// Profile content item class
class ProfileContent {
  final String id;
  final String content;
  final DateTime timestamp;
  final ContentType type;

  ProfileContent({
    required this.id,
    required this.content,
    required this.timestamp,
    required this.type,
  });

  factory ProfileContent.fromJson(Map<String, dynamic> json) {
    return ProfileContent(
      id: json['id'],
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
      type: ContentType.values.byName(json['type']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'type': type.name,
    };
  }
}

enum ContentType { text, image, link }

class UserModel {
  final String userId;
  final String userName;
  final String username; // Unique username for searching
  final String? userAvatar;
  final double latitude;
  final double longitude;
  final List<String> interests;
  final String? bio; // User bio/description
  final List<String> friendIds; // List of friends
  final List<String> blockedUserIds; // List of blocked users
  final List<String> sentFriendRequests; // Sent friend requests
  final List<String> receivedFriendRequests; // Received friend requests
  final List<String> rejectedFriendRequests; // Rejected friend requests
  final List<ProfileContent> profileContent; // Content shared on profile
  final bool friendsInsightEnabled; // If enabled, user shares and can see friendship changes
  final Map<String, dynamic>? data; // Custom profile data (background, colors, etc.)
  final bool isDetectable; // Whether user is visible on radar to other users

  UserModel({
    required this.userId,
    required this.userName,
    required this.username,
    this.userAvatar,
    required this.latitude,
    required this.longitude,
    required this.interests,
    this.bio,
    this.friendIds = const [],
    this.blockedUserIds = const [],
    this.sentFriendRequests = const [],
    this.receivedFriendRequests = const [],
    this.rejectedFriendRequests = const [],
    this.profileContent = const [],
    this.friendsInsightEnabled = false,
    this.isDetectable = true,
    this.data,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId'],
      userName: json['userName'],
      username: json['username'],
      userAvatar: json['userAvatar'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      interests: List<String>.from(json['interests'] ?? []),
      bio: json['bio'],
      friendIds: List<String>.from(json['friendIds'] ?? []),
      blockedUserIds: List<String>.from(json['blockedUserIds'] ?? []),
      sentFriendRequests: List<String>.from(json['sentFriendRequests'] ?? []),
      receivedFriendRequests: List<String>.from(json['receivedFriendRequests'] ?? []),
      rejectedFriendRequests: List<String>.from(json['rejectedFriendRequests'] ?? []),
      profileContent: (json['profileContent'] as List?)
          ?.map((item) => ProfileContent.fromJson(item))
          .toList() ?? [],
      friendsInsightEnabled: json['friendsInsightEnabled'] ?? false,
      isDetectable: json['isDetectable'] ?? true,
      data: json['data'] != null ? Map<String, dynamic>.from(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'username': username,
      'userAvatar': userAvatar,
      'latitude': latitude,
      'longitude': longitude,
      'interests': interests,
      'bio': bio,
      'friendIds': friendIds,
      'blockedUserIds': blockedUserIds,
      'sentFriendRequests': sentFriendRequests,
      'receivedFriendRequests': receivedFriendRequests,
      'rejectedFriendRequests': rejectedFriendRequests,
      'profileContent': profileContent.map((item) => item.toJson()).toList(),
      'friendsInsightEnabled': friendsInsightEnabled,
      'isDetectable': isDetectable,
      'data': data,
    };
  }

  UserModel copyWith({
    String? userId,
    String? userName,
    String? username,
    String? userAvatar,
    double? latitude,
    double? longitude,
    List<String>? interests,
    String? bio,
    List<String>? friendIds,
    List<String>? blockedUserIds,
    List<String>? sentFriendRequests,
    List<String>? receivedFriendRequests,
    List<String>? rejectedFriendRequests,
    List<ProfileContent>? profileContent,
    bool? friendsInsightEnabled,
    bool? isDetectable,
    Map<String, dynamic>? data,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      username: username ?? this.username,
      userAvatar: userAvatar ?? this.userAvatar,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      interests: interests ?? this.interests,
      bio: bio ?? this.bio,
      friendIds: friendIds ?? this.friendIds,
      blockedUserIds: blockedUserIds ?? this.blockedUserIds,
      sentFriendRequests: sentFriendRequests ?? this.sentFriendRequests,
      receivedFriendRequests: receivedFriendRequests ?? this.receivedFriendRequests,
      rejectedFriendRequests: rejectedFriendRequests ?? this.rejectedFriendRequests,
      profileContent: profileContent ?? this.profileContent,
      friendsInsightEnabled: friendsInsightEnabled ?? this.friendsInsightEnabled,
      isDetectable: isDetectable ?? this.isDetectable,
      data: data ?? this.data,
    );
  }
}