// lib/core/widgets/app_snack_bar.dart
//
// Single source of truth for snack bar display across the app.
//
// Usage:
//   AppSnackBar.show(context, 'Order placed!');
//   AppSnackBar.show(context, 'Something went wrong', type: SnackBarType.error);
//   AppSnackBar.show(context, 'Please wait...', type: SnackBarType.warning);
//
import 'package:flutter/material.dart';

import '../constants/app_color.dart';
import '../theme/app_text_styles.dart';

enum SnackBarType { success, error, warning }

class AppSnackBar {
  AppSnackBar._();

  static void show(
      BuildContext context,
      String message, {
        SnackBarType type = SnackBarType.success,
        // Legacy boolean support — maps to error type.
        bool? isError,
      }) {
    if (!context.mounted) return;

    final resolvedType =
    isError == true ? SnackBarType.error : type;

    final Color bg = switch (resolvedType) {
      SnackBarType.error   => AppColors.error,
      SnackBarType.warning => AppColors.warning,
      SnackBarType.success => AppColors.success,
    };

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message, style: AppTextStyles.body(false)),
          backgroundColor: bg,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }
}