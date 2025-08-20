import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../firebase_options.dart';

class FirebaseService {
  static FirebaseService? _instance;
  static FirebaseService get instance => _instance ??= FirebaseService._internal();

  FirebaseService._internal();

  // Firebase instances
  late FirebaseAuth _auth;
  late FirebaseFirestore _firestore;
  late FirebaseStorage _storage;
  late FirebaseMessaging _messaging;
  late FirebaseAnalytics _analytics;
  late FirebaseCrashlytics _crashlytics;

  // Getters
  FirebaseAuth get auth => _auth;
  FirebaseFirestore get firestore => _firestore;
  FirebaseStorage get storage => _storage;
  FirebaseMessaging get messaging => _messaging;
  FirebaseAnalytics get analytics => _analytics;
  FirebaseCrashlytics get crashlytics => _crashlytics;

  /// Initialize Firebase services
  Future<void> initialize() async {
    try {
      // Initialize Firebase Core
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Initialize Firebase services
      _auth = FirebaseAuth.instance;
      _firestore = FirebaseFirestore.instance;
      _storage = FirebaseStorage.instance;
      _messaging = FirebaseMessaging.instance;
      _analytics = FirebaseAnalytics.instance;
      _crashlytics = FirebaseCrashlytics.instance;

      // Configure Firebase services
      await _configureFirebaseServices();

      print('🔥 Firebase initialized successfully!');
    } catch (e) {
      print('❌ Firebase initialization failed: $e');
      rethrow;
    }
  }

  /// Configure Firebase services
  Future<void> _configureFirebaseServices() async {
    try {
      // Configure Firestore settings
      _firestore.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );

      // Configure messaging permissions
      await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      // Configure crashlytics
      await _crashlytics.setCrashlyticsCollectionEnabled(true);

      // Configure analytics
      await _analytics.setAnalyticsCollectionEnabled(true);

      print('✅ Firebase services configured successfully!');
    } catch (e) {
      print('⚠️ Firebase service configuration failed: $e');
      // Don't rethrow - these are optional configurations
    }
  }

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Check if user is signed in
  bool get isSignedIn => _auth.currentUser != null;

  /// Sign out user
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      print('👋 User signed out successfully');
    } catch (e) {
      print('❌ Sign out failed: $e');
      rethrow;
    }
  }

  /// Dispose Firebase service
  Future<void> dispose() async {
    try {
      await _auth.signOut();
      print('🧹 Firebase service disposed');
    } catch (e) {
      print('⚠️ Firebase service disposal failed: $e');
    }
  }
}


