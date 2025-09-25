import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ProfileService {
  static ProfileService? _instance;
  static ProfileService get instance => _instance ??= ProfileService._internal();

  ProfileService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get current user profile from Firestore
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        if (kDebugMode) {
          print('❌ No user signed in');
        }
        return null;
      }

      final doc = await _firestore.collection('users').doc(user.uid).get();
      
      if (doc.exists) {
        final data = doc.data()!;
        if (kDebugMode) {
          print('✅ User profile loaded from Firestore');
        }
        return data;
      } else {
        // Create default profile if doesn't exist
        final defaultProfile = _createDefaultProfile(user);
        await _firestore.collection('users').doc(user.uid).set(defaultProfile);
        if (kDebugMode) {
          print('✅ Default user profile created');
        }
        return defaultProfile;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting user profile: $e');
      }
      return null;
    }
  }

  /// Update user profile in Firestore
  Future<bool> updateUserProfile(Map<String, dynamic> profileData) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        if (kDebugMode) {
          print('❌ No user signed in');
        }
        return false;
      }

      // Update Firestore document
      await _firestore.collection('users').doc(user.uid).update({
        ...profileData,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Update Firebase Auth display name if provided
      if (profileData.containsKey('name')) {
        await user.updateDisplayName(profileData['name']);
      }

      if (kDebugMode) {
        print('✅ User profile updated successfully');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating user profile: $e');
      }
      return false;
    }
  }

  /// Create default profile for new user
  Map<String, dynamic> _createDefaultProfile(User user) {
    return {
      'uid': user.uid,
      'name': user.displayName ?? 'User',
      'username': '@${user.email?.split('@')[0] ?? 'user'}',
      'bio': 'Welcome to Comnecter! 👋',
      'location': 'Unknown',
      'joinedDate': DateTime.now().toIso8601String(),
      'friendsCount': 0,
      'followersCount': 0,
      'followingCount': 0,
      'achievementPoints': 0,
      'postsCount': 0,
      'avatar': '👤',
      'isOnline': true,
      'lastSeen': FieldValue.serverTimestamp(),
      'email': user.email ?? '',
      'phone': '',
      'interests': ['Technology', 'Social'],
      'createdAt': FieldValue.serverTimestamp(),
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }

  /// Update specific profile field
  Future<bool> updateProfileField(String field, dynamic value) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        if (kDebugMode) {
          print('❌ No user signed in');
        }
        return false;
      }

      await _firestore.collection('users').doc(user.uid).update({
        field: value,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Update Firebase Auth if it's display name
      if (field == 'name') {
        await user.updateDisplayName(value);
      }

      if (kDebugMode) {
        print('✅ Profile field $field updated successfully');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating profile field $field: $e');
      }
      return false;
    }
  }

  /// Listen to profile changes
  Stream<Map<String, dynamic>?> getProfileStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(null);
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return snapshot.data();
      }
      return null;
    });
  }

  /// Validate profile data
  bool validateProfileData(Map<String, dynamic> data) {
    // Check required fields
    if (data['name'] == null || data['name'].toString().trim().isEmpty) {
      return false;
    }
    
    if (data['username'] == null || data['username'].toString().trim().isEmpty) {
      return false;
    }

    // Validate email format if provided
    if (data['email'] != null && data['email'].toString().isNotEmpty) {
      final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
      if (!emailRegex.hasMatch(data['email'].toString())) {
        return false;
      }
    }

    return true;
  }

  /// Get profile statistics
  Future<Map<String, int>> getProfileStats() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {
          'friendsCount': 0,
          'followersCount': 0,
          'followingCount': 0,
          'postsCount': 0,
          'achievementPoints': 0,
        };
      }

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        return {
          'friendsCount': data['friendsCount'] ?? 0,
          'followersCount': data['followersCount'] ?? 0,
          'followingCount': data['followingCount'] ?? 0,
          'postsCount': data['postsCount'] ?? 0,
          'achievementPoints': data['achievementPoints'] ?? 0,
        };
      }

      return {
        'friendsCount': 0,
        'followersCount': 0,
        'followingCount': 0,
        'postsCount': 0,
        'achievementPoints': 0,
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting profile stats: $e');
      }
      return {
        'friendsCount': 0,
        'followersCount': 0,
        'followingCount': 0,
        'postsCount': 0,
        'achievementPoints': 0,
      };
    }
  }
}
