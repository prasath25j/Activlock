import 'package:flutter/material.dart';
import 'modern_theme.dart';

class WakandaBackground extends StatelessWidget {
  final Widget child;

  const WakandaBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!isDark) {
      return Stack(
        children: [
          Positioned.fill(
            child: Container(color: const Color(0xFFFDFDFF)),
          ),
          // Decorative Soft Mesh Gradients for Light Mode
          Positioned(
            top: -150,
            right: -100,
            child: _MeshCircle(
              color: ModernTheme.primaryBlue.withOpacity(0.08),
              size: 400,
            ),
          ),
          Positioned(
            bottom: -100,
            left: -100,
            child: _MeshCircle(
              color: ModernTheme.accentPink.withOpacity(0.05),
              size: 350,
            ),
          ),
          child,
        ],
      );
    }

    return Stack(
      children: [
        Positioned.fill(
          child: Container(color: ModernTheme.slate900),
        ),
        // Decorative Mesh Gradients
        Positioned(
          top: -100,
          right: -50,
          child: _MeshCircle(
            color: ModernTheme.primaryBlue.withOpacity(0.2),
            size: 300,
          ),
        ),
        Positioned(
          bottom: -50,
          left: -50,
          child: _MeshCircle(
            color: ModernTheme.accentPink.withOpacity(0.15),
            size: 250,
          ),
        ),
        Positioned(
          top: 300,
          left: -100,
          child: _MeshCircle(
            color: ModernTheme.accentCyan.withOpacity(0.1),
            size: 200,
          ),
        ),
        child,
      ],
    );
  }
}

class _MeshCircle extends StatelessWidget {
  final Color color;
  final double size;

  const _MeshCircle({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withOpacity(0)],
          stops: const [0.3, 1.0],
        ),
      ),
    );
  }
}
