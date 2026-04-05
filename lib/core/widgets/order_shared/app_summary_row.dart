// lib/core/widgets/order_shared/app_summary_row.dart
//
// A reusable icon + label + value row for order summary cards.
// Used in delivered view, cancelled view, and booking confirmation.
//
// Usage:
//   AppSummaryRow(
//     icon: Iconsax.money,
//     label: 'Total Paid',
//     value: '৳120',
//     isDark: isDark,
//     highlight: true,
//   )

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_color.dart';

class AppSummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;
  final bool highlight;

  const AppSummaryRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: highlight
              ? AppColors.primary.withOpacity(0.12)
              : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          size: 16,
          color: highlight
              ? AppColors.primary
              : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          label,
          style: GoogleFonts.alexandria(
            fontSize: 13,
            color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
          ),
        ),
      ),
      Text(
        value,
        style: GoogleFonts.alexandria(
          fontSize: highlight ? 16 : 13,
          fontWeight: FontWeight.bold,
          color: highlight
              ? AppColors.primary
              : (isDark ? Colors.white : AppColors.lightText),
        ),
      ),
    ],
  );
}
