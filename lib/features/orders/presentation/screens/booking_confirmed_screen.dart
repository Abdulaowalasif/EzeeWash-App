// lib/features/orders/presentation/screens/booking_confirmed_screen.dart

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
                    'Your laundry request has been successfully received.\nWe are processing your details now.',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 20),

                  // ── Order badge ─────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                          color: AppColors.primary.withOpacity(0.25)),
                    ),
                    child: Text('Order #$orderNumber',
                        style: AppTextStyles.buttonOutline
                            .copyWith(fontSize: 14, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 32),

                  // ── NEW: "What Happens Next" Card (Replaces Hardcoded Fake Data) ──
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 12),
                      child: Text(
                        'What happens next?',
                        style: AppTextStyles.heading(isDark).copyWith(fontSize: 16),
                      ),
                    ),
                  ),
                  AppCard(
                    isDark: isDark,
                    borderRadius: 22,
                    child: Column(
                      children: [
                        _NextStepRow(
                          icon: Icons.person_search_rounded,
                          color: AppColors.primary,
                          title: '1. Rider Assignment',
                          subtitle: 'A rider will be assigned to pick up your order.',
                          isDark: isDark,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(height: 1, color: Colors.black12),
                        ),
                        _NextStepRow(
                          icon: Icons.local_shipping_rounded,
                          color: AppColors.warning,
                          title: '2. Safe Transit',
                          subtitle: 'Your items are safely transported to our facility.',
                          isDark: isDark,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(height: 1, color: Colors.black12),
                        ),
                        _NextStepRow(
                          icon: Icons.check_circle_outline_rounded,
                          color: AppColors.success,
                          title: '3. Track Live',
                          subtitle: 'You can track the entire cleaning process live.',
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Buttons ─────────────────────────────────────────
                  AppGradientButton(
                    label: 'Track My Order',
                    icon: Icons.my_location_rounded,
                    onPressed: () => context.go(RoutesName.orders), // Goes to orders screen
                    verticalPadding: 16,
                    borderRadius: 16,
                  ),
                  const SizedBox(height: 14),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => context.go(RoutesName.home),
                      icon: const Icon(Icons.home_rounded,
                          color: AppColors.primary, size: 20),
                      label: Text('Back to Home',
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

// ─── Next Step Row ────────────────────────────────────────────────────────────

class _NextStepRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title, subtitle;
  final bool isDark;

  const _NextStepRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: AppTextStyles.rowTitle(isDark).copyWith(fontSize: 14)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: AppTextStyles.caption(isDark).copyWith(height: 1.3)),
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