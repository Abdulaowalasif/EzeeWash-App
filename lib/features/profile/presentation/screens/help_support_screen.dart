// lib/features/profile/presentation/screens/help_support_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

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
    a: 'Most orders are completed within 24–48 hours depending on service type and load.'
    ),
    (
    q: 'Can I track my order?',
    a: 'Yes! You can track your active orders directly from the Orders section in the app.'
    ),
    (
    q: 'What payment methods do you accept?',
    a: 'We accept Cash on Delivery and selected mobile payment options.'
    ),
    (
    q: 'Can I reschedule my pickup?',
    a: 'Yes, you can reschedule your pickup before confirmation by contacting support.'
    ),
    (
    q: 'What if my clothes are damaged?',
    a:
    'We take utmost care of all garments. In rare cases, please contact us within 24 hours of delivery and we\'ll resolve the issue promptly.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: GradientAppBar(title: 'Help & Support'),
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

                // ── Hero card ──────────────────────────────────────────
                AppCard(
                  isDark: isDark,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: AppColors.gradient,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.headset_mic_rounded, color: Colors.white, size: 26),
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
                                color: isDark ? Colors.white : AppColors.lightText,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Your satisfaction is our priority.',
                              style: GoogleFonts.alexandria(
                                fontSize: 13,
                                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                AppSectionLabel(text: '📌 Frequently Asked Questions', isDark: isDark),
                const SizedBox(height: 14),

                // ── FAQ tiles ──────────────────────────────────────────
                ..._faqs.map((item) => _FaqTile(q: item.q, a: item.a, isDark: isDark)),

                const SizedBox(height: 28),

                AppSectionLabel(text: '📞 Contact Us', isDark: isDark),
                const SizedBox(height: 14),

                // ── Contact card ───────────────────────────────────────
                AppCard(
                  isDark: isDark,
                  child: Column(
                    children: [
                      _ContactRow(
                        icon: Icons.alternate_email_rounded,
                        color: AppColors.primary,
                        label: 'Email',
                        value: 'support@ezeewash.com',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 16),
                      _ContactRow(
                        icon: Icons.phone_iphone_rounded,
                        color: AppColors.success,
                        label: 'Phone',
                        value: '+880-1516-503532',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 16),
                      _ContactRow(
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

                // ── Footer ─────────────────────────────────────────────
                Center(
                  child: Column(
                    children: [
                      Text('Ezee Wash',
                          style: GoogleFonts.pacifico(fontSize: 18, color: AppColors.primary)),
                      const SizedBox(height: 4),
                      Text(
                        'Clean Clothes. Clear Mind.',
                        style: GoogleFonts.alexandria(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
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

// ──────────────────────────────────────────────────────────────────────────────
// Shared sub-widgets
// ──────────────────────────────────────────────────────────────────────────────




class _FaqTile extends StatelessWidget {
  final String q;
  final String a;
  final bool isDark;
  const _FaqTile({required this.q, required this.a, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: AppColors.primary,
          collapsedIconColor: Colors.grey,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          title: Text(q,
              style: GoogleFonts.alexandria(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.lightText,
              )),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(a,
                  style: GoogleFonts.alexandria(
                    fontSize: 13,
                    height: 1.6,
                    color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                  )),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final bool isDark;
  const _ContactRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, size: 18, color: color),
      ),
      const SizedBox(width: 14),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: GoogleFonts.alexandria(
                fontSize: 11, color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext)),
        Text(value,
            style: GoogleFonts.alexandria(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.lightText)),
      ]),
    ]);
  }
}