// lib/features/orders/presentation/models/order_filter.dart
//
// Pure data/logic model for order filtering and sorting.
// Extracted from order_screen.dart to keep screens thin.

import '../../domain/entities/order_entity.dart';
import '../../../../core/constants/order_status.dart';

// ─── Enums ────────────────────────────────────────────────────────────────────

enum DateRange { all, today, last7, last30, custom }

// ─── Model ────────────────────────────────────────────────────────────────────

const _sentinel = Object();

class OrderFilter {
  final DateRange dateRange;
  final DateTime? customStart;
  final DateTime? customEnd;
  final String? storeId;
  final String? serviceName;
  final String? status;
  final String? sortBy;

  const OrderFilter({
    this.dateRange = DateRange.all,
    this.customStart,
    this.customEnd,
    this.storeId,
    this.serviceName,
    this.status,
    this.sortBy = 'newest',
  });

  bool get isActive =>
      dateRange != DateRange.all ||
      storeId != null ||
      serviceName != null ||
      status != null ||
      (sortBy != 'newest');

  int get activeCount {
    int c = 0;
    if (dateRange != DateRange.all) c++;
    if (storeId != null) c++;
    if (serviceName != null) c++;
    if (status != null) c++;
    if (sortBy != 'newest') c++;
    return c;
  }

  OrderFilter copyWith({
    DateRange? dateRange,
    DateTime? customStart,
    DateTime? customEnd,
    Object? storeId = _sentinel,
    Object? serviceName = _sentinel,
    Object? status = _sentinel,
    String? sortBy,
  }) {
    return OrderFilter(
      dateRange: dateRange ?? this.dateRange,
      customStart: customStart ?? this.customStart,
      customEnd: customEnd ?? this.customEnd,
      storeId: storeId == _sentinel ? this.storeId : storeId as String?,
      serviceName: serviceName == _sentinel
          ? this.serviceName
          : serviceName as String?,
      status: status == _sentinel ? this.status : status as String?,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  List<OrderEntity> apply(List<OrderEntity> orders) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    var result = orders.where((o) {
      if (dateRange != DateRange.all) {
        final d = o.createdAt;
        switch (dateRange) {
          case DateRange.today:
            if (d.isBefore(today)) return false;
            break;
          case DateRange.last7:
            if (d.isBefore(today.subtract(const Duration(days: 7)))) {
              return false;
            }
            break;
          case DateRange.last30:
            if (d.isBefore(today.subtract(const Duration(days: 30)))) {
              return false;
            }
            break;
          case DateRange.custom:
            if (customStart != null && d.isBefore(customStart!)) return false;
            if (customEnd != null &&
                d.isAfter(customEnd!.add(const Duration(days: 1)))) {
              return false;
            }
            break;
          case DateRange.all:
            break;
        }
      }
      if (storeId != null && o.storeId != storeId) return false;
      if (serviceName != null && o.serviceName != serviceName) return false;
      if (status != null && OrderStatus.getDisplayStatus(o.status) != status) {
        return false;
      }
      return true;
    }).toList();

    switch (sortBy) {
      case 'oldest':
        result.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'price_asc':
        result.sort((a, b) => a.totalPrice.compareTo(b.totalPrice));
        break;
      case 'price_desc':
        result.sort((a, b) => b.totalPrice.compareTo(a.totalPrice));
        break;
      default:
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }
    return result;
  }
}
