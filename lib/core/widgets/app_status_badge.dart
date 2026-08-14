// lib/core/widgets/app_status_badge.dart
//
// Order-status pill badge — small rounded container whose color and label
// come directly from OrderStatus helpers.
//
// Usage:
//   AppStatusBadge(status: order.status)          // auto-formats label
//   AppStatusBadge(status: order.status, large: true)

import 'package:flutter/material.dart';

import '../constants/order_status.dart';
import '../theme/app_text_styles.dart';

class AppStatusBadge extends StatelessWidget {
  final String status;

  /// When true uses a slightly larger pill (chip-style for filter sheets).
  final bool large;

  const AppStatusBadge({super.key, required this.status, this.large = false});

  @override
  Widget build(BuildContext context) {
    final display = OrderStatus.getDisplayStatus(status);
    final color = OrderStatus.getColor(display);
    final label = OrderStatus.format(display).toUpperCase();

    if (large) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: AppTextStyles.statusLabel(color)),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: AppTextStyles.statusBadge(color)),
    );
  }
}
