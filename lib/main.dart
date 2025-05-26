

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme.dart';
import 'providers/user_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/community_provider.dart';
import 'services/notification_service.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  
  WidgetsFlutterBinding.ensureInitialized();
  
  // Check if user exists in SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  final hasUser = prefs.containsKey('current_user');

  runApp(MyApp(hasUser: hasUser));
}

class MyApp extends StatelessWidget {
  final bool hasUser;
  
  const MyApp({super.key, required this.hasUser});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => CommunityProvider()),
        ChangeNotifierProvider(create: (_) => NotificationService()..initialize()),
      ],
      child: MaterialApp(
        title: 'Comnecter',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: hasUser ? const HomeScreen() : const OnboardingScreen(),
      ),
    );
  }
}

class DfMessageListener {
  static final DfMessageListener _instance = DfMessageListener._internal();

  factory DfMessageListener() {
    return _instance;
  }

  DfMessageListener._internal();

  void initialize() {
    // This would be initialized in a real app
  }
}

void dfInitMessageListener() {
  DfMessageListener().initialize();
}