import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../theme.dart';
import '../services/sound_service.dart';
import '../providers/user_provider.dart';

class EnhancedRadarView extends StatefulWidget {
  final List<UserModel> nearbyUsers;
  final UserModel currentUser;
  final Function(UserModel) onUserTap;
  final double maxDistance;
  final bool playSounds;

  const EnhancedRadarView({
    Key? key,
    required this.nearbyUsers,
    required this.currentUser,
    required this.onUserTap,
    this.maxDistance = 1000.0,
    this.playSounds = true,
  }) : super(key: key);

  @override
  State<EnhancedRadarView> createState() => _EnhancedRadarViewState();
}

class _EnhancedRadarViewState extends State<EnhancedRadarView> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final SoundService _soundService = SoundService();
  final List<GlobalKey> _userKeys = [];
  final Map<String, bool> _userPulsing = {};
  final Map<String, double> _userOpacity = {};
  
  // Track which users we've already seen to play sounds only for new users
  final Set<String> _discoveredUserIds = {};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    
    // Initialize user keys
    _initUserKeys();
    
    // Play radar ping sound when view is first shown
    if (widget.playSounds) {
      // Start with radar ambient sound for immersion
      _soundService.playRadarAmbientSound();
      
      // Initial ping with slight delay
      Future.delayed(const Duration(milliseconds: 300), () {
        _soundService.playRadarPingSound();
      });
      
      // Add radar sweep sound with animation timing
      _animationController.addListener(() {
        // Play sweep sound at the beginning of each cycle
        if (_animationController.value > 0 && _animationController.value < 0.05) {
          _soundService.playRadarSweepSound();
        }
      });
      
      // Schedule periodic radar pings with variety
      Future.delayed(const Duration(seconds: 15), _playPeriodicPing);
    }
  }
  
  void _playPeriodicPing() {
    if (!mounted) return;
    
    // Add variety to radar pings by randomly selecting between different ping types
    final random = math.Random();
    final pingType = random.nextInt(3);
    
    switch (pingType) {
      case 0:
        _soundService.playRadarPingSound();
      case 1:
        _soundService.playRadarHighPingSound();
      case 2:
        _soundService.playRadarLowPingSound();
    }
    
    // Schedule next ping with slight randomness to timing
    final nextPingDelay = 12 + random.nextInt(7); // 12-18 seconds
    Future.delayed(Duration(seconds: nextPingDelay), _playPeriodicPing);
  }
  
  @override
  void didUpdateWidget(EnhancedRadarView oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Check for new users
    if (widget.nearbyUsers.length > oldWidget.nearbyUsers.length) {
      _checkForNewUsers(oldWidget.nearbyUsers);
    }
    
    // Update keys if needed
    if (widget.nearbyUsers.length != _userKeys.length) {
      _initUserKeys();
    }
  }
  
  void _checkForNewUsers(List<UserModel> oldUsers) {
    // Find users that weren't in the previous list
    final oldUserIds = oldUsers.map((user) => user.userId).toSet();
    final newUsers = widget.nearbyUsers.where((user) => 
      !oldUserIds.contains(user.userId) && !_discoveredUserIds.contains(user.userId)
    ).toList();
    
    if (newUsers.isNotEmpty && widget.playSounds) {
      // Check if any users are relatively close (within 10% of max distance)
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final nearbyThreshold = widget.maxDistance * 0.1; // 10% of max distance
      final hasNearbyUsers = newUsers.any((user) {
        final distance = userProvider.getDistanceToUser(user);
        return distance < nearbyThreshold;
      });
      
      // Play appropriate sound based on proximity
      if (hasNearbyUsers) {
        _soundService.playUserNearbySound(); // Special sound for close users
      } else {
        _soundService.playUserDetectedSound(); // Regular detection sound
      }
      
      // Start pulsing animation for new users
      for (final user in newUsers) {
        _userPulsing[user.userId] = true;
        _userOpacity[user.userId] = 1.0;
        _discoveredUserIds.add(user.userId);
      }
      
      // Stop pulsing after a few seconds
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            for (final user in newUsers) {
              _userPulsing[user.userId] = false;
            }
          });
        }
      });
    }
  }
  
  void _initUserKeys() {
    // Create a key for each user
    _userKeys.clear();
    for (var i = 0; i < widget.nearbyUsers.length; i++) {
      _userKeys.add(GlobalKey());
      
      final user = widget.nearbyUsers[i];
      if (!_userOpacity.containsKey(user.userId)) {
        _userOpacity[user.userId] = 1.0;
      }
      if (!_userPulsing.containsKey(user.userId)) {
        _userPulsing[user.userId] = false;
      }
    }
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
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.2),
              blurRadius: 15,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Grid circles
            ..._buildGridCircles(),
            
            // Radar sweep animation
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return CustomPaint(
                  painter: EnhancedRadarSweepPainter(
                    _animationController.value,
                    Theme.of(context).brightness == Brightness.dark,
                  ),
                  size: Size.infinite,
                );
              },
            ),
            
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
                child: Center(
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  )
                  .animate(onPlay: (controller) => controller.repeat())
                  .scale(duration: 1.seconds, begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2))
                  .then(duration: 1.seconds, curve: Curves.easeOut)
                  .scale(duration: 1.seconds, begin: const Offset(1.2, 1.2), end: const Offset(0.8, 0.8)),
                ),
              ),
            ),
            
            // Nearby users
            ..._buildUserMarkers(),
          ],
        ),
      ),
    );
  }
  
  List<Widget> _buildGridCircles() {
    final circles = <Widget>[];
    final gridCount = 3;
    
    for (int i = 1; i <= gridCount; i++) {
      final radius = i / gridCount;
      circles.add(
        Center(
          child: Container(
            width: MediaQuery.of(context).size.width * radius,
            height: MediaQuery.of(context).size.width * radius,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.primaryColor.withOpacity(0.3),
                width: 1,
              ),
            ),
          ),
        ),
      );
      
      // Distance labels
      final distance = widget.maxDistance * radius;
      final distanceText = distance >= 1 
          ? '${distance.toStringAsFixed(0)} km'
          : '${(distance * 1000).toStringAsFixed(0)} m';
      circles.add(
        Positioned(
          top: MediaQuery.of(context).size.width * (0.5 - radius / 2),
          right: MediaQuery.of(context).size.width * 0.5 - 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black54
                : Colors.white70,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              distanceText,
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    }
    
    return circles;
  }
  
  List<Widget> _buildUserMarkers() {
    final markers = <Widget>[];
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    for (int i = 0; i < widget.nearbyUsers.length; i++) {
      final user = widget.nearbyUsers[i];
      
      // Calculate position based on actual distance
      final distance = userProvider.getDistanceToUser(user);
      final normalizedDistance = math.min(distance / widget.maxDistance, 1.0); // Ensure it's within the radar
      final angle = math.atan2(user.latitude - widget.currentUser.latitude, user.longitude - widget.currentUser.longitude);
      
      final xPos = math.cos(angle) * normalizedDistance;
      final yPos = math.sin(angle) * normalizedDistance;
      
      final isPulsing = _userPulsing[user.userId] ?? false;
      final opacity = _userOpacity[user.userId] ?? 1.0;
      
      markers.add(
        Positioned(
          key: _userKeys[i],
          left: (MediaQuery.of(context).size.width / 2) * (1 + xPos),
          top: (MediaQuery.of(context).size.width / 2) * (1 + yPos),
          child: GestureDetector(
            onTap: () {
              _soundService.playTapSound();
              widget.onUserTap(user);
            },
            child: AnimatedOpacity(
              opacity: opacity,
              duration: const Duration(milliseconds: 500),
              child: _buildUserDot(user, isPulsing),
            ),
          ),
        ),
      );
    }
    
    return markers;
  }
  
  Widget _buildUserDot(UserModel user, bool isPulsing) {
    // Base dot
    Widget dot = Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: AppTheme.accentColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentColor.withOpacity(0.4),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Text(
          user.userName.substring(0, 1).toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 8,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
    
    // Add pulsing animation for new users
    if (isPulsing) {
      dot = dot
        .animate(onPlay: (controller) => controller.repeat())
        .scale(duration: 1.seconds, begin: const Offset(1.0, 1.0), end: const Offset(1.3, 1.3))
        .then(duration: 1.seconds)
        .scale(duration: 1.seconds, begin: const Offset(1.3, 1.3), end: const Offset(1.0, 1.0));
    }
    
    // Add hover effect
    return dot
      .animate(target: 0.0)
      .scale(duration: 150.ms, begin: const Offset(1.0, 1.0), end: const Offset(1.2, 1.2))
      .callback(callback: (_) => _soundService.playTapSound());
  }
}

class EnhancedRadarSweepPainter extends CustomPainter {
  final double progress;
  final bool isDarkMode;
  
  EnhancedRadarSweepPainter(this.progress, this.isDarkMode);
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Draw sweep
    final sweepPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppTheme.primaryColor.withOpacity(isDarkMode ? 0.7 : 0.6),
          AppTheme.primaryColor.withOpacity(0.0),
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;
    
    final sweepAngle = progress * 2 * math.pi;
    final path = Path();
    path.moveTo(center.dx, center.dy);
    path.lineTo(
      center.dx + radius * math.cos(sweepAngle),
      center.dy + radius * math.sin(sweepAngle),
    );
    path.arcTo(
      Rect.fromCircle(center: center, radius: radius),
      sweepAngle,
      0.5,
      false,
    );
    path.close();
    
    canvas.drawPath(path, sweepPaint);
    
    // Draw moving edge highlight
    final highlightPaint = Paint()
      ..color = AppTheme.primaryColor.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    final edgePath = Path();
    edgePath.moveTo(center.dx, center.dy);
    edgePath.lineTo(
      center.dx + radius * math.cos(sweepAngle),
      center.dy + radius * math.sin(sweepAngle),
    );
    
    canvas.drawPath(edgePath, highlightPaint);
    
    // Draw a glow dot at the edge
    final glowPaint = Paint()
      ..color = AppTheme.primaryColor
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      Offset(
        center.dx + radius * math.cos(sweepAngle),
        center.dy + radius * math.sin(sweepAngle),
      ),
      4,
      glowPaint,
    );
  }
  
  @override
  bool shouldRepaint(EnhancedRadarSweepPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isDarkMode != isDarkMode;
  }
}