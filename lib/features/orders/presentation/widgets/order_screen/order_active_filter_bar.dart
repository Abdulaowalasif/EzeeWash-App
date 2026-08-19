// lib/features/orders/presentation/widgets/order_screen/order_active_filter_bar.dart
//
// Horizontal scrollable row of filter chips showing the currently active
// filters, with a "Clear all" chip on the right.

import 'package:flutter/material.dart';

import '../../../../../core/constants/app_color.dart';
import '../../../../../core/constants/order_status.dart';
import '../../../../../core/theme/app_text_styles.dart';
import '../../../domain/entities/order_entity.dart';
import '../../models/order_filter.dart';

class OrderActiveFilterBar extends StatelessWidget {
  final OrderFilter filter;
  final bool isDark;
  final VoidCallback onClear;
  final List<OrderEntity> allOrders;

  const OrderActiveFilterBar({
    super.key,
    required this.filter,
    required this.isDark,
    required this.onClear,
    required this.allOrders,
  });

  String _dateLabel(DateRange r) {
    switch (r) {
      case DateRange.today:
        return 'Today';
      case DateRange.last7:
        return 'Last 7 days';
      case DateRange.last30:
        return 'Last 30 days';
      case DateRange.custom:
        return 'Custom date';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final chips = <String>[];
    if (filter.dateRange != DateRange.all) {
      chips.add(_dateLabel(filter.dateRange));
    }
    if (filter.storeId != null) {
      final idx = allOrders.indexWhere((o) => o.storeId == filter.storeId);
      chips.add(idx != -1 ? allOrders[idx].storeName : filter.storeId!);
    }
    if (filter.serviceName != null) chips.add(filter.serviceName!);
    if (filter.status != null) chips.add(OrderStatus.format(filter.status!));
    if (filter.sortBy != 'newest') {
      chips.add(
        {
              'oldest': 'Oldest first',
              'price_asc': 'Price ↑',
              'price_desc': 'Price ↓',
            }[filter.sortBy] ??
            filter.sortBy ??
            '',
      );
    }

    return SizedBox(
      height: 32,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ...chips.map((c) => _FilterChip(label: c, isDark: isDark)),
          _ClearChip(isDark: isDark, onClear: onClear),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isDark;

  const _FilterChip({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: AppTextStyles.captionMedium(
          isDark,
        ).copyWith(color: AppColors.primary),
      ),
    );
  }
}

class _ClearChip extends StatelessWidget {
  final bool isDark;
  final VoidCallback onClear;

  const _ClearChip({required this.isDark, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClear,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const Icon(Icons.close_rounded, size: 12, color: AppColors.error),
            const SizedBox(width: 4),
            Text(
              'Clear all',
              style: AppTextStyles.captionMedium(
                isDark,
              ).copyWith(color: AppColors.error),
            ),
          ],
        ),
      ),
    );
  }
}
