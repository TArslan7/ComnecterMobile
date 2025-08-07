import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:async';
import 'dart:math';
import '../../services/sound_service.dart';
import '../../theme/app_theme.dart';
import 'models/user_model.dart';
import 'services/radar_service.dart';
import 'widgets/radar_widget.dart';
import 'widgets/empty_state_widget.dart';
import 'widgets/loading_widget.dart';
import 'widgets/radar_settings_widget.dart';

class RadarScreen extends HookWidget {
  const RadarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final radarService = useMemoized(() => RadarService());
    final nearbyUsers = useState<List<NearbyUser>>([]);
    final isLoading = useState(true);
    final isRefreshing = useState(false);
    final isScanning = useState(true); // Start scanning by default
    final showSettings = useState(false);
    final showRadarView = useState(true); // Toggle between radar and list view
    final confettiController = useMemoized(() => ConfettiController(duration: const Duration(seconds: 2)));
    final soundService = useMemoized(() => SoundService());
    final pulseController = useAnimationController(duration: const Duration(seconds: 2));
    final fadeController = useAnimationController(duration: const Duration(milliseconds: 300));
    final radarRotationController = useAnimationController(duration: const Duration(seconds: 10));
    final settings = useState<RadarSettings>(const RadarSettings());

    // Initialize radar service and start scanning automatically
    useEffect(() {
      radarService.initialize().then((_) {
        // Start scanning automatically when screen loads
        radarService.updateSettings(settings.value);
        radarService.startScanning();
      });
      return null;
    }, []);

    // Listen to radar service updates
    useEffect(() {
      final subscription = radarService.usersStream.listen((users) {
        nearbyUsers.value = users;
        if (isLoading.value) {
          isLoading.value = false;
        }
      });

      return () => subscription.cancel();
    }, []);

    // Listen to detection events
    useEffect(() {
      final subscription = radarService.detectionStream.listen((detection) {
        if (detection.isManual) {
          confettiController.play();
          soundService.playSuccessSound();
        } else {
          soundService.playRadarPingSound();
        }
      });

      return () => subscription.cancel();
    }, []);

    // Start animations
    useEffect(() {
      pulseController.repeat();
      radarRotationController.repeat();
      return null;
    }, []);

    Future<void> handleToggleScanning() async {
      if (isScanning.value) {
        // Stop scanning
        isScanning.value = false;
        soundService.playButtonClickSound();
        await radarService.stopScanning();
      } else {
        // Start scanning
        isScanning.value = true;
        isLoading.value = true;
        soundService.playButtonClickSound();
        await radarService.updateSettings(settings.value);
        await radarService.startScanning();
      }
    }

    Future<void> handleRefresh() async {
      if (isRefreshing.value) return;
      
      isRefreshing.value = true;
      soundService.playSwipeSound();
      
      // Restart scanning with current settings
      await radarService.stopScanning();
      await radarService.updateSettings(settings.value);
      await radarService.startScanning();
      
      isRefreshing.value = false;
    }

    void handleUserTap(NearbyUser user) {
      soundService.playTapSound();
      _buildUserDetailsDialog(context, user, radarService);
    }

    void handleManualDetection(String userId) async {
      try {
        await radarService.manuallyDetectUser(userId);
        soundService.playSuccessSound();
        confettiController.play();
      } catch (e) {
        soundService.playErrorSound();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User is out of range: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    void handleSettingsChanged(RadarSettings newSettings) {
      settings.value = newSettings;
      radarService.updateSettings(newSettings);
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: _buildAppBar(
        context, 
        soundService, 
        handleRefresh, 
        isRefreshing, 
        isScanning,
        () => showSettings.value = !showSettings.value,
        showRadarView,
        () => showRadarView.value = !showRadarView.value,
      ),
      body: Stack(
        children: [
          // Main content with smooth transitions
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: isLoading.value
                ? _buildLoadingState(context, radarRotationController, isScanning.value)
                : nearbyUsers.value.isEmpty
                    ? _buildEmptyState(context, isScanning.value)
                    : showRadarView.value
                        ? _buildRadarView(context, nearbyUsers.value, handleUserTap, settings.value, isScanning.value)
                        : _buildUserList(context, nearbyUsers.value, handleUserTap, handleManualDetection, settings.value),
          ),
          
          // Status indicator
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: _buildStatusIndicator(context, isLoading.value, nearbyUsers.value.length, isRefreshing.value, isScanning.value, settings.value),
          ),
          
          // Settings overlay
          if (showSettings.value)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    child: RadarSettingsWidget(
                      currentSettings: settings.value,
                      onSettingsChanged: handleSettingsChanged,
                    ),
                  ),
                ),
              ),
            ).animate().fadeIn(duration: const Duration(milliseconds: 300)),
          
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
      floatingActionButton: _buildFloatingActionButton(
        context,
        isScanning.value,
        handleToggleScanning,
        soundService,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    SoundService soundService,
    VoidCallback onRefresh,
    ValueNotifier<bool> isRefreshing,
    ValueNotifier<bool> isScanning,
    VoidCallback onSettingsTap,
    ValueNotifier<bool> showRadarView,
    VoidCallback onToggleView,
  ) {
    return AppBar(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: AppTheme.auroraGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.electricAurora.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Icon(
              Icons.radar,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Radar',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      actions: [
        // View toggle button
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.orangeAurora.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(
              showRadarView.value ? Icons.list : Icons.radar,
              color: AppTheme.orangeAurora,
            ),
            onPressed: () {
              soundService.playButtonClickSound();
              onToggleView();
            },
          ),
        ),
        // Animated refresh button
        AnimatedBuilder(
          animation: isRefreshing.value ? const AlwaysStoppedAnimation(1.0) : const AlwaysStoppedAnimation(0.0),
          builder: (context, child) {
            return Transform.rotate(
              angle: isRefreshing.value ? 2 * pi : 0,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.electricAurora.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    isRefreshing.value ? Icons.refresh : Icons.refresh,
                    color: AppTheme.electricAurora,
                  ),
                  onPressed: isRefreshing.value ? null : () async {
                    soundService.playButtonClickSound();
                    onRefresh();
                  },
                ),
              ),
            );
          },
        ),
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.purpleAurora.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(
              Icons.settings,
              color: AppTheme.purpleAurora,
            ),
            onPressed: () {
              soundService.playButtonClickSound();
              onSettingsTap();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRadarView(
    BuildContext context,
    List<NearbyUser> users,
    Function(NearbyUser) onUserTap,
    RadarSettings settings,
    bool isScanning,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Radar widget
          RadarWidget(
            users: users,
            maxRangeKm: settings.detectionRangeKm,
            isScanning: isScanning,
            onUserTap: onUserTap,
          ),
          const SizedBox(height: 24),
          // Legend
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppTheme.auroraGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.electricAurora.withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'Signal Strength Legend',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildLegendItem('Strong', AppTheme.greenAurora),
                    _buildLegendItem('Medium', AppTheme.orangeAurora),
                    _buildLegendItem('Weak', AppTheme.pinkAurora),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.6),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusIndicator(
    BuildContext context,
    bool isLoading,
    int userCount,
    bool isRefreshing,
    bool isScanning,
    RadarSettings settings,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: AppTheme.auroraGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.electricAurora.withOpacity(0.4),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: AppTheme.pinkAurora.withOpacity(0.3),
            blurRadius: 25,
            spreadRadius: 1,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLoading || isRefreshing) ...[
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.electricAurora.withOpacity(0.6),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              isRefreshing ? 'Refreshing...' : 'Initializing radar...',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ] else if (isScanning) ...[
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.greenAurora.withOpacity(0.6),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Scanning (${(settings.detectionRangeKm * 1000).round()}m range)',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(
                Icons.pause,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Scanning paused',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: const Duration(milliseconds: 300));
  }

  Widget _buildLoadingState(BuildContext context, AnimationController radarController, bool isScanning) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated radar with rotation
          AnimatedBuilder(
            animation: radarController,
            builder: (context, child) {
              return Transform.rotate(
                angle: radarController.value * 2 * pi,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    gradient: AppTheme.auroraGradient,
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.electricAurora.withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: AppTheme.purpleAurora.withOpacity(0.3),
                        blurRadius: 40,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.radar,
                    color: Colors.white,
                    size: 80,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          Text(
            isScanning ? 'Scanning for nearby users...' : 'Initializing radar...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isScanning ? 'This may take a few seconds' : 'Setting up detection system',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isScanning) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: AppTheme.auroraGradient,
              borderRadius: BorderRadius.circular(60),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.electricAurora.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              isScanning ? Icons.people_outline : Icons.pause_circle_outline,
              color: Colors.white,
              size: 60,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isScanning ? 'No users found in range' : 'Radar is paused',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isScanning ? 'Try increasing the detection range' : 'Tap the scan button to resume',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList(
    BuildContext context,
    List<NearbyUser> users,
    Function(NearbyUser) onUserTap,
    Function(String) onManualDetection,
    RadarSettings settings,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 80, 16, 16),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: _buildUserCard(context, user, onUserTap, onManualDetection, settings),
        ).animate().fadeIn(
          delay: Duration(milliseconds: index * 100),
          duration: const Duration(milliseconds: 300),
        ).slideY(
          begin: 0.3,
          duration: const Duration(milliseconds: 300),
        );
      },
    );
  }

  Widget _buildUserCard(
    BuildContext context,
    NearbyUser user,
    Function(NearbyUser) onUserTap,
    Function(String) onManualDetection,
    RadarSettings settings,
  ) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.electricAurora.withOpacity(0.3),
              blurRadius: 12,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: AppTheme.purpleAurora.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: InkWell(
          onTap: () => onUserTap(user),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar with online indicator and signal strength
                Stack(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: AppTheme.sunsetGradient,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.orangeAurora.withOpacity(0.5),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                          BoxShadow(
                            color: AppTheme.pinkAurora.withOpacity(0.3),
                            blurRadius: 25,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          user.avatar,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                    if (user.isOnline)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: AppTheme.greenAurora,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.greenAurora.withOpacity(0.6),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (settings.showSignalStrength)
                      Positioned(
                        left: -2,
                        top: -2,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _getSignalStrengthColor(user.signalStrength),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.white, width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: _getSignalStrengthColor(user.signalStrength).withOpacity(0.6),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              user.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: AppTheme.auroraGradient,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.electricAurora.withOpacity(0.3),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Text(
                              '${(user.distanceKm * 1000).round()}m',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.interests.join(' • '),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: user.isOnline ? AppTheme.greenAurora : Colors.grey[400],
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: user.isOnline ? [
                                BoxShadow(
                                  color: AppTheme.greenAurora.withOpacity(0.5),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ] : null,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            user.isOnline ? 'Online' : 'Offline',
                            style: TextStyle(
                              fontSize: 12,
                              color: user.isOnline ? AppTheme.greenAurora : Colors.grey[500],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (settings.showSignalStrength) ...[
                            const SizedBox(width: 12),
                            Icon(
                              Icons.signal_cellular_alt,
                              size: 12,
                              color: _getSignalStrengthColor(user.signalStrength),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${(user.signalStrength * 100).round()}%',
                              style: TextStyle(
                                fontSize: 10,
                                color: _getSignalStrengthColor(user.signalStrength),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (settings.enableManualDetection && !user.isDetected)
                  IconButton(
                    icon: Icon(
                      Icons.add_circle_outline,
                      color: AppTheme.electricAurora,
                    ),
                    onPressed: () => onManualDetection(user.id),
                  ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[400],
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getSignalStrengthColor(double signalStrength) {
    if (signalStrength > 0.8) return AppTheme.greenAurora;
    if (signalStrength > 0.5) return AppTheme.orangeAurora;
    if (signalStrength > 0.2) return AppTheme.pinkAurora;
    return Colors.grey;
  }

  Widget _buildFloatingActionButton(
    BuildContext context,
    bool isScanning,
    VoidCallback onToggleScanning,
    SoundService soundService,
  ) {
    return FloatingActionButton.extended(
      onPressed: onToggleScanning,
      backgroundColor: isScanning ? Colors.red : AppTheme.electricAurora,
      foregroundColor: Colors.white,
      icon: Icon(
        isScanning ? Icons.pause : Icons.radar,
        color: Colors.white,
      ),
      label: Text(
        isScanning ? 'Pause Scan' : 'Resume Scan',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  void _buildUserDetailsDialog(BuildContext context, NearbyUser user, RadarService radarService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: AppTheme.auroraGradient,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.electricAurora.withOpacity(0.4),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  user.avatar,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${(user.distanceKm * 1000).round()}m away',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Interests:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: user.interests.map((interest) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: AppTheme.auroraGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.electricAurora.withOpacity(0.3),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Text(
                  interest,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )).toList(),
            ),
            if (user.signalStrength > 0)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.signal_cellular_alt,
                      size: 16,
                      color: _getSignalStrengthColor(user.signalStrength),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Signal: ${(user.signalStrength * 100).round()}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: _getSignalStrengthColor(user.signalStrength),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement chat functionality
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.electricAurora,
              foregroundColor: Colors.white,
            ),
            child: const Text('Start Chat'),
          ),
        ],
      ),
    );
  }
}
