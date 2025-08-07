import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'dart:math';
import '../../../theme/app_theme.dart';
import '../models/user_model.dart';

class RadarWidget extends HookWidget {
  final List<NearbyUser> users;
  final double maxRangeKm;
  final bool isScanning;
  final Function(NearbyUser)? onUserTap;
  final Function(String)? onManualDetection;

  const RadarWidget({
    super.key,
    required this.users,
    this.maxRangeKm = 0.5,
    this.isScanning = true,
    this.onUserTap,
    this.onManualDetection,
  });

  @override
  Widget build(BuildContext context) {
    final scanAnimation = useAnimationController(duration: const Duration(seconds: 2));
    final rotationAnimation = useAnimationController(duration: const Duration(seconds: 10));

    useEffect(() {
      if (isScanning) {
        scanAnimation.repeat();
        rotationAnimation.repeat();
      } else {
        scanAnimation.stop();
        rotationAnimation.stop();
      }
      return null;
    }, [isScanning]);

    return Container(
      width: 300,
      height: 300,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Radar background with rings
          CustomPaint(
            size: const Size(300, 300),
            painter: RadarBackgroundPainter(
              maxRangeKm: maxRangeKm,
              isScanning: isScanning,
            ),
          ),
          
          // Scanning animation
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
          
          // User dots
          ...users.map((user) => _buildUserDot(user)),
          
          // Center indicator
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              gradient: AppTheme.auroraGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.electricAurora.withOpacity(0.6),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 12,
            ),
          ),
          
          // Range indicator
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: AppTheme.auroraGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.electricAurora.withOpacity(0.4),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Text(
                '${(maxRangeKm * 1000).round()}m',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          // User count indicator
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: AppTheme.auroraGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.electricAurora.withOpacity(0.4),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.people,
                    color: Colors.white,
                    size: 12,
                  ),
                  const SizedBox(width: 4),
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
        ],
      ),
    );
  }

  Widget _buildUserDot(NearbyUser user) {
    final centerX = 150.0;
    final centerY = 150.0;
    final maxRadius = 120.0;
    
    // Calculate position based on distance and angle
    final distanceRatio = user.distanceKm / maxRangeKm;
    final radius = distanceRatio * maxRadius;
    final angleRadians = user.angleDegrees * pi / 180;
    
    final x = centerX + radius * cos(angleRadians);
    final y = centerY + radius * sin(angleRadians);
    
    return Positioned(
      left: x - 15,
      top: y - 15,
      child: GestureDetector(
        onTap: () => onUserTap?.call(user),
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            gradient: _getUserGradient(user),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _getUserColor(user).withOpacity(0.6),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Text(
              user.avatar,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }

  Color _getUserColor(NearbyUser user) {
    if (user.signalStrength > 0.8) return AppTheme.greenAurora;
    if (user.signalStrength > 0.5) return AppTheme.orangeAurora;
    if (user.signalStrength > 0.2) return AppTheme.pinkAurora;
    return Colors.grey;
  }

  LinearGradient _getUserGradient(NearbyUser user) {
    final color = _getUserColor(user);
    return LinearGradient(
      colors: [color, color.withOpacity(0.7)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
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
    final maxRadius = size.width / 2 - 20;
    
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.white.withOpacity(0.3);

    // Draw distance rings
    for (int i = 1; i <= 5; i++) {
      final radius = maxRadius * i / 5;
      canvas.drawCircle(center, radius, paint);
    }

    // Draw angle lines
    for (int i = 0; i < 8; i++) {
      final angle = i * pi / 4;
      final endX = center.dx + maxRadius * cos(angle);
      final endY = center.dy + maxRadius * sin(angle);
      canvas.drawLine(center, Offset(endX, endY), paint);
    }

    // Draw outer circle
    final outerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = AppTheme.electricAurora.withOpacity(0.6);
    canvas.drawCircle(center, maxRadius, outerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
    final maxRadius = size.width / 2 - 20;
    
    // Create scanning sweep effect
    final sweepPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = RadialGradient(
        colors: [
          AppTheme.electricAurora.withOpacity(0.3),
          AppTheme.electricAurora.withOpacity(0.1),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius));

    // Draw scanning sweep
    final sweepAngle = progress * 2 * pi;
    final path = Path();
    path.moveTo(center.dx, center.dy);
    path.lineTo(
      center.dx + maxRadius * cos(sweepAngle),
      center.dy + maxRadius * sin(sweepAngle),
    );
    path.arcTo(
      Rect.fromCircle(center: center, radius: maxRadius),
      0,
      sweepAngle,
      false,
    );
    path.close();
    
    canvas.drawPath(path, sweepPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}