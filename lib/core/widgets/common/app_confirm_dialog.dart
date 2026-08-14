import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_color.dart';

// ─── Confirm dialog ───────────────────────────────────────────────────────────

class AppConfirmDialog {
  AppConfirmDialog._();

  static void show(
    BuildContext context, {
    required String title,
    required String message,
    String cancelLabel = 'Cancel',
    String confirmLabel = 'Confirm',
    Color confirmColor = AppColors.primary,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: GoogleFonts.alexandria(fontWeight: FontWeight.bold),
        ),
        content: Text(message, style: GoogleFonts.alexandria(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(
              cancelLabel,
              style: GoogleFonts.alexandria(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              onConfirm();
            },
            child: Text(
              confirmLabel,
              style: GoogleFonts.alexandria(
                color: confirmColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
