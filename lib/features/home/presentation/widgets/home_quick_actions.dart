// lib/features/home/presentation/widgets/home_quick_actions.dart
//
// Refactored: AppTextStyles replaces inline style references.
// Logic unchanged — AppColors.gradient and surface colors preserved.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/constants/app_color.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../routes/routes_name.dart';

class HomeQuickActions extends StatelessWidget {
  final bool isDark;
  const HomeQuickActions({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            label: 'Book Now',
            icon: Iconsax.calendar_tick,
            filled: true,
            isDark: isDark,
            onTap: () => context.push(RoutesName.placeOrdersNavigate),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _ActionButton(
            label: 'Track Order',
            icon: Iconsax.truck,
            filled: false,
            isDark: isDark,
            onTap: () => context.push(RoutesName.trackOrdersNavigate),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final bool isDark;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: filled ? AppColors.gradient : null,
          color: filled
              ? null
              : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
          borderRadius: BorderRadius.circular(14),
          border: filled
              ? null
              : Border.all(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  width: 1.5,
                ),
          boxShadow: filled
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: filled ? Colors.white : AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: filled
                  ? AppTextStyles.buttonOutline.copyWith(color: Colors.white)
                  : AppTextStyles.buttonOutline,
            ),
          ],
        ),
      ),
    );
  }
}
