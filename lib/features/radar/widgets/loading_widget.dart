import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'dart:math' as math;

class LoadingWidget extends HookWidget {
  final String message;

  const LoadingWidget({
    super.key,
    this.message = 'Zoeken naar gebruikers...',
  });

  @override
  Widget build(BuildContext context) {
    final animationController = useAnimationController(
      duration: const Duration(seconds: 2),
    );

    final pulseController = useAnimationController(
      duration: const Duration(milliseconds: 1500),
    );

    final fadeController = useAnimationController(
      duration: const Duration(milliseconds: 800),
    );

    final waveController = useAnimationController(
      duration: const Duration(milliseconds: 1200),
    );

    final rotationController = useAnimationController(
      duration: const Duration(seconds: 3),
    );

    // Rotation animation
    final rotationAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: animationController,
        curve: Curves.linear,
      ),
    );

    // Pulse animation
    final pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(
        parent: pulseController,
        curve: Curves.easeInOut,
      ),
    );

    // Fade animation for particles
    final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: fadeController,
        curve: Curves.easeInOut,
      ),
    );

    // Wave animation
    final waveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: waveController,
        curve: Curves.easeInOut,
      ),
    );

    // 3D rotation
    final rotation3D = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(
        parent: rotationController,
        curve: Curves.linear,
      ),
    );

    // Single useEffect to manage all controllers
    useEffect(() {
      // Start all animations
      animationController.repeat();
      pulseController.repeat(reverse: true);
      fadeController.repeat(reverse: true);
      waveController.repeat(reverse: true);
      rotationController.repeat();
      
      // Return cleanup function
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
          fadeController.stop();
          fadeController.dispose();
        } catch (e) {
          // Controller already disposed
        }
        try {
          waveController.stop();
          waveController.dispose();
        } catch (e) {
          // Controller already disposed
        }
        try {
          rotationController.stop();
          rotationController.dispose();
        } catch (e) {
          // Controller already disposed
        }
      };
    }, []);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Outer 3D rotating ring
              AnimatedBuilder(
                animation: rotation3D,
                builder: (context, child) {
                  return Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(rotation3D.value),
                    alignment: Alignment.center,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                            blurRadius: 15,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              
              // Middle pulsing ring with wave effect
              AnimatedBuilder(
                animation: pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: pulseAnimation.value,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                          width: 3,
                        ),
                      ),
                      child: CustomPaint(
                        painter: _WavePainter(
                          color: Theme.of(context).colorScheme.primary,
                          waveAnimation: waveAnimation,
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              // Inner rotating radar
              RotationTransition(
                turns: rotationAnimation,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                      width: 2,
                    ),
                  ),
                  child: CustomPaint(
                    painter: _EnhancedRadarPainter(
                      color: Theme.of(context).colorScheme.primary,
                      pulseAnimation: pulseAnimation,
                      waveAnimation: waveAnimation,
                    ),
                  ),
                ),
              ),
              
              // Inner pulsing circle with 3D effect
              AnimatedBuilder(
                animation: pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: pulseAnimation.value * 0.8,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary.withOpacity(0.4),
                            Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              
              // Center radar icon with 3D glow
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                      blurRadius: 15,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.radar,
                  size: 32,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              
              // Advanced particle system
              ...List.generate(12, (index) {
                return AnimatedBuilder(
                  animation: fadeAnimation,
                  builder: (context, child) {
                    final angle = (index * 30) * math.pi / 180;
                    final radius = 90.0 + (index % 3) * 10;
                    final x = math.cos(angle) * radius;
                    final y = math.sin(angle) * radius;
                    
                    return Positioned(
                      left: 50 + x - 4,
                      top: 50 + y - 4,
                      child: Opacity(
                        opacity: fadeAnimation.value * 0.7,
                        child: Container(
                          width: 6 + (index % 3) * 2,
                          height: 6 + (index % 3) * 2,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Theme.of(context).colorScheme.primary.withOpacity(0.6),
                                Theme.of(context).colorScheme.primary.withOpacity(0.2),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
              
              // Sound wave effect
              AnimatedBuilder(
                animation: waveAnimation,
                builder: (context, child) {
                  return CustomPaint(
                    size: const Size(200, 200),
                    painter: _SoundWavePainter(
                      color: Theme.of(context).colorScheme.primary,
                      waveAnimation: waveAnimation,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // Animated text with typing effect
          AnimatedBuilder(
            animation: fadeAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: fadeAnimation.value,
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            },
          ),
          
          const SizedBox(height: 24),
          
          // Enhanced progress indicator with wave effect
          Container(
            width: 200,
            height: 6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: Colors.grey.shade300,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: AnimatedBuilder(
              animation: pulseAnimation,
              builder: (context, child) {
                return FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: 0.3 + (pulseAnimation.value - 1) * 0.1,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.primary.withOpacity(0.7),
                          Theme.of(context).colorScheme.primary,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
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
}

class _EnhancedRadarPainter extends CustomPainter {
  final Color color;
  final Animation<double> pulseAnimation;
  final Animation<double> waveAnimation;

  _EnhancedRadarPainter({
    required this.color,
    required this.pulseAnimation,
    required this.waveAnimation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Draw concentric circles with pulse effect
    for (int i = 1; i <= 3; i++) {
      final paint = Paint()
        ..color = color.withOpacity(0.3 * pulseAnimation.value)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawCircle(center, radius * (i / 3), paint);
    }

    // Draw enhanced sweep line with glow and wave effect
    final sweepPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    canvas.drawLine(
      center,
      Offset(center.dx, center.dy - radius),
      sweepPaint,
    );

    // Draw additional sweep lines for effect
    for (int i = 1; i <= 3; i++) {
      final angle = (i * 30) * math.pi / 180;
      final endX = center.dx + math.sin(angle) * radius * 0.7;
      final endY = center.dy - math.cos(angle) * radius * 0.7;
      
      final linePaint = Paint()
        ..color = color.withOpacity(0.2 * pulseAnimation.value)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      canvas.drawLine(
        center,
        Offset(endX, endY),
        linePaint,
      );
    }

    // Draw wave effect
    for (int i = 0; i < 8; i++) {
      final waveRadius = radius * (0.3 + (i * 0.1)) * waveAnimation.value;
      final wavePaint = Paint()
        ..color = color.withOpacity(0.1 * (1 - waveAnimation.value))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      canvas.drawCircle(center, waveRadius, wavePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _EnhancedRadarPainter oldDelegate) {
    return oldDelegate.color != color || 
           oldDelegate.pulseAnimation != pulseAnimation ||
           oldDelegate.waveAnimation != waveAnimation;
  }
}

class _WavePainter extends CustomPainter {
  final Color color;
  final Animation<double> waveAnimation;

  _WavePainter({
    required this.color,
    required this.waveAnimation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    // Draw wave effect
    for (int i = 0; i < 4; i++) {
      final waveRadius = radius * (0.2 + (i * 0.2)) * waveAnimation.value;
      final wavePaint = Paint()
        ..color = color.withOpacity(0.2 * (1 - waveAnimation.value))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawCircle(center, waveRadius, wavePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) {
    return oldDelegate.color != color || 
           oldDelegate.waveAnimation != waveAnimation;
  }
}

class _SoundWavePainter extends CustomPainter {
  final Color color;
  final Animation<double> waveAnimation;

  _SoundWavePainter({
    required this.color,
    required this.waveAnimation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw sound wave bars
    for (int i = 0; i < 8; i++) {
      final angle = (i * 45) * math.pi / 180;
      final barLength = 20 + (waveAnimation.value * 30);
      final startX = center.dx + math.cos(angle) * (radius - 30);
      final startY = center.dy + math.sin(angle) * (radius - 30);
      final endX = center.dx + math.cos(angle) * (radius - 30 + barLength);
      final endY = center.dy + math.sin(angle) * (radius - 30 + barLength);

      final barPaint = Paint()
        ..color = color.withOpacity(0.4 * waveAnimation.value)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        barPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SoundWavePainter oldDelegate) {
    return oldDelegate.color != color || 
           oldDelegate.waveAnimation != waveAnimation;
  }
}