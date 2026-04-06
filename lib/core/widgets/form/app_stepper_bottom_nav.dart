// lib/core/widgets/form/app_stepper_bottom_nav.dart
//
// Back + Next/Confirm bottom nav bar for multi-step forms.
// The "next" button shows a gradient when enabled and a spinner when loading.
//
// Usage:
//   AppStepperBottomNav(
//     step: _step,
//     totalSteps: 5,
//     enabled: _canProceed,
//     isDark: isDark,
//     isLoading: _submitting,
//     confirmLabel: 'Confirm Order',
//     onBack: () => setState(() => _step--),
//     onNext: _handleNext,
//   )

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_color.dart';

class AppStepperBottomNav extends StatelessWidget {
  final int step;
  final int totalSteps;
  final bool enabled;
  final bool isDark;
  final bool isLoading;
  final String? confirmLabel; // overrides default "Confirm"
  final String? nextLabel;    // overrides default "Next"
  final String? backLabel;    // overrides default "Back"/"Cancel"
  final VoidCallback onBack;
  final VoidCallback onNext;

  const AppStepperBottomNav({
    super.key,
    required this.step,
    required this.totalSteps,
    required this.enabled,
    required this.isDark,
    required this.onBack,
    required this.onNext,
    this.isLoading = false,
    this.confirmLabel,
    this.nextLabel,
    this.backLabel,
  });

  String get _backText => backLabel ?? (step == 1 ? 'Cancel' : 'Back');
  String get _nextText => step < totalSteps
      ? (nextLabel ?? 'Next')
      : (confirmLabel ?? 'Confirm');

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 10, top: 2),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: onBack,
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  width: 1.5,
                ),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                _backText,
                style: GoogleFonts.alexandria(
                  color: isDark ? Colors.white70 : AppColors.lightSubtext,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: enabled ? AppColors.gradient : null,
                color: enabled
                    ? null
                    : (isDark
                        ? Colors.grey.shade800
                        : Colors.grey.shade300),
                borderRadius: BorderRadius.circular(14),
              ),
              child: ElevatedButton(
                onPressed: (enabled && !isLoading) ? onNext : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        _nextText,
                        style: GoogleFonts.alexandria(
                          color: enabled
                              ? Colors.white
                              : (isDark
                                  ? Colors.grey.shade500
                                  : Colors.grey.shade400),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
