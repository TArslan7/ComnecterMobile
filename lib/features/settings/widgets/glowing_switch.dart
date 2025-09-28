import 'package:flutter/material.dart';

class GlowingSwitch extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? activeColor;
  final Color? inactiveColor;
  final double width;
  final double height;
  final double thumbRadius;

  const GlowingSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.inactiveColor,
    this.width = 60.0,
    this.height = 32.0,
    this.thumbRadius = 14.0,
  });

  @override
  State<GlowingSwitch> createState() => _GlowingSwitchState();
}

class _GlowingSwitchState extends State<GlowingSwitch>
    with TickerProviderStateMixin {
  late AnimationController _glowController;
  late AnimationController _thumbController;
  late Animation<double> _glowAnimation;
  late Animation<double> _thumbAnimation;

  @override
  void initState() {
    super.initState();
    
    // Glow animation controller
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // Thumb animation controller
    _thumbController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Glow animation (continuous pulse when active)
    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    // Thumb animation (slide movement)
    _thumbAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _thumbController,
      curve: Curves.easeInOut,
    ));

    // Start glow animation if initially active
    if (widget.value) {
      _thumbController.forward();
      _glowController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(GlowingSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.value != oldWidget.value) {
      if (widget.value) {
        _thumbController.forward();
        _glowController.repeat(reverse: true);
      } else {
        _thumbController.reverse();
        _glowController.stop();
        _glowController.reset();
      }
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    _thumbController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.activeColor ?? Colors.green;
    final inactiveColor = widget.inactiveColor ?? Colors.grey.shade400;
    
    return GestureDetector(
      onTap: () {
        widget.onChanged(!widget.value);
      },
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.height / 2),
          color: widget.value ? activeColor : inactiveColor,
          boxShadow: widget.value
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: _glowAnimation.value),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                  BoxShadow(
                    color: activeColor.withValues(alpha: _glowAnimation.value * 0.5),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ]
              : null,
        ),
        child: AnimatedBuilder(
          animation: _thumbAnimation,
          builder: (context, child) {
            final thumbPosition = _thumbAnimation.value * 
                (widget.width - widget.thumbRadius * 2 - 4) + 2;
            
            return Stack(
              children: [
                // Thumb
                Positioned(
                  left: thumbPosition,
                  top: 2,
                  child: Container(
                    width: widget.thumbRadius * 2,
                    height: widget.thumbRadius * 2,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: widget.value
                        ? Icon(
                            Icons.check,
                            color: activeColor,
                            size: widget.thumbRadius * 0.8,
                          )
                        : Icon(
                            Icons.close,
                            color: inactiveColor,
                            size: widget.thumbRadius * 0.8,
                          ),
                  ),
                ),
                
                // Glow effect overlay when active
                if (widget.value)
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _glowAnimation,
                      builder: (context, child) {
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(widget.height / 2),
                            gradient: RadialGradient(
                              center: Alignment.center,
                              radius: 1.0,
                              colors: [
                                activeColor.withValues(alpha: _glowAnimation.value * 0.3),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
