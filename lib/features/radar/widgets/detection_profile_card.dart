import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter/services.dart';
import '../models/detection_model.dart';
import '../../../theme/app_theme.dart';

/// A profile card widget for displaying user detection information
/// with swipe-to-save functionality and glow animations
class DetectionProfileCard extends HookWidget {
  final UserDetection detection;
  final bool isFavorite;
  final VoidCallback? onTap;
  final VoidCallback? onSaveToFavorites;
  final VoidCallback? onRemoveFromFavorites;
  final bool showSwipeHint;

  const DetectionProfileCard({
    super.key,
    required this.detection,
    this.isFavorite = false,
    this.onTap,
    this.onSaveToFavorites,
    this.onRemoveFromFavorites,
    this.showSwipeHint = false,
  });

  @override
  Widget build(BuildContext context) {
    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 300),
    );
    final glowController = useAnimationController(
      duration: const Duration(milliseconds: 1500),
    );
    final swipeController = useAnimationController(
      duration: const Duration(milliseconds: 200),
    );
    
    final isGlowing = useState(false);
    final swipeOffset = useState(0.0);
    final isSwipeActive = useState(false);

    // Start glow animation when card is created
    useEffect(() {
      if (showSwipeHint) {
        glowController.repeat();
        isGlowing.value = true;
      }
      return null;
    }, [showSwipeHint]);

    // Handle swipe gestures
    void handlePanUpdate(DragUpdateDetails details) {
      if (isFavorite) return; // Don't allow swiping for favorites
      
      final delta = details.delta.dx;
      final newOffset = (swipeOffset.value + delta).clamp(-200.0, 200.0);
      swipeOffset.value = newOffset;
      
      if (newOffset.abs() > 50) {
        isSwipeActive.value = true;
        swipeController.forward();
      } else {
        isSwipeActive.value = false;
        swipeController.reverse();
      }
    }

    void handlePanEnd(DragEndDetails details) {
      if (isFavorite) return;
      
      if (swipeOffset.value > 100) {
        // Swipe right - save to favorites
        _performSaveAnimation(animationController, glowController, isGlowing);
        onSaveToFavorites?.call();
        HapticFeedback.mediumImpact();
      } else {
        // Reset position
        swipeController.reverse();
      }
      
      swipeOffset.value = 0.0;
      isSwipeActive.value = false;
    }

    return GestureDetector(
      onPanUpdate: handlePanUpdate,
      onPanEnd: handlePanEnd,
      onTap: onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([animationController, glowController, swipeController]),
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(swipeOffset.value, 0),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  ),
                  // Glow effect for swipe hint
                  if (isGlowing.value)
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.3 + (glowController.value * 0.4)),
                      blurRadius: 30 + (glowController.value * 20),
                      spreadRadius: 5 + (glowController.value * 10),
                    ),
                ],
              ),
              child: Stack(
                children: [
                  // Main card content
                  _buildCardContent(context, animationController),
                  
                  // Swipe action indicators
                  if (!isFavorite) _buildSwipeActions(context, swipeController, swipeOffset.value),
                  
                  // Favorite indicator
                  if (isFavorite) _buildFavoriteIndicator(context),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCardContent(BuildContext context, AnimationController animationController) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.grey.shade50,
          ],
        ),
        border: Border.all(
          color: detection.isOnline 
              ? AppTheme.primary.withValues(alpha: 0.3)
              : Colors.grey.shade200,
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            HapticFeedback.lightImpact();
            onTap?.call();
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Avatar with online indicator
                _buildAvatar(context),
                const SizedBox(width: 16),
                
                // User info
                Expanded(
                  child: _buildUserInfo(context),
                ),
                
                // Distance and timestamp
                _buildMetadata(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    return Stack(
      children: [
        // Avatar background with energy effect
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                detection.isOnline 
                    ? AppTheme.primary.withValues(alpha: 0.2)
                    : Colors.grey.shade300,
                Colors.white,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: detection.isOnline 
                    ? AppTheme.primary.withValues(alpha: 0.3)
                    : Colors.grey.shade300,
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Text(
              detection.name.isNotEmpty ? detection.name[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: detection.isOnline 
                    ? AppTheme.primary
                    : Colors.grey.shade600,
              ),
            ),
          ),
        ),
        
        // Online indicator
        if (detection.isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.6),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.fiber_manual_record,
                color: Colors.white,
                size: 8,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildUserInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name
        Text(
          detection.name,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        
        // Interests
        if (detection.interests.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: detection.interests.take(3).map((interest) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  interest,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),
        
        // Signal strength indicator
        const SizedBox(height: 8),
        _buildSignalStrength(context),
      ],
    );
  }

  Widget _buildSignalStrength(BuildContext context) {
    final strength = detection.signalStrength;
    final strengthColor = strength > 0.7 
        ? Colors.green 
        : strength > 0.4 
            ? Colors.orange 
            : Colors.red;
    
    return Row(
      children: [
        Icon(
          Icons.signal_cellular_alt,
          size: 16,
          color: strengthColor,
        ),
        const SizedBox(width: 4),
        Text(
          '${(strength * 100).round()}%',
          style: TextStyle(
            fontSize: 12,
            color: strengthColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildMetadata(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Distance
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.primary.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_on,
                size: 14,
                color: AppTheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                '${detection.distanceKm.toStringAsFixed(1)} km',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Timestamp
        Text(
          _formatTimestamp(detection.detectedAt),
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSwipeActions(BuildContext context, AnimationController swipeController, double swipeOffset) {
    return Positioned.fill(
      child: Row(
        children: [
          // Left side - remove action (if needed)
          if (swipeOffset < -50)
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.close,
                    color: Colors.red,
                    size: 24,
                  ),
                ),
              ),
            ),
          
          // Right side - save action
          if (swipeOffset > 50)
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: AnimatedBuilder(
                  animation: swipeController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1.0 + (swipeController.value * 0.2),
                      child: const Center(
                        child: Icon(
                          Icons.favorite,
                          color: Colors.green,
                          size: 24,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFavoriteIndicator(BuildContext context) {
    return Positioned(
      top: 12,
      right: 12,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.red.withValues(alpha: 0.4),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(
          Icons.favorite,
          color: Colors.white,
          size: 16,
        ),
      ),
    );
  }

  void _performSaveAnimation(
    AnimationController animationController,
    AnimationController glowController,
    ValueNotifier<bool> isGlowing,
  ) {
    animationController.forward().then((_) {
      animationController.reverse();
    });
    
    // Stop glow animation
    glowController.stop();
    isGlowing.value = false;
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }
}
