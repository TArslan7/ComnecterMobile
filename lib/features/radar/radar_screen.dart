import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'dart:async';
import 'dart:math';
import '../../services/sound_service.dart';
import '../../theme/app_theme.dart';
import 'models/user_model.dart';
import 'services/radar_service.dart';
import 'widgets/radar_widget.dart';
import 'widgets/radar_settings_widget.dart';
import 'widgets/map_widget.dart';

class RadarScreen extends HookWidget {
  const RadarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final radarService = useMemoized(() => RadarService());
    final nearbyUsers = useState<List<NearbyUser>>([]);
    final isLoading = useState(true);
    final isRadarEnabled = useState(true);
    final showSettings = useState(false);
    final currentView = useState<RadarView>(RadarView.radar);
    final confettiController = useMemoized(() => ConfettiController(duration: const Duration(seconds: 3)));
    final soundService = useMemoized(() => SoundService());
    final settings = useState<RadarSettings>(const RadarSettings());
    final showTutorial = useState(true);
    final selectedUser = useState<NearbyUser?>(null);
    final showUserDetails = useState(false);

    // Initialize radar service
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.background,
              Theme.of(context).colorScheme.background.withOpacity(0.95),
              Theme.of(context).colorScheme.background.withOpacity(0.9),
            ],
            stops: const [0.0, 0.7, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Main content
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.1),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    )),
                    child: child,
                  ),
                );
              },
              child: isLoading.value
                  ? _buildPerfectLoadingState(context, isRadarEnabled.value)
                  : nearbyUsers.value.isEmpty
                      ? _buildPerfectEmptyState(context, isRadarEnabled.value)
                      : _buildCurrentView(context, nearbyUsers.value, handleUserTap, handleManualDetection, settings.value, isRadarEnabled.value, currentView.value),
            ),
            
            // Perfect status indicator
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              right: 16,
              child: _buildPerfectStatusIndicator(context, isLoading.value, nearbyUsers.value.length, isRadarEnabled.value, settings.value),
            ),
            
            // Perfect settings overlay
            if (showSettings.value)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.8),
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
              ).animate().fadeIn(duration: const Duration(milliseconds: 500)),
            
            // Perfect confetti overlay
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: confettiController,
                blastDirection: pi / 2,
                maxBlastForce: 10,
                minBlastForce: 4,
                emissionFrequency: 0.02,
                numberOfParticles: 100,
                gravity: 0.06,
                colors: [
                  AppTheme.electricAurora,
                  AppTheme.purpleAurora,
                  AppTheme.pinkAurora,
                  AppTheme.orangeAurora,
                  AppTheme.greenAurora,
                ],
              ),
            ),

            // Perfect tutorial overlay
            if (showTutorial.value)
              _buildPerfectTutorialOverlay(context, () => showTutorial.value = false),

            // Perfect user details modal
            if (showUserDetails.value && selectedUser.value != null)
              _buildPerfectUserDetailsModal(context, selectedUser.value!, radarService, () {
                showUserDetails.value = false;
                selectedUser.value = null;
              }),
          ],
        ),
      ),
      floatingActionButton: _buildPerfectFloatingActionButton(
        context,
        isRadarEnabled.value,
        handleToggleRadar,
        soundService,
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
        return _buildPerfectRadarView(context, users, onUserTap, settings, isRadarEnabled);
      case RadarView.list:
        return _buildPerfectUserList(context, users, onUserTap, onManualDetection, settings);
      case RadarView.map:
        return _buildMapView(context, users, onUserTap, isRadarEnabled);
    }
  }

  Widget _buildPerfectRadarView(
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
      child: Column(
        children: [
          const SizedBox(height: 100),
          // Perfect radar widget
          RadarWidget(
            users: users,
            maxRangeKm: settings.detectionRangeKm,
            isScanning: isRadarEnabled,
            onUserTap: onUserTap,
          ),
          const SizedBox(height: 40),
          // Perfect legend
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppTheme.auroraGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.electricAurora.withOpacity(0.5),
                  blurRadius: 25,
                  spreadRadius: 5,
                ),
                BoxShadow(
                  color: AppTheme.purpleAurora.withOpacity(0.3),
                  blurRadius: 35,
                  spreadRadius: 2,
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
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Signal Strength Legend',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildPerfectLegendItem('Strong', AppTheme.greenAurora, '80-100%'),
                    _buildPerfectLegendItem('Medium', AppTheme.orangeAurora, '50-80%'),
                    _buildPerfectLegendItem('Weak', AppTheme.pinkAurora, '20-50%'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerfectLegendItem(String label, Color color, String range) {
    return Column(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.8),
                blurRadius: 12,
                spreadRadius: 3,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          range,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPerfectUserList(
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
        padding: const EdgeInsets.fromLTRB(16, 100, 16, 16),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 20),
            child: _buildPerfectUserCard(context, user, onUserTap, onManualDetection, settings),
          ).animate().fadeIn(
            delay: Duration(milliseconds: index * 200),
            duration: const Duration(milliseconds: 500),
          ).slideY(
            begin: 0.3,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
          );
        },
      ),
    );
  }

  Widget _buildPerfectUserCard(
    BuildContext context,
    NearbyUser user,
    Function(NearbyUser) onUserTap,
    Function(String) onManualDetection,
    RadarSettings settings,
  ) {
    return Card(
      elevation: 12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
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
              color: AppTheme.electricAurora.withOpacity(0.4),
              blurRadius: 25,
              spreadRadius: 3,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: AppTheme.purpleAurora.withOpacity(0.3),
              blurRadius: 35,
              spreadRadius: 0,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: InkWell(
          onTap: () => onUserTap(user),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                // Perfect avatar with effects
                Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: AppTheme.sunsetGradient,
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.orangeAurora.withOpacity(0.7),
                            blurRadius: 25,
                            spreadRadius: 4,
                          ),
                          BoxShadow(
                            color: AppTheme.pinkAurora.withOpacity(0.5),
                            blurRadius: 35,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          user.avatar,
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
                    ),
                    if (user.isOnline)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppTheme.greenAurora,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.greenAurora.withOpacity(0.9),
                                blurRadius: 12,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (settings.showSignalStrength)
                      Positioned(
                        left: -4,
                        top: -4,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: _getSignalStrengthColor(user.signalStrength),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: _getSignalStrengthColor(user.signalStrength).withOpacity(0.9),
                                blurRadius: 10,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 24),
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
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: AppTheme.auroraGradient,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.electricAurora.withOpacity(0.5),
                                  blurRadius: 12,
                                  spreadRadius: 3,
                                ),
                              ],
                            ),
                            child: Text(
                              '${(user.distanceKm * 1000).round()}m',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user.interests.join(' • '),
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: user.isOnline ? AppTheme.greenAurora : Colors.grey[400],
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: user.isOnline ? [
                                BoxShadow(
                                  color: AppTheme.greenAurora.withOpacity(0.7),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ] : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            user.isOnline ? 'Online' : 'Offline',
                            style: TextStyle(
                              fontSize: 16,
                              color: user.isOnline ? AppTheme.greenAurora : Colors.grey[500],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (settings.showSignalStrength) ...[
                            const SizedBox(width: 20),
                            Icon(
                              Icons.signal_cellular_alt,
                              size: 18,
                              color: _getSignalStrengthColor(user.signalStrength),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${(user.signalStrength * 100).round()}%',
                              style: TextStyle(
                                fontSize: 14,
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
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.electricAurora.withOpacity(0.5),
                          blurRadius: 12,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.add_circle_outline,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () => onManualDetection(user.id),
                    ),
                  ),
                const SizedBox(width: 12),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[400],
                  size: 20,
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

  Widget _buildPerfectStatusIndicator(
    BuildContext context,
    bool isLoading,
    int userCount,
    bool isRadarEnabled,
    RadarSettings settings,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        gradient: AppTheme.auroraGradient,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppTheme.electricAurora.withOpacity(0.6),
            blurRadius: 25,
            spreadRadius: 4,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AppTheme.pinkAurora.withOpacity(0.4),
            blurRadius: 35,
            spreadRadius: 3,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLoading) ...[
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.electricAurora.withOpacity(0.9),
                    blurRadius: 12,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: const CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              'Initializing radar...',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ] else if (isRadarEnabled) ...[
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.greenAurora.withOpacity(0.9),
                    blurRadius: 12,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: const CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              'Radar Active (${(settings.detectionRangeKm * 1000).round()}m range)',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.7),
                    blurRadius: 12,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: const Icon(
                Icons.radar,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              'Radar Disabled',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: const Duration(milliseconds: 500));
  }

  Widget _buildPerfectLoadingState(BuildContext context, bool isRadarEnabled) {
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
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                gradient: AppTheme.auroraGradient,
                borderRadius: BorderRadius.circular(150),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.electricAurora.withOpacity(0.7),
                    blurRadius: 40,
                    spreadRadius: 5,
                  ),
                  BoxShadow(
                    color: AppTheme.purpleAurora.withOpacity(0.5),
                    blurRadius: 60,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: const Icon(
                Icons.radar,
                color: Colors.white,
                size: 120,
              ),
            ),
            const SizedBox(height: 50),
            Text(
              isRadarEnabled ? 'Scanning for nearby users...' : 'Initializing radar...',
              style: TextStyle(
                fontSize: 24,
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isRadarEnabled ? 'This may take a few seconds' : 'Setting up detection system',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerfectEmptyState(BuildContext context, bool isRadarEnabled) {
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
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                gradient: AppTheme.auroraGradient,
                borderRadius: BorderRadius.circular(100),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.electricAurora.withOpacity(0.7),
                    blurRadius: 40,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                isRadarEnabled ? Icons.people_outline : Icons.radar,
                color: Colors.white,
                size: 100,
              ),
            ),
            const SizedBox(height: 40),
            Text(
              isRadarEnabled ? 'No users found in range' : 'Radar is disabled',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
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

  Widget _buildPerfectTutorialOverlay(BuildContext context, VoidCallback onDismiss) {
    return Container(
      color: Colors.black.withOpacity(0.9),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: AppTheme.auroraGradient,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: AppTheme.electricAurora.withOpacity(0.6),
                blurRadius: 40,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lightbulb,
                color: Colors.white,
                size: 64,
              ),
              const SizedBox(height: 24),
              const Text(
                'Welcome to Radar!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '• Switch between Radar, List, and Map views\n• Enable/disable radar detection\n• Tap users to view details\n• Adjust settings for optimal detection',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: onDismiss,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.electricAurora,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text(
                  'Got it!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPerfectUserDetailsModal(
    BuildContext context,
    NearbyUser user,
    RadarService radarService,
    VoidCallback onClose,
  ) {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: AppTheme.auroraGradient,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: AppTheme.electricAurora.withOpacity(0.6),
                blurRadius: 40,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(32),
                child: Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: AppTheme.sunsetGradient,
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.orangeAurora.withOpacity(0.7),
                            blurRadius: 20,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          user.avatar,
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${(user.distanceKm * 1000).round()}m away',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 16,
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
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Interests:',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: user.interests.map((interest) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.electricAurora.withOpacity(0.4),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Text(
                          interest,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )).toList(),
                    ),
                    if (user.signalStrength > 0) ...[
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Icon(
                            Icons.signal_cellular_alt,
                            size: 24,
                            color: _getSignalStrengthColor(user.signalStrength),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Signal: ${(user.signalStrength * 100).round()}%',
                            style: TextStyle(
                              color: _getSignalStrengthColor(user.signalStrength),
                              fontSize: 18,
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
                padding: const EdgeInsets.all(32),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onClose,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Close'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          onClose();
                          // TODO: Implement chat functionality
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.electricAurora,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

  Widget _buildPerfectFloatingActionButton(
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
        size: 28,
      ),
      label: Text(
        isRadarEnabled ? 'Disable Radar' : 'Enable Radar',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      elevation: 16,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
    );
  }
}

enum RadarView {
  radar,
  list,
  map,
}
