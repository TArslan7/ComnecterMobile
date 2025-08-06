import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'dart:math' as math;
import '../models/user_model.dart';
import 'radar_painter.dart';

class RadarWidget extends HookWidget {
  final List<NearbyUser> users;
  final bool isLoading;
  final VoidCallback? onUserTap;
  final double size;

  const RadarWidget({
    super.key,
    required this.users,
    this.isLoading = false,
    this.onUserTap,
    this.size = 300,
  });

  @override
  Widget build(BuildContext context) {
    final animationController = useAnimationController(
      duration: const Duration(seconds: 2),
    );

    final pulseController = useAnimationController(
      duration: const Duration(milliseconds: 2000),
    );

    final userDetectionController = useAnimationController(
      duration: const Duration(milliseconds: 1500),
    );

    final hologramController = useAnimationController(
      duration: const Duration(milliseconds: 3000),
    );

    final scanController = useAnimationController(
      duration: const Duration(milliseconds: 1800),
    );

    final sweepAnimation = Tween<double>(begin: 0, end: 360).animate(
      CurvedAnimation(
        parent: animationController,
        curve: Curves.linear,
      ),
    );

    final pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(
        parent: pulseController,
        curve: Curves.easeInOut,
      ),
    );

    final userDetectionAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: userDetectionController,
        curve: Curves.elasticOut,
      ),
    );

    final hologramAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: hologramController,
        curve: Curves.easeInOut,
      ),
    );

    final scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: scanController,
        curve: Curves.easeInOut,
      ),
    );

    // Manage animation lifecycle properly
    useEffect(() {
      // Start continuous animations
      animationController.repeat();
      pulseController.repeat(reverse: true);
      hologramController.repeat(reverse: true);
      scanController.repeat(reverse: true);
      
      return () {
        // Stop animations before disposing
        try {
          animationController.stop();
          animationController.dispose();
        } catch (e) {
          // Controller already disposed
        }
        try {
          pulseController.stop();
          pulseController.dispose();
        } catch (e) {
          // Controller already disposed
        }
        try {
          userDetectionController.stop();
          userDetectionController.dispose();
        } catch (e) {
          // Controller already disposed
        }
        try {
          hologramController.stop();
          hologramController.dispose();
        } catch (e) {
          // Controller already disposed
        }
        try {
          scanController.stop();
          scanController.dispose();
        } catch (e) {
          // Controller already disposed
        }
      };
    }, []);

    // Separate effect for user detection animation
    useEffect(() {
      if (users.isNotEmpty) {
        // Only trigger if controller is not disposed
        try {
          userDetectionController.forward().then((_) {
            try {
              userDetectionController.reverse();
            } catch (e) {
              // Controller disposed during animation
            }
          });
        } catch (e) {
          // Controller already disposed
        }
      }
      return null; // No cleanup needed for this effect
    }, [users.length]);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Colors.black.withOpacity(0.15),
            Colors.black.withOpacity(0.08),
            Colors.black.withOpacity(0.02),
          ],
          stops: const [0.0, 0.7, 1.0],
        ),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            blurRadius: 25,
            spreadRadius: 8,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Holographic background effect
          AnimatedBuilder(
            animation: hologramAnimation,
            builder: (context, child) {
              return CustomPaint(
                size: Size(size, size),
                painter: _HolographicPainter(
                  color: Theme.of(context).colorScheme.primary,
                  hologramAnimation: hologramAnimation,
                ),
              );
            },
          ),
          
          // Radar display
          CustomPaint(
            size: Size(size, size),
            painter: EnhancedRadarPainter(
              sweepAngle: sweepAnimation.value,
              users: users,
              radarColor: Theme.of(context).colorScheme.primary,
              sweepColor: Theme.of(context).colorScheme.primary,
              userDotColor: Theme.of(context).colorScheme.secondary,
              pulseAnimation: pulseAnimation,
              userDetectionAnimation: userDetectionAnimation,
            ),
          ),
          
          // Scan line effect
          AnimatedBuilder(
            animation: scanAnimation,
            builder: (context, child) {
              return CustomPaint(
                size: Size(size, size),
                painter: _ScanLinePainter(
                  color: Theme.of(context).colorScheme.primary,
                  scanAnimation: scanAnimation,
                ),
              );
            },
          ),
          
          // Animated outer ring with holographic effect
          AnimatedBuilder(
            animation: pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: pulseAnimation.value,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                ),
              );
            },
          ),
          
          // Loading overlay with enhanced animation
          if (isLoading)
            AnimatedBuilder(
              animation: pulseAnimation,
              builder: (context, child) {
                return Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.5 * pulseAnimation.value),
                  ),
                  child: Center(
                    child: Transform.scale(
                      scale: pulseAnimation.value,
                      child: CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.primary,
                        strokeWidth: 4,
                      ),
                    ),
                  ),
                );
              },
            ),
          
          // Enhanced distance labels with holographic effect
          _buildEnhancedDistanceLabels(context),
          
          // User count indicator with holographic effect
          if (users.isNotEmpty)
            Positioned(
              top: 10,
              right: 10,
              child: AnimatedBuilder(
                animation: userDetectionAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 0.8 + (userDetectionAnimation.value * 0.2),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary.withOpacity(0.9),
                            Theme.of(context).colorScheme.primary.withOpacity(0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.people,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${users.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          
          // Interactive center button
          Positioned(
            bottom: 10,
            right: 10,
            child: AnimatedBuilder(
              animation: pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: pulseAnimation.value * 0.9,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary.withOpacity(0.8),
                          Theme.of(context).colorScheme.primary.withOpacity(0.4),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: () {
                        // Add interaction feedback
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Radar geoptimaliseerd'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.settings,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedDistanceLabels(BuildContext context) {
    final radius = size / 2 - 20;
    final center = size / 2;
    
    return Stack(
      children: [
        // 1km label with holographic effect
        _buildHolographicLabel(
          context,
          center - 12,
          center - (radius * 0.25) - 12,
          '1km',
          Colors.green,
        ),
        // 3km label with holographic effect
        _buildHolographicLabel(
          context,
          center - 12,
          center - (radius * 0.75) - 12,
          '3km',
          Colors.orange,
        ),
        // 5km label with holographic effect
        _buildHolographicLabel(
          context,
          center - 12,
          center - radius - 12,
          '5km',
          Colors.red,
        ),
      ],
    );
  }

  Widget _buildHolographicLabel(
    BuildContext context,
    double left,
    double top,
    String text,
    Color color,
  ) {
    return Positioned(
      left: left,
      top: top,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.9),
              color.withOpacity(0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withOpacity(0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _HolographicPainter extends CustomPainter {
  final Color color;
  final Animation<double> hologramAnimation;

  _HolographicPainter({
    required this.color,
    required this.hologramAnimation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw holographic grid
    for (int i = 0; i < 8; i++) {
      final angle = (i * 45) * math.pi / 180;
      final endX = center.dx + math.cos(angle) * radius;
      final endY = center.dy + math.sin(angle) * radius;

      final gridPaint = Paint()
        ..color = color.withOpacity(0.1 * hologramAnimation.value)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);

      canvas.drawLine(center, Offset(endX, endY), gridPaint);
    }

    // Draw holographic circles
    for (int i = 1; i <= 3; i++) {
      final circleRadius = radius * (i / 4);
      final circlePaint = Paint()
        ..color = color.withOpacity(0.05 * hologramAnimation.value)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      canvas.drawCircle(center, circleRadius, circlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _HolographicPainter oldDelegate) {
    return oldDelegate.color != color || 
           oldDelegate.hologramAnimation != hologramAnimation;
  }
}

class _ScanLinePainter extends CustomPainter {
  final Color color;
  final Animation<double> scanAnimation;

  _ScanLinePainter({
    required this.color,
    required this.scanAnimation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw scanning line
    final scanAngle = scanAnimation.value * 2 * math.pi;
    final endX = center.dx + math.cos(scanAngle) * radius;
    final endY = center.dy + math.sin(scanAngle) * radius;

    final scanPaint = Paint()
      ..color = color.withOpacity(0.3 * scanAnimation.value)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    canvas.drawLine(center, Offset(endX, endY), scanPaint);

    // Draw scan pulse
    final pulseRadius = radius * scanAnimation.value;
    final pulsePaint = Paint()
      ..color = color.withOpacity(0.1 * (1 - scanAnimation.value))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawCircle(center, pulseRadius, pulsePaint);
  }

  @override
  bool shouldRepaint(covariant _ScanLinePainter oldDelegate) {
    return oldDelegate.color != color || 
           oldDelegate.scanAnimation != scanAnimation;
  }
}