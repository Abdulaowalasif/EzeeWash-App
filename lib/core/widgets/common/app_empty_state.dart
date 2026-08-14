import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../constants/app_color.dart';
import '../../theme/app_text_styles.dart';

// ─── Empty-state placeholder ──────────────────────────────────────────────────

class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? subtitle;
  final bool isDark;

  const AppEmptyState({
    super.key,
    this.icon = Iconsax.box_remove,
    required this.message,
    this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 64,
          color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
        ),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: AppTextStyles.cardTitle(isDark),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption(isDark),
          ),
        ],
      ],
    ),
  );
}
