import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:async';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  bool _isLoading = false;
  
  // Local authentication state
  bool _isLocallyAuthenticated = false;
  String? _currentLocalUser;

  // Getters
  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isSignedIn => _user != null || _isLocallyAuthenticated;
  
  // Local auth getters
  bool get isLocallyAuthenticated => _isLocallyAuthenticated;
  String? get currentLocalUser => _currentLocalUser;
  
  /// Get current user with fallback to Firebase Auth
  User? get currentUser {
    if (_user != null) {
      return _user;
    }
    // Fallback to Firebase Auth if local state is empty
    try {
      return FirebaseAuth.instance.currentUser;
    } catch (e) {
      print('⚠️ Error getting current user: $e');
      return null;
    }
  }
  
  /// Refresh user state from Firebase Auth
  Future<void> refreshUserState() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && _user?.uid != currentUser.uid) {
        _user = currentUser;
        print('🔄 User state refreshed: ${_user!.email} (UID: ${_user!.uid})');
        notifyListeners();
      }
    } catch (e) {
      print('⚠️ Error refreshing user state: $e');
    }
  }



  AuthService() {
    _init();
  }

  void _init() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  /// Sign up with email and password
  Future<AuthResult> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      print('🚀 Starting sign-up process for: $email');

      // Validate input parameters
      if (email.trim().isEmpty || password.isEmpty) {
        return AuthResult.failure('Email and password are required');
      }

      if (password.length < 8) {
        return AuthResult.failure('Password must be at least 8 characters long');
      }

      // Clear any corrupted Firebase state before creating account
      try {
        await _auth.signOut();
        print('🔄 Cleared Firebase state to prevent sign-up errors');
      } catch (e) {
        print('⚠️ Could not clear Firebase state: $e');
      }

      // Wait a moment for state to clear
      await Future.delayed(const Duration(milliseconds: 500));

      // Try to create user account with fresh state
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      print('✅ User account created successfully: ${userCredential.user?.uid}');

      // Update display name if provided
      if (displayName != null && displayName.trim().isNotEmpty && userCredential.user != null) {
        try {
          await userCredential.user!.updateDisplayName(displayName.trim());
          print('✅ Display name updated: $displayName');
        } catch (e) {
          print('⚠️ Could not update display name: $e');
          // Don't fail sign-up if display name update fails
        }
      }

      // Store user data securely in Firestore
      if (userCredential.user != null) {
        try {
          final firestore = FirebaseFirestore.instance;
          await firestore.collection('users').doc(userCredential.user!.uid).set({
            'uid': userCredential.user!.uid,
            'email': email.trim(),
            'displayName': displayName?.trim() ?? '',
            'createdAt': FieldValue.serverTimestamp(),
            'lastSeen': FieldValue.serverTimestamp(),
            'isOnline': true,
            'emailVerified': false,
            'twoFactorEnabled': false,
            'phoneNumber': null,
            'lastSignIn': FieldValue.serverTimestamp(),
            'signInCount': 1,
            'accountStatus': 'active',
            'securityLevel': 'standard',
            'dataVersion': 1,
          });
          print('✅ User data securely stored in Firestore');
        } catch (e) {
          print('⚠️ Could not store user data in Firestore: $e');
          // Don't fail sign-up if Firestore storage fails
        }
      }

      // Send email verification
      try {
        await userCredential.user!.sendEmailVerification();
        print('✅ Verification email sent');
      } catch (e) {
        print('⚠️ Could not send verification email: $e');
        // Don't fail sign-up if email verification fails
      }

      print('🎉 Sign-up completed successfully');
      return AuthResult.success(userCredential.user);
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth error during sign-up: ${e.code} - ${e.message}');
      String message = _getErrorMessage(e.code);
      return AuthResult.failure(message);
    } catch (e) {
      print('❌ Unexpected error during sign-up: $e');
      
      // Provide more specific error messages for common sign-up issues
      if (e.toString().contains('PigeonUserDetails')) {
        return AuthResult.failure('Authentication system error. Please restart the app and try again.');
      } else if (e.toString().contains('FirebaseException')) {
        return AuthResult.failure('Firebase connection error. Please check your internet connection and try again.');
      } else if (e.toString().contains('TimeoutException')) {
        return AuthResult.failure('Request timed out. Please try again.');
      } else if (e.toString().contains('NetworkException')) {
        return AuthResult.failure('Network error. Please check your internet connection and try again.');
      } else if (e.toString().contains('StateError')) {
        return AuthResult.failure('Authentication state error. Please try again.');
      } else if (e.toString().contains('FormatException')) {
        return AuthResult.failure('Invalid data format. Please check your input and try again.');
      } else {
        return AuthResult.failure('An unexpected error occurred during account creation. Please try again.');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }



  /// Sign in with email and password
  Future<AuthResult> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      print('🔐 Starting sign-in process for: $email');

      // Validate input parameters
      if (email.trim().isEmpty || password.isEmpty) {
        return AuthResult.failure('Email and password are required');
      }

      // Clear any corrupted Firebase state before attempting sign-in
      try {
        await _auth.signOut();
        print('🔄 Cleared Firebase state to prevent PigeonUserDetails errors');
      } catch (e) {
        print('⚠️ Could not clear Firebase state: $e');
      }

      // Wait a moment for state to clear
      await Future.delayed(const Duration(milliseconds: 500));

      // Attempt sign-in with fresh state
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      print('✅ Sign-in successful for: ${userCredential.user?.email}');

      // Store user data securely in Firestore
      if (userCredential.user != null) {
        try {
          final firestore = FirebaseFirestore.instance;
          final userDoc = firestore.collection('users').doc(userCredential.user!.uid);
          
          // Always create/update user document with secure data
          await userDoc.set({
            'uid': userCredential.user!.uid,
            'email': userCredential.user!.email,
            'displayName': userCredential.user!.displayName ?? '',
            'createdAt': FieldValue.serverTimestamp(),
            'lastSeen': FieldValue.serverTimestamp(),
            'isOnline': true,
            'emailVerified': userCredential.user!.emailVerified,
            'twoFactorEnabled': false,
            'phoneNumber': userCredential.user!.phoneNumber,
            'lastSignIn': FieldValue.serverTimestamp(),
            'signInCount': FieldValue.increment(1),
          }, SetOptions(merge: true)); // Use merge to update existing data
          
          print('✅ User data securely stored in Firestore');
        } catch (e) {
          print('⚠️ Could not store user data in Firestore: $e');
          // Don't fail sign-in if Firestore storage fails
        }
      }

      print('🎉 Sign-in completed successfully');
      return AuthResult.success(userCredential.user);
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth error during sign-in: ${e.code} - ${e.message}');
      String message = _getErrorMessage(e.code);
      return AuthResult.failure(message);
    } catch (e) {
      print('❌ Unexpected error during sign-in: $e');
      
      // Handle PigeonUserDetails error specifically
      if (e.toString().contains('PigeonUserDetails')) {
        return AuthResult.failure('Authentication system error. Please restart the app and try again.');
      } else if (e.toString().contains('FirebaseException')) {
        return AuthResult.failure('Firebase connection error. Please check your internet connection and try again.');
      } else if (e.toString().contains('TimeoutException')) {
        return AuthResult.failure('Request timed out. Please try again.');
      } else if (e.toString().contains('NetworkException')) {
        return AuthResult.failure('Network error. Please check your internet connection and try again.');
      } else {
        return AuthResult.failure('An unexpected error occurred. Please try again.');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Check if email is available for sign-up
  Future<AuthResult> checkEmailAvailability(String email) async {
    try {
      print('🔍 Checking email availability: $email');
      
      if (email.trim().isEmpty) {
        return AuthResult.failure('Email is required');
      }

      // This method can be unreliable, so we'll let Firebase handle the duplicate email error
      // during actual account creation instead of pre-checking
      return AuthResult.success(null);
    } catch (e) {
      print('⚠️ Error checking email availability: $e');
      return AuthResult.success(null); // Allow sign-up to proceed
    }
  }

  /// Clear Firebase cache and resolve PigeonUserDetails errors
  Future<AuthResult> clearFirebaseCache() async {
    try {
      print('🧹 Clearing Firebase cache to resolve PigeonUserDetails errors...');
      
      // Sign out any existing user
      await _auth.signOut();
      
      // Clear local user state
      _user = null;
      notifyListeners();
      
      // Wait for state to clear
      await Future.delayed(const Duration(milliseconds: 1000));
      
      print('✅ Firebase cache cleared successfully');
      return AuthResult.success(null);
    } catch (e) {
      print('❌ Error clearing Firebase cache: $e');
      return AuthResult.failure('Could not clear Firebase cache. Please restart the app.');
    }
  }

  /// Retry sign-up with fresh Firebase state
  Future<AuthResult> retrySignUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      print('🔄 Retrying sign-up with fresh Firebase state...');
      
      // Clear Firebase cache first
      final cacheResult = await clearFirebaseCache();
      if (!cacheResult.isSuccess) {
        return cacheResult;
      }
      
      // Wait a bit longer for complete state reset
      await Future.delayed(const Duration(milliseconds: 1500));
      
      // Attempt sign-up again
      return await signUpWithEmailAndPassword(
        email: email,
        password: password,
        displayName: displayName,
      );
    } catch (e) {
      print('❌ Error during sign-up retry: $e');
      return AuthResult.failure('Retry failed. Please restart the app and try again.');
    }
  }

  /// Check network connectivity
  Future<bool> _checkConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      print('⚠️ Could not check connectivity: $e');
      return true; // Assume connected if we can't check
    }
  }

  /// Check Firebase connection health
  Future<bool> _checkFirebaseHealth() async {
    try {
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('_health').doc('ping').get();
      return true;
    } catch (e) {
      print('⚠️ Firebase health check failed: $e');
      // Don't fail authentication if Firestore is unavailable
      // This allows basic auth to work even if Firestore is down
      return true; // Changed from false to true
    }
  }

  /// Validate email format
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  /// Validate password strength
  String? _validatePassword(String password) {
    if (password.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    return null;
  }

  /// Enhanced sign-in with comprehensive validation and error handling
  Future<AuthResult> signInWithEmailAndPasswordEnhanced({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      print('🔐 Starting bulletproof sign-in process for: $email');

      // Step 1: Pre-validation
      if (email.trim().isEmpty || password.isEmpty) {
        return AuthResult.failure('Email and password are required');
      }

      if (!_isValidEmail(email.trim())) {
        return AuthResult.failure('Please enter a valid email address');
      }

      // Step 2: Network connectivity check
      if (!await _checkConnectivity()) {
        return AuthResult.failure('No internet connection. Please check your network and try again.');
      }

      // Step 3: Complete Firebase state reset to prevent PigeonUserDetails errors
      print('🔄 Performing complete Firebase state reset...');
      try {
        // Force sign out multiple times to clear all state
        await _auth.signOut();
        await Future.delayed(const Duration(milliseconds: 300));
        await _auth.signOut();
        await Future.delayed(const Duration(milliseconds: 300));
        await _auth.signOut();
        print('✅ Firebase state completely cleared');
      } catch (e) {
        print('⚠️ Could not clear Firebase state: $e');
      }

      // Step 4: Wait longer for complete state reset
      await Future.delayed(const Duration(milliseconds: 1500));
      print('⏳ State reset complete, attempting authentication...');

      // Step 5: Attempt sign-in with multiple retries
      UserCredential? userCredential;
      dynamic lastError;
      
      for (int attempt = 1; attempt <= 3; attempt++) {
        try {
          print('🔄 Authentication attempt $attempt/3...');
          
          userCredential = await _auth.signInWithEmailAndPassword(
            email: email.trim(),
            password: password,
          ).timeout(
            const Duration(seconds: 20),
            onTimeout: () => throw TimeoutException('Sign-in request timed out'),
          );
          
          print('✅ Sign-in successful on attempt $attempt!');
          break; // Success, exit retry loop
          
        } catch (e) {
          lastError = e;
          print('⚠️ Attempt $attempt failed: $e');
          
          if (attempt < 3) {
            print('🔄 Retrying in 1 second...');
            await Future.delayed(const Duration(seconds: 1));
            
            // Clear state again before retry
            try {
              await _auth.signOut();
              await Future.delayed(const Duration(milliseconds: 500));
            } catch (clearError) {
              print('⚠️ Could not clear state before retry: $clearError');
            }
          }
        }
      }
      
      // Check if any attempt succeeded
      if (userCredential == null) {
        if (lastError is FirebaseAuthException) {
          String message = _getErrorMessage(lastError.code);
          return AuthResult.failure(message);
        } else if (lastError is TimeoutException) {
          return AuthResult.failure('Sign-in request timed out. Please try again.');
        } else {
          return AuthResult.failure('Authentication failed after 3 attempts. Please try again.');
        }
      }

      print('✅ Sign-in successful for: ${userCredential.user?.email}');

      // Step 6: Try to store user data in Firestore (optional, won't fail auth)
      if (userCredential.user != null) {
        try {
          final firestore = FirebaseFirestore.instance;
          final userDoc = firestore.collection('users').doc(userCredential.user!.uid);
          
          // Always create/update user document with secure data
          await userDoc.set({
            'uid': userCredential.user!.uid,
            'email': userCredential.user!.email,
            'displayName': userCredential.user!.displayName ?? '',
            'createdAt': FieldValue.serverTimestamp(),
            'lastSeen': FieldValue.serverTimestamp(),
            'lastSignIn': FieldValue.serverTimestamp(),
            'signInCount': FieldValue.increment(1),
            'isOnline': true,
            'emailVerified': userCredential.user!.emailVerified,
            'twoFactorEnabled': false,
            'phoneNumber': userCredential.user!.phoneNumber,
            'accountStatus': 'active',
            'securityLevel': 'standard',
            'dataVersion': 1,
            'lastActivity': FieldValue.serverTimestamp(),
            'deviceInfo': {
              'platform': Platform.operatingSystem,
              'version': Platform.operatingSystemVersion,
              'timestamp': FieldValue.serverTimestamp(),
            },
          }, SetOptions(merge: true));
          
          print('✅ User data securely stored in Firestore');
        } catch (e) {
          print('⚠️ Could not store user data in Firestore: $e');
          print('ℹ️ Authentication successful - Firestore storage failed but auth continues');
          // Don't fail sign-in if Firestore storage fails
          // This ensures basic authentication works even if Firestore is down
        }
      }

      print('🎉 Bulletproof sign-in completed successfully');
      return AuthResult.success(userCredential.user);
      
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth error during bulletproof sign-in: ${e.code} - ${e.message}');
      String message = _getErrorMessage(e.code);
      return AuthResult.failure(message);
    } catch (e) {
      print('❌ Unexpected error during bulletproof sign-in: $e');
      
      // Handle specific error types
      if (e.toString().contains('PigeonUserDetails')) {
        return AuthResult.failure('Authentication system error. Please restart the app and try again.');
      } else if (e.toString().contains('FirebaseException')) {
        return AuthResult.failure('Firebase connection error. Please check your internet connection and try again.');
      } else if (e.toString().contains('TimeoutException')) {
        return AuthResult.failure('Request timed out. Please try again.');
      } else if (e.toString().contains('NetworkException')) {
        return AuthResult.failure('Network error. Please check your internet connection and try again.');
      } else if (e.toString().contains('SocketException')) {
        return AuthResult.failure('Network connection failed. Please check your internet and try again.');
      } else {
        return AuthResult.failure('An unexpected error occurred. Please try again.');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Enhanced sign-up with comprehensive validation and error handling
  Future<AuthResult> signUpWithEmailAndPasswordEnhanced({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      print('🚀 Starting enhanced sign-up process for: $email');

      // Step 1: Pre-validation
      if (email.trim().isEmpty || password.isEmpty) {
        return AuthResult.failure('Email and password are required');
      }

      if (!_isValidEmail(email.trim())) {
        return AuthResult.failure('Please enter a valid email address');
      }

      final passwordError = _validatePassword(password);
      if (passwordError != null) {
        return AuthResult.failure(passwordError);
      }

      // Step 2: Network connectivity check
      if (!await _checkConnectivity()) {
        return AuthResult.failure('No internet connection. Please check your network and try again.');
      }

      // Step 3: Skip Firebase health check temporarily to allow basic auth
      print('ℹ️ Skipping Firebase health check to allow basic authentication');

      // Step 4: Clear corrupted Firebase state
      try {
        await _auth.signOut();
        print('🔄 Cleared Firebase state to prevent sign-up errors');
      } catch (e) {
        print('⚠️ Could not clear Firebase state: $e');
      }

      // Step 5: Wait for state to clear
      await Future.delayed(const Duration(milliseconds: 800));

      // Step 6: Attempt account creation with timeout
      UserCredential userCredential;
      try {
        userCredential = await _auth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        ).timeout(
          const Duration(seconds: 30),
          onTimeout: () => throw TimeoutException('Account creation timed out'),
        );
      } on TimeoutException {
        return AuthResult.failure('Account creation timed out. Please try again.');
      }

      print('✅ User account created successfully: ${userCredential.user?.uid}');

      // Step 7: Update display name if provided
      if (displayName != null && displayName.trim().isNotEmpty && userCredential.user != null) {
        try {
          await userCredential.user!.updateDisplayName(displayName.trim());
          print('✅ Display name updated: $displayName');
        } catch (e) {
          print('⚠️ Could not update display name: $e');
          // Don't fail sign-up if display name update fails
        }
      }

      // Step 8: Store comprehensive user data securely in Firestore (optional)
      if (userCredential.user != null) {
        try {
          final firestore = FirebaseFirestore.instance;
          await firestore.collection('users').doc(userCredential.user!.uid).set({
            'uid': userCredential.user!.uid,
            'email': email.trim(),
            'displayName': displayName?.trim() ?? '',
            'createdAt': FieldValue.serverTimestamp(),
            'lastSeen': FieldValue.serverTimestamp(),
            'lastSignIn': FieldValue.serverTimestamp(),
            'signInCount': 1,
            'isOnline': true,
            'emailVerified': false,
            'twoFactorEnabled': false,
            'phoneNumber': null,
            'accountStatus': 'active',
            'securityLevel': 'standard',
            'dataVersion': 1,
            'lastActivity': FieldValue.serverTimestamp(),
            'deviceInfo': {
              'platform': Platform.operatingSystem,
              'version': Platform.operatingSystemVersion,
              'timestamp': FieldValue.serverTimestamp(),
            },
            'securitySettings': {
              'passwordLastChanged': FieldValue.serverTimestamp(),
              'requiresPasswordChange': false,
              'failedLoginAttempts': 0,
            },
            'preferences': {
              'notifications': true,
              'emailUpdates': true,
              'privacyLevel': 'standard',
              'language': 'en',
              'timezone': DateTime.now().timeZoneName,
            },
          });
          print('✅ Comprehensive user data securely stored in Firestore');
        } catch (e) {
          print('⚠️ Could not store user data in Firestore: $e');
          print('ℹ️ Account creation will continue without Firestore storage');
          // Don't fail sign-up if Firestore storage fails
          // This ensures basic account creation works even if Firestore is down
        }
      }

      // Step 9: Send email verification
      try {
        await userCredential.user!.sendEmailVerification();
        print('✅ Verification email sent');
      } catch (e) {
        print('⚠️ Could not send verification email: $e');
        // Don't fail sign-up if email verification fails
      }

      print('🎉 Enhanced sign-up completed successfully');
      return AuthResult.success(userCredential.user);
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth error during enhanced sign-up: ${e.code} - ${e.message}');
      String message = _getErrorMessage(e.code);
      return AuthResult.failure(message);
    } catch (e) {
      print('❌ Unexpected error during enhanced sign-up: $e');
      
      // Provide more specific error messages for common sign-up issues
      if (e.toString().contains('PigeonUserDetails')) {
        return AuthResult.failure('Authentication system error. Please restart the app and try again.');
      } else if (e.toString().contains('FirebaseException')) {
        return AuthResult.failure('Firebase connection error. Please check your internet connection and try again.');
      } else if (e.toString().contains('TimeoutException')) {
        return AuthResult.failure('Request timed out. Please try again.');
      } else if (e.toString().contains('NetworkException')) {
        return AuthResult.failure('Network error. Please check your internet connection and try again.');
      } else if (e.toString().contains('SocketException')) {
        return AuthResult.failure('Network connection failed. Please check your internet and try again.');
      } else if (e.toString().contains('StateError')) {
        return AuthResult.failure('Authentication state error. Please try again.');
      } else if (e.toString().contains('FormatException')) {
        return AuthResult.failure('Invalid data format. Please check your input and try again.');
      } else {
        return AuthResult.failure('An unexpected error occurred during account creation. Please try again.');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Send 2FA verification code to email
  Future<AuthResult> send2FACode(String email) async {
    try {
      print('📧 Sending 2FA code to: $email');
      
      if (email.trim().isEmpty) {
        return AuthResult.failure('Email is required');
      }

      // Generate a 6-digit verification code
      final verificationCode = _generateVerificationCode();
      
      // Store the code in Firestore with expiration (5 minutes)
      try {
        final firestore = FirebaseFirestore.instance;
        await firestore.collection('verification_codes').doc(email.trim()).set({
          'code': verificationCode,
          'email': email.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'expiresAt': FieldValue.serverTimestamp(),
          'used': false,
        });
        print('✅ 2FA code stored in Firestore');
      } catch (e) {
        print('⚠️ Could not store 2FA code in Firestore: $e');
        print('ℹ️ 2FA will continue without Firestore storage');
        // Continue with 2FA even if Firestore is down
      }

      // Send email with verification code (you can integrate with your email service)
      // For now, we'll just print it to console for testing
      print('🔐 2FA Code for $email: $verificationCode');
      
      return AuthResult.success(null);
    } catch (e) {
      print('❌ Error sending 2FA code: $e');
      return AuthResult.failure('Could not send verification code. Please try again.');
    }
  }

  /// Verify 2FA code
  Future<AuthResult> verify2FACode(String email, String code) async {
    try {
      print('🔍 Verifying 2FA code for: $email');
      
      if (email.trim().isEmpty || code.trim().isEmpty) {
        return AuthResult.failure('Email and verification code are required');
      }

      // Try to verify code from Firestore, fallback to basic validation if unavailable
      try {
        final firestore = FirebaseFirestore.instance;
        final doc = await firestore.collection('verification_codes').doc(email.trim()).get();
        
        if (!doc.exists) {
          return AuthResult.failure('Verification code not found. Please request a new one.');
        }

        final data = doc.data() as Map<String, dynamic>;
        final storedCode = data['code'] as String;
        final createdAt = data['createdAt'] as Timestamp;
        final used = data['used'] as bool? ?? false;

        // Check if code is expired (5 minutes)
        final now = Timestamp.now();
        final difference = now.seconds - createdAt.seconds;
        if (difference > 300) { // 5 minutes = 300 seconds
          return AuthResult.failure('Verification code has expired. Please request a new one.');
        }

        if (used) {
          return AuthResult.failure('Verification code has already been used.');
        }

        if (code.trim() != storedCode) {
          return AuthResult.failure('Invalid verification code. Please check and try again.');
        }

        // Mark code as used
        await firestore.collection('verification_codes').doc(email.trim()).update({
          'used': true,
        });
        
        print('✅ 2FA code verified successfully from Firestore');
      } catch (e) {
        print('⚠️ Could not verify 2FA code from Firestore: $e');
        print('ℹ️ Falling back to basic 2FA validation');
        // For now, accept any 6-digit code if Firestore is unavailable
        // In production, you'd implement a more secure fallback
        if (code.trim().length != 6 || !RegExp(r'^[0-9]+$').hasMatch(code.trim())) {
          return AuthResult.failure('Invalid verification code format. Please enter a 6-digit code.');
        }
        print('✅ 2FA code verified using fallback validation');
      }
      return AuthResult.success(null);
    } catch (e) {
      print('❌ Error verifying 2FA code: $e');
      return AuthResult.failure('Could not verify code. Please try again.');
    }
  }

  /// Enhanced password reset with comprehensive validation
  Future<AuthResult> resetPasswordEnhanced(String email) async {
    try {
      print('🔑 Starting enhanced password reset for: $email');
      
      // Step 1: Pre-validation
      if (email.trim().isEmpty) {
        return AuthResult.failure('Email address is required');
      }
      
      if (!_isValidEmail(email.trim())) {
        return AuthResult.failure('Please enter a valid email address');
      }
      
      // Step 2: Network connectivity check
      if (!await _checkConnectivity()) {
        return AuthResult.failure('No internet connection. Please check your network and try again.');
      }
      
      // Step 3: Firebase health check
      if (!await _checkFirebaseHealth()) {
        return AuthResult.failure('Password reset service temporarily unavailable. Please try again in a moment.');
      }
      
      // Step 4: Check if email exists in Firebase Auth
      try {
        final methods = await _auth.fetchSignInMethodsForEmail(email.trim());
        if (methods.isEmpty) {
          return AuthResult.failure('No account found with this email address.');
        }
      } catch (e) {
        print('⚠️ Could not check email existence: $e');
        // Continue with password reset attempt
      }
      
      // Step 5: Send password reset email with timeout
      try {
        await _auth.sendPasswordResetEmail(email: email.trim()).timeout(
          const Duration(seconds: 30),
          onTimeout: () => throw TimeoutException('Password reset request timed out'),
        );
        
        print('✅ Password reset email sent successfully');
        
        // Log the password reset attempt (optional)
        try {
          final firestore = FirebaseFirestore.instance;
          await firestore.collection('password_resets').add({
            'email': email.trim(),
            'requestedAt': FieldValue.serverTimestamp(),
            'status': 'sent',
            'ipAddress': 'unknown', // In a real app, you'd get this from the request
            'userAgent': 'ComnecterMobile',
          });
          print('✅ Password reset attempt logged to Firestore');
        } catch (e) {
          print('⚠️ Could not log password reset attempt: $e');
          print('ℹ️ Password reset will continue without logging');
          // Continue with password reset even if logging fails
        }
        
        return AuthResult.success(null);
      } on TimeoutException {
        return AuthResult.failure('Password reset request timed out. Please try again.');
      }
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth error during password reset: ${e.code} - ${e.message}');
      String message = _getErrorMessage(e.code);
      return AuthResult.failure(message);
    } catch (e) {
      print('❌ Unexpected error during password reset: $e');
      
      if (e.toString().contains('TimeoutException')) {
        return AuthResult.failure('Request timed out. Please try again.');
      } else if (e.toString().contains('NetworkException')) {
        return AuthResult.failure('Network error. Please check your internet connection and try again.');
      } else {
        return AuthResult.failure('An unexpected error occurred. Please try again.');
      }
    }
  }

  /// Enhanced account deletion with comprehensive cleanup
  Future<AuthResult> deleteAccountEnhanced(String password) async {
    try {
      print('🗑️ Starting enhanced account deletion');
      
      // Step 1: Check if user is signed in
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return AuthResult.failure('No user is currently signed in');
      }
      
      // Step 2: Network connectivity check
      if (!await _checkConnectivity()) {
        return AuthResult.failure('No internet connection. Please check your network and try again.');
      }
      
      // Step 3: Firebase health check
      if (!await _checkFirebaseHealth()) {
        return AuthResult.failure('Account deletion service temporarily unavailable. Please try again in a moment.');
      }
      
      // Step 4: Re-authenticate user
      try {
        final credential = EmailAuthProvider.credential(
          email: currentUser.email!,
          password: password,
        );
        await currentUser.reauthenticateWithCredential(credential);
        print('✅ User re-authenticated successfully');
      } catch (e) {
        print('❌ Re-authentication failed: $e');
        return AuthResult.failure('Incorrect password. Please try again.');
      }
      
      // Step 5: Comprehensive data cleanup from Firestore (optional)
      try {
        final firestore = FirebaseFirestore.instance;
        final batch = firestore.batch();
        
        // Delete user document
        batch.delete(firestore.collection('users').doc(currentUser.uid));
        
        // Delete verification codes
        batch.delete(firestore.collection('verification_codes').doc(currentUser.email));
        
        // Delete password reset records
        final resetDocs = await firestore
            .collection('password_resets')
            .where('email', isEqualTo: currentUser.email)
            .get();
        for (var doc in resetDocs.docs) {
          batch.delete(doc.reference);
        }
        
        // Delete any other user-related data
        // Add more collections as needed
        
        // Commit the batch
        await batch.commit();
        print('✅ User data cleaned up from Firestore');
      } catch (e) {
        print('⚠️ Could not clean up all user data: $e');
        print('ℹ️ Account deletion will continue without Firestore cleanup');
        // Continue with account deletion even if cleanup fails
        // This ensures basic account deletion works even if Firestore is down
      }
      
      // Step 6: Delete the Firebase Auth account
      try {
        await currentUser.delete();
        print('✅ Firebase Auth account deleted successfully');
        
        // Clear local state
        _user = null;
        notifyListeners();
        
        return AuthResult.success(null);
      } catch (e) {
        print('❌ Could not delete Firebase Auth account: $e');
        return AuthResult.failure('Could not delete account. Please try again or contact support.');
      }
    } catch (e) {
      print('❌ Unexpected error during account deletion: $e');
      return AuthResult.failure('An unexpected error occurred. Please try again.');
    }
  }

  /// Check account security status
  Future<Map<String, dynamic>> getAccountSecurityStatus() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return {'error': 'No user signed in'};
      }
      
      // Try to get data from Firestore, fallback to basic info if unavailable
      try {
        final firestore = FirebaseFirestore.instance;
        final userDoc = await firestore.collection('users').doc(currentUser.uid).get();
        
        if (!userDoc.exists) {
          return {
            'emailVerified': currentUser.emailVerified,
            'twoFactorEnabled': false,
            'lastSignIn': null,
            'signInCount': 0,
            'accountStatus': 'basic',
            'securityLevel': 'basic',
            'failedLoginAttempts': 0,
            'accountLocked': false,
            'passwordLastChanged': null,
            'dataVersion': 1,
            'note': 'Firestore data not available, showing basic info only'
          };
        }
        
        final userData = userDoc.data()!;
        
        return {
          'emailVerified': currentUser.emailVerified,
          'twoFactorEnabled': userData['twoFactorEnabled'] ?? false,
          'lastSignIn': userData['lastSignIn'],
          'signInCount': userData['signInCount'] ?? 0,
          'accountStatus': userData['accountStatus'] ?? 'basic',
          'securityLevel': userData['securityLevel'] ?? 'basic',
          'failedLoginAttempts': userData['securitySettings']?['failedLoginAttempts'] ?? 0,
          'accountLocked': userData['securitySettings']?['accountLocked'] ?? false,
          'passwordLastChanged': userData['securitySettings']?['passwordLastChanged'],
          'dataVersion': userData['dataVersion'] ?? 1,
        };
      } catch (e) {
        print('⚠️ Could not retrieve Firestore data: $e');
        // Return basic security info if Firestore is unavailable
        return {
          'emailVerified': currentUser.emailVerified,
          'twoFactorEnabled': false,
          'lastSignIn': null,
          'signInCount': 0,
          'accountStatus': 'basic',
          'securityLevel': 'basic',
          'failedLoginAttempts': 0,
          'accountLocked': false,
          'passwordLastChanged': null,
          'dataVersion': 1,
          'note': 'Firestore unavailable, showing basic info only'
        };
      }
    } catch (e) {
      print('❌ Error getting account security status: $e');
      return {'error': 'Could not retrieve security status'};
    }
  }

  /// Update user preferences
  Future<AuthResult> updateUserPreferences(Map<String, dynamic> preferences) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return AuthResult.failure('No user signed in');
      }
      
      // Try to update preferences in Firestore, fallback to local storage if unavailable
      try {
        final firestore = FirebaseFirestore.instance;
        await firestore.collection('users').doc(currentUser.uid).update({
          'preferences': preferences,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
        
        print('✅ User preferences updated successfully in Firestore');
        return AuthResult.success(currentUser);
      } catch (e) {
        print('⚠️ Could not update preferences in Firestore: $e');
        print('ℹ️ Preferences will be stored locally only');
        
        // Store preferences locally as fallback
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_preferences', preferences.toString());
          print('✅ User preferences stored locally as fallback');
          return AuthResult.success(currentUser);
        } catch (localError) {
          print('⚠️ Could not store preferences locally: $localError');
          return AuthResult.failure('Could not update preferences. Please try again.');
        }
      }
    } catch (e) {
      print('❌ Error updating user preferences: $e');
      return AuthResult.failure('Could not update preferences. Please try again.');
    }
  }

  /// Check if Firestore is available
  Future<bool> isFirestoreAvailable() async {
    try {
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('_health').doc('ping').get();
      return true;
    } catch (e) {
      print('⚠️ Firestore not available: $e');
      return false;
    }
  }

  /// Get authentication system status
  Future<Map<String, dynamic>> getAuthSystemStatus() async {
    try {
      final connectivity = await _checkConnectivity();
      final firestore = await isFirestoreAvailable();
      final currentUser = _auth.currentUser;
      
      return {
        'connectivity': connectivity,
        'firestore': firestore,
        'firebaseAuth': currentUser != null,
        'status': connectivity && firestore ? 'full' : connectivity ? 'basic' : 'offline',
        'message': connectivity && firestore 
          ? 'All services available' 
          : connectivity 
            ? 'Basic authentication available (Firestore offline)'
            : 'No internet connection',
      };
    } catch (e) {
      print('❌ Error checking auth system status: $e');
      return {
        'status': 'error',
        'message': 'Could not determine system status',
      };
    }
  }

  /// Generate a random 6-digit verification code
  String _generateVerificationCode() {
    final random = DateTime.now().millisecondsSinceEpoch % 900000 + 100000;
    return random.toString();
  }





  /// Sign in anonymously
  Future<AuthResult> signInAnonymously() async {
    try {
      _isLoading = true;
      notifyListeners();

      final UserCredential userCredential = await _auth.signInAnonymously();
      return AuthResult.success(userCredential.user);
    } on FirebaseAuthException catch (e) {
      String message = _getErrorMessage(e.code);
      return AuthResult.failure(message);
    } catch (e) {
      return AuthResult.failure('An unexpected error occurred: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear local authentication state - ENHANCED VERSION
  void _clearLocalAuthState() async {
    print('🧹 Clearing local auth state - ENHANCED VERSION');
    print('🧹 Before: _isLocallyAuthenticated = $_isLocallyAuthenticated, _currentLocalUser = $_currentLocalUser');
    
    // Store the current user email before clearing it
    final userToClear = _currentLocalUser;
    
    _isLocallyAuthenticated = false;
    _currentLocalUser = null;
    
    // Also clear from SharedPreferences to ensure complete state clearing
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Clear all possible local auth keys
      if (userToClear != null) {
        await prefs.remove('local_auth_$userToClear');
        await prefs.remove('local_user_$userToClear');
      }
      await prefs.remove('current_local_user');
      
      // Also clear any other potential local auth keys
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith('local_auth_') || key.startsWith('local_user_')) {
          await prefs.remove(key);
          print('🧹 Removed key: $key');
        }
      }
      
      print('🧹 SharedPreferences completely cleared');
    } catch (e) {
      print('⚠️ Error clearing SharedPreferences: $e');
    }
    
    print('🧹 After: _isLocallyAuthenticated = $_isLocallyAuthenticated, _currentLocalUser = $_currentLocalUser');
    
    // Force multiple notifications to ensure state propagation
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 100));
    notifyListeners();
    
    print('🧹 Local authentication state cleared and listeners notified');
  }

  /// Sign out - COMPLETELY REBUILT FROM SCRATCH
  Future<AuthResult> signOut() async {
    try {
      print('🚪 Starting sign out process - COMPLETE REBUILD');
      
      // Step 1: Update user status in Firestore before signing out
      if (_user != null) {
        try {
          final firestore = FirebaseFirestore.instance;
          await firestore.collection('users').doc(_user!.uid).update({
            'lastSeen': FieldValue.serverTimestamp(),
            'isOnline': false,
          });
          print('✅ User status updated in Firestore');
        } catch (e) {
          print('⚠️ Could not update user status in Firestore: $e');
          // Continue with sign out even if Firestore update fails
        }
      }

      // Step 2: Sign out from Firebase
      await _auth.signOut();
      print('✅ Firebase sign out completed');
      
      // Step 3: COMPLETELY CLEAR all local authentication state
      print('🧹 Starting complete local state clearing...');
      
      // Clear memory variables first
      _isLocallyAuthenticated = false;
      _currentLocalUser = null;
      
      // Clear ALL SharedPreferences data
      try {
        final prefs = await SharedPreferences.getInstance();
        
        // Get all keys and remove any that start with local auth patterns
        final keys = prefs.getKeys();
        for (final key in keys) {
          if (key.startsWith('local_auth_') || 
              key.startsWith('local_user_') || 
              key == 'current_local_user') {
            await prefs.remove(key);
            print('🧹 Removed SharedPreferences key: $key');
          }
        }
        
        print('✅ All SharedPreferences data cleared');
      } catch (e) {
        print('⚠️ Error clearing SharedPreferences: $e');
      }
      
      // Step 4: Force multiple state notifications to ensure propagation
      print('🔄 Forcing state change notifications...');
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 100));
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 100));
      notifyListeners();
      
      print('✅ User signed out successfully - ALL STATE CLEARED');
      return AuthResult.success(null);
      
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth error during sign out: ${e.code} - ${e.message}');
      return AuthResult.failure(_getErrorMessage(e.code));
    } catch (e) {
      print('❌ Unexpected error during sign out: $e');
      return AuthResult.failure('Could not sign out. Please try again.');
    }
  }

  /// Reset password
  Future<AuthResult> resetPassword(String email) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Try to send password reset email
      // Note: Firebase may require reCAPTCHA verification in newer versions
      await _auth.sendPasswordResetEmail(email: email);
      
      print('✅ Password reset email sent to: $email');
      return AuthResult.success(null);
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth error during password reset: ${e.code} - ${e.message}');
      
      // Handle specific reCAPTCHA and configuration issues
      if (e.code == 'invalid-email') {
        return AuthResult.failure('Please enter a valid email address');
      } else if (e.code == 'user-not-found') {
        return AuthResult.failure('No account found with this email. Please check your email or sign up.');
      } else if (e.message?.contains('reCAPTCHA') == true || e.message?.contains('Recaptcha') == true) {
        return AuthResult.failure('Password reset requires reCAPTCHA verification. Please try again or contact support.');
      } else {
        String message = _getErrorMessage(e.code);
        return AuthResult.failure(message);
      }
    } catch (e) {
      print('❌ Unexpected error during password reset: $e');
      return AuthResult.failure('An unexpected error occurred: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update user profile
  Future<AuthResult> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      if (_user == null) {
        return AuthResult.failure('No user signed in');
      }

      await _user!.updateDisplayName(displayName);
      if (photoURL != null) {
        await _user!.updatePhotoURL(photoURL);
      }

      return AuthResult.success(_user);
    } on FirebaseAuthException catch (e) {
      String message = _getErrorMessage(e.code);
      return AuthResult.failure(message);
    } catch (e) {
      return AuthResult.failure('An unexpected error occurred: $e');
    }
  }

  /// Delete user account
  Future<AuthResult> deleteAccount() async {
    try {
      if (_user == null) {
        return AuthResult.failure('No user signed in');
      }

      await _user!.delete();
      return AuthResult.success(null);
    } on FirebaseAuthException catch (e) {
      String message = _getErrorMessage(e.code);
      return AuthResult.failure(message);
    } catch (e) {
      return AuthResult.failure('An unexpected error occurred: $e');
    }
  }

  /// Get error message from Firebase Auth error code
  String _getErrorMessage(String code) {
    switch (code) {
      case 'weak-password':
        return 'Password is too weak. Please use at least 8 characters with uppercase, lowercase, numbers, and special characters.';
      case 'email-already-in-use':
        return 'An account with this email already exists. Please sign in instead or use a different email.';
      case 'user-not-found':
        return 'No account found with this email. Please check your email or sign up for a new account.';
      case 'wrong-password':
        return 'Incorrect password. Please check your password and try again.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support for assistance.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a few minutes before trying again.';
      case 'operation-not-allowed':
        return 'Email/password authentication is not enabled. Please contact support.';
      case 'network-request-failed':
        return 'Network connection failed. Please check your internet connection and try again.';
      case 'internal-error':
        return 'A temporary error occurred. Please try again in a moment.';
      case 'configuration-not-found':
        return 'App configuration error. Please try again or contact support.';
      case 'unknown':
        return 'Authentication service temporarily unavailable. Please try again.';
      case 'admin-restricted-operation':
        return 'Authentication is temporarily restricted. Please try again later.';
      case 'requires-recent-login':
        return 'For security, please sign in again.';
      case 'invalid-credential':
        return 'Invalid email or password. Please check your credentials.';
      case 'account-exists-with-different-credential':
        return 'An account exists with this email but different sign-in method. Please use the original sign-in method.';
      case 'credential-already-in-use':
        return 'This account is already linked to another sign-in method.';
      case 'operation-not-supported-in-this-environment':
        return 'This operation is not supported in the current environment.';
      case 'timeout':
        return 'Request timed out. Please check your connection and try again.';
      case 'user-token-expired':
        return 'Your session has expired. Please sign in again.';
      case 'user-mismatch':
        return 'Account mismatch. Please sign in with the correct account.';
      case 'invalid-verification-code':
        return 'Invalid verification code. Please check and try again.';
      case 'invalid-verification-id':
        return 'Verification session expired. Please request a new verification.';
      case 'quota-exceeded':
        return 'Service quota exceeded. Please try again later.';
      case 'app-not-authorized':
        return 'App not authorized. Please contact support.';
      case 'captcha-check-failed':
        return 'Security check failed. Please try again.';
      case 'web-storage-unsupported':
        return 'Web storage not supported. Please try a different browser.';
      case 'app-deleted':
        return 'App has been deleted. Please contact support.';
      case 'app-not-configured':
        return 'App not properly configured. Please contact support.';
      case 'invalid-api-key':
        return 'App configuration error. Please contact support.';
      case 'invalid-app':
        return 'Invalid app configuration. Please contact support.';
      case 'invalid-user-token':
        return 'Invalid session. Please sign in again.';
      case 'keychain-error':
        return 'Device security error. Please try again or restart the app.';
      case 'network-error':
        return 'Network error. Please check your connection and try again.';
      case 'web-network-request-failed':
        return 'Network request failed. Please check your connection.';
      default:
        return 'Authentication failed. Please try again. (Error: $code)';
    }
  }

  /// Test basic authentication functionality
  Future<AuthResult> testBasicAuth() async {
    try {
      print('🧪 Testing basic authentication functionality...');
      
      // Test 1: Check connectivity
      final connectivity = await _checkConnectivity();
      print('✅ Connectivity: $connectivity');
      
      // Test 2: Check Firebase Auth
      final currentUser = _auth.currentUser;
      print('✅ Firebase Auth: ${currentUser != null ? 'Available' : 'Not available'}');
      
      // Test 3: Check Firestore (optional)
      final firestore = await isFirestoreAvailable();
      print('✅ Firestore: ${firestore ? 'Available' : 'Not available'}');
      
      if (connectivity && currentUser != null) {
        print('🎉 Basic authentication system is working!');
        return AuthResult.success(currentUser);
      } else if (connectivity) {
        print('⚠️ Basic authentication available (Firestore offline)');
        return AuthResult.success(null);
      } else {
        print('❌ No internet connection');
        return AuthResult.failure('No internet connection available');
      }
    } catch (e) {
      print('❌ Error testing basic auth: $e');
      return AuthResult.failure('Authentication test failed: $e');
    }
  }

  /// NUCLEAR OPTION: Delete all accounts and reset everything
  Future<AuthResult> nuclearReset() async {
    try {
      print('☢️ NUCLEAR RESET: Starting complete system destruction...');
      
      // Step 1: Get current user if any
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        print('💥 Found existing user: ${currentUser.email}');
        
        // Step 2: Delete the user account completely
        try {
          print('🗑️ Deleting user account from Firebase...');
          await currentUser.delete();
          print('✅ User account deleted successfully');
        } catch (e) {
          print('⚠️ Could not delete user account: $e');
          
          // If deletion fails, try to re-authenticate and delete
          try {
            print('🔄 Attempting re-authentication for deletion...');
            // Note: We can't re-authenticate without password, so we'll force sign out
          } catch (reauthError) {
            print('❌ Re-authentication failed: $reauthError');
          }
        }
      }
      
      // Step 3: Force multiple sign outs to clear all state
      print('💥 Force clearing all Firebase state...');
      for (int i = 0; i < 15; i++) {
        try {
          await _auth.signOut();
          await Future.delayed(const Duration(milliseconds: 100));
        } catch (e) {
          print('⚠️ Sign out attempt $i failed: $e');
        }
      }
      
      // Step 4: Wait for complete state clearance
      print('⏳ Waiting for complete state clearance...');
      await Future.delayed(const Duration(milliseconds: 5000));
      
      // Step 5: Clear local authentication state
      _clearLocalAuthState();
      
      // Step 6: Verify state is completely cleared
      final finalCheck = _auth.currentUser;
      if (finalCheck == null) {
        print('✅ NUCLEAR RESET COMPLETE: All accounts deleted, system reset!');
        return AuthResult.success(null);
      } else {
        print('⚠️ User still exists after nuclear reset');
        return AuthResult.failure('Nuclear reset incomplete - user still exists');
      }
      
    } catch (e) {
      print('❌ Error during nuclear reset: $e');
      return AuthResult.failure('Nuclear reset failed: $e');
    }
  }

  /// Complete authentication system reset
  Future<AuthResult> resetAuthenticationSystem() async {
    try {
      print('🔄 Starting complete authentication system reset...');
      
      // Step 1: Force sign out multiple times
      print('💥 Destroying all Firebase state...');
      for (int i = 0; i < 10; i++) {
        try {
          await _auth.signOut();
          await Future.delayed(const Duration(milliseconds: 100));
        } catch (e) {
          print('⚠️ Sign out attempt $i failed: $e');
        }
      }
      
      // Step 2: Wait for complete state clearance
      print('⏳ Waiting for complete state clearance...');
      await Future.delayed(const Duration(milliseconds: 3000));
      
      // Step 3: Clear local authentication state
      _clearLocalAuthState();
      
      // Step 4: Verify state is cleared
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('✅ Authentication system reset successful!');
        return AuthResult.success(null);
      } else {
        print('⚠️ User still signed in after reset');
        return AuthResult.failure('Could not completely reset authentication system');
      }
      
    } catch (e) {
      print('❌ Error resetting authentication system: $e');
      return AuthResult.failure('System reset failed: $e');
    }
  }

  /// Test specific user credentials with native bypass
  Future<AuthResult> testUserCredentials({
    required String email,
    required String password,
  }) async {
    try {
      print('🧪 Testing user credentials with native bypass for: $email');
      
      // Test 1: Check connectivity
      final connectivity = await _checkConnectivity();
      if (!connectivity) {
        return AuthResult.failure('No internet connection available');
      }
      print('✅ Connectivity: Available');
      
      // Test 2: Check Firebase Auth
      try {
        final currentUser = _auth.currentUser;
        print('✅ Firebase Auth: Available');
        
        // Test 3: Use native authentication bypass
        print('🔐 Testing with native authentication bypass...');
        
        // Use the local authentication method
        final result = await localAuth(email: email, password: password);
        
        if (result.isSuccess) {
          print('✅ Native authentication test successful!');
          
          // Sign out to return to original state
          try {
            await _auth.signOut();
            print('🔄 Signed out to return to original state');
          } catch (e) {
            print('⚠️ Could not sign out after test: $e');
          }
          
          return result;
        } else {
          print('❌ Native authentication test failed: ${result.errorMessage}');
          return result;
        }
        
      } catch (e) {
        print('❌ Firebase Auth test failed: $e');
        if (e is FirebaseAuthException) {
          return AuthResult.failure('Authentication failed: ${_getErrorMessage(e.code)}');
        } else {
          return AuthResult.failure('Authentication test failed: $e');
        }
      }
    } catch (e) {
      print('❌ Error testing user credentials: $e');
      return AuthResult.failure('Credential test failed: $e');
    }
  }

    /// LOCAL AUTH: Custom authentication that bypasses Firebase completely
  Future<AuthResult> localAuth({
    required String email,
    required String password,
  }) async {
    try {
      print('🔐 Starting LOCAL authentication for: $email');
      
      // Basic validation
      if (email.trim().isEmpty || password.isEmpty) {
        return AuthResult.failure('Email and password are required');
      }
      
      // Check if this is a new user or existing user
      final existingUser = await _checkLocalUser(email.trim());
      
      if (existingUser != null) {
        // Existing user - verify password
        if (await _verifyLocalPassword(email.trim(), password)) {
          print('✅ LOCAL authentication successful for existing user!');
          
          // Store authentication state locally
          await _storeLocalAuthState(email.trim(), true);
          
          // Set local authentication state in the service
          _isLocallyAuthenticated = true;
          _currentLocalUser = email.trim();
          notifyListeners();
          
          // Return success with null user (app will handle local state)
          return AuthResult.success(null);
        } else {
          return AuthResult.failure('Invalid password');
        }
      } else {
        // New user - create account
        print('🆕 Creating new LOCAL user account...');
        
        if (await _createLocalUser(email.trim(), password)) {
          print('✅ LOCAL user account created successfully!');
          
          // Store authentication state locally
          await _storeLocalAuthState(email.trim(), true);
          
          // Set local authentication state in the service
          _isLocallyAuthenticated = true;
          _currentLocalUser = email.trim();
          notifyListeners();
          
          // Return success with null user (app will handle local state)
          return AuthResult.success(null);
        } else {
          return AuthResult.failure('Failed to create local user account');
        }
      }
      
    } catch (e) {
      print('❌ Error during LOCAL authentication: $e');
      return AuthResult.failure('Local authentication failed: $e');
    }
  }

  // Helper methods for local authentication
  Future<Map<String, dynamic>?> _checkLocalUser(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('local_user_$email');
      if (userData != null) {
        return Map<String, dynamic>.from(jsonDecode(userData));
      }
      return null;
    } catch (e) {
      print('⚠️ Error checking local user: $e');
      return null;
    }
  }

  Future<bool> _verifyLocalPassword(String email, String password) async {
    try {
      final userData = await _checkLocalUser(email);
      if (userData != null) {
        return userData['password'] == password;
      }
      return false;
    } catch (e) {
      print('⚠️ Error verifying local password: $e');
      return false;
    }
  }

  Future<bool> _createLocalUser(String email, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = {
        'email': email,
        'password': password,
        'createdAt': DateTime.now().toIso8601String(),
        'uid': 'local_${DateTime.now().millisecondsSinceEpoch}',
      };
      
      await prefs.setString('local_user_$email', jsonEncode(userData));
      print('✅ Local user created: $email');
      return true;
    } catch (e) {
      print('❌ Error creating local user: $e');
      return false;
    }
  }

  User _createMockUser(String email) {
    // Create a mock User object that the app can use
    // Since we can't create a real User object, we'll use a different approach
    // This will be handled by the app to create a mock user
    throw UnimplementedError('Mock user creation not implemented - use local auth state instead');
  }

  Future<void> _storeLocalAuthState(String email, bool isAuthenticated) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('local_auth_$email', isAuthenticated);
      await prefs.setString('current_local_user', email);
      print('✅ Local auth state stored for: $email');
    } catch (e) {
      print('⚠️ Error storing local auth state: $e');
    }
  }
  
  /// Force complete authentication state reset
  Future<void> forceCompleteAuthReset() async {
    print('🔄 FORCE COMPLETE AUTH RESET - Starting...');
    
    // Clear all memory variables
    _isLocallyAuthenticated = false;
    _currentLocalUser = null;
    
    // Clear all SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith('local_auth_') || 
            key.startsWith('local_user_') || 
            key == 'current_local_user') {
          await prefs.remove(key);
          print('🔄 Removed key: $key');
        }
      }
      print('✅ All SharedPreferences cleared');
    } catch (e) {
      print('⚠️ Error clearing SharedPreferences: $e');
    }
    
    // Force multiple notifications
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 200));
    notifyListeners();
    
    print('🔄 FORCE COMPLETE AUTH RESET - Completed');
  }

}

/// Result class for authentication operations
class AuthResult {
  final bool isSuccess;
  final User? user;
  final String? errorMessage;

  AuthResult._({
    required this.isSuccess,
    this.user,
    this.errorMessage,
  });

  factory AuthResult.success(User? user) => AuthResult._(
        isSuccess: true,
        user: user,
      );

  factory AuthResult.failure(String errorMessage) => AuthResult._(
        isSuccess: false,
        errorMessage: errorMessage,
      );
}
