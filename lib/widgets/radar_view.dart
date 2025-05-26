// TIP: Optimaliseer deze widget voor performance bij veel gebruikers op radar
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/user_model.dart';
import '../theme.dart';

class RadarView extends StatefulWidget {
  final List<UserModel> nearbyUsers;
  final UserModel currentUser;
  final Function(UserModel) onUserTap;
  final double maxDistance;

  const RadarView({
    Key? key,
    required this.nearbyUsers,
    required this.currentUser,
    required this.onUserTap,
    this.maxDistance = 5.0,
  }) : super(key: key);

  @override
  State<RadarView> createState() => _RadarViewState();
}

class _RadarViewState extends State<RadarView> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Simplified placeholder for the radar view
    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppTheme.radarBackgroundDark
              : AppTheme.radarBackgroundLight,
          shape: BoxShape.circle,
          border: Border.all(
            color: AppTheme.primaryColor,
            width: 2,
          ),
        ),
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return CustomPaint(
              painter: RadarSweepPainter(_animationController.value),
              child: Stack(
                children: [
                  // Center dot (current user)
                  Center(
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.5),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Example nearby users (simplified)
                  ...widget.nearbyUsers.take(5).map((user) {
                    // Position randomly on the radar
                    final double angle = user.userId.hashCode / 1000;
                    final double distance = (user.userId.hashCode % 100) / 100 * 0.8;
                    
                    final xPos = cos(angle * 6.28) * distance;
                    final yPos = sin(angle * 6.28) * distance;
                    
                    return Positioned(
                      left: (MediaQuery.of(context).size.width / 2) * (1 + xPos),
                      top: (MediaQuery.of(context).size.width / 2) * (1 + yPos),
                      child: GestureDetector(
                        onTap: () => widget.onUserTap(user),
                        child: Container(
                          width: 15,
                          height: 15,
                          decoration: BoxDecoration(
                            color: AppTheme.accentColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
  
  // Simple helper function for positioning
  double cos(double angle) => math.cos(angle);
  double sin(double angle) => math.sin(angle);
}

class RadarSweepPainter extends CustomPainter {
  final double progress;
  
  RadarSweepPainter(this.progress);
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Draw grid circles
    for (int i = 1; i <= 3; i++) {
      final gridPaint = Paint()
        ..color = AppTheme.primaryColor.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      
      canvas.drawCircle(center, radius * (i / 3), gridPaint);
    }
    
    // Draw sweep
    final sweepPaint = Paint()
      ..color = AppTheme.primaryColor.withOpacity(0.5)
      ..style = PaintingStyle.fill;
    
    final sweepAngle = progress * 2 * 3.14159;
    final path = Path();
    path.moveTo(center.dx, center.dy);
    path.lineTo(
      center.dx + radius * cos(sweepAngle),
      center.dy + radius * sin(sweepAngle),
    );
    path.arcTo(
      Rect.fromCircle(center: center, radius: radius),
      sweepAngle - 0.3,
      0.6,
      false,
    );
    path.close();
    
    canvas.drawPath(path, sweepPaint);
  }
  
  double cos(double angle) => math.cos(angle);
  double sin(double angle) => math.sin(angle);
  
  @override
  bool shouldRepaint(RadarSweepPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}