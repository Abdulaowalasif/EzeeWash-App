// lib/core/widgets/order_shared/app_info_tile.dart
//
// A reusable icon + label + value row used in order detail cards,
// rider info sheets, and delivery details sections.
//
// Usage:
//   AppInfoTile(
//     icon: Icons.location_on_rounded,
//     color: AppColors.primary,
//     title: 'Address',
//     sub: order.pickupAddress,
//     isDark: isDark,
//   )

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_color.dart';

class AppInfoTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String sub;
  final bool isDark;
  final EdgeInsetsGeometry? padding;

  const AppInfoTile({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.sub,
    required this.isDark,
    this.padding,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: padding ?? const EdgeInsets.only(bottom: 14),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.alexandria(
                  fontSize: 11,
                  color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                ),
              ),
              Text(
                sub,
                style: GoogleFonts.alexandria(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.lightText,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
