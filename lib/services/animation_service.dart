import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AnimationService {
  static final AnimationService _instance = AnimationService._internal();
  factory AnimationService() => _instance;
  AnimationService._internal();

  // Animation durations
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration verySlow = Duration(milliseconds: 800);

  // Animation curves
  static const Curve bounceOut = Curves.bounceOut;
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve elasticOut = Curves.elasticOut;
  static const Curve fastOutSlowIn = Curves.fastOutSlowIn;

  // Common animations
  static Animation<double> fadeIn(AnimationController controller) {
    return Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: controller, curve: easeInOut),
    );
  }

  static Animation<double> slideUp(AnimationController controller) {
    return Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: controller, curve: fastOutSlowIn),
    );
  }

  static Animation<double> scaleIn(AnimationController controller) {
    return Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: controller, curve: elasticOut),
    );
  }

  static Animation<double> rotate(AnimationController controller) {
    return Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: controller, curve: Curves.linear),
    );
  }

  // Predefined animation effects
  static List<Effect> get fadeInEffect => [
    const FadeEffect(duration: normal),
    const SlideEffect(begin: Offset(0, 0.1), end: Offset.zero, duration: normal),
  ];

  static List<Effect> get slideUpEffect => [
    const SlideEffect(begin: Offset(0, 0.3), end: Offset.zero, duration: normal),
    const FadeEffect(duration: normal),
  ];

  static List<Effect> get scaleInEffect => [
    const ScaleEffect(begin: Offset(0.8, 0.8), end: Offset.one, duration: normal),
    const FadeEffect(duration: normal),
  ];

  static List<Effect> get bounceInEffect => [
    const ScaleEffect(begin: Offset(0.3, 0.3), end: Offset.one, duration: slow, curve: bounceOut),
    const FadeEffect(duration: slow),
  ];

  static List<Effect> get slideInLeftEffect => [
    const SlideEffect(begin: Offset(-0.3, 0), end: Offset.zero, duration: normal),
    const FadeEffect(duration: normal),
  ];

  static List<Effect> get slideInRightEffect => [
    const SlideEffect(begin: Offset(0.3, 0), end: Offset.zero, duration: normal),
    const FadeEffect(duration: normal),
  ];

  static List<Effect> get pulseEffect => [
    const ScaleEffect(begin: Offset.one, end: Offset(1.1, 1.1), duration: fast),
    const ScaleEffect(begin: Offset(1.1, 1.1), end: Offset.one, duration: fast, delay: fast),
  ];

  static List<Effect> get shakeEffect => [
    const ShakeEffect(duration: normal),
  ];

  static List<Effect> get shimmerEffect => [
    const ShimmerEffect(duration: Duration(seconds: 2)),
  ];

  // Staggered animations
  static List<Effect> get staggeredFadeIn => [
    const FadeEffect(duration: normal, delay: Duration(milliseconds: 100)),
  ];

  static List<Effect> get staggeredSlideUp => [
    const SlideEffect(begin: Offset(0, 0.2), end: Offset.zero, duration: normal, delay: Duration(milliseconds: 100)),
    const FadeEffect(duration: normal, delay: Duration(milliseconds: 100)),
  ];

  // Radar specific animations
  static List<Effect> get radarPulseEffect => [
    const ScaleEffect(begin: Offset.one, end: Offset(1.2, 1.2), duration: Duration(milliseconds: 1500), curve: Curves.easeOut),
    const FadeEffect(begin: 0.8, end: 0.0, duration: Duration(milliseconds: 1500), curve: Curves.easeOut),
  ];

  static List<Effect> get userFoundEffect => [
    const ScaleEffect(begin: Offset(0.5, 0.5), end: Offset.one, duration: slow, curve: elasticOut),
    const FadeEffect(duration: slow),
  ];

  // Button animations
  static List<Effect> get buttonPressEffect => [
    const ScaleEffect(begin: Offset.one, end: Offset(0.95, 0.95), duration: fast),
    const ScaleEffect(begin: Offset(0.95, 0.95), end: Offset.one, duration: fast, delay: fast),
  ];

  // Success animations
  static List<Effect> get successEffect => [
    const ScaleEffect(begin: Offset.one, end: Offset(1.1, 1.1), duration: fast),
    const ScaleEffect(begin: Offset(1.1, 1.1), end: Offset.one, duration: fast, delay: fast),
    const ShakeEffect(duration: fast, delay: Duration(milliseconds: 200)),
  ];

  // Error animations
  static List<Effect> get errorEffect => [
    const ShakeEffect(duration: normal),
  ];

  // Loading animations
  static List<Effect> get loadingEffect => [
    const ShimmerEffect(duration: Duration(seconds: 1)),
  ];

  // Navigation animations
  static List<Effect> get pageTransitionEffect => [
    const SlideEffect(begin: Offset(0.1, 0), end: Offset.zero, duration: normal),
    const FadeEffect(duration: normal),
  ];

  // Card animations
  static List<Effect> get cardHoverEffect => [
    const ScaleEffect(begin: Offset.one, end: Offset(1.02, 1.02), duration: fast),
  ];

  static List<Effect> get cardPressEffect => [
    const ScaleEffect(begin: Offset.one, end: Offset(0.98, 0.98), duration: fast),
  ];

  // List item animations
  static List<Effect> get listItemEffect => [
    const SlideEffect(begin: Offset(0, 0.1), end: Offset.zero, duration: normal),
    const FadeEffect(duration: normal),
  ];

  // Notification animations
  static List<Effect> get notificationEffect => [
    const SlideEffect(begin: Offset(0, -0.5), end: Offset.zero, duration: normal, curve: elasticOut),
    const FadeEffect(duration: normal),
  ];

  // Modal animations
  static List<Effect> get modalEffect => [
    const ScaleEffect(begin: Offset(0.8, 0.8), end: Offset.one, duration: normal, curve: elasticOut),
    const FadeEffect(duration: normal),
  ];

  // Floating action button animations
  static List<Effect> get fabEffect => [
    const ScaleEffect(begin: Offset.zero, end: Offset.one, duration: slow, curve: elasticOut),
    const FadeEffect(duration: slow),
  ];

  // Search bar animations
  static List<Effect> get searchBarEffect => [
    const SlideEffect(begin: Offset(0, -0.2), end: Offset.zero, duration: normal),
    const FadeEffect(duration: normal),
  ];

  // Profile image animations
  static List<Effect> get profileImageEffect => [
    const ScaleEffect(begin: Offset(0.9, 0.9), end: Offset.one, duration: normal),
    const FadeEffect(duration: normal),
  ];

  // Status indicator animations
  static List<Effect> get statusIndicatorEffect => [
    const ScaleEffect(begin: Offset.zero, end: Offset.one, duration: fast, curve: elasticOut),
    const FadeEffect(duration: fast),
  ];

  // Typing indicator animations
  static List<Effect> get typingIndicatorEffect => [
    const ShimmerEffect(duration: Duration(milliseconds: 800)),
  ];

  // Message bubble animations
  static List<Effect> get messageBubbleEffect => [
    const SlideEffect(begin: Offset(0.1, 0), end: Offset.zero, duration: normal),
    const FadeEffect(duration: normal),
  ];

  // Settings toggle animations
  static List<Effect> get toggleEffect => [
    const ScaleEffect(begin: Offset.one, end: Offset(1.1, 1.1), duration: fast),
    const ScaleEffect(begin: Offset(1.1, 1.1), end: Offset.one, duration: fast, delay: fast),
  ];

  // Refresh animations
  static List<Effect> get refreshEffect => [
    const RotateEffect(begin: 0, end: 1, duration: Duration(seconds: 1)),
  ];

  // Confetti animations
  static List<Effect> get confettiEffect => [
    const ScaleEffect(begin: Offset.zero, end: Offset.one, duration: slow, curve: elasticOut),
    const FadeEffect(begin: 1.0, end: 0.0, duration: Duration(seconds: 2), delay: Duration(seconds: 1)),
  ];
}
