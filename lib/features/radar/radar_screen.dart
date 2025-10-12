import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'dart:math';
import 'services/radar_service.dart';
import 'models/user_model.dart';
import 'widgets/radar_range_slider.dart';

class RadarScreen extends HookWidget {
  final bool? isDetectableParam;
  
  const RadarScreen({super.key, this.isDetectableParam});

  @override
  Widget build(BuildContext context) {
    final heartbeatController = useAnimationController(
      duration: const Duration(milliseconds: 800),
    );
    final radarController = useAnimationController(
      duration: const Duration(milliseconds: 1200),
    );
    
    // Radar service integration
    final radarService = useMemoized(() => RadarService(), []);
    final detectedUsers = useState<List<NearbyUser>>([]);
    final rangeSettings = useState<RadarRangeSettings>(const RadarRangeSettings(rangeKm: 1.0));
    
    // Real-time privacy settings feedback
    final currentRange = useState(1.0);
    final displayRange = useState(1.0); // Range displayed in UI (only updates after save)
    final displayUnit = useState(false); // Unit displayed in UI (only updates after save)
    final pendingRange = useState(1.0); // Range that user is adjusting (not yet saved)
    final hasPendingChanges = useState(false); // Track if there are unsaved changes
    final isDetectable = useState(isDetectableParam ?? true);

    useEffect(() {
      // Initialize services (RadarService will initialize DetectionHistoryService)
      radarService.initialize().then((_) {
        // Initialize privacy settings
        currentRange.value = radarService.getCurrentRange();
        displayRange.value = currentRange.value; // Set display range to current range
        displayUnit.value = rangeSettings.value.useMiles; // Set display unit to current unit
        pendingRange.value = currentRange.value; // Set pending range to current range
        isDetectable.value = radarService.getDetectabilityStatus();
        // Initialize range settings with current range
        rangeSettings.value = rangeSettings.value.copyWith(rangeKm: currentRange.value);
      });
      
      // Listen to detected users
      final subscription = radarService.usersStream.listen((users) {
        detectedUsers.value = users.where((user) => user.isDetected).toList();
        // Update privacy settings from radar service
        currentRange.value = radarService.getCurrentRange();
        displayRange.value = currentRange.value; // Update display range
        displayUnit.value = rangeSettings.value.useMiles; // Update display unit
        // Only update pending range if there are no pending changes
        if (!hasPendingChanges.value) {
          pendingRange.value = currentRange.value; // Update pending range
        }
        isDetectable.value = radarService.getDetectabilityStatus();
        // Update range settings to reflect current state
        rangeSettings.value = rangeSettings.value.copyWith(rangeKm: currentRange.value);
      });


      // Start scanning initially if visible
      if (isDetectable.value) {
        radarService.startScanning();
      }

      return () {
        subscription.cancel();
        radarService.stopScanning();
      };
    }, []);

    // Save range changes function
    void saveRangeChanges() {
      // Update the range settings with pending range
      rangeSettings.value = rangeSettings.value.copyWith(rangeKm: pendingRange.value);
      // Apply the changes to radar service
      radarService.updateRangeSettings(rangeSettings.value);
      // Update display range and unit to show saved values
      displayRange.value = pendingRange.value;
      displayUnit.value = rangeSettings.value.useMiles;
      // Clear pending changes
      hasPendingChanges.value = false;
    }

    useEffect(() {
      if (isDetectable.value) {
        radarService.startScanning();
        heartbeatController.repeat();
        radarController.repeat();
      } else {
        radarService.stopScanning();
        heartbeatController.stop();
        radarController.stop();
      }
      return null;
    }, [isDetectable.value]);

    return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
                        colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surface.withValues(alpha: 0.3),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Main Radar Circle
              Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Stack(
                  children: [
                    // Expanding radar rings
                    ...List.generate(3, (index) {
                      return AnimatedBuilder(
                        animation: radarController,
                        builder: (context, child) {
                          final progress = (radarController.value + index * 0.3) % 1.0;
                          final radius = 140 * progress;
                          final opacity = (1.0 - progress) * 0.8;
                          
                          return Positioned(
                            left: 140 - radius,
                            top: 140 - radius,
                            child: Container(
                              width: radius * 2,
                              height: radius * 2,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.primary.withValues(alpha: opacity),
                                  width: 1.5,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    }),
                    
                    // Central pulsing radar core
                    Center(
                      child: AnimatedBuilder(
                        animation: heartbeatController,
                        builder: (context, child) {
                          final opacity = 0.7 + (heartbeatController.value * 0.3);
                          
                          return Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Theme.of(context).colorScheme.primary.withValues(alpha: opacity),
                                  Theme.of(context).colorScheme.primary.withValues(alpha: opacity * 0.5),
                                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.radar,
                              color: Theme.of(context).colorScheme.onPrimary,
                              size: 25,
                            ),
                          );
                        },
                      ),
                    ),
                    
                    // Scanning indicator dots
                    ...List.generate(8, (index) {
                      return AnimatedBuilder(
                        animation: radarController,
                        builder: (context, child) {
                          final progress = (radarController.value + index * 0.125) % 1.0;
                          final angle = index * (3.14159 / 4); // 45 degrees apart
                          final radius = 110 * progress;
                          final x = 140 + (radius * cos(angle));
                          final y = 140 + (radius * sin(angle));
                          final opacity = (1.0 - progress) * 0.9;
                          
                          return Positioned(
                            left: x - 3,
                            top: y - 3,
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Theme.of(context).colorScheme.secondary.withValues(alpha: opacity),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context).colorScheme.secondary.withValues(alpha: opacity * 0.5),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    }),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Status text
              Text(
                isDetectable.value ? 'Scanning for connections...' : 'Radar hidden - not detecting others',
                style: TextStyle(
                  fontSize: 16,
                  color: isDetectable.value 
                      ? Theme.of(context).colorScheme.onSurface
                      : Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Connection status
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDetectable.value 
                          ? Colors.green.shade600 
                          : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isDetectable.value ? 'Visible' : 'Hidden',
                      style: TextStyle(
                        color: isDetectable.value 
                          ? Colors.green.shade700 
                          : Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Real-time Privacy Settings Feedback
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Range Display
                    Row(
                      children: [
                        Icon(
                          Icons.radar,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          rangeSettings.value.copyWith(rangeKm: displayRange.value, useMiles: displayUnit.value).getDisplayValue(),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    
                    // Divider
                    Container(
                      width: 1,
                      height: 20,
                      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                    ),
                    
                    // Detection Ability Status
                    Row(
                      children: [
                        Icon(
                          isDetectable.value ? Icons.radar : Icons.radar_outlined,
                          size: 16,
                          color: isDetectable.value 
                              ? Colors.blue.shade600 
                              : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isDetectable.value ? 'Detecting' : 'Not Detecting',
                          style: TextStyle(
                            color: isDetectable.value 
                                ? Colors.blue.shade700 
                                : Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 25),
              
              // Range Slider
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: RadarRangeSlider(
                  settings: rangeSettings.value.copyWith(rangeKm: pendingRange.value),
                  onChanged: (newSettings) {
                    // Update pending range and mark as having changes
                    pendingRange.value = newSettings.rangeKm;
                    hasPendingChanges.value = true;
                    // Update range settings to reflect unit changes
                    rangeSettings.value = newSettings;
                  },
                  userCount: detectedUsers.value.length,
                ),
              ),
              
              // Save Range Button
              if (hasPendingChanges.value) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: saveRangeChanges,
                          icon: const Icon(Icons.save, size: 18),
                          label: Text(
                            'Update Range to ${rangeSettings.value.copyWith(rangeKm: pendingRange.value).getDisplayValue()}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 25),
              
              // Quick info: Detected users count
              if (detectedUsers.value.isNotEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_pin_circle,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${detectedUsers.value.length} ${detectedUsers.value.length == 1 ? 'user' : 'users'} detected',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '• Go to Scroll View to see list',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
    );
  }
}
