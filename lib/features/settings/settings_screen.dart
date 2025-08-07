import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import '../../services/sound_service.dart';
import '../../theme/app_theme.dart';
import 'models/app_settings.dart';
import 'services/settings_service.dart';

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
              // Monetization Section
              _buildSettingsCard(
                context,
                'Premium & Monetization',
                Icons.workspace_premium,
                [
                  _buildSubscriptionSection(context, soundService),
                  const SizedBox(height: 16),
                  _buildAdSettingsSection(context, soundService),
                ],
              ),
              const SizedBox(height: 20),

              // Sound Settings
              _buildSettingsCard(
                context,
                'Sound & Feedback',
                Icons.volume_up,
                [
                  _buildToggleSetting(
                    context,
                    'Sound Effects',
                    'Play sounds for interactions',
                    Icons.music_note,
                    currentSettings.soundEnabled,
                    (value) async {
                      await soundService.toggleSound();
                      final settingsService = SettingsService();
                      await settingsService.updateSoundEnabled(value);
                      settings.value = await settingsService.getSettings();
                    },
                    soundService,
                  ),
                  const SizedBox(height: 16),
                  _buildSliderSetting(
                    context,
                    'Sound Volume',
                    'Adjust sound effect volume',
                    currentSettings.soundVolume,
                    0.0,
                    1.0,
                    (value) async {
                      await soundService.setVolume(value);
                      final settingsService = SettingsService();
                      await settingsService.updateSoundVolume(value);
                      settings.value = await settingsService.getSettings();
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildToggleSetting(
                    context,
                    'Haptic Feedback',
                    'Vibrate on interactions',
                    Icons.vibration,
                    currentSettings.hapticFeedbackEnabled,
                    (value) async {
                      final settingsService = SettingsService();
                      await settingsService.updateHapticFeedbackEnabled(value);
                      settings.value = await settingsService.getSettings();
                    },
                    soundService,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // App Settings
              _buildSettingsCard(
                context,
                'App Settings',
                Icons.app_settings_alt,
                [
                  _buildActionSetting(
                    context,
                    'Notifications',
                    'Manage notification preferences',
                    Icons.notifications,
                    () async {
                      await soundService.playButtonClickSound();
                      _showNotificationsDialog(context);
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildActionSetting(
                    context,
                    'Privacy Policy',
                    'Read our privacy policy',
                    Icons.security,
                    () async {
                      await soundService.playButtonClickSound();
                      _showPrivacyDialog(context);
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildActionSetting(
                    context,
                    'Terms of Service',
                    'Read our terms of service',
                    Icons.description,
                    () async {
                      await soundService.playButtonClickSound();
                      _showTermsDialog(context);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // About Section
              _buildSettingsCard(
                context,
                'About',
                Icons.info,
                [
                  _buildActionSetting(
                    context,
                    'App Version',
                    'Version 1.0.0',
                    Icons.apps,
                    () async {
                      await soundService.playButtonClickSound();
                      _showAboutDialog(context);
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildActionSetting(
                    context,
                    'Rate App',
                    'Rate us on the app store',
                    Icons.star,
                    () async {
                      await soundService.playButtonClickSound();
                      _showRateDialog(context);
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildActionSetting(
                    context,
                    'Contact Support',
                    'Get help and support',
                    Icons.support_agent,
                    () async {
                      await soundService.playButtonClickSound();
                      _showSupportDialog(context);
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

  Widget _buildSubscriptionSection(BuildContext context, SoundService soundService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Subscription Plans',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildSubscriptionCard(
          context,
          'Free Plan',
          'Basic features',
          'Free',
          false,
          () async {
            await soundService.playButtonClickSound();
            _showSubscriptionDialog(context, 'Free Plan');
          },
        ),
        const SizedBox(height: 8),
        _buildSubscriptionCard(
          context,
          'Premium Plan',
          'Ad-free experience + advanced features',
          '\$9.99/month',
          true,
          () async {
            await soundService.playButtonClickSound();
            _showSubscriptionDialog(context, 'Premium Plan');
          },
        ),
        const SizedBox(height: 8),
        _buildSubscriptionCard(
          context,
          'Pro Plan',
          'Everything + priority support',
          '\$19.99/month',
          false,
          () async {
            await soundService.playButtonClickSound();
            _showSubscriptionDialog(context, 'Pro Plan');
          },
        ),
      ],
    );
  }

  Widget _buildSubscriptionCard(
    BuildContext context,
    String title,
    String description,
    String price,
    bool isRecommended,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: isRecommended ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isRecommended 
            ? BorderSide(color: AppTheme.primaryBlue, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (isRecommended) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'RECOMMENDED',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                price,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isRecommended ? AppTheme.primaryBlue : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdSettingsSection(BuildContext context, SoundService soundService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Advertisement Settings',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildToggleSetting(
          context,
          'Show Ads',
          'Display advertisements in the app',
          Icons.ad_units,
          true, // Default to showing ads
          (value) async {
            await soundService.playButtonClickSound();
            _showAdSettingsDialog(context, value);
          },
          soundService,
        ),
        const SizedBox(height: 16),
        _buildActionSetting(
          context,
          'Ad Preferences',
          'Customize ad experience',
          Icons.tune,
          () async {
            await soundService.playButtonClickSound();
            _showAdPreferencesDialog(context);
          },
        ),
      ],
    );
  }

  Widget _buildToggleSetting(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged,
    SoundService soundService,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppTheme.primaryBlue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: (newValue) {
              soundService.playToggleEffect();
              onChanged(newValue);
            },
            activeColor: AppTheme.primaryBlue,
          ),
        ],
      ),
    );
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
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
                child: const Icon(Icons.volume_up, color: AppTheme.primaryBlue, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(value * 100).round()}%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
            activeColor: AppTheme.primaryBlue,
            inactiveColor: Colors.grey[300],
          ),
        ],
      ),
    );
  }

  Widget _buildActionSetting(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppTheme.primaryBlue, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: 16,
            ),
          ],
        ),
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

  void _showSubscriptionDialog(BuildContext context, String plan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$plan Subscription'),
        content: Text('This feature will be available soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAdSettingsDialog(BuildContext context, bool showAds) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ad Settings'),
        content: Text('Ads are currently ${showAds ? 'enabled' : 'disabled'}. This feature will be available soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAdPreferencesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ad Preferences'),
        content: const Text('Customize your ad experience. This feature will be available soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showNotificationsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notifications'),
        content: const Text('Manage your notification preferences. This feature will be available soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
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
        content: const Text('Read our privacy policy. This feature will be available soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
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
        content: const Text('Read our terms of service. This feature will be available soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Comnecter'),
        content: const Text('Version 1.0.0\n\nA social discovery app for connecting with people nearby.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showRateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rate App'),
        content: const Text('Rate us on the app store. This feature will be available soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Support'),
        content: const Text('Get help and support. This feature will be available soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
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
        content: const Text('Need help? Contact our support team. This feature will be available soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
} 