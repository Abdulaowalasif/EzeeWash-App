// lib/features/error/screens/error_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../routes/routes_name.dart';
import '../../core/constants/app_color.dart';
import '../../core/utils/revponsive.dart';

class ErrorScreen extends StatelessWidget {
  final Exception? error;
  const ErrorScreen({super.key, this.error});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: Responsive.maxContentWidth(context)),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: Responsive.horizontalPadding(context)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── Animated error illustration ──────────────────────
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.error.withOpacity(0.2), width: 2),
                    ),
                    child: const Icon(Icons.wifi_off_rounded, color: AppColors.error, size: 52),
                  ),

                  const SizedBox(height: 32),

                  // ── Title ─────────────────────────────────────────────
                  Text(
                    'Oops! Something went wrong.',
                    style: GoogleFonts.alexandria(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.lightText,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 12),

                  // ── Error message ─────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.error.withOpacity(0.15)),
                    ),
                    child: Text(
                      error?.toString() ?? 'An unexpected error occurred. Please try again.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.alexandria(
                        fontSize: 13,
                        color: isDark ? Colors.grey.shade400 : AppColors.lightSubtext,
                        height: 1.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // ── Go back ───────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: AppColors.gradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go(RoutesName.main);
                          }
                        },
                        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                        label: Text(
                          'Go Back',
                          style: GoogleFonts.alexandria(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Go home ───────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => context.go(RoutesName.main),
                      icon: const Icon(Icons.home_rounded, color: AppColors.primary, size: 20),
                      label: Text(
                        'Back to Home',
                        style: GoogleFonts.alexandria(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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