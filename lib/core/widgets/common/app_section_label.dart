import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_color.dart';
import '../../theme/app_text_styles.dart';

// ─── Section heading ───────────────────────────────────────────────────────────

class AppSectionLabel extends StatelessWidget {
  final String text;
  final bool isDark;
  final double fontSize;
  final bool caps;

  const AppSectionLabel({
    super.key,
    required this.text,
    required this.isDark,
    this.fontSize = 16,
    this.caps = false,
  });

  @override
  Widget build(BuildContext context) {
    if (caps) {
      return Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(
          text.toUpperCase(),
          style: GoogleFonts.alexandria(
            fontWeight: FontWeight.bold,
            fontSize: 11,
            letterSpacing: 1.2,
            color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
          ),
        ),
      );
    }
    return Text(
      text,
      style: AppTextStyles.sectionTitle(isDark).copyWith(fontSize: fontSize),
    );
  }
}
