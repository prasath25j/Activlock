import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/modern_theme.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final Color? color;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 15,
    this.opacity = 0.1,
    this.color,
    this.borderRadius,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // ADJUST FOR LIGHT MODE:
    // In light mode, we need a darker, more solid "frosted" look
    final Color effectiveColor = color ?? (isDark ? Colors.white : ModernTheme.slate900);
    final double effectiveOpacity = isDark ? opacity : (opacity + 0.05).clamp(0.0, 1.0);
    final Color borderColor = isDark ? Colors.white.withOpacity(0.1) : ModernTheme.slate900.withOpacity(0.1);

    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: effectiveColor.withOpacity(effectiveOpacity),
              borderRadius: borderRadius ?? BorderRadius.circular(20),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
