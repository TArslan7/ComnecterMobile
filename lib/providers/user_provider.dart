// FUTURE: Use this to toggle premium access and radar range upgrades
// FUTURE: Koppel gebruikersstatus aan radar-boost logica voor zichtbaarheid
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class UserProvider extends ChangeNotifier {
  final UserService _userService = UserService();
  
  UserModel? _currentUser;
  List<UserModel> _nearbyUsers = [];
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  List<UserModel> get nearbyUsers => _nearbyUsers;
  bool get isLoading => _isLoading;

  UserProvider() {
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = await _userService.getCurrentUser();
      
      if (_currentUser != null) {
        await refreshNearbyUsers();
      }
    } catch (e) {
      print('Error loading user: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createUser(String userName, String username, List<String> interests, 
      {double latitude = 0.0, double longitude = 0.0}) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Check if username is unique
      final isUnique = await _userService.isUsernameUnique(username);
      if (!isUnique) {
        throw Exception('Username "$username" is already taken');
      }
      
      final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
      final newUser = UserModel(
        userId: userId,
        userName: userName,
        username: username,
        latitude: latitude,
        longitude: longitude,
        interests: interests,
      );

      await _userService.saveCurrentUser(newUser);
      _currentUser = newUser;
      
      await refreshNearbyUsers();
    } catch (e) {
      print('Error creating user: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Update username
  Future<void> updateUsername(String newUsername) async {
    if (_currentUser == null) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      // Check if username is unique
      final isUnique = await _userService.isUsernameUnique(newUsername);
      if (!isUnique) {
        throw Exception('Username "$newUsername" is already taken');
      }
      
      final updatedUser = _currentUser!.copyWith(username: newUsername);
      await _userService.saveCurrentUser(updatedUser);
      _currentUser = updatedUser;
    } catch (e) {
      print('Error updating username: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Search users by username or name
  Future<List<UserModel>> searchUsers(String query) async {
    if (query.isEmpty) return [];
    
    try {
      return await _userService.searchUsers(query);
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }

  Future<void> updateUserLocation(double latitude, double longitude) async {
    if (_currentUser == null) return;

    try {
      _currentUser = await _userService.updateUserLocation(latitude, longitude);
      await refreshNearbyUsers();
      notifyListeners();
    } catch (e) {
      print('Error updating location: $e');
    }
  }

  Future<void> refreshNearbyUsers() async {
    if (_currentUser == null) return;

    try {
      // Generate 10 simulated nearby users
      _nearbyUsers = await _userService.generateNearbyUsers(10);
      notifyListeners();
    } catch (e) {
      print('Error refreshing nearby users: $e');
    }
  }

  double getDistanceToUser(UserModel otherUser) {
    if (_currentUser == null) return double.infinity;

    return _userService.calculateDistance(
      _currentUser!.latitude,
      _currentUser!.longitude,
      otherUser.latitude,
      otherUser.longitude,
    );
  }

  List<UserModel> getNearbyUsersWithinDistance(double maxDistanceKm) {
    return _nearbyUsers.where((user) {
      final distance = getDistanceToUser(user);
      return distance <= maxDistanceKm;
    }).toList();
  }

  Future<void> updateUser(UserModel updatedUser) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _userService.saveCurrentUser(updatedUser);
      _currentUser = updatedUser;
      notifyListeners();
    } catch (e) {
      print('Error updating user: $e');
      throw e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Check if username is unique (public method)
  Future<bool> checkUsernameUnique(String username) async {
    return await _userService.isUsernameUnique(username);
  }

  // Send a friend request
  Future<void> sendFriendRequest(String userId) async {
    if (_currentUser == null) return;
    
    // Check if already friends
    if (_currentUser!.friendIds.contains(userId)) {
      throw Exception('Already friends with this user');
    }
    
    // Check if already sent request
    if (_currentUser!.sentFriendRequests.contains(userId)) {
      throw Exception('Friend request already sent');
    }
    
    // Update current user's sent requests
    final updatedUser = _currentUser!.copyWith(
      sentFriendRequests: [..._currentUser!.sentFriendRequests, userId],
    );
    
    await _userService.saveCurrentUser(updatedUser);
    _currentUser = updatedUser;
    notifyListeners();
  }

  // Accept a friend request
  Future<void> acceptFriendRequest(String userId) async {
    if (_currentUser == null) return;
    
    // Check if request exists
    if (!_currentUser!.receivedFriendRequests.contains(userId)) {
      throw Exception('No friend request from this user');
    }
    
    // Update current user's friends and received requests
    final updatedUser = _currentUser!.copyWith(
      friendIds: [..._currentUser!.friendIds, userId],
      receivedFriendRequests: _currentUser!.receivedFriendRequests
          .where((id) => id != userId)
          .toList(),
    );
    
    await _userService.saveCurrentUser(updatedUser);
    _currentUser = updatedUser;
    notifyListeners();
  }

  // Remove a friend
  Future<void> removeFriend(String userId) async {
    if (_currentUser == null) return;
    
    // Check if they are a friend
    if (!_currentUser!.friendIds.contains(userId)) {
      throw Exception('Not friends with this user');
    }
    
    // Update current user's friends
    final updatedUser = _currentUser!.copyWith(
      friendIds: _currentUser!.friendIds
          .where((id) => id != userId)
          .toList(),
    );
    
    await _userService.saveCurrentUser(updatedUser);
    _currentUser = updatedUser;
    notifyListeners();
  }

  // Block a user
  Future<void> blockUser(String userId) async {
    if (_currentUser == null) return;
    
    // Check if already blocked
    if (_currentUser!.blockedUserIds.contains(userId)) {
      throw Exception('User is already blocked');
    }
    
    // Remove from friends if they are a friend
    List<String> updatedFriends = List.from(_currentUser!.friendIds);
    if (updatedFriends.contains(userId)) {
      updatedFriends = updatedFriends.where((id) => id != userId).toList();
    }
    
    // Remove from friend requests if any
    List<String> updatedSentRequests = List.from(_currentUser!.sentFriendRequests);
    if (updatedSentRequests.contains(userId)) {
      updatedSentRequests = updatedSentRequests.where((id) => id != userId).toList();
    }
    
    List<String> updatedReceivedRequests = List.from(_currentUser!.receivedFriendRequests);
    if (updatedReceivedRequests.contains(userId)) {
      updatedReceivedRequests = updatedReceivedRequests.where((id) => id != userId).toList();
    }
    
    // Update current user's blocked list
    final updatedUser = _currentUser!.copyWith(
      blockedUserIds: [..._currentUser!.blockedUserIds, userId],
      friendIds: updatedFriends,
      sentFriendRequests: updatedSentRequests,
      receivedFriendRequests: updatedReceivedRequests,
    );
    
    await _userService.saveCurrentUser(updatedUser);
    _currentUser = updatedUser;
    notifyListeners();
  }

  // Toggle Friends Insight setting
  Future<void> toggleFriendsInsight(bool enabled) async {
    if (_currentUser == null) return;
    
    final updatedUser = _currentUser!.copyWith(
      friendsInsightEnabled: enabled,
    );
    
    await _userService.saveCurrentUser(updatedUser);
    _currentUser = updatedUser;
    notifyListeners();
  }

  // Unblock a user
  Future<void> unblockUser(String userId) async {
    if (_currentUser == null) return;
    
    // Check if blocked
    if (!_currentUser!.blockedUserIds.contains(userId)) {
      throw Exception('User is not blocked');
    }
    
    // Update current user's blocked list
    final updatedUser = _currentUser!.copyWith(
      blockedUserIds: _currentUser!.blockedUserIds
          .where((id) => id != userId)
          .toList(),
    );
    
    await _userService.saveCurrentUser(updatedUser);
    _currentUser = updatedUser;
    notifyListeners();
  }

  // Report a user
  Future<void> reportUser(String userId, String reason) async {
    if (_currentUser == null) return;
    
    // In a real app, this would send a report to a server
    // For this demo, we'll just log it
    print('User ${_currentUser!.userId} reported user $userId for reason: $reason');
    
    // Optionally block the user after reporting
    if (!_currentUser!.blockedUserIds.contains(userId)) {
      await blockUser(userId);
    }
  }
}