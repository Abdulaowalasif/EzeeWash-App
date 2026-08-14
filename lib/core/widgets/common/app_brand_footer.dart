import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_color.dart';

// ─── Brand footer ─────────────────────────────────────────────────────────────

class AppBrandFooter extends StatelessWidget {
  const AppBrandFooter({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      children: [
        Text(
          'Ezze Wash',
          style: GoogleFonts.pacifico(fontSize: 18, color: AppColors.primary),
        ),
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
  );
}
