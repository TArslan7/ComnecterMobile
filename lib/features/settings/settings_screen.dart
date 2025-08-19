import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import '../../services/sound_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../../providers/theme_provider.dart';
import 'models/app_settings.dart';
import 'services/settings_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> with TickerProviderStateMixin {
  AppSettings? settings;
  bool isLoading = true;
  late ConfettiController confettiController;
  late SoundService soundService;

  @override
  void initState() {
    super.initState();
    confettiController = ConfettiController(duration: const Duration(seconds: 2));
    soundService = SoundService();
    _loadSettings();
  }

  @override
  void dispose() {
    confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() {
      isLoading = true;
    });
    await Future.delayed(const Duration(milliseconds: 500));
    final settingsService = SettingsService();
    final loadedSettings = await settingsService.getSettings();
    setState(() {
      settings = loadedSettings;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch the theme mode provider
    final currentThemeMode = ref.watch(themeModeProvider);

    if (isLoading || settings == null) {
      return Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Icon(
                Icons.settings,
                color: Theme.of(context).colorScheme.primary,
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

    final currentSettings = settings!;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Flexible(
                    child: IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Go Back',
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.settings,
                    color: Theme.of(context).colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: const Text(
                      'Settings',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: IconButton(
                      icon: Icon(
                        Icons.help_outline,
                        color: AppTheme.electricAurora,
                        size: 24,
                      ),
                      onPressed: () async {
                        await soundService.playButtonClickSound();
                        _showHelpDialog(context);
                      },
                      tooltip: 'Help',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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
                      final updatedSettings = await settingsService.getSettings();
                      setState(() {
                        settings = updatedSettings;
                      });
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
                      final updatedSettings = await settingsService.getSettings();
                      setState(() {
                        settings = updatedSettings;
                      });
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
                      final updatedSettings = await settingsService.getSettings();
                      setState(() {
                        settings = updatedSettings;
                      });
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
                    'Privacy',
                    'Control your privacy settings',
                    Icons.privacy_tip,
                    () async {
                      await soundService.playButtonClickSound();
                      _showPrivacyDialog(context);
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildThemeModeSetting(
                    context,
                    'Theme Mode',
                    'Choose your preferred theme',
                    Icons.dark_mode,
                    currentThemeMode,
                    (mode) async {
                      // Update the theme mode provider
                      ref.read(themeModeProvider.notifier).setThemeMode(mode);
                      
                      soundService.playToggleEffect();
                      confettiController.play();
                    },
                    soundService,
                  ),
                  const SizedBox(height: 16),
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
                    'Help & Support',
                    'Get help and contact support',
                    Icons.help,
                    () async {
                      await soundService.playButtonClickSound();
                      _showHelpDialog(context);
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildActionSetting(
                    context,
                    'About',
                    'App version and information',
                    Icons.info,
                    () async {
                      await soundService.playButtonClickSound();
                      _showAboutDialog(context);
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
          ).animate().fadeIn(duration: const Duration(milliseconds: 400)).slideY(begin: 0.2, duration: const Duration(milliseconds: 400)),
          
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
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
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
              if (!mounted) return;
              if (context.mounted) context.push('/subscription');
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
              if (!mounted) return;
              if (context.mounted) context.push('/subscription');
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
              if (!mounted) return;
              if (context.mounted) context.push('/subscription');
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
      elevation: isRecommended ? 6 : 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isRecommended 
            ? BorderSide(color: AppTheme.electricAurora, width: 2)
            : BorderSide.none,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: isRecommended ? [
            BoxShadow(
                              color: AppTheme.electricAurora.withValues(alpha: 0.4),
              blurRadius: 15,
              spreadRadius: 2,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
                              color: AppTheme.purpleAurora.withValues(alpha: 0.3),
              blurRadius: 25,
              spreadRadius: 1,
              offset: const Offset(0, 12),
            ),
          ] : [
            BoxShadow(
                              color: AppTheme.electricAurora.withValues(alpha: 0.2),
              blurRadius: 8,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
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
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          if (isRecommended) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                gradient: AppTheme.auroraGradient,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.electricAurora.withValues(alpha: 0.5),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: const Text(
                                'RECOMMENDED',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
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
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
                Text(
                  price,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isRecommended ? AppTheme.electricAurora : Colors.grey[700],
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
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
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
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

  Widget _buildThemeModeSetting(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    AppThemeMode currentMode,
    Function(AppThemeMode) onChanged,
    SoundService soundService,
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
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppTheme.primary, size: 20),
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
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child:                   _buildThemeModeOption(
                    context,
                    'Light',
                    Icons.light_mode,
                    AppThemeMode.light,
                    currentMode,
                    onChanged,
                  ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child:                   _buildThemeModeOption(
                    context,
                    'System',
                    Icons.brightness_auto,
                    AppThemeMode.system,
                    currentMode,
                    onChanged,
                  ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child:                   _buildThemeModeOption(
                    context,
                    'Dark',
                    Icons.brightness_auto,
                    AppThemeMode.dark,
                    currentMode,
                    onChanged,
                  ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeModeOption(
    BuildContext context,
    String label,
    IconData icon,
    AppThemeMode mode,
    AppThemeMode currentMode,
    Function(AppThemeMode) onChanged,
  ) {
    final isSelected = currentMode == mode;
    return InkWell(
      onTap: () => onChanged(mode),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primary : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppTheme.primary : Colors.grey[600],
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
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
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppTheme.primary, size: 20),
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
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
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
            activeColor: AppTheme.primary,
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
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.volume_up, color: AppTheme.primary, size: 20),
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
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
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
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
            activeColor: AppTheme.primary,
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
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppTheme.primary, size: 20),
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
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
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
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppTheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
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

  // Removed legacy subscription dialog; navigation to '/subscription' is handled directly from cards.

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
    final notificationService = NotificationService();
    final currentSettings = notificationService.settings;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.notifications, color: AppTheme.primary),
                const SizedBox(width: 8),
                const Text('Notification Settings'),
              ],
            ),
            content: Container(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildNotificationToggle(
                    'Enable Notifications',
                    'Turn all notifications on/off',
                    currentSettings.enabled,
                    (value) {
                      setState(() {
                        notificationService.updateSettings(currentSettings.copyWith(enabled: value));
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildNotificationToggle(
                    'Sound Effects',
                    'Play sound for notifications',
                    currentSettings.soundEnabled,
                    (value) {
                      setState(() {
                        notificationService.updateSettings(currentSettings.copyWith(soundEnabled: value));
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildNotificationToggle(
                    'Vibration',
                    'Vibrate for notifications',
                    currentSettings.vibrationEnabled,
                    (value) {
                      setState(() {
                        notificationService.updateSettings(currentSettings.copyWith(vibrationEnabled: value));
                      });
                    },
                  ),
                  const Divider(height: 32),
                  _buildNotificationToggle(
                    'Friend Requests',
                    'Notify when someone sends a friend request',
                    currentSettings.friendRequests,
                    (value) {
                      setState(() {
                        notificationService.updateSettings(currentSettings.copyWith(friendRequests: value));
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildNotificationToggle(
                    'Messages',
                    'Notify when you receive messages',
                    currentSettings.messages,
                    (value) {
                      setState(() {
                        notificationService.updateSettings(currentSettings.copyWith(messages: value));
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildNotificationToggle(
                    'Radar Detections',
                    'Notify when users are detected nearby',
                    currentSettings.radarDetections,
                    (value) {
                      setState(() {
                        notificationService.updateSettings(currentSettings.copyWith(radarDetections: value));
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildNotificationToggle(
                    'System Updates',
                    'Notify about app updates and news',
                    currentSettings.systemUpdates,
                    (value) {
                      setState(() {
                        notificationService.updateSettings(currentSettings.copyWith(systemUpdates: value));
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              ElevatedButton(
                onPressed: () {
                  soundService.playButtonClickSound();
                  notificationService.sendSystemNotification(
                    'Test Notification',
                    'This is a test notification to verify your settings!',
                  );
                },
                child: const Text('Test Notification'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNotificationToggle(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textMedium,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppTheme.primary,
        ),
      ],
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