// lib/core/constants/order_status.dart
import 'package:flutter/material.dart';
import 'app_color.dart';

class OrderStatus {
  // ─── Exact DB Statuses ─────────────────────────────────────────────────────
  static const String pending = 'pending'; // 0.0
  static const String confirmed = 'confirmed'; // 0.2
  static const String assignPickup = 'assign_pickup'; // 0.3
  static const String pickedUp = 'picked_up'; // 0.4
  static const String dropped = 'dropped'; // 0.5
  static const String received = 'received'; // 0.6
  static const String inProcess = 'in_process'; // 0.7
  static const String ready = 'ready'; // 0.8
  static const String outForDelivery = 'out_for_delivery'; // 0.9
  static const String delivered = 'delivered'; // 1.0
  static const String cancelled = 'cancelled';

  // The definitive list of valid statuses for filtering
  static const List<String> validStatuses = [
    pending,
    confirmed,
    assignPickup,
    pickedUp,
    dropped,
    received,
    inProcess,
    ready,
    outForDelivery,
    delivered,
    cancelled,
  ];

  // ─── Core Logic ────────────────────────────────────────────────────────────

  /// Normalizes incoming DB status strings to our exact constants
  static String getDisplayStatus(String dbStatus) {
    final status = dbStatus.toLowerCase().trim();
    if (validStatuses.contains(status)) return status;

    // Catch edge cases (e.g., if DB sends 'confirm' instead of 'confirmed')
    if (status == 'confirm') return confirmed;

    return pending; // Fallback
  }

  /// Formats the string beautifully for chips and UI text
  static String format(String status) {
    if (status.isEmpty) return '';
    final s = getDisplayStatus(status);

    // Special formatting for specific statuses
    switch (s) {
      case assignPickup:
        return 'Rider Assigned';
      case dropped:
        return 'Dropped at Laundry';
      case received:
        return 'Laundry Received';
      case outForDelivery:
        return 'Out For Delivery';
      case pickedUp:
        return 'Picked Up';
      case inProcess:
        return 'In Process';
      default:
        return s[0].toUpperCase() + s.substring(1);
    }
  }

  /// Returns the appropriate theme color for the status badge/progress bar
  static Color getColor(String status) {
    final s = getDisplayStatus(status);
    switch (s) {
      case pending:
        return AppColors.primary;
      case confirmed:
      case assignPickup:
        return AppColors.info; // Blue
      case pickedUp:
      case dropped:
      case received:
      case inProcess:
        return AppColors.warning; // Orange/Yellow
      case ready:
      case outForDelivery:
      case delivered:
        return AppColors.success; // Green
      case cancelled:
        return AppColors.error; // Red
      default:
        return AppColors.primary;
    }
  }

  /// The exact DB progress mapping you provided
  static double getProgress(String status) {
    final s = getDisplayStatus(status);
    switch (s) {
      case pending:
        return 0.0;
      case confirmed:
        return 0.2;
      case assignPickup:
        return 0.3;
      case pickedUp:
        return 0.4;
      case dropped:
        return 0.5;
      case received:
        return 0.6;
      case inProcess:
        return 0.7;
      case ready:
        return 0.8;
      case outForDelivery:
        return 0.9;
      case delivered:
        return 1.0;
      case cancelled:
        return 0.0;
      default:
        return 0.0;
    }
  }

  /// Used by the Timeline in the Order Details to check off completed steps
  static int getStepCompletionOrder(String status) {
    final s = getDisplayStatus(status);
    switch (s) {
      case pending:
        return 1;
      case confirmed:
        return 2;
      case assignPickup:
        return 3;
      case pickedUp:
        return 4;
      case dropped:
        return 5;
      case received:
        return 6;
      case inProcess:
        return 7;
      case ready:
        return 8;
      case outForDelivery:
        return 9;
      case delivered:
        return 10;
      default:
        return 0;
    }
  }
}
