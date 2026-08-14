// lib/core/widgets/form/app_step_progress.dart
//
// A horizontal step-progress bar (numbered circles + connector lines).
// Completed steps show a checkmark; active step is highlighted with gradient.
//
// Usage:
//   AppStepProgress(step: _step, totalSteps: 5, isDark: isDark)

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_color.dart';

class AppStepProgress extends StatelessWidget {
  final int step;
  final int totalSteps;
  final bool isDark;

  const AppStepProgress({
    super.key,
    required this.step,
    required this.totalSteps,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        children: List.generate(totalSteps * 2 - 1, (i) {
          if (i.isEven) {
            final s = i ~/ 2 + 1;
            final done = s < step;
            final active = s == step;
            return Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: (done || active) ? AppColors.gradient : null,
                color: (done || active)
                    ? null
                    : (isDark ? Colors.grey.shade800 : Colors.grey.shade100),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: done
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : Text(
                        '$s',
                        style: GoogleFonts.alexandria(
                          color: active ? Colors.white : Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
              ),
            );
          }
          // Connector line
          final done = (i ~/ 2 + 1) < step;
          return Expanded(
            child: Container(
              height: 3,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                gradient: done ? AppColors.gradient : null,
                color: done
                    ? null
                    : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          );
        }),
      ),
    );
  }
}
