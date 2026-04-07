// lib/features/orders/presentation/widgets/order_screen/order_flowing_timeline.dart
//
// Animated vertical step-timeline shown inside an expanded OrderCard.

import 'package:flutter/material.dart';

import '../../../../../core/constants/app_color.dart';
import '../../../../../core/theme/app_text_styles.dart';

class OrderFlowingTimeline extends StatelessWidget {
  final int currentLevel;
  final bool isDark;

  const OrderFlowingTimeline({
    super.key,
    required this.currentLevel,
    required this.isDark,
  });

  static const _steps = [
    {'threshold': 2, 'title': 'Confirmed', 'sub': 'Store has accepted your order.'},
    {'threshold': 4, 'title': 'Picked Up', 'sub': 'Items picked up and heading to laundry.'},
    {'threshold': 7, 'title': 'Cleaning', 'sub': 'Washing, drying, and ironing.'},
    {'threshold': 9, 'title': 'Out for Delivery', 'sub': 'Rider is on the way to deliver.'},
    {'threshold': 10, 'title': 'Delivered', 'sub': 'Order completed successfully.'},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _steps.asMap().entries.map((e) {
        final index = e.key;
        final step = e.value;
        final threshold = step['threshold'] as int;
        final isDone = currentLevel >= threshold;
        final isActive = !isDone &&
            (index == 0 ||
                currentLevel >= (_steps[index - 1]['threshold'] as int));
        final isLast = index == _steps.length - 1;

        return _TimelineStep(
          title: step['title'] as String,
          subtitle: step['sub'] as String,
          isDone: isDone,
          isActive: isActive,
          isLast: isLast,
          isDark: isDark,
        );
      }).toList(),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isDone;
  final bool isActive;
  final bool isLast;
  final bool isDark;

  const _TimelineStep({
    required this.title,
    required this.subtitle,
    required this.isDone,
    required this.isActive,
    required this.isLast,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone
                    ? AppColors.primary
                    : (isDark ? Colors.white12 : Colors.grey.shade200),
                border: isActive
                    ? Border.all(
                        color: AppColors.primary.withOpacity(0.3), width: 4)
                    : null,
              ),
              child: isDone
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : (isActive
                      ? Center(
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary,
                            ),
                          ),
                        )
                      : null),
            ),
            if (!isLast)
              SizedBox(
                height: 44,
                width: 2,
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    Container(
                        width: 2,
                        color: isDark ? Colors.white12 : Colors.grey.shade200),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeInOut,
                      width: 2,
                      height: isDone ? 44.0 : 0.0,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.body(isDark).copyWith(
                    fontWeight:
                        isDone || isActive ? FontWeight.bold : FontWeight.w500,
                    color: isDone || isActive
                        ? (isDark ? Colors.white : Colors.black87)
                        : Colors.grey.shade500,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: AppTextStyles.subtitle(isDark)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
