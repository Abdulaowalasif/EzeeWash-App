// lib/features/orders/presentation/screens/booking_confirmed_screen.dart
//
// Refactored: AppCard replaces raw Container+BoxDecoration
//             AppIconBox replaces _InfoRow icon container
//             AppGradientButton replaces inline gradient button
//             AppTextStyles replaces GoogleFonts inline calls

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../routes/routes_name.dart';
import '../../../../core/constants/app_color.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/widgets.dart';

class BookingConfirmedScreen extends StatelessWidget {
  final String orderNumber;
  const BookingConfirmedScreen({super.key, required this.orderNumber});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
      isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: const GradientAppBar(
          title: 'Booking Confirmed', backEnabled: false),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
                maxWidth: Responsive.maxContentWidth(context)),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.horizontalPadding(context),
                vertical: 24,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OrderSuccessAnimation(
                    title: 'Order Confirmed!',
                    subtitle:
                    'Your laundry request has been received.\nWe are assigning a rider now.',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 20),

                  // ── Order badge ─────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 9),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                          color: AppColors.primary.withOpacity(0.25)),
                    ),
                    child: Text('Order #$orderNumber',
                        style: AppTextStyles.buttonOutline
                            .copyWith(fontSize: 13)),
                  ),
                  const SizedBox(height: 32),

                  // ── Summary card ────────────────────────────────────
                  AppCard(
                    isDark: isDark,
                    borderRadius: 22,
                    child: Column(
                      children: [
                        _InfoRow(
                          icon: Icons.local_laundry_service_rounded,
                          color: AppColors.primary,
                          label: 'Service',
                          value: 'Wash & Fold',
                          isDark: isDark,
                        ),
                        const SizedBox(height: 14),
                        _InfoRow(
                          icon: Icons.storefront_rounded,
                          color: const Color(0xFF8B5CF6),
                          label: 'Store',
                          value: 'Downtown Store',
                          isDark: isDark,
                        ),
                        const SizedBox(height: 14),
                        _InfoRow(
                          icon: Icons.calendar_today_rounded,
                          color: AppColors.success,
                          label: 'Est. Pickup',
                          value: 'Tomorrow, 10:00 AM',
                          isDark: isDark,
                        ),
                        const SizedBox(height: 14),
                        _InfoRow(
                          icon: Icons.notifications_active_rounded,
                          color: AppColors.warning,
                          label: 'Updates',
                          value: 'Via push notifications',
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  AppGradientButton(
                    label: 'Back to Home',
                    icon: Icons.home_rounded,
                    onPressed: () => context.go(RoutesName.home),
                    verticalPadding: 16,
                    borderRadius: 16,
                  ),
                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => context.go(RoutesName.orders),
                      icon: const Icon(Icons.receipt_long_rounded,
                          color: AppColors.primary, size: 20),
                      label: Text('View My Orders',
                          style: AppTextStyles.buttonOutline),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: AppColors.primary, width: 1.5),
                        padding:
                        const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Info row ─────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label, value;
  final bool isDark;

  const _InfoRow({
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
        AppIconBox(icon: icon, color: color, borderRadius: 12),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.caption(isDark)),
              Text(value,
                  style: AppTextStyles.rowTitle(isDark)
                      .copyWith(fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Success animation (public — reused by other screens) ─────────────────────

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
        vsync: this, duration: const Duration(milliseconds: 700));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
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
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.4),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(Icons.check_rounded,
                  color: Colors.white, size: 60),
            ),
          ),
        ),
        const SizedBox(height: 24),
        FadeTransition(
          opacity: _fade,
          child: Column(
            children: [
              Text(widget.title,
                  style: AppTextStyles.heading(widget.isDark)
                      .copyWith(fontSize: 26)),
              const SizedBox(height: 8),
              Text(widget.subtitle,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyLong(widget.isDark)),
            ],
          ),
        ),
      ],
    );
  }
}
