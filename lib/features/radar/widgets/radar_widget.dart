import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class RadarWidget extends StatelessWidget {
  const RadarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppTheme.primary,
          width: 2,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.radar,
          size: 80,
          color: AppTheme.primary,
        ),
      ),
    );
  }
}