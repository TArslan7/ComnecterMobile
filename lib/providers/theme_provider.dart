import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/settings/services/settings_service.dart';
import '../theme/app_theme.dart';

// Enum for theme modes
enum AppThemeMode {
  light,
  dark,
  system,
}

// Theme mode provider
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, AppThemeMode>((ref) {
  return ThemeModeNotifier();
});

// Dark mode provider (for backward compatibility)
final darkModeProvider = Provider<bool>((ref) {
  final themeMode = ref.watch(themeModeProvider);
  final systemBrightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
  
  switch (themeMode) {
    case AppThemeMode.light:
      return false;
    case AppThemeMode.dark:
      return true;
    case AppThemeMode.system:
      return systemBrightness == Brightness.dark;
  }
});

// Theme data provider
final themeDataProvider = Provider<ThemeData>((ref) {
  final isDarkMode = ref.watch(darkModeProvider);
  return isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme;
});

// Theme mode notifier
class ThemeModeNotifier extends StateNotifier<AppThemeMode> {
  ThemeModeNotifier() : super(AppThemeMode.system) {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    try {
      final settingsService = SettingsService();
      final settings = await settingsService.getSettings();
      
      if (settings.darkModeEnabled) {
        state = AppThemeMode.dark;
      } else {
        state = AppThemeMode.light;
      }
    } catch (e) {
      // Default to system theme if loading fails
      state = AppThemeMode.system;
    }
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    state = mode;
    
    try {
      final settingsService = SettingsService();
      final settings = await settingsService.getSettings();
      
      // Update the dark mode setting based on the new theme mode
      bool darkModeEnabled;
      switch (mode) {
        case AppThemeMode.light:
          darkModeEnabled = false;
          break;
        case AppThemeMode.dark:
          darkModeEnabled = true;
          break;
        case AppThemeMode.system:
          // For system mode, we'll keep the current setting but let the system decide
          darkModeEnabled = settings.darkModeEnabled;
          break;
      }
      
      await settingsService.updateDarkModeEnabled(darkModeEnabled);
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> toggleDarkMode() async {
    final newMode = state == AppThemeMode.dark ? AppThemeMode.light : AppThemeMode.dark;
    await setThemeMode(newMode);
  }
}
