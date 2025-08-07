import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'routing/app_router.dart';
import 'theme/app_theme.dart';
import 'features/settings/services/settings_service.dart';
import 'services/sound_service.dart';

class ComnecterApp extends ConsumerStatefulWidget {
  const ComnecterApp({super.key});

  @override
  ConsumerState<ComnecterApp> createState() => _ComnecterAppState();
}

class _ComnecterAppState extends ConsumerState<ComnecterApp> with TickerProviderStateMixin {
  late AnimationController _splashController;
  late Animation<double> _splashAnimation;
  bool _isInitialized = false;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Initialize sound service
      await SoundService().initialize();
      
      // Load dark mode setting
      final settingsService = SettingsService();
      final settings = await settingsService.getSettings();
      _isDarkMode = settings.darkModeEnabled;
      
      // Initialize splash animation
      _splashController = AnimationController(
        duration: const Duration(milliseconds: 2000),
        vsync: this,
      );
      
      _splashAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _splashController,
        curve: Curves.easeInOut,
      ));
      
      // Start splash animation
      await _splashController.forward();
      
      // Play startup sound
      await SoundService().playSuccessSound();
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      // If initialization fails, still show the app
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _splashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return MaterialApp(
        home: _buildSplashScreen(),
        theme: _isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme,
      );
    }

    return MaterialApp.router(
      title: 'Comnecter',
      theme: _isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme,
      routerConfig: createRouter(),
      debugShowCheckedModeBanner: false,
    );
  }

  Widget _buildSplashScreen() {
    return Scaffold(
      backgroundColor: _isDarkMode ? AppTheme.darkTheme.colorScheme.background : AppTheme.lightTheme.colorScheme.background,
      body: Center(
        child: FadeTransition(
          opacity: _splashAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo with aurora gradient
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: AppTheme.auroraGradient,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.electricAurora.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.people,
                  color: Colors.white,
                  size: 60,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Comnecter',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: _isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Connect with people nearby',
                style: TextStyle(
                  fontSize: 16,
                  color: _isDarkMode ? Colors.grey[300] : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}