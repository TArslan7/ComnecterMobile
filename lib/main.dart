import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
// TODO: Uncomment after Firebase project setup
// import 'services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // TODO: Uncomment after Firebase project setup
  // try {
  //   // Initialize Firebase
  //   await FirebaseService.instance.initialize();
  // } catch (e) {
  //   print('❌ Firebase initialization failed: $e');
  //   // Continue without Firebase for now
  // }
  
  runApp(const ProviderScope(child: ComnecterApp()));
}
