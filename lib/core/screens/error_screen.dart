// lib/core/screens/error_screen.dart
//
// Refactored: AppTextStyles replaces GoogleFonts inline calls.
// AppGradientButton and AppCard are already used — kept clean.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../routes/routes_name.dart';
import '../constants/app_color.dart';
import '../theme/app_text_styles.dart';
import '../utils/responsive.dart';
import '../widgets/common_widgets.dart';
import '../widgets/widgets.dart';

class ErrorScreen extends StatelessWidget {
  final Exception? error;
  const ErrorScreen({super.key, this.error});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
      isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
                maxWidth: Responsive.maxContentWidth(context)),
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: Responsive.horizontalPadding(context)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppColors.error.withOpacity(0.2), width: 2),
                    ),
                    child: const Icon(Icons.wifi_off_rounded,
                        color: AppColors.error, size: 52),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Oops! Something went wrong.',
                    style: AppTextStyles.heading(isDark).copyWith(fontSize: 22),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: AppColors.error.withOpacity(0.15)),
                    ),
                    child: Text(
                      error?.toString() ??
                          'An unexpected error occurred. Please try again.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyLong(isDark).copyWith(fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 40),
                  AppGradientButton(
                    label: 'Go Back',
                    icon: Icons.arrow_back_rounded,
                    verticalPadding: 16,
                    borderRadius: 16,
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go(RoutesName.home);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => context.go(RoutesName.home),
                      icon: const Icon(Icons.home_rounded,
                          color: AppColors.primary, size: 20),
                      label: Text('Back to Home',
                          style: AppTextStyles.buttonOutline.copyWith(fontSize: 15)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: AppColors.primary, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
