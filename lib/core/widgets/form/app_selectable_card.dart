// lib/core/widgets/form/app_selectable_card.dart
//
// A tappable animated card with a selection state.
// Used for service cards, store cards, and payment options across the app.
//
// Usage:
//   AppSelectableCard(
//     selected: _serviceIdx == i,
//     isDark: isDark,
//     onTap: () => setState(() => _serviceIdx = i),
//     child: Row(children: [...]),
//   )

import 'package:flutter/material.dart';
import '../../constants/app_color.dart';

class AppSelectableCard extends StatelessWidget {
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final Color? accentColor;

  const AppSelectableCard({
    super.key,
    required this.selected,
    required this.isDark,
    required this.onTap,
    required this.child,
    this.margin = const EdgeInsets.only(bottom: 14),
    this.accentColor,
  });

  Color get _accent => accentColor ?? AppColors.primary;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        margin: margin,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected
              ? _accent.withOpacity(isDark ? 0.15 : 0.07)
              : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected
                ? _accent
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: selected ? 2 : 1,
          ),
        ),
        child: child,
      ),
    );
  }
}

/// Gradient check-mark badge shown at trailing end of a selected card.
class AppSelectedBadge extends StatelessWidget {
  const AppSelectedBadge({super.key});

  @override
  Widget build(BuildContext context) => Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.gradient,
        ),
        child: const Icon(Icons.check, color: Colors.white, size: 16),
      );
}

/// Thumbnail/icon box shown on the leading end of a service or store card.
class AppItemThumbnail extends StatelessWidget {
  final String? imageUrl;
  final IconData fallbackIcon;
  final bool selected;
  final bool isDark;

  const AppItemThumbnail({
    super.key,
    required this.imageUrl,
    required this.fallbackIcon,
    required this.selected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) => Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: selected && imageUrl == null ? AppColors.gradient : null,
          color: selected
              ? null
              : (isDark ? Colors.grey.shade800 : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(15),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: imageUrl != null
              ? Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(
                    fallbackIcon,
                    color: selected ? Colors.white : Colors.grey,
                  ),
                )
              : Icon(fallbackIcon,
                  color: selected ? Colors.white : Colors.grey),
        ),
      );
}
