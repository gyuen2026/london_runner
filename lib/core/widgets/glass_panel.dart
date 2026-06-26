import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:london_runner/core/theme/app_theme.dart';
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius,
    this.blur = 24,
    this.tint,
  });

  final Widget child;
  final EdgeInsets padding;
  final double? borderRadius;
  final double blur;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final r = borderRadius ?? AppTheme.radiusMd;
    return ClipRRect(
      borderRadius: BorderRadius.circular(r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: (tint ?? AppTheme.glassFill).withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(r),
            border: Border.all(color: AppTheme.glassBorder.withValues(alpha: 0.35)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.14),
                Colors.white.withValues(alpha: 0.04),
              ],
            ),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
