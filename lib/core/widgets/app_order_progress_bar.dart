// lib/core/widgets/app_order_progress_bar.dart
//
// Order progress bar with "X% Complete" label.
// Used on the home screen recent-orders card and the orders list screen.
//
// Usage:
//   AppOrderProgressBar(progress: order.progress, status: order.status, isDark: isDark)

import 'package:flutter/material.dart';

import '../constants/order_status.dart';
import '../theme/app_text_styles.dart';

class AppOrderProgressBar extends StatelessWidget {
  final double progress;
  final String status;
  final bool isDark;

  const AppOrderProgressBar({
    super.key,
    required this.progress,
    required this.status,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    final color = OrderStatus.getColor(OrderStatus.getDisplayStatus(status));

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOutQuart,
      tween: Tween<double>(begin: 0.0, end: clamped),
      builder: (context, value, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 6,
                backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${(value * 100).toInt()}% Complete',
                style: AppTextStyles.captionMedium(isDark),
              ),
            ),
          ],
        );
      },
    );
  }
}
