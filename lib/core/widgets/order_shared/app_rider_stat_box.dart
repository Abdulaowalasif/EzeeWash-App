// lib/core/widgets/order_shared/app_rider_stat_box.dart
//
// A compact stat box (icon + value + label) used in the rider info bottom sheet.
// Rendered in a row of 3: Rating, Trips, ETA.
//
// Usage:
//   Row(children: [
//     AppRiderStatBox(label: 'Rating', value: '4.9', icon: Icons.star_rounded, color: Colors.amber, isDark: isDark),
//     AppRiderStatBox(label: 'Trips', value: '142', icon: Icons.route_rounded, color: AppColors.primary, isDark: isDark),
//     AppRiderStatBox(label: 'ETA', value: '8 min', icon: Icons.access_time_rounded, color: AppColors.success, isDark: isDark),
//   ])

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_color.dart';

class AppRiderStatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const AppRiderStatBox({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.alexandria(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.lightText,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.alexandria(
              fontSize: 10,
              color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
            ),
          ),
        ],
      ),
    ),
  );
}
