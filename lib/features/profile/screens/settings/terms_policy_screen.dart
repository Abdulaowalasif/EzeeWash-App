import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const primaryColor = Color(0xFF1D4BC7);
const primaryGradient = LinearGradient(
  colors: [Color(0xFF1D4BC7), Color(0xFF2F2E98)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

class TermsPolicyScreen extends StatelessWidget {
  const TermsPolicyScreen({super.key});

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
                  "Terms & Policy",
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
          constraints: const BoxConstraints(maxWidth: 600), // Responsive tablet constraint
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),

                  /// Introduction
                  _sectionCard(
                    isDark: isDark,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Welcome to Ezee Wash",
                          style: GoogleFonts.alexandria(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "By using our laundry services, you agree to the following terms and policies. "
                              "Please read them carefully to understand your rights and responsibilities.",
                          style: GoogleFonts.alexandria(
                            fontSize: 14,
                            height: 1.6,
                            color: isDark ? Colors.grey.shade400 : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  Text(
                    "📜 Service Policies",
                    style: GoogleFonts.alexandria(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),

                  const SizedBox(height: 12),

                  _policyTile(
                      isDark,
                      "1. Service Agreement",
                      "Ezee Wash provides washing, drying, and ironing services. "
                          "All services are subject to availability and confirmation."
                  ),

                  _policyTile(
                      isDark,
                      "2. Order Processing Time",
                      "Standard orders are completed within 24–48 hours. "
                          "Delays may occur during peak seasons or due to unforeseen circumstances."
                  ),

                  _policyTile(
                      isDark,
                      "3. Pricing & Payments",
                      "All prices are listed in the app. Payments must be made upon delivery "
                          "unless otherwise agreed. We accept Cash on Delivery and selected digital payments."
                  ),

                  _policyTile(
                      isDark,
                      "4. Damage & Liability",
                      "While we take utmost care of your garments, Ezee Wash is not responsible "
                          "for damage caused by pre-existing fabric weaknesses or incorrect care labels."
                  ),

                  _policyTile(
                      isDark,
                      "5. Lost Items Policy",
                      "In rare cases of loss, compensation will be limited to a maximum value "
                          "based on garment type and condition."
                  ),

                  _policyTile(
                      isDark,
                      "6. Pickup & Delivery",
                      "Customers must ensure availability during scheduled pickup and delivery times. "
                          "Missed appointments may result in rescheduling."
                  ),

                  _policyTile(
                      isDark,
                      "7. Cancellation Policy",
                      "Orders can be cancelled before processing begins. "
                          "Once washing has started, cancellation may not be possible."
                  ),

                  _policyTile(
                      isDark,
                      "8. Privacy Policy",
                      "Your personal information is kept secure and used only for service-related purposes. "
                          "We do not share customer data with third parties without consent."
                  ),

                  const SizedBox(height: 30),

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
      ),
    );
  }

  /// Policy Card Style
  Widget _policyTile(bool isDark, String title, String description) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade100),
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.alexandria(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: GoogleFonts.alexandria(
              fontSize: 13,
              height: 1.6,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  /// Section Card
  Widget _sectionCard({required Widget child, required bool isDark}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade100),
        boxShadow: isDark ? [] : [
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
}