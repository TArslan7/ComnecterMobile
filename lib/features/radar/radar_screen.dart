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
      return () {};
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

    void handleToggleRadar() {
      if (isRadarEnabled.value) {
        isRadarEnabled.value = false;
        soundService.playButtonClickSound();
        radarService.stopScanning();
      } else {
        isRadarEnabled.value = true;
        isLoading.value = true;
        soundService.playButtonClickSound();
        radarService.updateSettings(settings.value);
        radarService.startScanning();
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
      backgroundColor: AppTheme.backgroundLight,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.backgroundLight,
              AppTheme.backgroundLight.withOpacity(0.95),
              AppTheme.backgroundLight.withOpacity(0.9),
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
                  ? _buildLoadingState(context, isRadarEnabled.value)
                  : nearbyUsers.value.isEmpty
                      ? _buildEmptyState(context, isRadarEnabled.value)
                      : _buildCurrentView(context, nearbyUsers.value, handleUserTap, handleManualDetection, settings.value, isRadarEnabled.value, currentView.value),
            ),
            
            // Status indicator
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              right: 16,
              child: _buildStatusIndicator(context, isLoading.value, nearbyUsers.value.length, isRadarEnabled.value, settings.value),
            ),
            
            // Settings overlay
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
            
            // Confetti overlay
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
                  AppTheme.primary,
                  AppTheme.secondary,
                  AppTheme.success,
                  AppTheme.warning,
                  AppTheme.error,
                ],
              ),
            ),

            // Tutorial overlay
            if (showTutorial.value)
              _buildTutorialOverlay(context, () => showTutorial.value = false),

            // User details modal
            if (showUserDetails.value && selectedUser.value != null)
              _buildUserDetailsModal(context, selectedUser.value!, radarService, () {
                showUserDetails.value = false;
                selectedUser.value = null;
              }),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(
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
        return _buildRadarView(context, users, onUserTap, settings, isRadarEnabled);
      case RadarView.list:
        return _buildUserList(context, users, onUserTap, onManualDetection, settings);
      case RadarView.map:
        return _buildMapView(context, users, onUserTap, isRadarEnabled);
    }
  }

  Widget _buildRadarView(
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
            AppTheme.backgroundLight,
            AppTheme.backgroundLight.withOpacity(0.8),
          ],
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 100),
          // Radar widget
          RadarWidget(
            users: users,
            maxRangeKm: settings.detectionRangeKm,
            isScanning: isRadarEnabled,
            onUserTap: onUserTap,
          ),
          const SizedBox(height: 40),
          // Legend
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.5),
                  blurRadius: 25,
                  spreadRadius: 5,
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
                    _buildLegendItem('Strong', AppTheme.success, '80-100%'),
                    _buildLegendItem('Medium', AppTheme.warning, '50-80%'),
                    _buildLegendItem('Weak', AppTheme.error, '20-50%'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, String range) {
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

  Widget _buildUserList(
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
            AppTheme.backgroundLight,
            AppTheme.backgroundLight.withOpacity(0.8),
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
            child: _buildUserCard(context, user, onUserTap, onManualDetection, settings),
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

  Widget _buildUserCard(
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
              AppTheme.surfaceLight,
              AppTheme.surfaceLight.withOpacity(0.8),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withOpacity(0.4),
              blurRadius: 25,
              spreadRadius: 3,
              offset: const Offset(0, 10),
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
                // Avatar with effects
                Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withOpacity(0.7),
                            blurRadius: 25,
                            spreadRadius: 4,
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
                            color: AppTheme.success,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.success.withOpacity(0.9),
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
                            color: user.signalStrengthColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: user.signalStrengthColor.withOpacity(0.9),
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
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primary.withOpacity(0.5),
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
                      if (settings.showInterests && user.interests.isNotEmpty)
                        Text(
                          user.interests.join(' • '),
                          style: TextStyle(
                            fontSize: 18,
                            color: AppTheme.textMedium,
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
                              color: user.isOnline ? AppTheme.success : AppTheme.textMedium,
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: user.isOnline ? [
                                BoxShadow(
                                  color: AppTheme.success.withOpacity(0.7),
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
                              color: user.isOnline ? AppTheme.success : AppTheme.textMedium,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (settings.showSignalStrength) ...[
                            const SizedBox(width: 20),
                            Icon(
                              Icons.signal_cellular_alt,
                              size: 18,
                              color: user.signalStrengthColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${(user.signalStrength * 100).round()}%',
                              style: TextStyle(
                                fontSize: 14,
                                color: user.signalStrengthColor,
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
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withOpacity(0.5),
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
                  color: AppTheme.textMedium,
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.map,
            size: 80,
            color: AppTheme.primary,
          ),
          const SizedBox(height: 20),
          Text(
            'Map View',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Map integration coming soon...',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(
    BuildContext context,
    bool isLoading,
    int userCount,
    bool isRadarEnabled,
    RadarSettings settings,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.6),
            blurRadius: 25,
            spreadRadius: 4,
            offset: const Offset(0, 8),
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
                    color: AppTheme.primary.withOpacity(0.9),
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
                    color: AppTheme.success.withOpacity(0.9),
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
                    color: AppTheme.error.withOpacity(0.7),
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

  Widget _buildLoadingState(BuildContext context, bool isRadarEnabled) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.backgroundLight,
            AppTheme.backgroundLight.withOpacity(0.8),
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
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(150),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.7),
                    blurRadius: 40,
                    spreadRadius: 5,
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
                color: AppTheme.textDark,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isRadarEnabled ? 'This may take a few seconds' : 'Setting up detection system',
              style: TextStyle(
                fontSize: 18,
                color: AppTheme.textMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isRadarEnabled) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.backgroundLight,
            AppTheme.backgroundLight.withOpacity(0.8),
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
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(100),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.7),
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
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isRadarEnabled ? 'Try increasing the detection range' : 'Enable radar to start detecting users',
              style: TextStyle(
                fontSize: 18,
                color: AppTheme.textMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTutorialOverlay(BuildContext context, VoidCallback onDismiss) {
    return Container(
      color: Colors.black.withOpacity(0.9),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.6),
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
                  foregroundColor: AppTheme.primary,
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

  Widget _buildUserDetailsModal(
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
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.6),
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
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withOpacity(0.7),
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
                              color: AppTheme.primary.withOpacity(0.4),
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
                            color: user.signalStrengthColor,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Signal: ${(user.signalStrength * 100).round()}%',
                            style: TextStyle(
                              color: user.signalStrengthColor,
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
                          foregroundColor: AppTheme.primary,
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

  Widget _buildFloatingActionButton(
    BuildContext context,
    bool isRadarEnabled,
    VoidCallback onToggleRadar,
    SoundService soundService,
  ) {
    return FloatingActionButton.extended(
      onPressed: onToggleRadar,
      backgroundColor: isRadarEnabled ? AppTheme.error : AppTheme.primary,
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
    final settings = useState(currentSettings);

    void updateSettings(RadarSettings newSettings) {
      settings.value = newSettings;
      onSettingsChanged(newSettings);
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.settings,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Radar Settings',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildSliderSetting(
                  context,
                  'Detection Range',
                  '${(settings.value.detectionRangeKm * 1000).round()}m',
                  settings.value.detectionRangeKm,
                  0.5,
                  5.0,
                  (value) => updateSettings(settings.value.copyWith(detectionRangeKm: value)),
                ),
                const SizedBox(height: 20),
                _buildSliderSetting(
                  context,
                  'Scan Interval',
                  '${settings.value.scanIntervalMs}ms',
                  settings.value.scanIntervalMs.toDouble(),
                  1000,
                  10000,
                  (value) => updateSettings(settings.value.copyWith(scanIntervalMs: value.toInt())),
                ),
                const SizedBox(height: 20),
                _buildToggleSetting(
                  'Auto Detection',
                  'Automatically detect nearby users',
                  settings.value.enableAutoDetection,
                  (value) => updateSettings(settings.value.copyWith(enableAutoDetection: value)),
                ),
                const SizedBox(height: 16),
                _buildToggleSetting(
                  'Manual Detection',
                  'Allow manual user detection',
                  settings.value.enableManualDetection,
                  (value) => updateSettings(settings.value.copyWith(enableManualDetection: value)),
                ),
                const SizedBox(height: 16),
                _buildToggleSetting(
                  'Sound Effects',
                  'Play sound on detection',
                  settings.value.enableSound,
                  (value) => updateSettings(settings.value.copyWith(enableSound: value)),
                ),
                const SizedBox(height: 16),
                _buildToggleSetting(
                  'Vibration',
                  'Vibrate on detection',
                  settings.value.enableVibration,
                  (value) => updateSettings(settings.value.copyWith(enableVibration: value)),
                ),
                const SizedBox(height: 16),
                _buildToggleSetting(
                  'Signal Strength',
                  'Show signal strength indicators',
                  settings.value.showSignalStrength,
                  (value) => updateSettings(settings.value.copyWith(showSignalStrength: value)),
                ),
                const SizedBox(height: 16),
                _buildToggleSetting(
                  'Online Status',
                  'Show online/offline status',
                  settings.value.showOnlineStatus,
                  (value) => updateSettings(settings.value.copyWith(showOnlineStatus: value)),
                ),
                const SizedBox(height: 16),
                _buildToggleSetting(
                  'User Interests',
                  'Show user interests',
                  settings.value.showInterests,
                  (value) => updateSettings(settings.value.copyWith(showInterests: value)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderSetting(
    BuildContext context,
    String title,
    String value,
    double currentValue,
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
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textMedium,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppTheme.primary,
            inactiveTrackColor: AppTheme.textMedium.withOpacity(0.3),
            thumbColor: AppTheme.primary,
            overlayColor: AppTheme.primary.withOpacity(0.2),
          ),
          child: Slider(
            value: currentValue,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildToggleSetting(
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
                  color: AppTheme.textDark,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textMedium,
                ),
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
}
