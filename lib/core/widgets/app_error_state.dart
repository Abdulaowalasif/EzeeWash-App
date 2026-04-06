// lib/core/widgets/app_error_state.dart
//
// Full-screen error state with icon, message, and optional retry button.
// Used in order_screen, service_screen, notification_screen, settings_screen.
//
// Usage:
//   AppErrorState(
//     message: state.message,
//     isDark: isDark,
//     onRetry: () => context.read<MyBloc>().add(LoadRequested()),
//   )

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_color.dart';

class AppErrorState extends StatelessWidget {
  final String message;
  final bool isDark;
  final VoidCallback? onRetry;
  final String retryLabel;
  final IconData icon;

  const AppErrorState({
    super.key,
    required this.message,
    required this.isDark,
    this.onRetry,
    this.retryLabel = 'Retry',
    this.icon = Icons.error_outline,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.error, size: 52),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.alexandria(
                fontSize: 14,
                color: isDark
                    ? AppColors.darkSubtext
                    : AppColors.lightSubtext,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh_rounded, size: 18),
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                label: Text(retryLabel,
                    style: GoogleFonts.alexandria(
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
