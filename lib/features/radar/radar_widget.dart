import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'radar_painter.dart';

/// Displays a radar with animated sweep.
class RadarWidget extends HookWidget {
  const RadarWidget({super.key, required this.points});

  /// Points of detected users in polar coordinates (0..1 radius).
  final List<Offset> points;

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(
      duration: const Duration(seconds: 2),
    )..repeat();

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return CustomPaint(
          painter: RadarPainter(
            points: points,
            sweep: controller.value * 2 * math.pi,
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}
