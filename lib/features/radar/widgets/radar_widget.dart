import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'dart:math' as math;
import '../models/user_model.dart';

class RadarWidget extends HookWidget {
  final List<NearbyUser> users;
  final bool isLoading;
  final Function(NearbyUser)? onUserTap;
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

    final sweepAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: animationController,
        curve: Curves.linear,
      ),
    );

    useEffect(() {
      animationController.repeat();
      return () {
        try {
          animationController.stop();
          animationController.dispose();
        } catch (e) {
          // Controller already disposed
        }
      };
    }, []);

    return Container(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Radar background circles
          ...List.generate(3, (index) {
            return Container(
              width: size * (0.6 + index * 0.2),
              height: size * (0.6 + index * 0.2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3 - index * 0.1),
                  width: 1,
                ),
              ),
            );
          }),
          
          // Sweep line
          RotationTransition(
            turns: sweepAnimation,
            child: Container(
              width: 2,
              height: size / 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          
          // User dots
          ...users.map((user) {
            final angle = user.angleDegrees * math.pi / 180;
            final distance = (user.distanceKm / 5.0).clamp(0.0, 1.0); // Normalize to 5km max
            final radius = (size / 2) * distance;
            
            return Positioned(
              left: size / 2 + math.cos(angle) * radius - 8,
              top: size / 2 + math.sin(angle) * radius - 8,
              child: GestureDetector(
                onTap: () {
                  if (onUserTap != null) {
                    onUserTap!(user);
                  }
                },
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.primary,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          
          // Center button
          Positioned(
            bottom: 20,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.primary,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                Icons.my_location,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        ],
      ),
    );
  }
}