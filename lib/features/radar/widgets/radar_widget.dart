import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math';
import '../../../theme/app_theme.dart';
import '../models/user_model.dart';

class RadarWidget extends HookWidget {
  final List<NearbyUser> users;
  final double maxRangeKm;
  final bool isScanning;
  final Function(NearbyUser)? onUserTap;

  const RadarWidget({
    super.key,
    required this.users,
    required this.maxRangeKm,
    required this.isScanning,
    this.onUserTap,
  });

  @override
  Widget build(BuildContext context) {
    final scanAnimation = useAnimationController(duration: const Duration(seconds: 2));
    final rotationAnimation = useAnimationController(duration: const Duration(seconds: 10));
    final pulseAnimation = useAnimationController(duration: const Duration(seconds: 1));
    final userPulseAnimation = useAnimationController(duration: const Duration(milliseconds: 1500));

    useEffect(() {
      if (isScanning) {
        scanAnimation.repeat();
        rotationAnimation.repeat();
        pulseAnimation.repeat();
        userPulseAnimation.repeat();
      } else {
        scanAnimation.stop();
        rotationAnimation.stop();
        pulseAnimation.stop();
        userPulseAnimation.stop();
      }
      return null;
    }, [isScanning]);

    return Container(
      width: 300,
      height: 300,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Radar background with multiple layers
          CustomPaint(
            size: const Size(300, 300),
            painter: RadarBackgroundPainter(
              maxRangeKm: maxRangeKm,
              isScanning: isScanning,
            ),
          ),
          
          // Scanning animation with enhanced effects
          if (isScanning)
            AnimatedBuilder(
              animation: scanAnimation,
              builder: (context, child) {
                return CustomPaint(
                  size: const Size(300, 300),
                  painter: RadarScanPainter(
                    progress: scanAnimation.value,
                    maxRangeKm: maxRangeKm,
                  ),
                );
              },
            ),
          
          // User dots with animations
          ...users.map((user) => _buildUserDot(user, userPulseAnimation)),
          
          // Center indicator with pulse effect
          AnimatedBuilder(
            animation: pulseAnimation,
            builder: (context, child) {
              return Container(
                width: 20 + (pulseAnimation.value * 10),
                height: 20 + (pulseAnimation.value * 10),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.6 - pulseAnimation.value * 0.3),
                      blurRadius: 10 + (pulseAnimation.value * 20),
                      spreadRadius: 2 + (pulseAnimation.value * 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 12,
                ),
              );
            },
          ),
          
          // Range indicator
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.5),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.radar,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${(maxRangeKm * 1000).round()}m',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // User count indicator
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.5),
                    blurRadius: 12,
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
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${users.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Scanning status indicator
          if (isScanning)
            Positioned(
              bottom: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.5),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: scanAnimation,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: scanAnimation.value * 2 * pi,
                          child: const Icon(
                            Icons.radar,
                            color: Colors.white,
                            size: 16,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Scanning...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUserDot(NearbyUser user, AnimationController pulseAnimation) {
    final angle = user.angleDegrees * pi / 180;
    final distance = (user.distanceKm / maxRangeKm).clamp(0.0, 1.0);
    final radius = 150.0 * distance;
    
    return Positioned(
      left: 150.0 + cos(angle) * radius - 12.0,
      top: 150.0 + sin(angle) * radius - 12.0,
      child: GestureDetector(
        onTap: () {
          if (onUserTap != null) {
            onUserTap!(user);
          }
        },
        child: AnimatedBuilder(
          animation: pulseAnimation,
          builder: (context, child) {
            final pulseValue = (sin(pulseAnimation.value * 2 * pi) + 1) / 2;
            final signalColor = user.signalStrengthColor;
            
            return Container(
              width: 24 + (pulseValue * 8),
              height: 24 + (pulseValue * 8),
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    signalColor.withOpacity(0.8 + pulseValue * 0.2),
                    signalColor.withOpacity(0.4 + pulseValue * 0.3),
                    signalColor.withOpacity(0.1 + pulseValue * 0.1),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: signalColor.withOpacity(0.6 + pulseValue * 0.3),
                    blurRadius: 12 + (pulseValue * 8),
                    spreadRadius: 2 + (pulseValue * 3),
                  ),
                  BoxShadow(
                    color: signalColor.withOpacity(0.3 + pulseValue * 0.2),
                    blurRadius: 20 + (pulseValue * 15),
                    spreadRadius: 1 + (pulseValue * 2),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.8),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class RadarBackgroundPainter extends CustomPainter {
  final double maxRangeKm;
  final bool isScanning;

  RadarBackgroundPainter({
    required this.maxRangeKm,
    required this.isScanning,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw multiple concentric circles with enhanced styling
    for (int i = 1; i <= 4; i++) {
      final circleRadius = radius * (i / 4);
      final paint = Paint()
        ..color = AppTheme.primary.withOpacity(0.1 - (i * 0.02))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      canvas.drawCircle(center, circleRadius, paint);
    }

    // Draw radial lines with enhanced styling
    for (int i = 0; i < 8; i++) {
      final angle = (i * pi / 4);
      final startPoint = center;
      final endPoint = Offset(
        center.dx + cos(angle) * radius,
        center.dy + sin(angle) * radius,
      );

      final paint = Paint()
        ..color = AppTheme.primary.withOpacity(0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5;

      canvas.drawLine(startPoint, endPoint, paint);
    }

    // Draw enhanced grid pattern
    for (int i = 1; i <= 3; i++) {
      final gridRadius = radius * (i / 4);
      final paint = Paint()
        ..color = AppTheme.secondary.withOpacity(0.05)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5;

      canvas.drawCircle(center, gridRadius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class RadarScanPainter extends CustomPainter {
  final double progress;
  final double maxRangeKm;

  RadarScanPainter({
    required this.progress,
    required this.maxRangeKm,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw scanning sweep with enhanced effects
    final sweepAngle = progress * 2 * pi;
    
    // Create gradient sweep
    final sweepPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppTheme.primary.withOpacity(0.8),
          AppTheme.primary.withOpacity(0.4),
          AppTheme.secondary.withOpacity(0.2),
          Colors.transparent,
        ],
        stops: const [0.0, 0.3, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    // Draw the sweep sector
    final path = Path()
      ..moveTo(center.dx, center.dy)
      ..lineTo(
        center.dx + cos(sweepAngle) * radius,
        center.dy + sin(sweepAngle) * radius,
      )
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius),
        0,
        -sweepAngle,
        false,
      )
      ..close();

    canvas.drawPath(path, sweepPaint);

    // Draw scanning line
    final linePaint = Paint()
      ..color = AppTheme.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final lineEnd = Offset(
      center.dx + cos(sweepAngle) * radius,
      center.dy + sin(sweepAngle) * radius,
    );

    canvas.drawLine(center, lineEnd, linePaint);

    // Draw scanning pulse effect
    final pulsePaint = Paint()
      ..color = AppTheme.primary.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawLine(center, lineEnd, pulsePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}