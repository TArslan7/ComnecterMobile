import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../../../theme/app_theme.dart';
import '../models/user_model.dart';

class RadarSettingsWidget extends HookWidget {
  final RadarSettings currentSettings;
  final Function(RadarSettings) onSettingsChanged;

  const RadarSettingsWidget({
    super.key,
    required this.currentSettings,
    required this.onSettingsChanged,
  });

  @override
  Widget build(BuildContext context) {
    final detectionRange = useState(currentSettings.detectionRangeKm);
    final enableSound = useState(currentSettings.enableSound);
    final enableVibration = useState(currentSettings.enableVibration);
    final autoDetect = useState(currentSettings.autoDetect);
    final scanInterval = useState(currentSettings.scanIntervalMs);
    final showSignalStrength = useState(currentSettings.showSignalStrength);
    final enableManualDetection = useState(currentSettings.enableManualDetection);

    void updateSettings() {
      final newSettings = RadarSettings(
        detectionRangeKm: detectionRange.value,
        enableSound: enableSound.value,
        enableVibration: enableVibration.value,
        autoDetect: autoDetect.value,
        scanIntervalMs: scanInterval.value,
        showSignalStrength: showSignalStrength.value,
        enableManualDetection: enableManualDetection.value,
      );
      onSettingsChanged(newSettings);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.auroraGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.electricAurora.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AppTheme.purpleAurora.withOpacity(0.2),
            blurRadius: 30,
            spreadRadius: 1,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.electricAurora.withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.settings,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Radar Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Detection Range Slider
          _buildSettingSection(
            title: 'Detection Range',
            subtitle: '${(detectionRange.value * 1000).round()}m',
            icon: Icons.radar,
            child: Column(
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Colors.white,
                    inactiveTrackColor: Colors.white.withOpacity(0.3),
                    thumbColor: AppTheme.electricAurora,
                    overlayColor: AppTheme.electricAurora.withOpacity(0.2),
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                  ),
                  child: Slider(
                    value: detectionRange.value,
                    min: 0.05,
                    max: 1.0,
                    divisions: 19,
                    onChanged: (value) {
                      detectionRange.value = value;
                      updateSettings();
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '50m',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '1km',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Scan Interval
          _buildSettingSection(
            title: 'Scan Interval',
            subtitle: '${scanInterval.value}ms',
            icon: Icons.timer,
            child: Column(
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Colors.white,
                    inactiveTrackColor: Colors.white.withOpacity(0.3),
                    thumbColor: AppTheme.purpleAurora,
                    overlayColor: AppTheme.purpleAurora.withOpacity(0.2),
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                  ),
                  child: Slider(
                    value: scanInterval.value.toDouble(),
                    min: 1000,
                    max: 5000,
                    divisions: 8,
                    onChanged: (value) {
                      scanInterval.value = value.round();
                      updateSettings();
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '1s',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '5s',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Toggle Settings
          _buildToggleSetting(
            title: 'Auto Detection',
            subtitle: 'Automatically detect nearby users',
            icon: Icons.auto_awesome,
            value: autoDetect.value,
            onChanged: (value) {
              autoDetect.value = value;
              updateSettings();
            },
          ),

          _buildToggleSetting(
            title: 'Manual Detection',
            subtitle: 'Allow manual user detection',
            icon: Icons.touch_app,
            value: enableManualDetection.value,
            onChanged: (value) {
              enableManualDetection.value = value;
              updateSettings();
            },
          ),

          _buildToggleSetting(
            title: 'Sound Effects',
            subtitle: 'Play sounds when users are detected',
            icon: Icons.volume_up,
            value: enableSound.value,
            onChanged: (value) {
              enableSound.value = value;
              updateSettings();
            },
          ),

          _buildToggleSetting(
            title: 'Vibration',
            subtitle: 'Vibrate when users are detected',
            icon: Icons.vibration,
            value: enableVibration.value,
            onChanged: (value) {
              enableVibration.value = value;
              updateSettings();
            },
          ),

          _buildToggleSetting(
            title: 'Signal Strength',
            subtitle: 'Show signal strength indicators',
            icon: Icons.signal_cellular_alt,
            value: showSignalStrength.value,
            onChanged: (value) {
              showSignalStrength.value = value;
              updateSettings();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.electricAurora.withOpacity(0.3),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildToggleSetting({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.electricAurora.withOpacity(0.3),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.electricAurora,
            activeTrackColor: Colors.white.withOpacity(0.3),
            inactiveThumbColor: Colors.white.withOpacity(0.5),
            inactiveTrackColor: Colors.white.withOpacity(0.1),
          ),
        ],
      ),
    );
  }
}
