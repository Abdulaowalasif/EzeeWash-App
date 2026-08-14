// lib/core/widgets/order_shared/app_surface_card.dart
//
// A themed card container used throughout the app. Handles dark/light theming,
// border, shadow, and optional accent border color.
//
// Usage:
//   AppSurfaceCard(
//     isDark: isDark,
//     child: YourContent(),
//   )
//
//   AppSurfaceCard(
//     isDark: isDark,
//     accentColor: AppColors.primary,  // optional colored border
//     child: YourContent(),
//   )

import 'package:flutter/material.dart';
import '../../constants/app_color.dart';

class AppSurfaceCard extends StatelessWidget {
  final Widget child;
  final bool isDark;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? accentColor;
  final bool hasShadow;

  const AppSurfaceCard({
    super.key,
    required this.child,
    required this.isDark,
    this.padding = const EdgeInsets.all(18),
    this.borderRadius = 22,
    this.accentColor,
    this.hasShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor =
        accentColor?.withValues(alpha: 0.3) ??
        (isDark ? AppColors.darkBorder : AppColors.lightBorder);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor,
          width: accentColor != null ? 1.5 : 1,
        ),
        boxShadow: (!isDark && hasShadow)
            ? [
                BoxShadow(
                  color:
                      accentColor?.withValues(alpha: 0.08) ??
                      Colors.black.withValues(alpha: 0.03),
                  blurRadius: accentColor != null ? 16 : 10,
                  offset: Offset(0, accentColor != null ? 6 : 4),
                ),
              ]
            : [],
      ),
      child: child,
    );
  }
}
