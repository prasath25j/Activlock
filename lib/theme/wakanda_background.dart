import 'package:flutter/material.dart';
import 'arctic_theme.dart';

class WakandaBackground extends StatelessWidget {
  final Widget child;

  const WakandaBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            ArcticTheme.iceWhite,
            ArcticTheme.pureWhite,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Decorative Soft Circles
          Positioned(
            top: -150,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ArcticTheme.frostBlue.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ArcticTheme.frostBlue.withOpacity(0.03),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
