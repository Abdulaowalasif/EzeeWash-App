// lib/features/orders/presentation/models/reorder_params.dart
//
// Parameters passed when navigating to PlaceOrderScreen for a reorder.
// Moved from place_order_screen.dart so any file can import it without
// creating a circular dependency.

class ReorderParams {
  final String serviceId;
  final String storeId;
  final String serviceName;
  final String storeName;
  final int itemCount;
  final double totalPrice;
  final double discountAmount; // ── NEW FIELD ──
  final String pickupAddress;
  final String? deliveryAddress;
  final String? specialInstructions;
  final DateTime pickupDate;
  final String pickupTime;
  final DateTime deliveryDate;
  final String deliveryTime;
  final String paymentMethod;

  const ReorderParams({
    required this.serviceId,
    required this.storeId,
    required this.serviceName,
    required this.storeName,
    required this.itemCount,
    required this.totalPrice,
    required this.discountAmount, // ── NEW FIELD ──
    required this.pickupAddress,
    this.deliveryAddress,
    this.specialInstructions,
    required this.pickupDate,
    required this.pickupTime,
    required this.deliveryDate,
    required this.deliveryTime,
    required this.paymentMethod,
  });
}
