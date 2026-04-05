// lib/core/widgets/gradient_app_bar.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_color.dart';
import '../theme/app_text_styles.dart';

/// A gradient pill-shaped app bar used across profile sub-screens.
///
/// Usage:
/// ```dart
/// appBar: GradientAppBar(title: 'Manage Addresses')
/// appBar: GradientAppBar(title: 'Help & Support', trailing: myWidget)
/// ```
class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  /// Optional leading icon (defaults to back arrow).
  final Widget? leading;

  /// Optional widget placed at the trailing end of the bar.
  final Widget? trailing;

  final bool? backEnabled;

  /// Extra height for bars that need more space (e.g. with subtitles).
  final double height;

  const GradientAppBar({
    super.key,
    required this.title,
    this.leading,
    this.trailing,
    this.height = 100,
    this.backEnabled = true,
  });

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: AppColors.gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            backEnabled == true
                ? GestureDetector(
              onTap: () => context.pop(),
              child:
              leading ??
                  const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
            )
                : SizedBox(),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.appBarTitle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          ],
        ),
      ),
    );
  }
}