import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'models/app_settings.dart';
import 'services/settings_service.dart';
import '../../services/sound_service.dart';
import '../../theme/app_theme.dart';

class SettingsScreen extends HookWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = useState<AppSettings?>(null);
    final isLoading = useState(true);
    final confettiController = useMemoized(() => ConfettiController(duration: const Duration(seconds: 2)));
    final soundService = useMemoized(() => SoundService());

    Future<void> _loadSettings() async {
      isLoading.value = true;
      await Future.delayed(const Duration(milliseconds: 500));
      final settingsService = SettingsService();
      settings.value = await settingsService.getSettings();
      isLoading.value = false;
    }

    useEffect(() {
      _loadSettings();
      return null;
    }, []);

    if (isLoading.value || settings.value == null) {
      return Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Icon(
                Icons.settings,
                color: AppTheme.primaryBlue,
                size: 28,
              ),
              const SizedBox(width: 8),
              const Text(
                'Settings',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final currentSettings = settings.value!;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.settings,
              color: AppTheme.primaryBlue,
              size: 28,
            ),
            const SizedBox(width: 8),
            const Text(
              'Settings',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              Icons.help_outline,
              color: AppTheme.primaryBlue,
            ),
            onPressed: () async {
              await soundService.playButtonClickSound();
              _showHelpDialog(context);
            },
            tooltip: 'Help',
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Radar Settings
              _buildSettingsCard(
                context,
                'Radar Settings',
                Icons.radar,
                [
                  _buildSliderSetting(
                    context,
                    'Radar Radius (km)',
                    '${currentSettings.radarRadiusKm.toStringAsFixed(1)} km',
                    currentSettings.radarRadiusKm,
                    1,
                    20,
                    (value) async {
                      final settingsService = SettingsService();
                      await settingsService.updateRadarRadius(value);
                      await _loadSettings();
                      await soundService.playButtonClickSound();
                    },
                  ),
                  _buildSwitchSetting(
                    context,
                    'Auto Refresh Radar',
                    'Automatically refresh radar every 5 seconds',
                    currentSettings.autoRefreshEnabled,
                    (value) async {
                      final settingsService = SettingsService();
                      await settingsService.updateAutoRefreshEnabled(value);
                      await _loadSettings();
                      await soundService.playToggleEffect();
                    },
                  ),
                  _buildSwitchSetting(
                    context,
                    'Location Services',
                    'Enable to detect nearby users',
                    currentSettings.locationServicesEnabled,
                    (value) async {
                      final settingsService = SettingsService();
                      await settingsService.updateLocationServicesEnabled(value);
                      await _loadSettings();
                      await soundService.playToggleEffect();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Notification Settings
              _buildSettingsCard(
                context,
                'Notifications',
                Icons.notifications,
                [
                  _buildSwitchSetting(
                    context,
                    'Enable Notifications',
                    'Receive push notifications',
                    currentSettings.notificationsEnabled,
                    (value) async {
                      final settingsService = SettingsService();
                      await settingsService.updateNotificationsEnabled(value);
                      await _loadSettings();
                      await soundService.playToggleEffect();
                    },
                  ),
                  _buildSwitchSetting(
                    context,
                    'Sound',
                    'Play sound for notifications',
                    currentSettings.soundEnabled,
                    (value) async {
                      final settingsService = SettingsService();
                      await settingsService.updateSoundEnabled(value);
                      await _loadSettings();
                      await soundService.playToggleEffect();
                    },
                  ),
                  _buildSwitchSetting(
                    context,
                    'Vibration',
                    'Vibrate for notifications',
                    currentSettings.vibrationEnabled,
                    (value) async {
                      final settingsService = SettingsService();
                      await settingsService.updateVibrationEnabled(value);
                      await _loadSettings();
                      await soundService.playToggleEffect();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Privacy Settings
              _buildSettingsCard(
                context,
                'Privacy',
                Icons.privacy_tip,
                [
                  _buildSwitchSetting(
                    context,
                    'Privacy Mode',
                    'Hide your location from others',
                    currentSettings.privacyModeEnabled,
                    (value) async {
                      final settingsService = SettingsService();
                      await settingsService.updatePrivacyModeEnabled(value);
                      await _loadSettings();
                      await soundService.playToggleEffect();
                    },
                  ),
                  _buildSwitchSetting(
                    context,
                    'Show Online Status',
                    'Let others see when you\'re online',
                    currentSettings.showOnlineStatus,
                    (value) async {
                      final settingsService = SettingsService();
                      await settingsService.updateShowOnlineStatus(value);
                      await _loadSettings();
                      await soundService.playToggleEffect();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Sound Settings
              _buildSettingsCard(
                context,
                'Sound & Haptics',
                Icons.volume_up,
                [
                  _buildSliderSetting(
                    context,
                    'Sound Volume',
                    '${(currentSettings.soundVolume * 100).toInt()}%',
                    currentSettings.soundVolume,
                    0.0,
                    1.0,
                    (value) async {
                      final settingsService = SettingsService();
                      await settingsService.updateSoundVolume(value);
                      await _loadSettings();
                      await soundService.playButtonClickSound();
                    },
                  ),
                  _buildSwitchSetting(
                    context,
                    'Haptic Feedback',
                    'Vibrate on interactions',
                    currentSettings.hapticFeedbackEnabled,
                    (value) async {
                      final settingsService = SettingsService();
                      await settingsService.updateHapticFeedbackEnabled(value);
                      await _loadSettings();
                      await soundService.playToggleEffect();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Data Management
              _buildSettingsCard(
                context,
                'Data Management',
                Icons.storage,
                [
                  _buildActionSetting(
                    context,
                    'Reset Settings',
                    'Reset to default values',
                    Icons.restore,
                    () async {
                      await soundService.playButtonClickSound();
                      _showResetConfirmDialog(context, () async {
                        final settingsService = SettingsService();
                        await settingsService.resetSettings();
                        await _loadSettings();
                        confettiController.play();
                        await soundService.playSuccessSound();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Settings reset to default!'),
                              backgroundColor: AppTheme.accentGreen,
                            ),
                          );
                        }
                      });
                    },
                  ),
                  _buildActionSetting(
                    context,
                    'Clear All Data',
                    'Delete all app data',
                    Icons.delete_forever,
                    () async {
                      await soundService.playButtonClickSound();
                      _showClearDataConfirmDialog(context, () async {
                        final settingsService = SettingsService();
                        await settingsService.clearAllData();
                        await soundService.playSuccessSound();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('All data cleared!'),
                              backgroundColor: AppTheme.accentGreen,
                            ),
                          );
                        }
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // About Section
              _buildSettingsCard(
                context,
                'About',
                Icons.info,
                [
                  _buildInfoSetting(
                    context,
                    'App Version',
                    '1.0.0',
                    Icons.apps,
                  ),
                  _buildInfoSetting(
                    context,
                    'Build Number',
                    '2024.1.0',
                    Icons.build,
                  ),
                  _buildActionSetting(
                    context,
                    'Terms of Service',
                    'Read our terms and conditions',
                    Icons.description,
                    () async {
                      await soundService.playButtonClickSound();
                      _showTermsDialog(context);
                    },
                  ),
                  _buildActionSetting(
                    context,
                    'Privacy Policy',
                    'Read our privacy policy',
                    Icons.privacy,
                    () async {
                      await soundService.playButtonClickSound();
                      _showPrivacyDialog(context);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
          
          // Confetti overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: confettiController,
              blastDirection: pi / 2,
              maxBlastForce: 5,
              minBlastForce: 2,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              gravity: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(
    BuildContext context,
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppTheme.primaryBlue),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    ).animate().fadeIn(duration: const Duration(milliseconds: 400)).slideY(begin: 0.2, duration: const Duration(milliseconds: 400));
  }

  Widget _buildSliderSetting(
    BuildContext context,
    String title,
    String subtitle,
    double value,
    double min,
    double max,
    Function(double) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppTheme.neutralGrey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: ((max - min) * 10).toInt(),
          label: subtitle,
          onChanged: onChanged,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSwitchSetting(
    BuildContext context,
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return Column(
      children: [
        SwitchListTile(
          title: Text(title),
          subtitle: Text(subtitle),
          value: value,
          onChanged: onChanged,
          activeColor: AppTheme.primaryBlue,
        ),
        const Divider(),
      ],
    );
  }

  Widget _buildActionSetting(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: AppTheme.primaryBlue),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: onTap,
        ),
        const Divider(),
      ],
    );
  }

  Widget _buildInfoSetting(
    BuildContext context,
    String title,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: AppTheme.primaryBlue),
          title: Text(title),
          subtitle: Text(value),
        ),
        const Divider(),
      ],
    );
  }

  void _showResetConfirmDialog(BuildContext context, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text('Are you sure you want to reset all settings to default values?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showClearDataConfirmDialog(BuildContext context, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text('This will delete all your data. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentRed,
            ),
            child: const Text('Clear All Data'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help'),
        content: const Text('Need help with settings? Contact our support team.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement help functionality
            },
            child: const Text('Contact Support'),
          ),
        ],
      ),
    );
  }

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms of Service'),
        content: const Text('Our terms of service will be displayed here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const Text('Our privacy policy will be displayed here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
} 