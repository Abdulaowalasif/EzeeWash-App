// lib/core/widgets/app_section_header.dart
//
// Section title row with an optional "View All" link on the right.
//
// Usage:
//   AppSectionHeader(title: 'Our Top Services', onViewAll: () => ..., isDark: isDark)
//   AppSectionHeader(title: 'History', isDark: isDark)  // no link

import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';

class AppSectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onViewAll;
  final bool isDark;

  const AppSectionHeader({
    super.key,
    required this.title,
    required this.isDark,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTextStyles.sectionTitle(isDark)),
        if (onViewAll != null)
          GestureDetector(
            onTap: onViewAll,
            child: Text('View All', style: AppTextStyles.link),
          ),
      ],
    );
  }
}
