import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Paints a simple radar visualization with a sweeping arc.
class RadarPainter extends CustomPainter {
  RadarPainter({required this.points, required this.sweep});

  /// Points are provided in polar coordinates relative to radius 1.
  final List<Offset> points;

  /// Current sweep angle in radians.
  final double sweep;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;

    // Background circle.
    final bgPaint = Paint()..color = Colors.green.withOpacity(0.2);
    canvas.drawCircle(center, radius, bgPaint);

    // Grid circles.
    final gridPaint = Paint()
      ..color = Colors.green.withOpacity(0.4)
      ..style = PaintingStyle.stroke;
    for (var i = 1; i <= 5; i++) {
      canvas.drawCircle(center, radius * i / 5, gridPaint);
    }

    // Sweeping arc.
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        startAngle: sweep,
        endAngle: sweep + 0.4,
        colors: [Colors.greenAccent.withOpacity(0.6), Colors.transparent],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, sweepPaint);

    // Points for nearby users.
    final pointPaint = Paint()..color = Colors.red;
    for (final p in points) {
      canvas.drawCircle(center + Offset(p.dx * radius, p.dy * radius), 5, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant RadarPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.sweep != sweep;
  }
}
