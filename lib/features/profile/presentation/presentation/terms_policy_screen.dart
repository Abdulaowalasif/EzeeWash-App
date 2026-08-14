// lib/features/profile/presentation/presentation/terms_policy_screen.dart
//
// Refactored: _PolicyTile → AppCard (inline, always expanded)
//             footer → AppBrandFooter
//             section label → AppSectionLabel
//             GoogleFonts inline → AppTextStyles

import 'package:flutter/material.dart';

import '../../../../core/constants/app_color.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/widgets.dart';

class TermsPolicyScreen extends StatelessWidget {
  const TermsPolicyScreen({super.key});

  static const _policies = [
    (
      title: '1. Service Agreement',
      body:
          'Ezee Wash provides washing, drying, and ironing services. All services are subject to availability and confirmation.',
    ),
    (
      title: '2. Order Processing Time',
      body:
          'Standard orders are completed within 24–48 hours. Delays may occur during peak seasons or due to unforeseen circumstances.',
    ),
    (
      title: '3. Pricing & Payments',
      body:
          'All prices are listed in the app. Payments must be made upon delivery unless otherwise agreed. We accept Cash on Delivery and selected digital payments.',
    ),
    (
      title: '4. Damage & Liability',
      body:
          'While we take utmost care of your garments, Ezee Wash is not responsible for damage caused by pre-existing fabric weaknesses or incorrect care labels.',
    ),
    (
      title: '5. Lost Items Policy',
      body:
          'In rare cases of loss, compensation will be limited to a maximum value based on garment type and condition.',
    ),
    (
      title: '6. Pickup & Delivery',
      body:
          'Customers must ensure availability during scheduled pickup and delivery times. Missed appointments may result in rescheduling.',
    ),
    (
      title: '7. Cancellation Policy',
      body:
          'Orders can be cancelled before processing begins. Once washing has started, cancellation may not be possible.',
    ),
    (
      title: '8. Privacy Policy',
      body:
          'Your personal information is kept secure and used only for service-related purposes. We do not share customer data with third parties without consent.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: GradientAppBar(title: 'Terms & Policy'),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: Responsive.maxContentWidth(context),
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.horizontalPadding(context),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),

                // ── Intro card ──────────────────────────────────────
                AppCard(
                  isDark: isDark,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          AppGradientIconBox(
                            icon: Icons.description_rounded,
                            size: 20,
                            padding: 10,
                            borderRadius: 12,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Welcome to Ezee Wash',
                            style: AppTextStyles.sectionTitle(isDark),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'By using our laundry services, you agree to the following terms and policies. Please read them carefully to understand your rights and responsibilities.',
                        style: AppTextStyles.bodyLong(
                          isDark,
                        ).copyWith(fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Last updated: January 2025',
                          style: AppTextStyles.price.copyWith(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                AppSectionLabel(text: '📜 Service Policies', isDark: isDark),
                const SizedBox(height: 14),

                // ── Policy tiles ────────────────────────────────────
                ..._policies.map(
                  (p) =>
                      _PolicyTile(title: p.title, body: p.body, isDark: isDark),
                ),

                const SizedBox(height: 32),
                const AppBrandFooter(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Policy tile (always-expanded) ───────────────────────────────────────────

class _PolicyTile extends StatelessWidget {
  final String title;
  final String body;
  final bool isDark;

  const _PolicyTile({
    required this.title,
    required this.body,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      isDark: isDark,
      padding: const EdgeInsets.all(18),
      borderRadius: 20,
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.body(isDark).copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: AppTextStyles.bodyLong(isDark).copyWith(fontSize: 13),
          ),
        ],
      ),
    );
  }
}
