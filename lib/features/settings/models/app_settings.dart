import 'dart:convert';

class AppSettings {
  final double radarRadiusKm;
  final bool notificationsEnabled;
  final bool friendRequestNotifications;
  final bool messageNotifications;
  final bool nearbyUserNotifications;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool darkModeEnabled;
  final bool autoRefreshEnabled;
  final int autoRefreshIntervalSeconds;
  final bool locationServicesEnabled;
  final bool privacyModeEnabled;
  final bool showOnlineStatus;
  final bool showLastSeen;
  final bool allowFriendRequests;
  final bool allowMessagesFromStrangers;
  final String language;
  final String theme;
  final double soundVolume;
  final bool hapticFeedbackEnabled;

  AppSettings({
    required this.radarRadiusKm,
    required this.notificationsEnabled,
    required this.friendRequestNotifications,
    required this.messageNotifications,
    required this.nearbyUserNotifications,
    required this.soundEnabled,
    required this.vibrationEnabled,
    required this.darkModeEnabled,
    required this.autoRefreshEnabled,
    required this.autoRefreshIntervalSeconds,
    required this.locationServicesEnabled,
    required this.privacyModeEnabled,
    required this.showOnlineStatus,
    required this.showLastSeen,
    required this.allowFriendRequests,
    required this.allowMessagesFromStrangers,
    required this.language,
    required this.theme,
    required this.soundVolume,
    required this.hapticFeedbackEnabled,
  });

  AppSettings copyWith({
    double? radarRadiusKm,
    bool? notificationsEnabled,
    bool? friendRequestNotifications,
    bool? messageNotifications,
    bool? nearbyUserNotifications,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? darkModeEnabled,
    bool? autoRefreshEnabled,
    int? autoRefreshIntervalSeconds,
    bool? locationServicesEnabled,
    bool? privacyModeEnabled,
    bool? showOnlineStatus,
    bool? showLastSeen,
    bool? allowFriendRequests,
    bool? allowMessagesFromStrangers,
    String? language,
    String? theme,
    double? soundVolume,
    bool? hapticFeedbackEnabled,
  }) {
    return AppSettings(
      radarRadiusKm: radarRadiusKm ?? this.radarRadiusKm,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      friendRequestNotifications: friendRequestNotifications ?? this.friendRequestNotifications,
      messageNotifications: messageNotifications ?? this.messageNotifications,
      nearbyUserNotifications: nearbyUserNotifications ?? this.nearbyUserNotifications,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      darkModeEnabled: darkModeEnabled ?? this.darkModeEnabled,
      autoRefreshEnabled: autoRefreshEnabled ?? this.autoRefreshEnabled,
      autoRefreshIntervalSeconds: autoRefreshIntervalSeconds ?? this.autoRefreshIntervalSeconds,
      locationServicesEnabled: locationServicesEnabled ?? this.locationServicesEnabled,
      privacyModeEnabled: privacyModeEnabled ?? this.privacyModeEnabled,
      showOnlineStatus: showOnlineStatus ?? this.showOnlineStatus,
      showLastSeen: showLastSeen ?? this.showLastSeen,
      allowFriendRequests: allowFriendRequests ?? this.allowFriendRequests,
      allowMessagesFromStrangers: allowMessagesFromStrangers ?? this.allowMessagesFromStrangers,
      language: language ?? this.language,
      theme: theme ?? this.theme,
      soundVolume: soundVolume ?? this.soundVolume,
      hapticFeedbackEnabled: hapticFeedbackEnabled ?? this.hapticFeedbackEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'radarRadiusKm': radarRadiusKm,
      'notificationsEnabled': notificationsEnabled,
      'friendRequestNotifications': friendRequestNotifications,
      'messageNotifications': messageNotifications,
      'nearbyUserNotifications': nearbyUserNotifications,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'darkModeEnabled': darkModeEnabled,
      'autoRefreshEnabled': autoRefreshEnabled,
      'autoRefreshIntervalSeconds': autoRefreshIntervalSeconds,
      'locationServicesEnabled': locationServicesEnabled,
      'privacyModeEnabled': privacyModeEnabled,
      'showOnlineStatus': showOnlineStatus,
      'showLastSeen': showLastSeen,
      'allowFriendRequests': allowFriendRequests,
      'allowMessagesFromStrangers': allowMessagesFromStrangers,
      'language': language,
      'theme': theme,
      'soundVolume': soundVolume,
      'hapticFeedbackEnabled': hapticFeedbackEnabled,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      radarRadiusKm: json['radarRadiusKm']?.toDouble() ?? 5.0,
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      friendRequestNotifications: json['friendRequestNotifications'] ?? true,
      messageNotifications: json['messageNotifications'] ?? true,
      nearbyUserNotifications: json['nearbyUserNotifications'] ?? true,
      soundEnabled: json['soundEnabled'] ?? true,
      vibrationEnabled: json['vibrationEnabled'] ?? true,
      darkModeEnabled: json['darkModeEnabled'] ?? false,
      autoRefreshEnabled: json['autoRefreshEnabled'] ?? true,
      autoRefreshIntervalSeconds: json['autoRefreshIntervalSeconds'] ?? 3,
      locationServicesEnabled: json['locationServicesEnabled'] ?? true,
      privacyModeEnabled: json['privacyModeEnabled'] ?? false,
      showOnlineStatus: json['showOnlineStatus'] ?? true,
      showLastSeen: json['showLastSeen'] ?? true,
      allowFriendRequests: json['allowFriendRequests'] ?? true,
      allowMessagesFromStrangers: json['allowMessagesFromStrangers'] ?? false,
      language: json['language'] ?? 'English',
      theme: json['theme'] ?? 'light',
      soundVolume: json['soundVolume']?.toDouble() ?? 0.7,
      hapticFeedbackEnabled: json['hapticFeedbackEnabled'] ?? true,
    );
  }

  static AppSettings defaultSettings() {
    return AppSettings(
      radarRadiusKm: 5.0,
      notificationsEnabled: true,
      friendRequestNotifications: true,
      messageNotifications: true,
      nearbyUserNotifications: true,
      soundEnabled: true,
      vibrationEnabled: true,
      darkModeEnabled: false,
      autoRefreshEnabled: true,
      autoRefreshIntervalSeconds: 3,
      locationServicesEnabled: true,
      privacyModeEnabled: false,
      showOnlineStatus: true,
      showLastSeen: true,
      allowFriendRequests: true,
      allowMessagesFromStrangers: false,
      language: 'English',
      theme: 'light',
      soundVolume: 0.7,
      hapticFeedbackEnabled: true,
    );
  }
} 