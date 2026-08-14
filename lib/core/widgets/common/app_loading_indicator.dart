import 'package:flutter/material.dart';
import '../../constants/app_color.dart';

// ─── Loading indicator ────────────────────────────────────────────────────────

class AppLoadingIndicator extends StatelessWidget {
  final double strokeWidth;
  const AppLoadingIndicator({super.key, this.strokeWidth = 2.5});

  @override
  Widget build(BuildContext context) => Center(
    child: CircularProgressIndicator(
      color: AppColors.primary,
      strokeWidth: strokeWidth,
    ),
  );
}
