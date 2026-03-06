import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const primaryColor = Color(0xFF1D4BC7);
const primaryGradient = LinearGradient(
  colors: [Color(0xFF1D4BC7), Color(0xFF2F2E98)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),

      /// ---------------- Gradient AppBar ----------------
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 16),
                Text(
                  "Help & Support",
                  style: GoogleFonts.alexandria(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      /// ---------------- Body ----------------
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),

                /// Need Assistance Card
                _sectionCard(
                  isDark: isDark,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Need Assistance? We’re Here to Help! 💡",
                        style: GoogleFonts.alexandria(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "At Ezee Wash, your satisfaction is our priority.\n"
                            "If you have any questions, issues, or feedback, feel free to reach out to us.",
                        style: GoogleFonts.alexandria(
                          fontSize: 14,
                          height: 1.6,
                          color: isDark ? Colors.grey.shade400 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                /// FAQ Section
                Text(
                  "📌 Frequently Asked Questions",
                  style: GoogleFonts.alexandria(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),

                const SizedBox(height: 16),

                _faqTile(
                  isDark,
                  "How long does it take to complete an order?",
                  "Most orders are completed within 24–48 hours depending on service type and load.",
                ),
                _faqTile(
                  isDark,
                  "Can I track my order?",
                  "Yes! You can track your active orders directly from the Orders section in the app.",
                ),
                _faqTile(
                  isDark,
                  "What payment methods do you accept?",
                  "We accept Cash on Delivery and selected mobile payment options.",
                ),
                _faqTile(
                  isDark,
                  "Can I reschedule my pickup?",
                  "Yes, you can reschedule your pickup before confirmation by contacting support.",
                ),

                const SizedBox(height: 30),

                /// Contact Section
                _sectionCard(
                  isDark: isDark,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.headset_mic_rounded, color: primaryColor),
                          const SizedBox(width: 10),
                          Text(
                            "Contact Us",
                            style: GoogleFonts.alexandria(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "If you still need help, contact us directly:",
                        style: GoogleFonts.alexandria(
                          fontSize: 14,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _contactInfoRow(isDark, Icons.alternate_email_rounded, "support@ezwash.com"),
                      const SizedBox(height: 12),
                      _contactInfoRow(isDark, Icons.phone_iphone_rounded, "+880-1516503532"),
                      const SizedBox(height: 12),
                      _contactInfoRow(isDark, Icons.schedule_rounded, "10:00 AM – 8:00 PM"),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                /// Footer
                Center(
                  child: Column(
                    children: [
                      Text(
                        "Ezee Wash",
                        style: GoogleFonts.pacifico(
                          fontSize: 18,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Clean Clothes. Clear Mind.",
                        textAlign: TextAlign.center,
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

  /// Card Section
  Widget _sectionCard({required Widget child, required bool isDark}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade100),
        boxShadow: isDark
            ? []
            : [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  /// Contact Info Row Helper
  Widget _contactInfoRow(bool isDark, IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: primaryColor),
        ),
        const SizedBox(width: 14),
        Text(
          text,
          style: GoogleFonts.alexandria(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.grey.shade300 : Colors.black87,
          ),
        ),
      ],
    );
  }

  /// Expandable FAQ Tile
  Widget _faqTile(bool isDark, String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade100),
      ),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: primaryColor,
          collapsedIconColor: Colors.grey,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          title: Text(
            question,
            style: GoogleFonts.alexandria(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                answer,
                style: GoogleFonts.alexandria(
                  fontSize: 13,
                  height: 1.6,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}