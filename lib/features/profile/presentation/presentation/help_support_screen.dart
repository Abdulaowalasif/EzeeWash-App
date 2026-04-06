// lib/features/profile/presentation/presentation/help_support_screen.dart
//
// Refactored: all duplicated widget patterns replaced with core widgets.
//   _FaqTile      → AppExpandableTile
//   _ContactRow   → AppContactRow
//   footer        → AppBrandFooter
//   hero/contact card → AppCard

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_color.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/gradient_app_bar.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const _faqs = [
    (
    q: 'How long does it take to complete an order?',
    a: 'Most orders are completed within 24–48 hours depending on service type and load.',
    ),
    (
    q: 'Can I track my order?',
    a: 'Yes! You can track your active orders directly from the Orders section in the app.',
    ),
    (
    q: 'What payment methods do you accept?',
    a: 'We accept Cash on Delivery and selected mobile payment options.',
    ),
    (
    q: 'Can I reschedule my pickup?',
    a: 'Yes, you can reschedule your pickup before confirmation by contacting support.',
    ),
    (
    q: 'What if my clothes are damaged?',
    a: "We take utmost care of all garments. In rare cases, please contact us within 24 hours of delivery and we'll resolve the issue promptly.",
    ),
  ];

  Future<void> _launchUrl(String urlString) async {
    final Uri uri = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Could not launch $uri: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
      isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: GradientAppBar(title: 'Help & Support'),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxWidth: Responsive.maxContentWidth(context)),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(
                horizontal: Responsive.horizontalPadding(context)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),

                // ── Hero card ───────────────────────────────────────
                AppCard(
                  isDark: isDark,
                  child: Row(
                    children: [
                      AppIconBox(
                        icon: Icons.headset_mic_rounded,
                        iconSize: 26,
                        padding: 14,
                        borderRadius: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "We're Here to Help!",
                              style: GoogleFonts.alexandria(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.lightText,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Your satisfaction is our priority.',
                              style: GoogleFonts.alexandria(
                                fontSize: 13,
                                color: isDark
                                    ? AppColors.darkSubtext
                                    : AppColors.lightSubtext,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),
                AppSectionLabel(
                    text: '📌 Frequently Asked Questions',
                    isDark: isDark),
                const SizedBox(height: 14),

                // ── FAQ tiles ───────────────────────────────────────
                ..._faqs.map((item) => AppExpandableTile(
                  title: item.q,
                  body: item.a,
                  isDark: isDark,
                )),

                const SizedBox(height: 28),
                AppSectionLabel(text: '📞 Contact Us', isDark: isDark),
                const SizedBox(height: 14),

                // ── Contact card ────────────────────────────────────
                AppCard(
                  isDark: isDark,
                  child: Column(
                    children: [
                      AppContactRow(
                        icon: Icons.alternate_email_rounded,
                        color: AppColors.primary,
                        label: 'Email',
                        value: 'support@ezeewash.com',
                        isDark: isDark,
                        onTap: () =>
                            _launchUrl('mailto:support@ezeewash.com'),
                      ),
                      const SizedBox(height: 16),
                      AppContactRow(
                        icon: Icons.phone_iphone_rounded,
                        color: AppColors.success,
                        label: 'Phone',
                        value: '+880-1516-503532',
                        isDark: isDark,
                        onTap: () => _launchUrl('tel:+8801516503532'),
                      ),
                      const SizedBox(height: 16),
                      AppContactRow(
                        icon: Icons.schedule_rounded,
                        color: AppColors.warning,
                        label: 'Working Hours',
                        value: '10:00 AM – 8:00 PM',
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 36),
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