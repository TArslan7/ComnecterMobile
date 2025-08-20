import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  bool _isLoading = false;

  // Getters
  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isSignedIn => _user != null;

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

      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name if provided
      if (displayName != null && userCredential.user != null) {
        await userCredential.user!.updateDisplayName(displayName);
      }



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



  /// Sign in with email and password
  Future<AuthResult> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );



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

  /// Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
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
        return 'The password provided is too weak. Please use at least 6 characters.';
      case 'email-already-in-use':
        return 'An account already exists for that email. Please sign in instead.';
      case 'user-not-found':
        return 'No user found for that email. Please check your email or sign up.';
      case 'wrong-password':
        return 'Wrong password provided. Please check your password.';
      case 'invalid-email':
        return 'The email address is invalid. Please enter a valid email.';
      case 'user-disabled':
        return 'This user account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled. Please contact support.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'internal-error':
        return 'An internal error occurred. This might be a configuration issue. Please try again later.';
      case 'configuration-not-found':
        return 'Firebase configuration issue. Please try again or contact support.';
      case 'unknown':
        return 'Firebase configuration issue: Email/password authentication needs to be enabled in Firebase Console. Please try "Continue as Guest" instead.';
      case 'admin-restricted-operation':
        return 'Anonymous authentication is disabled. Please enable it in Firebase Console or contact support.';
      case 'invalid-email':
        return 'The email address is invalid. Please enter a valid email.';
      case 'user-not-found':
        return 'No account found with this email address. Please check your email or sign up.';
      case 'too-many-requests':
        return 'Too many password reset attempts. Please wait a while before trying again.';
      default:
        return 'Authentication failed. Please try again. Error: $code';
    }
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
