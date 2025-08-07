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
import 'widgets/map_widget.dart';

class RadarScreen extends HookWidget {
  const RadarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final radarService = useMemoized(() => RadarService());
    final nearbyUsers = useState<List<NearbyUser>>([]);
    final isLoading = useState(true);
    final isRefreshing = useState(false);
    final isRadarEnabled = useState(true);
    final showSettings = useState(false);
    final currentView = useState<RadarView>(RadarView.radar);
    final confettiController = useMemoized(() => ConfettiController(duration: const Duration(seconds: 3)));
    final soundService = useMemoized(() => SoundService());
    final pulseController = useAnimationController(duration: const Duration(seconds: 2));
    final fadeController = useAnimationController(duration: const Duration(milliseconds: 300));
    final radarRotationController = useAnimationController(duration: const Duration(seconds: 10));
    final settings = useState<RadarSettings>(const RadarSettings());
    final showTutorial = useState(true);
    final selectedUser = useState<NearbyUser?>(null);
    final showUserDetails = useState(false);

    // Initialize radar service and start scanning automatically
    useEffect(() {
      radarService.initialize().then((_) {
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

    Future<void> handleToggleRadar() async {
      if (isRadarEnabled.value) {
        isRadarEnabled.value = false;
        soundService.playButtonClickSound();
        await radarService.stopScanning();
      } else {
        isRadarEnabled.value = true;
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
      
      await radarService.stopScanning();
      await radarService.updateSettings(settings.value);
      await radarService.startScanning();
      
      isRefreshing.value = false;
    }

    void handleUserTap(NearbyUser user) {
      soundService.playTapSound();
      selectedUser.value = user;
      showUserDetails.value = true;
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
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }

    void handleSettingsChanged(RadarSettings newSettings) {
      settings.value = newSettings;
      radarService.updateSettings(newSettings);
    }

    void handleViewChanged(RadarView view) {
      soundService.playButtonClickSound();
      currentView.value = view;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: _buildEnhancedAppBar(
        context, 
        soundService, 
        handleRefresh, 
        isRefreshing, 
        isRadarEnabled,
        () => showSettings.value = !showSettings.value,
        currentView,
        handleViewChanged,
        nearbyUsers.value.length,
        settings.value,
      ),
      body: Stack(
        children: [
          // Main content with enhanced transitions
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.1),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: isLoading.value
                ? _buildEnhancedLoadingState(context, radarRotationController, isRadarEnabled.value)
                : nearbyUsers.value.isEmpty
                    ? _buildEnhancedEmptyState(context, isRadarEnabled.value)
                    : _buildCurrentView(context, nearbyUsers.value, handleUserTap, handleManualDetection, settings.value, isRadarEnabled.value, currentView.value),
          ),
          
          // Enhanced status indicator
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: _buildEnhancedStatusIndicator(context, isLoading.value, nearbyUsers.value.length, isRefreshing.value, isRadarEnabled.value, settings.value),
          ),
          
          // Enhanced settings overlay
          if (showSettings.value)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.7),
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
            ).animate().fadeIn(duration: const Duration(milliseconds: 400)),
          
          // Enhanced confetti overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: confettiController,
              blastDirection: pi / 2,
              maxBlastForce: 8,
              minBlastForce: 3,
              emissionFrequency: 0.03,
              numberOfParticles: 80,
              gravity: 0.08,
              colors: [
                AppTheme.electricAurora,
                AppTheme.purpleAurora,
                AppTheme.pinkAurora,
                AppTheme.orangeAurora,
                AppTheme.greenAurora,
              ],
            ),
          ),

          // Tutorial overlay
          if (showTutorial.value)
            _buildTutorialOverlay(context, () => showTutorial.value = false),

          // Enhanced user details modal
          if (showUserDetails.value && selectedUser.value != null)
            _buildEnhancedUserDetailsModal(context, selectedUser.value!, radarService, () {
              showUserDetails.value = false;
              selectedUser.value = null;
            }),
        ],
      ),
      floatingActionButton: _buildEnhancedFloatingActionButton(
        context,
        isRadarEnabled.value,
        handleToggleRadar,
        soundService,
      ),
    );
  }

  PreferredSizeWidget _buildEnhancedAppBar(
    BuildContext context,
    SoundService soundService,
    VoidCallback onRefresh,
    ValueNotifier<bool> isRefreshing,
    ValueNotifier<bool> isRadarEnabled,
    VoidCallback onSettingsTap,
    ValueNotifier<RadarView> currentView,
    Function(RadarView) onViewChanged,
    int userCount,
    RadarSettings settings,
  ) {
    return AppBar(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: AppTheme.auroraGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.electricAurora.withOpacity(0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.radar,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Radar',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              Text(
                '${userCount} users nearby',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      actions: [
        // Enhanced view toggle buttons
        _buildEnhancedViewToggleButton(
          context,
          RadarView.radar,
          Icons.radar,
          'Radar',
          currentView.value == RadarView.radar,
          onViewChanged,
          soundService,
        ),
        _buildEnhancedViewToggleButton(
          context,
          RadarView.list,
          Icons.list,
          'List',
          currentView.value == RadarView.list,
          onViewChanged,
          soundService,
        ),
        _buildEnhancedViewToggleButton(
          context,
          RadarView.map,
          Icons.map,
          'Map',
          currentView.value == RadarView.map,
          onViewChanged,
          soundService,
        ),
        // Enhanced refresh button
        _buildEnhancedRefreshButton(context, isRefreshing, onRefresh, soundService),
        // Enhanced settings button
        _buildEnhancedSettingsButton(context, onSettingsTap, soundService),
      ],
    );
  }

  Widget _buildEnhancedViewToggleButton(
    BuildContext context,
    RadarView view,
    IconData icon,
    String label,
    bool isSelected,
    Function(RadarView) onViewChanged,
    SoundService soundService,
  ) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: isSelected ? AppTheme.auroraGradient : LinearGradient(
                colors: [Colors.grey.withOpacity(0.3), Colors.grey.withOpacity(0.1)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: (isSelected ? AppTheme.electricAurora : Colors.grey).withOpacity(0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[600],
                size: 20,
              ),
              onPressed: () {
                soundService.playButtonClickSound();
                onViewChanged(view);
              },
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isSelected ? AppTheme.electricAurora : Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedRefreshButton(
    BuildContext context,
    ValueNotifier<bool> isRefreshing,
    VoidCallback onRefresh,
    SoundService soundService,
  ) {
    return AnimatedBuilder(
      animation: isRefreshing.value ? const AlwaysStoppedAnimation(1.0) : const AlwaysStoppedAnimation(0.0),
      builder: (context, child) {
        return Transform.rotate(
          angle: isRefreshing.value ? 2 * pi : 0,
          child: Container(
            decoration: BoxDecoration(
              gradient: AppTheme.auroraGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.electricAurora.withOpacity(0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                isRefreshing.value ? Icons.refresh : Icons.refresh,
                color: Colors.white,
                size: 20,
              ),
              onPressed: isRefreshing.value ? null : () async {
                soundService.playButtonClickSound();
                onRefresh();
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedSettingsButton(
    BuildContext context,
    VoidCallback onSettingsTap,
    SoundService soundService,
  ) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        gradient: AppTheme.auroraGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.purpleAurora.withOpacity(0.4),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: IconButton(
        icon: const Icon(
          Icons.settings,
          color: Colors.white,
          size: 20,
        ),
        onPressed: () {
          soundService.playButtonClickSound();
          onSettingsTap();
        },
      ),
    );
  }

  Widget _buildCurrentView(
    BuildContext context,
    List<NearbyUser> users,
    Function(NearbyUser) onUserTap,
    Function(String) onManualDetection,
    RadarSettings settings,
    bool isRadarEnabled,
    RadarView currentView,
  ) {
    switch (currentView) {
      case RadarView.radar:
        return _buildEnhancedRadarView(context, users, onUserTap, settings, isRadarEnabled);
      case RadarView.list:
        return _buildEnhancedUserList(context, users, onUserTap, onManualDetection, settings);
      case RadarView.map:
        return _buildMapView(context, users, onUserTap, isRadarEnabled);
    }
  }

  Widget _buildEnhancedRadarView(
    BuildContext context,
    List<NearbyUser> users,
    Function(NearbyUser) onUserTap,
    RadarSettings settings,
    bool isRadarEnabled,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.background,
            Theme.of(context).colorScheme.background.withOpacity(0.8),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Enhanced radar widget
            RadarWidget(
              users: users,
              maxRangeKm: settings.detectionRangeKm,
              isScanning: isRadarEnabled,
              onUserTap: onUserTap,
            ),
            const SizedBox(height: 32),
            // Enhanced legend
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppTheme.auroraGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.electricAurora.withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.legend_toggle,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Signal Strength Legend',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildEnhancedLegendItem('Strong', AppTheme.greenAurora, '80-100%'),
                      _buildEnhancedLegendItem('Medium', AppTheme.orangeAurora, '50-80%'),
                      _buildEnhancedLegendItem('Weak', AppTheme.pinkAurora, '20-50%'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedLegendItem(String label, Color color, String range) {
    return Column(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.8),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          range,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedUserList(
    BuildContext context,
    List<NearbyUser> users,
    Function(NearbyUser) onUserTap,
    Function(String) onManualDetection,
    RadarSettings settings,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.background,
            Theme.of(context).colorScheme.background.withOpacity(0.8),
          ],
        ),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 80, 16, 16),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: _buildEnhancedUserCard(context, user, onUserTap, onManualDetection, settings),
          ).animate().fadeIn(
            delay: Duration(milliseconds: index * 150),
            duration: const Duration(milliseconds: 400),
          ).slideY(
            begin: 0.3,
            duration: const Duration(milliseconds: 400),
          );
        },
      ),
    );
  }

  Widget _buildEnhancedUserCard(
    BuildContext context,
    NearbyUser user,
    Function(NearbyUser) onUserTap,
    Function(String) onManualDetection,
    RadarSettings settings,
  ) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surface.withOpacity(0.8),
            ],
          ),
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
              spreadRadius: 0,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: InkWell(
          onTap: () => onUserTap(user),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Enhanced avatar with effects
                Stack(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        gradient: AppTheme.sunsetGradient,
                        borderRadius: BorderRadius.circular(35),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.orangeAurora.withOpacity(0.6),
                            blurRadius: 20,
                            spreadRadius: 3,
                          ),
                          BoxShadow(
                            color: AppTheme.pinkAurora.withOpacity(0.4),
                            blurRadius: 30,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          user.avatar,
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    ),
                    if (user.isOnline)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: AppTheme.greenAurora,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.greenAurora.withOpacity(0.8),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (settings.showSignalStrength)
                      Positioned(
                        left: -3,
                        top: -3,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: _getSignalStrengthColor(user.signalStrength),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: _getSignalStrengthColor(user.signalStrength).withOpacity(0.8),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 20),
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
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: AppTheme.auroraGradient,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.electricAurora.withOpacity(0.4),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Text(
                              '${(user.distanceKm * 1000).round()}m',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        user.interests.join(' • '),
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: user.isOnline ? AppTheme.greenAurora : Colors.grey[400],
                              borderRadius: BorderRadius.circular(5),
                              boxShadow: user.isOnline ? [
                                BoxShadow(
                                  color: AppTheme.greenAurora.withOpacity(0.6),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ] : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            user.isOnline ? 'Online' : 'Offline',
                            style: TextStyle(
                              fontSize: 14,
                              color: user.isOnline ? AppTheme.greenAurora : Colors.grey[500],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (settings.showSignalStrength) ...[
                            const SizedBox(width: 16),
                            Icon(
                              Icons.signal_cellular_alt,
                              size: 16,
                              color: _getSignalStrengthColor(user.signalStrength),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${(user.signalStrength * 100).round()}%',
                              style: TextStyle(
                                fontSize: 12,
                                color: _getSignalStrengthColor(user.signalStrength),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (settings.enableManualDetection && !user.isDetected)
                  Container(
                    decoration: BoxDecoration(
                      gradient: AppTheme.auroraGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.electricAurora.withOpacity(0.4),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.add_circle_outline,
                        color: Colors.white,
                        size: 24,
                      ),
                      onPressed: () => onManualDetection(user.id),
                    ),
                  ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[400],
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMapView(
    BuildContext context,
    List<NearbyUser> users,
    Function(NearbyUser) onUserTap,
    bool isRadarEnabled,
  ) {
    return MapWidget(
      users: users,
      isScanning: isRadarEnabled,
      onUserTap: onUserTap,
    );
  }

  Widget _buildEnhancedStatusIndicator(
    BuildContext context,
    bool isLoading,
    int userCount,
    bool isRefreshing,
    bool isRadarEnabled,
    RadarSettings settings,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: AppTheme.auroraGradient,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: AppTheme.electricAurora.withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: 3,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: AppTheme.pinkAurora.withOpacity(0.3),
            blurRadius: 30,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLoading || isRefreshing) ...[
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.electricAurora.withOpacity(0.8),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              isRefreshing ? 'Refreshing...' : 'Initializing radar...',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ] else if (isRadarEnabled) ...[
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.greenAurora.withOpacity(0.8),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Radar Active (${(settings.detectionRangeKm * 1000).round()}m range)',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.6),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.radar,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Radar Disabled',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: const Duration(milliseconds: 400));
  }

  Widget _buildEnhancedLoadingState(BuildContext context, AnimationController radarController, bool isRadarEnabled) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.background,
            Theme.of(context).colorScheme.background.withOpacity(0.8),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Enhanced animated radar
            AnimatedBuilder(
              animation: radarController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: radarController.value * 2 * pi,
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      gradient: AppTheme.auroraGradient,
                      borderRadius: BorderRadius.circular(125),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.electricAurora.withOpacity(0.6),
                          blurRadius: 30,
                          spreadRadius: 4,
                        ),
                        BoxShadow(
                          color: AppTheme.purpleAurora.withOpacity(0.4),
                          blurRadius: 50,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.radar,
                      color: Colors.white,
                      size: 100,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
            Text(
              isRadarEnabled ? 'Scanning for nearby users...' : 'Initializing radar...',
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isRadarEnabled ? 'This may take a few seconds' : 'Setting up detection system',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedEmptyState(BuildContext context, bool isRadarEnabled) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.background,
            Theme.of(context).colorScheme.background.withOpacity(0.8),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                gradient: AppTheme.auroraGradient,
                borderRadius: BorderRadius.circular(75),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.electricAurora.withOpacity(0.6),
                    blurRadius: 30,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Icon(
                isRadarEnabled ? Icons.people_outline : Icons.radar,
                color: Colors.white,
                size: 80,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              isRadarEnabled ? 'No users found in range' : 'Radar is disabled',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isRadarEnabled ? 'Try increasing the detection range' : 'Enable radar to start detecting users',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTutorialOverlay(BuildContext context, VoidCallback onDismiss) {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: AppTheme.auroraGradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppTheme.electricAurora.withOpacity(0.5),
                blurRadius: 30,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lightbulb,
                color: Colors.white,
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                'Welcome to Radar!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '• Switch between Radar, List, and Map views\n• Enable/disable radar detection\n• Tap users to view details\n• Adjust settings for optimal detection',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onDismiss,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.electricAurora,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text(
                  'Got it!',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedUserDetailsModal(
    BuildContext context,
    NearbyUser user,
    RadarService radarService,
    VoidCallback onClose,
  ) {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: AppTheme.auroraGradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppTheme.electricAurora.withOpacity(0.5),
                blurRadius: 30,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: AppTheme.sunsetGradient,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.orangeAurora.withOpacity(0.6),
                            blurRadius: 15,
                            spreadRadius: 2,
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
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${(user.distanceKm * 1000).round()}m away',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: onClose,
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Interests:',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: user.interests.map((interest) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.electricAurora.withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Text(
                          interest,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )).toList(),
                    ),
                    if (user.signalStrength > 0) ...[
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Icon(
                            Icons.signal_cellular_alt,
                            size: 20,
                            color: _getSignalStrengthColor(user.signalStrength),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Signal: ${(user.signalStrength * 100).round()}%',
                            style: TextStyle(
                              color: _getSignalStrengthColor(user.signalStrength),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Actions
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onClose,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Close'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          onClose();
                          // TODO: Implement chat functionality
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.electricAurora,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          'Start Chat',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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

  Widget _buildEnhancedFloatingActionButton(
    BuildContext context,
    bool isRadarEnabled,
    VoidCallback onToggleRadar,
    SoundService soundService,
  ) {
    return FloatingActionButton.extended(
      onPressed: onToggleRadar,
      backgroundColor: isRadarEnabled ? Colors.red : AppTheme.electricAurora,
      foregroundColor: Colors.white,
      icon: Icon(
        isRadarEnabled ? Icons.radar : Icons.radar,
        color: Colors.white,
        size: 24,
      ),
      label: Text(
        isRadarEnabled ? 'Disable Radar' : 'Enable Radar',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      elevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}

enum RadarView {
  radar,
  list,
  map,
}
