import 'package:flutter/material.dart';
import '../../constants/app_color.dart';
import '../../theme/app_text_styles.dart';

// ─── Expandable tile ──────────────────────────────────────────────────────────

class AppExpandableTile extends StatelessWidget {
  final String title;
  final String body;
  final bool isDark;
  final EdgeInsetsGeometry margin;

  const AppExpandableTile({
    super.key,
    required this.title,
    required this.body,
    required this.isDark,
    this.margin = const EdgeInsets.only(bottom: 12),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: AppColors.primary,
          collapsedIconColor: Colors.grey,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          title: Text(
            title,
            style: AppTextStyles.body(
              isDark,
            ).copyWith(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                body,
                style: AppTextStyles.bodyLong(isDark).copyWith(fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
