// lib/core/widgets/app_card.dart
//
// A themed surface card — single source of truth for card styling.
// Every card in the app (settings, help, terms, service, etc.) uses this.
//
// Usage:
//   AppCard(isDark: isDark, child: myContent)
//   AppCard(isDark: isDark, padding: EdgeInsets.all(12), child: myContent)
//   AppCard(isDark: isDark, borderRadius: 16, child: myContent)

import 'package:flutter/material.dart';

import '../constants/app_color.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final bool isDark;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color? borderColor;
  final EdgeInsetsGeometry? margin;

  const AppCard({
    super.key,
    required this.child,
    required this.isDark,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 24,
    this.borderColor,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color:
              borderColor ??
              (isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: child,
    );
  }
}
