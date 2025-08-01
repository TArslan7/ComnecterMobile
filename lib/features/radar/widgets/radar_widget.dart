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

    final sweepAnimation = useAnimation(
      Tween<double>(begin: 0, end: 360).animate(
        CurvedAnimation(
          parent: animationController,
          curve: Curves.linear,
        ),
      ),
    );

    // Start the sweep animation
    useEffect(() {
      animationController.repeat();
      return animationController.dispose;
    }, []);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withOpacity(0.1),
        border: Border.all(
          color: Colors.green.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Stack(
        children: [
          // Radar display
          CustomPaint(
            size: Size(size, size),
            painter: RadarPainter(
              sweepAngle: sweepAnimation,
              users: users,
              radarColor: Theme.of(context).colorScheme.primary,
              sweepColor: Theme.of(context).colorScheme.primary,
              userDotColor: Theme.of(context).colorScheme.secondary,
            ),
          ),
          
          // Loading overlay
          if (isLoading)
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withOpacity(0.3),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.green,
                ),
              ),
            ),
          
          // Distance labels
          _buildDistanceLabels(context),
        ],
      ),
    );
  }

  Widget _buildDistanceLabels(BuildContext context) {
    final radius = size / 2 - 20;
    final center = size / 2;
    
    return Stack(
      children: [
        // 1km label
        Positioned(
          left: center - 10,
          top: center - (radius * 0.25) - 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '1km',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontSize: 10,
              ),
            ),
          ),
        ),
        // 3km label
        Positioned(
          left: center - 10,
          top: center - (radius * 0.75) - 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '3km',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontSize: 10,
              ),
            ),
          ),
        ),
        // 5km label
        Positioned(
          left: center - 10,
          top: center - radius - 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '5km',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontSize: 10,
              ),
            ),
          ),
        ),
      ],
    );
  }
}