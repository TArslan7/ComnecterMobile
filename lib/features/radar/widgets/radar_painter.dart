import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/user_model.dart';

class RadarPainter extends CustomPainter {
  final double sweepAngle;
  final List<NearbyUser> users;
  final double maxDistance;
  final Color radarColor;
  final Color sweepColor;
  final Color userDotColor;

  RadarPainter({
    required this.sweepAngle,
    required this.users,
    this.maxDistance = 5.0,
    this.radarColor = Colors.green,
    this.sweepColor = Colors.greenAccent,
    this.userDotColor = Colors.blue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 20;

    // Draw radar circles (concentric circles)
    _drawRadarCircles(canvas, center, radius);
    
    // Draw radar lines (cross lines)
    _drawRadarLines(canvas, center, radius);
    
    // Draw sweep
    _drawSweep(canvas, center, radius);
    
    // Draw users
    _drawUsers(canvas, center, radius);
  }

  void _drawRadarCircles(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = radarColor.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw concentric circles (representing distance rings)
    for (int i = 1; i <= 4; i++) {
      final circleRadius = radius * (i / 4);
      canvas.drawCircle(center, circleRadius, paint);
    }
  }

  void _drawRadarLines(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = radarColor.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw cross lines (horizontal and vertical)
    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      paint,
    );
  }

  void _drawSweep(Canvas canvas, Offset center, double radius) {
    final sweepPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          sweepColor.withOpacity(0.8),
          sweepColor.withOpacity(0.0),
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    // Draw the sweep as a sector
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      (sweepAngle - 45) * math.pi / 180, // Start angle (45 degrees behind)
      45 * math.pi / 180, // Sweep angle (45 degrees)
      true,
      sweepPaint,
    );
  }

  void _drawUsers(Canvas canvas, Offset center, double radius) {
    for (final user in users) {
      if (user.distanceKm <= maxDistance) {
        final userRadius = (user.distanceKm / maxDistance) * radius;
        final angleRad = user.angleDegrees * math.pi / 180;
        
        final userPosition = Offset(
          center.dx + userRadius * math.cos(angleRad - math.pi / 2),
          center.dy + userRadius * math.sin(angleRad - math.pi / 2),
        );

        // Draw user dot
        final dotPaint = Paint()
          ..color = user.isOnline ? userDotColor : Colors.grey
          ..style = PaintingStyle.fill;

        canvas.drawCircle(userPosition, 6, dotPaint);

        // Draw online indicator (small green dot)
        if (user.isOnline) {
          final onlinePaint = Paint()
            ..color = Colors.green
            ..style = PaintingStyle.fill;
          canvas.drawCircle(userPosition, 2, onlinePaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant RadarPainter oldDelegate) {
    return oldDelegate.sweepAngle != sweepAngle ||
           oldDelegate.users != users;
  }
}

class EnhancedRadarPainter extends CustomPainter {
  final double sweepAngle;
  final List<NearbyUser> users;
  final double maxDistance;
  final Color radarColor;
  final Color sweepColor;
  final Color userDotColor;
  final Animation<double> pulseAnimation;
  final Animation<double> userDetectionAnimation;

  EnhancedRadarPainter({
    required this.sweepAngle,
    required this.users,
    this.maxDistance = 5.0,
    this.radarColor = Colors.green,
    this.sweepColor = Colors.greenAccent,
    this.userDotColor = Colors.blue,
    required this.pulseAnimation,
    required this.userDetectionAnimation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 20;

    // Draw energy field background
    _drawEnergyField(canvas, center, radius);
    
    // Draw enhanced radar circles
    _drawEnhancedRadarCircles(canvas, center, radius);
    
    // Draw enhanced radar lines
    _drawEnhancedRadarLines(canvas, center, radius);
    
    // Draw enhanced sweep with energy effects
    _drawEnhancedSweep(canvas, center, radius);
    
    // Draw enhanced users with holographic effects
    _drawEnhancedUsers(canvas, center, radius);
    
    // Draw energy particles
    _drawEnergyParticles(canvas, center, radius);
    
    // Draw data streams
    _drawDataStreams(canvas, center, radius);
  }

  void _drawEnergyField(Canvas canvas, Offset center, double radius) {
    // Draw energy field background
    for (int i = 0; i < 5; i++) {
      final fieldRadius = radius * (0.2 + (i * 0.2));
      final fieldPaint = Paint()
        ..color = radarColor.withOpacity(0.02 * pulseAnimation.value)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(center, fieldRadius, fieldPaint);
    }
  }

  void _drawEnhancedRadarCircles(Canvas canvas, Offset center, double radius) {
    for (int i = 1; i <= 4; i++) {
      final circleRadius = radius * (i / 4);
      final opacity = 0.4 * pulseAnimation.value;
      
      final paint = Paint()
        ..color = radarColor.withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      canvas.drawCircle(center, circleRadius, paint);
      
      // Draw additional glow effect
      final glowPaint = Paint()
        ..color = radarColor.withOpacity(opacity * 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      canvas.drawCircle(center, circleRadius, glowPaint);
    }
  }

  void _drawEnhancedRadarLines(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = radarColor.withOpacity(0.5 * pulseAnimation.value)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    // Draw cross lines with glow
    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dy, center.dy + radius),
      paint,
    );
    
    // Draw diagonal lines for enhanced effect
    final diagonalPaint = Paint()
      ..color = radarColor.withOpacity(0.3 * pulseAnimation.value)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawLine(
      Offset(center.dx - radius * 0.7, center.dy - radius * 0.7),
      Offset(center.dx + radius * 0.7, center.dy + radius * 0.7),
      diagonalPaint,
    );
    canvas.drawLine(
      Offset(center.dx + radius * 0.7, center.dy - radius * 0.7),
      Offset(center.dx - radius * 0.7, center.dy + radius * 0.7),
      diagonalPaint,
    );
  }

  void _drawEnhancedSweep(Canvas canvas, Offset center, double radius) {
    // Main sweep with enhanced gradient and energy effects
    final sweepPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          sweepColor.withOpacity(0.95 * pulseAnimation.value),
          sweepColor.withOpacity(0.7 * pulseAnimation.value),
          sweepColor.withOpacity(0.3 * pulseAnimation.value),
          sweepColor.withOpacity(0.0),
        ],
        stops: const [0.0, 0.2, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      (sweepAngle - 75) * math.pi / 180, // Wider sweep
      75 * math.pi / 180, // 75 degrees sweep
      true,
      sweepPaint,
    );
    
    // Draw enhanced sweep line with energy glow
    final sweepLinePaint = Paint()
      ..color = sweepColor.withOpacity(0.9 * pulseAnimation.value)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final sweepAngleRad = sweepAngle * math.pi / 180;
    final endX = center.dx + math.cos(sweepAngleRad - math.pi / 2) * radius;
    final endY = center.dy + math.sin(sweepAngleRad - math.pi / 2) * radius;
    
    canvas.drawLine(center, Offset(endX, endY), sweepLinePaint);
    
    // Draw energy trail
    final trailPaint = Paint()
      ..color = sweepColor.withOpacity(0.3 * pulseAnimation.value)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    canvas.drawLine(center, Offset(endX, endY), trailPaint);
  }

  void _drawEnhancedUsers(Canvas canvas, Offset center, double radius) {
    for (int i = 0; i < users.length; i++) {
      final user = users[i];
      if (user.distanceKm <= maxDistance) {
        final userRadius = (user.distanceKm / maxDistance) * radius;
        final angleRad = user.angleDegrees * math.pi / 180;
        
        final userPosition = Offset(
          center.dx + userRadius * math.cos(angleRad - math.pi / 2),
          center.dy + userRadius * math.sin(angleRad - math.pi / 2),
        );

        // Draw energy field around user
        final energyPaint = Paint()
          ..color = userDotColor.withOpacity(0.2 * userDetectionAnimation.value)
          ..style = PaintingStyle.fill;

        canvas.drawCircle(userPosition, 20, energyPaint);

        // Draw detection ring with holographic effect
        final detectionRingPaint = Paint()
          ..color = userDotColor.withOpacity(0.4 * userDetectionAnimation.value)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

        canvas.drawCircle(userPosition, 15, detectionRingPaint);

        // Draw user dot with energy glow
        final dotPaint = Paint()
          ..color = user.isOnline ? userDotColor : Colors.grey
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

        canvas.drawCircle(userPosition, 10, dotPaint);

        // Draw enhanced online indicator with energy pulse
        if (user.isOnline) {
          final onlinePaint = Paint()
            ..color = Colors.green
            ..style = PaintingStyle.fill;
          canvas.drawCircle(userPosition, 4, onlinePaint);
          
          // Draw energy pulse for online users
          final pulsePaint = Paint()
            ..color = Colors.green.withOpacity(0.5 * pulseAnimation.value)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.0;
          canvas.drawCircle(userPosition, 8, pulsePaint);
          
          // Draw energy field
          final energyFieldPaint = Paint()
            ..color = Colors.green.withOpacity(0.1 * pulseAnimation.value)
            ..style = PaintingStyle.fill;
          canvas.drawCircle(userPosition, 12, energyFieldPaint);
        }
        
        // Draw data connection lines
        if (i < users.length - 1) {
          final nextUser = users[i + 1];
          if (nextUser.distanceKm <= maxDistance) {
            final nextUserRadius = (nextUser.distanceKm / maxDistance) * radius;
            final nextAngleRad = nextUser.angleDegrees * math.pi / 180;
            
            final nextUserPosition = Offset(
              center.dx + nextUserRadius * math.cos(nextAngleRad - math.pi / 2),
              center.dy + nextUserRadius * math.sin(nextAngleRad - math.pi / 2),
            );
            
            final connectionPaint = Paint()
              ..color = userDotColor.withOpacity(0.2 * pulseAnimation.value)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.0
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);
            
            canvas.drawLine(userPosition, nextUserPosition, connectionPaint);
          }
        }
      }
    }
  }

  void _drawEnergyParticles(Canvas canvas, Offset center, double radius) {
    // Draw floating energy particles around the radar
    for (int i = 0; i < 16; i++) {
      final angle = (i * 22.5 + sweepAngle) * math.pi / 180;
      final particleRadius = radius * (0.2 + (i % 4) * 0.15);
      final x = center.dx + math.cos(angle) * particleRadius;
      final y = center.dy + math.sin(angle) * particleRadius;
      
      final particlePaint = Paint()
        ..color = radarColor.withOpacity(0.4 * pulseAnimation.value)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      canvas.drawCircle(Offset(x, y), 2 + (i % 3), particlePaint);
    }
  }

  void _drawDataStreams(Canvas canvas, Offset center, double radius) {
    // Draw data stream effects
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 + sweepAngle * 0.5) * math.pi / 180;
      final streamLength = 30 + (pulseAnimation.value * 20);
      final startX = center.dx + math.cos(angle) * (radius - 40);
      final startY = center.dy + math.sin(angle) * (radius - 40);
      final endX = center.dx + math.cos(angle) * (radius - 40 + streamLength);
      final endY = center.dy + math.sin(angle) * (radius - 40 + streamLength);

      final streamPaint = Paint()
        ..color = radarColor.withOpacity(0.3 * pulseAnimation.value)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        streamPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant EnhancedRadarPainter oldDelegate) {
    return oldDelegate.sweepAngle != sweepAngle ||
           oldDelegate.users != users ||
           oldDelegate.pulseAnimation != pulseAnimation ||
           oldDelegate.userDetectionAnimation != userDetectionAnimation;
  }
}