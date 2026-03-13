// lib/features/profile/screens/settings/terms_policy_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_color.dart';
import '../../core/utils/revponsive.dart';

class TermsPolicyScreen extends StatelessWidget {
  const TermsPolicyScreen({super.key});

  static const _policies = [
    (
    title: '1. Service Agreement',
    body:
    'Ezee Wash provides washing, drying, and ironing services. All services are subject to availability and confirmation.'
    ),
    (
    title: '2. Order Processing Time',
    body:
    'Standard orders are completed within 24–48 hours. Delays may occur during peak seasons or due to unforeseen circumstances.'
    ),
    (
    title: '3. Pricing & Payments',
    body:
    'All prices are listed in the app. Payments must be made upon delivery unless otherwise agreed. We accept Cash on Delivery and selected digital payments.'
    ),
    (
    title: '4. Damage & Liability',
    body:
    'While we take utmost care of your garments, Ezee Wash is not responsible for damage caused by pre-existing fabric weaknesses or incorrect care labels.'
    ),
    (
    title: '5. Lost Items Policy',
    body:
    'In rare cases of loss, compensation will be limited to a maximum value based on garment type and condition.'
    ),
    (
    title: '6. Pickup & Delivery',
    body:
    'Customers must ensure availability during scheduled pickup and delivery times. Missed appointments may result in rescheduling.'
    ),
    (
    title: '7. Cancellation Policy',
    body:
    'Orders can be cancelled before processing begins. Once washing has started, cancellation may not be possible.'
    ),
    (
    title: '8. Privacy Policy',
    body:
    'Your personal information is kept secure and used only for service-related purposes. We do not share customer data with third parties without consent.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: _GradientAppBar(title: 'Terms & Policy'),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: Responsive.maxContentWidth(context)),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: Responsive.horizontalPadding(context)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),

                // ── Intro card ─────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    boxShadow: isDark
                        ? []
                        : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 6))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: AppColors.gradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.description_rounded, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Welcome to Ezee Wash',
                          style: GoogleFonts.alexandria(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.lightText,
                          ),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      Text(
                        'By using our laundry services, you agree to the following terms and policies. Please read them carefully to understand your rights and responsibilities.',
                        style: GoogleFonts.alexandria(
                          fontSize: 13,
                          height: 1.6,
                          color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Last updated badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Last updated: January 2025',
                          style: GoogleFonts.alexandria(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  '📜 Service Policies',
                  style: GoogleFonts.alexandria(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.lightText,
                  ),
                ),

                const SizedBox(height: 14),

                // ── Policy tiles ───────────────────────────────────────
                ..._policies.map((p) => _PolicyTile(title: p.title, body: p.body, isDark: isDark)),

                const SizedBox(height: 32),

                // ── Footer ─────────────────────────────────────────────
                Center(
                  child: Column(children: [
                    Text('Ezee Wash',
                        style: GoogleFonts.pacifico(fontSize: 18, color: AppColors.primary)),
                    const SizedBox(height: 4),
                    Text(
                      'Clean Clothes. Clear Mind.',
                      style: GoogleFonts.alexandria(
                          fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey.shade500),
                    ),
                  ]),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  const _GradientAppBar({required this.title});

  @override
  Size get preferredSize => const Size.fromHeight(100);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: EdgeInsets.fromLTRB(
            Responsive.horizontalPadding(context), 10, Responsive.horizontalPadding(context), 10),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: AppColors.gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 5))
          ],
        ),
        child: Row(children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 16),
          Text(title,
              style: GoogleFonts.alexandria(
                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }
}

class _PolicyTile extends StatelessWidget {
  final String title;
  final String body;
  final bool isDark;
  const _PolicyTile({required this.title, required this.body, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        boxShadow: isDark
            ? []
            : [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.alexandria(
                  fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
          const SizedBox(height: 8),
          Text(body,
              style: GoogleFonts.alexandria(
                  fontSize: 13,
                  height: 1.6,
                  color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
        ],
      ),
    );
  }
}