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