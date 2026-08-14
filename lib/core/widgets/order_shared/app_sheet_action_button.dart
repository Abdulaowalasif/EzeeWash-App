// lib/core/widgets/order_shared/app_sheet_action_button.dart
//
// A themed action button for bottom sheets (e.g. "Call Rider", "Message").
// Supports enabled/disabled state with graceful visual degradation.
//
// Usage:
//   AppSheetActionButton(
//     icon: Icons.call_rounded,
//     label: 'Call Rider',
//     color: AppColors.success,
//     isDark: isDark,
//     enabled: phone.isNotEmpty,
//     onTap: () async { ... },
//   )

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppSheetActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final bool enabled;
  final VoidCallback onTap;

  const AppSheetActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: enabled ? onTap : null,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: enabled
            ? color.withValues(alpha: isDark ? 0.18 : 0.1)
            : (isDark ? Colors.white10 : Colors.grey.shade100),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: enabled
              ? color.withValues(alpha: 0.3)
              : (isDark ? Colors.white12 : Colors.grey.shade200),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 18,
            color: enabled
                ? color
                : (isDark ? Colors.white38 : Colors.grey.shade400),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.alexandria(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: enabled
                  ? color
                  : (isDark ? Colors.white38 : Colors.grey.shade400),
            ),
          ),
        ],
      ),
    ),
  );
}
