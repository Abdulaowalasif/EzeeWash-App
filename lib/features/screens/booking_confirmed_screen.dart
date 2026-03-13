// lib/features/orders/screens/booking_confirmed_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../../../routes/routes_name.dart';
import '../../core/constants/app_color.dart';
import '../../core/utils/responsive.dart';

class BookingConfirmedScreen extends StatelessWidget {
  final String orderNumber;
  const BookingConfirmedScreen({super.key, required this.orderNumber});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: Responsive.maxContentWidth(context)),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: Responsive.horizontalPadding(context), vertical: 24),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [

                // ── Animation ─────────────────────────────────────
                SizedBox(
                  height: 220,
                  child: Lottie.asset(
                    'assets/animation/confirmed.json',
                    repeat: false,
                    errorBuilder: (_, __, ___) => Container(
                      width: 120, height: 120,
                      decoration: BoxDecoration(
                        gradient: AppColors.gradient, shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 24, offset: const Offset(0, 8))],
                      ),
                      child: const Icon(Icons.check_rounded, color: Colors.white, size: 60),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Order badge ────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: AppColors.primary.withOpacity(0.25)),
                  ),
                  child: Text('Order #$orderNumber',
                      style: GoogleFonts.alexandria(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
                ),

                const SizedBox(height: 20),

                Text('Booking Confirmed!',
                    style: GoogleFonts.alexandria(fontSize: 26, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.lightText),
                    textAlign: TextAlign.center),

                const SizedBox(height: 12),

                Text("Your laundry is in good hands. We'll notify you once our rider is on the way for pickup.",
                    style: GoogleFonts.alexandria(fontSize: 14, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext, height: 1.6),
                    textAlign: TextAlign.center),

                const SizedBox(height: 32),

                // ── Summary card ───────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 14, offset: const Offset(0, 5))],
                  ),
                  child: Column(children: [
                    _InfoRow(icon: Icons.local_laundry_service_rounded, color: AppColors.primary, label: 'Service', value: 'Wash & Fold', isDark: isDark),
                    const SizedBox(height: 14),
                    _InfoRow(icon: Icons.storefront_rounded, color: const Color(0xFF8B5CF6), label: 'Store', value: 'Downtown Store', isDark: isDark),
                    const SizedBox(height: 14),
                    _InfoRow(icon: Icons.calendar_today_rounded, color: AppColors.success, label: 'Est. Pickup', value: 'Tomorrow, 10:00 AM', isDark: isDark),
                    const SizedBox(height: 14),
                    _InfoRow(icon: Icons.notifications_active_rounded, color: AppColors.warning, label: 'Updates', value: 'Via push notifications', isDark: isDark),
                  ]),
                ),

                const SizedBox(height: 28),

                // ── Back to Home ───────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.gradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 14, offset: const Offset(0, 5))],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () => context.go(RoutesName.main),
                      icon: const Icon(Icons.home_rounded, color: Colors.white),
                      label: Text('Back to Home', style: GoogleFonts.alexandria(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => context.go(RoutesName.orders),
                    icon: const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 20),
                    label: Text('View My Orders', style: GoogleFonts.alexandria(color: AppColors.primary, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.primary, width: 1.5), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon; final Color color; final String label, value; final bool isDark;
  const _InfoRow({required this.icon, required this.color, required this.label, required this.value, required this.isDark});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 18)),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.alexandria(fontSize: 11, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
        Text(value, style: GoogleFonts.alexandria(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.lightText)),
      ])),
    ]);
  }
}