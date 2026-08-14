// lib/features/orders/presentation/widgets/track_order_info_panel.dart
//
// Info panel shown during "waiting" and "heading to store" phases.
// Displays a pulsing icon, title, subtitle, and the order details card below.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/constants/app_color.dart';
import '../../../../../core/widgets/order_shared/app_pulse_icon.dart';
import '../../../domain/entities/order_entity.dart';
import 'track_order_details_card.dart';
import '../../screens/track_order_screen.dart' show OrderPhase;

class TrackOrderInfoPanel extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final OrderEntity order;
  final bool isDark;
  final OrderPhase phase;

  const TrackOrderInfoPanel({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.order,
    required this.isDark,
    required this.phase,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 220,
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkSurface
                : color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? AppColors.darkBorder
                  : color.withValues(alpha: 0.15),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppPulseIcon(icon: icon, color: color, size: 48),
              const SizedBox(height: 20),
              Text(
                title,
                style: GoogleFonts.alexandria(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.lightText,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.alexandria(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.darkSubtext
                        : AppColors.lightSubtext,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        TrackOrderDetailsCard(order: order, isDark: isDark, phase: phase),
      ],
    );
  }
}
