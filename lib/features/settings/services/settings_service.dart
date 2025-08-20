import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';

class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  static const String _settingsKey = 'app_settings';

  // Get current settings
  Future<AppSettings> getSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_settingsKey);
      
      if (settingsJson != null) {
        return AppSettings.fromJson(json.decode(settingsJson));
      }
    } catch (e) {
      // Handle error, e.g., corrupted data
    }
    return AppSettings.defaultSettings(); // Return default if no settings found or error
  }

  // Save settings
  Future<void> saveSettings(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, json.encode(settings.toJson()));
  }

  // Update individual settings
  Future<void> updateRadarRadius(double radius) async {
    final currentSettings = await getSettings();
    await saveSettings(currentSettings.copyWith(radarRadiusKm: radius));
  }

  Future<void> updateNotificationsEnabled(bool enabled) async {
    final currentSettings = await getSettings();
    await saveSettings(currentSettings.copyWith(notificationsEnabled: enabled));
  }

  Future<void> updateFriendRequestNotifications(bool enabled) async {
    final currentSettings = await getSettings();
    await saveSettings(currentSettings.copyWith(friendRequestNotifications: enabled));
  }

  Future<void> updateMessageNotifications(bool enabled) async {
    final currentSettings = await getSettings();
    await saveSettings(currentSettings.copyWith(messageNotifications: enabled));
  }

  Future<void> updateNearbyUserNotifications(bool enabled) async {
    final currentSettings = await getSettings();
    await saveSettings(currentSettings.copyWith(nearbyUserNotifications: enabled));
  }

  Future<void> updateSoundEnabled(bool enabled) async {
    final currentSettings = await getSettings();
    await saveSettings(currentSettings.copyWith(soundEnabled: enabled));
  }

  Future<void> updateVibrationEnabled(bool enabled) async {
    final currentSettings = await getSettings();
    await saveSettings(currentSettings.copyWith(vibrationEnabled: enabled));
  }

  Future<void> updateDarkModeEnabled(bool enabled) async {
    final currentSettings = await getSettings();
    await saveSettings(currentSettings.copyWith(darkModeEnabled: enabled));
  }

  Future<void> updateAutoRefreshEnabled(bool enabled) async {
    final currentSettings = await getSettings();
    await saveSettings(currentSettings.copyWith(autoRefreshEnabled: enabled));
  }

  Future<void> updateAutoRefreshIntervalSeconds(int interval) async {
    final currentSettings = await getSettings();
    await saveSettings(currentSettings.copyWith(autoRefreshIntervalSeconds: interval));
  }

  Future<void> updateLocationServicesEnabled(bool enabled) async {
    final currentSettings = await getSettings();
    await saveSettings(currentSettings.copyWith(locationServicesEnabled: enabled));
  }

  Future<void> updatePrivacyModeEnabled(bool enabled) async {
    final currentSettings = await getSettings();
    await saveSettings(currentSettings.copyWith(privacyModeEnabled: enabled));
  }

  Future<void> updateShowOnlineStatus(bool enabled) async {
    final currentSettings = await getSettings();
    await saveSettings(currentSettings.copyWith(showOnlineStatus: enabled));
  }

  Future<void> updateShowLastSeen(bool enabled) async {
    final currentSettings = await getSettings();
    await saveSettings(currentSettings.copyWith(showLastSeen: enabled));
  }

  Future<void> updateAllowFriendRequests(bool enabled) async {
    final currentSettings = await getSettings();
    await saveSettings(currentSettings.copyWith(allowFriendRequests: enabled));
  }

  Future<void> updateAllowMessagesFromStrangers(bool enabled) async {
    final currentSettings = await getSettings();
    await saveSettings(currentSettings.copyWith(allowMessagesFromStrangers: enabled));
  }

  Future<void> updateLanguage(String language) async {
    final currentSettings = await getSettings();
    await saveSettings(currentSettings.copyWith(language: language));
  }

  Future<void> updateTheme(String theme) async {
    final currentSettings = await getSettings();
    await saveSettings(currentSettings.copyWith(theme: theme));
  }

  Future<void> updateSoundVolume(double volume) async {
    final currentSettings = await getSettings();
    await saveSettings(currentSettings.copyWith(soundVolume: volume));
  }

  Future<void> updateHapticFeedbackEnabled(bool enabled) async {
    final currentSettings = await getSettings();
    await saveSettings(currentSettings.copyWith(hapticFeedbackEnabled: enabled));
  }

  // Data Management
  Future<void> exportSettings() async {
    // Mock implementation
  }

  Future<void> importSettings() async {
    // Mock implementation
  }

  Future<void> resetSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_settingsKey);
  }

  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
} 