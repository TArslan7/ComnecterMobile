import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Service for managing saved/favorited items (users, communities, events)
class SavedItemsService {
  static final SavedItemsService _instance = SavedItemsService._internal();
  factory SavedItemsService() => _instance;
  SavedItemsService._internal();

  final _savedUsersController = StreamController<List<SavedItem>>.broadcast();
  final _savedCommunitiesController = StreamController<List<SavedItem>>.broadcast();
  final _savedEventsController = StreamController<List<SavedItem>>.broadcast();

  Stream<List<SavedItem>> get savedUsersStream => _savedUsersController.stream;
  Stream<List<SavedItem>> get savedCommunitiesStream => _savedCommunitiesController.stream;
  Stream<List<SavedItem>> get savedEventsStream => _savedEventsController.stream;

  List<SavedItem> _savedUsers = [];
  List<SavedItem> _savedCommunities = [];
  List<SavedItem> _savedEvents = [];

  static const String _usersKey = 'saved_users';
  static const String _communitiesKey = 'saved_communities';
  static const String _eventsKey = 'saved_events';

  /// Initialize service and load saved items
  Future<void> initialize() async {
    await _loadSavedItems();
  }

  /// Load saved items from local storage
  Future<void> _loadSavedItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load saved users
      final usersJson = prefs.getString(_usersKey);
      if (usersJson != null) {
        final List<dynamic> usersList = jsonDecode(usersJson);
        _savedUsers = usersList.map((json) => SavedItem.fromJson(json)).toList();
        _savedUsersController.add(_savedUsers);
      }
      
      // Load saved communities
      final communitiesJson = prefs.getString(_communitiesKey);
      if (communitiesJson != null) {
        final List<dynamic> communitiesList = jsonDecode(communitiesJson);
        _savedCommunities = communitiesList.map((json) => SavedItem.fromJson(json)).toList();
        _savedCommunitiesController.add(_savedCommunities);
      }
      
      // Load saved events
      final eventsJson = prefs.getString(_eventsKey);
      if (eventsJson != null) {
        final List<dynamic> eventsList = jsonDecode(eventsJson);
        _savedEvents = eventsList.map((json) => SavedItem.fromJson(json)).toList();
        _savedEventsController.add(_savedEvents);
      }
    } catch (e) {
      print('Error loading saved items: $e');
    }
  }

  /// Save items to local storage
  Future<void> _persistSavedItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setString(
        _usersKey,
        jsonEncode(_savedUsers.map((item) => item.toJson()).toList()),
      );
      
      await prefs.setString(
        _communitiesKey,
        jsonEncode(_savedCommunities.map((item) => item.toJson()).toList()),
      );
      
      await prefs.setString(
        _eventsKey,
        jsonEncode(_savedEvents.map((item) => item.toJson()).toList()),
      );
    } catch (e) {
      print('Error persisting saved items: $e');
    }
  }

  /// Save a user
  Future<bool> saveUser(String id, String name, String avatar, {String? bio}) async {
    if (isUserSaved(id)) return false;
    
    final savedItem = SavedItem(
      id: id,
      type: SavedItemType.user,
      name: name,
      avatar: avatar,
      bio: bio,
      savedAt: DateTime.now(),
    );
    
    _savedUsers.add(savedItem);
    _savedUsersController.add(_savedUsers);
    await _persistSavedItems();
    return true;
  }

  /// Unsave a user
  Future<bool> unsaveUser(String id) async {
    final initialLength = _savedUsers.length;
    _savedUsers.removeWhere((item) => item.id == id);
    
    if (_savedUsers.length < initialLength) {
      _savedUsersController.add(_savedUsers);
      await _persistSavedItems();
      return true;
    }
    return false;
  }

  /// Toggle save status for user
  Future<bool> toggleSaveUser(String id, String name, String avatar, {String? bio}) async {
    if (isUserSaved(id)) {
      return await unsaveUser(id);
    } else {
      return await saveUser(id, name, avatar, bio: bio);
    }
  }

  /// Save a community
  Future<bool> saveCommunity(String id, String name, String avatar, {String? description, int? memberCount}) async {
    if (isCommunitySaved(id)) return false;
    
    final savedItem = SavedItem(
      id: id,
      type: SavedItemType.community,
      name: name,
      avatar: avatar,
      bio: description,
      memberCount: memberCount,
      savedAt: DateTime.now(),
    );
    
    _savedCommunities.add(savedItem);
    _savedCommunitiesController.add(_savedCommunities);
    await _persistSavedItems();
    return true;
  }

  /// Unsave a community
  Future<bool> unsaveCommunity(String id) async {
    final initialLength = _savedCommunities.length;
    _savedCommunities.removeWhere((item) => item.id == id);
    
    if (_savedCommunities.length < initialLength) {
      _savedCommunitiesController.add(_savedCommunities);
      await _persistSavedItems();
      return true;
    }
    return false;
  }

  /// Toggle save status for community
  Future<bool> toggleSaveCommunity(String id, String name, String avatar, {String? description, int? memberCount}) async {
    if (isCommunitySaved(id)) {
      return await unsaveCommunity(id);
    } else {
      return await saveCommunity(id, name, avatar, description: description, memberCount: memberCount);
    }
  }

  /// Save an event
  Future<bool> saveEvent(String id, String name, {String? description, DateTime? startTime, String? location}) async {
    if (isEventSaved(id)) return false;
    
    final savedItem = SavedItem(
      id: id,
      type: SavedItemType.event,
      name: name,
      bio: description,
      eventStartTime: startTime,
      eventLocation: location,
      savedAt: DateTime.now(),
    );
    
    _savedEvents.add(savedItem);
    _savedEventsController.add(_savedEvents);
    await _persistSavedItems();
    return true;
  }

  /// Unsave an event
  Future<bool> unsaveEvent(String id) async {
    final initialLength = _savedEvents.length;
    _savedEvents.removeWhere((item) => item.id == id);
    
    if (_savedEvents.length < initialLength) {
      _savedEventsController.add(_savedEvents);
      await _persistSavedItems();
      return true;
    }
    return false;
  }

  /// Toggle save status for event
  Future<bool> toggleSaveEvent(String id, String name, {String? description, DateTime? startTime, String? location}) async {
    if (isEventSaved(id)) {
      return await unsaveEvent(id);
    } else {
      return await saveEvent(id, name, description: description, startTime: startTime, location: location);
    }
  }

  /// Check if user is saved
  bool isUserSaved(String id) => _savedUsers.any((item) => item.id == id);

  /// Check if community is saved
  bool isCommunitySaved(String id) => _savedCommunities.any((item) => item.id == id);

  /// Check if event is saved
  bool isEventSaved(String id) => _savedEvents.any((item) => item.id == id);

  /// Get all saved users
  List<SavedItem> get savedUsers => List.unmodifiable(_savedUsers);

  /// Get all saved communities
  List<SavedItem> get savedCommunities => List.unmodifiable(_savedCommunities);

  /// Get all saved events
  List<SavedItem> get savedEvents => List.unmodifiable(_savedEvents);

  /// Get all saved items combined
  List<SavedItem> get allSavedItems {
    final all = <SavedItem>[];
    all.addAll(_savedUsers);
    all.addAll(_savedCommunities);
    all.addAll(_savedEvents);
    // Sort by saved date (most recent first)
    all.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return all;
  }

  /// Get total count of saved items
  int get totalSavedCount => _savedUsers.length + _savedCommunities.length + _savedEvents.length;

  /// Clear all saved items
  Future<void> clearAll() async {
    _savedUsers.clear();
    _savedCommunities.clear();
    _savedEvents.clear();
    
    _savedUsersController.add(_savedUsers);
    _savedCommunitiesController.add(_savedCommunities);
    _savedEventsController.add(_savedEvents);
    
    await _persistSavedItems();
  }

  /// Dispose streams
  void dispose() {
    _savedUsersController.close();
    _savedCommunitiesController.close();
    _savedEventsController.close();
  }
}

/// Model for saved items
class SavedItem {
  final String id;
  final SavedItemType type;
  final String name;
  final String? avatar;
  final String? bio;
  final int? memberCount;
  final DateTime? eventStartTime;
  final String? eventLocation;
  final DateTime savedAt;

  const SavedItem({
    required this.id,
    required this.type,
    required this.name,
    this.avatar,
    this.bio,
    this.memberCount,
    this.eventStartTime,
    this.eventLocation,
    required this.savedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'name': name,
      'avatar': avatar,
      'bio': bio,
      'memberCount': memberCount,
      'eventStartTime': eventStartTime?.toIso8601String(),
      'eventLocation': eventLocation,
      'savedAt': savedAt.toIso8601String(),
    };
  }

  factory SavedItem.fromJson(Map<String, dynamic> json) {
    return SavedItem(
      id: json['id'],
      type: SavedItemType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => SavedItemType.user,
      ),
      name: json['name'],
      avatar: json['avatar'],
      bio: json['bio'],
      memberCount: json['memberCount'],
      eventStartTime: json['eventStartTime'] != null
          ? DateTime.parse(json['eventStartTime'])
          : null,
      eventLocation: json['eventLocation'],
      savedAt: DateTime.parse(json['savedAt']),
    );
  }
}

enum SavedItemType {
  user,
  community,
  event,
}

