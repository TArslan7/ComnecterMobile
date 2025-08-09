import 'dart:async';
import 'dart:math';
import '../models/friend_model.dart';
import '../../../services/sound_service.dart';

class FriendService {
  static final FriendService _instance = FriendService._internal();
  factory FriendService() => _instance;
  FriendService._internal();

  final StreamController<List<Friend>> _friendsController = StreamController<List<Friend>>.broadcast();
  final StreamController<List<FriendRequest>> _requestsController = StreamController<List<FriendRequest>>.broadcast();
  final StreamController<FriendStats> _statsController = StreamController<FriendStats>.broadcast();
  
  Stream<List<Friend>> get friendsStream => _friendsController.stream;
  Stream<List<FriendRequest>> get requestsStream => _requestsController.stream;
  Stream<FriendStats> get statsStream => _statsController.stream;

  List<Friend> _friends = [];
  List<FriendRequest> _requests = [];
  final Random _random = Random();

  // Initialize the friend service
  Future<void> initialize() async {
    // Generate mock friends and requests
    _friends = _generateMockFriends();
    _requests = _generateMockRequests();
    
    _friendsController.add(_friends);
    _requestsController.add(_requests);
    _updateStats();
  }

  // Get all friends
  List<Friend> getFriends() {
    return List.unmodifiable(_friends);
  }

  // Get friends by status
  List<Friend> getFriendsByStatus(FriendStatus status) {
    return _friends.where((friend) => friend.status == status).toList();
  }

  // Get online friends
  List<Friend> getOnlineFriends() {
    return _friends.where((friend) => friend.isOnline && friend.status == FriendStatus.accepted).toList();
  }

  // Get friend requests
  List<FriendRequest> getRequests() {
    return List.unmodifiable(_requests);
  }

  // Get requests by type
  List<FriendRequest> getRequestsByType(FriendRequestType type) {
    return _requests.where((request) => request.type == type).toList();
  }

  // Send friend request
  Future<void> sendFriendRequest(String toUserId, String toUserName, String toUserAvatar, {String? message}) async {
    final request = FriendRequest(
      id: 'request_${DateTime.now().millisecondsSinceEpoch}',
      fromUserId: 'current_user',
      toUserId: toUserId,
      fromUserName: 'You',
      fromUserAvatar: '👤',
      message: message,
      type: FriendRequestType.sent,
      createdAt: DateTime.now(),
    );

    _requests.add(request);
    _requestsController.add(_requests);
    _updateStats();
    
    SoundService().playSuccessSound();
  }

  // Accept friend request
  Future<void> acceptFriendRequest(String requestId) async {
    final requestIndex = _requests.indexWhere((r) => r.id == requestId);
    if (requestIndex == -1) return;

    final request = _requests[requestIndex];
    final updatedRequest = request.copyWith(
      response: FriendStatus.accepted,
      respondedAt: DateTime.now(),
    );

    _requests[requestIndex] = updatedRequest;
    _requestsController.add(_requests);

    // Create friend relationship
    final friend = Friend(
      id: 'friend_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'current_user',
      friendId: request.fromUserId,
      name: request.fromUserName,
      avatar: request.fromUserAvatar,
      interests: _generateRandomInterests(),
      isOnline: _random.nextBool(),
      lastSeen: DateTime.now().subtract(Duration(minutes: _random.nextInt(60))),
      status: FriendStatus.accepted,
      createdAt: DateTime.now(),
    );

    _friends.add(friend);
    _friendsController.add(_friends);
    _updateStats();
    
    SoundService().playSuccessSound();
  }

  // Reject friend request
  Future<void> rejectFriendRequest(String requestId) async {
    final requestIndex = _requests.indexWhere((r) => r.id == requestId);
    if (requestIndex == -1) return;

    final request = _requests[requestIndex];
    final updatedRequest = request.copyWith(
      response: FriendStatus.rejected,
      respondedAt: DateTime.now(),
    );

    _requests[requestIndex] = updatedRequest;
    _requestsController.add(_requests);
    _updateStats();
    
    SoundService().playErrorSound();
  }

  // Remove friend
  Future<void> removeFriend(String friendId) async {
    final friendIndex = _friends.indexWhere((f) => f.friendId == friendId);
    if (friendIndex == -1) return;

    final friend = _friends[friendIndex];
    final updatedFriend = friend.copyWith(
      status: FriendStatus.removed,
      updatedAt: DateTime.now(),
    );

    _friends[friendIndex] = updatedFriend;
    _friendsController.add(_friends);
    _updateStats();
    
    SoundService().playButtonClickSound();
  }

  // Block friend
  Future<void> blockFriend(String friendId) async {
    final friendIndex = _friends.indexWhere((f) => f.friendId == friendId);
    if (friendIndex == -1) return;

    final friend = _friends[friendIndex];
    final updatedFriend = friend.copyWith(
      status: FriendStatus.blocked,
      updatedAt: DateTime.now(),
    );

    _friends[friendIndex] = updatedFriend;
    _friendsController.add(_friends);
    _updateStats();
    
    SoundService().playErrorSound();
  }

  // Unblock friend
  Future<void> unblockFriend(String friendId) async {
    final friendIndex = _friends.indexWhere((f) => f.friendId == friendId);
    if (friendIndex == -1) return;

    final friend = _friends[friendIndex];
    final updatedFriend = friend.copyWith(
      status: FriendStatus.accepted,
      updatedAt: DateTime.now(),
    );

    _friends[friendIndex] = updatedFriend;
    _friendsController.add(_friends);
    _updateStats();
    
    SoundService().playSuccessSound();
  }

  // Search friends
  List<Friend> searchFriends(String query) {
    final lowercaseQuery = query.toLowerCase();
    return _friends.where((friend) => 
      friend.name.toLowerCase().contains(lowercaseQuery) ||
      friend.bio?.toLowerCase().contains(lowercaseQuery) == true ||
      friend.interests.any((interest) => interest.toLowerCase().contains(lowercaseQuery))
    ).toList();
  }

  // Update friend online status
  void updateFriendStatus(String friendId, bool isOnline) {
    final friendIndex = _friends.indexWhere((f) => f.friendId == friendId);
    if (friendIndex == -1) return;

    final friend = _friends[friendIndex];
    final updatedFriend = friend.copyWith(
      isOnline: isOnline,
      lastSeen: DateTime.now(),
    );

    _friends[friendIndex] = updatedFriend;
    _friendsController.add(_friends);
    _updateStats();
  }

  // Simulate friend status changes
  void simulateStatusChanges() {
    Timer.periodic(const Duration(seconds: 30), (timer) {
      for (int i = 0; i < _friends.length; i++) {
        if (_random.nextDouble() < 0.3) {
          final friend = _friends[i];
          final updatedFriend = friend.copyWith(
            isOnline: _random.nextBool(),
            lastSeen: DateTime.now(),
          );
          _friends[i] = updatedFriend;
        }
      }
      _friendsController.add(_friends);
      _updateStats();
    });
  }

  // Update stats
  void _updateStats() {
    final stats = FriendStats(
      totalFriends: _friends.where((f) => f.status == FriendStatus.accepted).length,
      onlineFriends: _friends.where((f) => f.isOnline && f.status == FriendStatus.accepted).length,
      pendingRequests: _requests.where((r) => r.response == null).length,
      sentRequests: _requests.where((r) => r.type == FriendRequestType.sent && r.response == null).length,
    );
    _statsController.add(stats);
  }

  // Generate mock friends
  List<Friend> _generateMockFriends() {
    final names = [
      'Alex Johnson', 'Sarah Chen', 'Mike Rodriguez', 'Emma Wilson',
      'David Kim', 'Lisa Park', 'James Thompson', 'Sophie Brown',
      'Ryan Davis', 'Olivia White', 'Daniel Lee', 'Ava Miller',
      'Ethan Taylor', 'Isabella Anderson', 'Noah Martinez', 'Mia Garcia'
    ];

    final avatars = ['👨', '👩', '👨‍🦱', '👩‍🦰', '👨‍🦳', '👩‍🦳', '👨‍🦲', '👩‍🦲'];
    final interests = [
      ['Music', 'Travel'], ['Sports', 'Gaming'], ['Art', 'Photography'],
      ['Technology', 'Coding'], ['Food', 'Cooking'], ['Fitness', 'Health'],
      ['Reading', 'Writing'], ['Dancing', 'Fashion'], ['Nature', 'Hiking'],
      ['Movies', 'TV Shows'], ['Science', 'Space'], ['History', 'Culture']
    ];

    return List.generate(8, (index) {
      return Friend(
        id: 'friend_$index',
        userId: 'current_user',
        friendId: 'user_$index',
        name: names[index % names.length],
        avatar: avatars[index % avatars.length],
        bio: 'This is a mock friend bio for testing purposes.',
        interests: interests[index % interests.length],
        isOnline: _random.nextBool(),
        lastSeen: DateTime.now().subtract(Duration(minutes: _random.nextInt(60))),
        status: FriendStatus.accepted,
        createdAt: DateTime.now().subtract(Duration(days: _random.nextInt(30))),
      );
    });
  }

  // Generate mock friend requests
  List<FriendRequest> _generateMockRequests() {
    final names = [
      'John Smith', 'Maria Garcia', 'Tom Wilson', 'Anna Lee',
      'Chris Brown', 'Lisa Johnson', 'Mark Davis', 'Rachel Green'
    ];

    final avatars = ['👤', '👥', '👤', '👥', '👤', '👥', '👤', '👥'];

    return List.generate(4, (index) {
      return FriendRequest(
        id: 'request_$index',
        fromUserId: 'user_${index + 10}',
        toUserId: 'current_user',
        fromUserName: names[index % names.length],
        fromUserAvatar: avatars[index % avatars.length],
        message: index % 2 == 0 ? 'Hey! Would you like to be friends?' : null,
        type: index < 2 ? FriendRequestType.received : FriendRequestType.sent,
        createdAt: DateTime.now().subtract(Duration(hours: _random.nextInt(24))),
      );
    });
  }

  // Generate random interests
  List<String> _generateRandomInterests() {
    final allInterests = [
      'Music', 'Travel', 'Sports', 'Gaming', 'Art', 'Photography',
      'Technology', 'Coding', 'Food', 'Cooking', 'Fitness', 'Health',
      'Reading', 'Writing', 'Dancing', 'Fashion', 'Nature', 'Hiking',
      'Movies', 'TV Shows', 'Science', 'Space', 'History', 'Culture'
    ];
    
    final count = _random.nextInt(3) + 1;
    final interests = <String>[];
    
    for (int i = 0; i < count; i++) {
      final interest = allInterests[_random.nextInt(allInterests.length)];
      if (!interests.contains(interest)) {
        interests.add(interest);
      }
    }
    
    return interests;
  }

  // Dispose resources
  void dispose() {
    _friendsController.close();
    _requestsController.close();
    _statsController.close();
  }
}
