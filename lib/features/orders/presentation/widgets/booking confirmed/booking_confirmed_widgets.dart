// lib/features/orders/presentation/widgets/booking_confirmed/booking_confirmed_widgets.dart
//
// Widgets for the booking_confirmed_screen:
//   OrderSuccessAnimation  – animated check circle with title + subtitle
//                            (also used anywhere a success state is shown)
//   BookingConfirmedInfoRow – icon + label + value detail row

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/constants/app_color.dart';

// ─── Animated success hero ────────────────────────────────────────────────────

class OrderSuccessAnimation extends StatefulWidget {
  final String title;
  final String subtitle;
  final bool isDark;

  const OrderSuccessAnimation({
    super.key,
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  @override
  State<OrderSuccessAnimation> createState() =>
      _OrderSuccessAnimationState();
}

class _OrderSuccessAnimationState extends State<OrderSuccessAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scale =
        CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 24),
        FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.gradient,
                
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 60,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        FadeTransition(
          opacity: _fade,
          child: Column(
            children: [
              Text(
                widget.title,
                style: GoogleFonts.alexandria(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: widget.isDark
                      ? Colors.white
                      : AppColors.lightText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.alexandria(
                  fontSize: 14,
                  color: widget.isDark
                      ? AppColors.darkSubtext
                      : AppColors.lightSubtext,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Info row ─────────────────────────────────────────────────────────────────

class BookingConfirmedInfoRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final bool isDark;

  const BookingConfirmedInfoRow({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
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
                label,
                style: GoogleFonts.alexandria(
                  fontSize: 11,
                  color: isDark
                      ? AppColors.darkSubtext
                      : AppColors.lightSubtext,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.alexandria(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color:
                      isDark ? Colors.white : AppColors.lightText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
