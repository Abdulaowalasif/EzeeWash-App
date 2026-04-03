// lib/core/widgets/app_card.dart
import 'package:flutter/material.dart';

import '../constants/app_color.dart';

/// A themed surface card with consistent border, shadow, and radius.
///
/// Automatically adapts to [isDark] mode. Pass [padding] to override the
/// default 20px padding, or [borderRadius] for a different corner radius.
///
/// Usage:
/// ```dart
/// AppCard(isDark: isDark, child: myContent)
/// AppCard(isDark: isDark, padding: EdgeInsets.all(12), child: myContent)
/// ```
class AppCard extends StatelessWidget {
  final Widget child;
  final bool isDark;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color? borderColor;

  const AppCard({
    super.key,
    required this.child,
    required this.isDark,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 24,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ??
              (isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: child,
    );
  }
}
