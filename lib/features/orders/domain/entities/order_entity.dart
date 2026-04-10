import 'package:equatable/equatable.dart';

class OrderTimelineStep extends Equatable {
  final String title;
  final String? description;
  final DateTime? eventTime;
  final bool isDone;
  final int stepOrder;

  const OrderTimelineStep({
    required this.title,
    this.description,
    this.eventTime,
    required this.isDone,
    required this.stepOrder,
  });

  @override
  List<Object?> get props => [title, isDone, stepOrder];
}

class OrderEntity extends Equatable {
  final String id;
  final String orderNumber;
  final String userId;
  final String serviceId;
  final String serviceName;
  final String? serviceImageUrl;
  final String storeId;
  final String storeName;
  final String status;
  final int itemCount;
  final double totalPrice;
  final String pickupAddress;
  final String? deliveryAddress;
  final DateTime? pickupDate;
  final String? pickupTime;
  final DateTime? deliveryDate;
  final String? deliveryTime;
  final String? specialInstructions;
  final double progress;
  final List<OrderTimelineStep> timeline;
  final DateTime createdAt;

  // ── Payment fields ────────────────────────────────────────────────────────
  final String paymentMethod;   // 'cash_on_delivery' | 'stripe'
  final String paymentStatus;   // 'pending' | 'paid' | 'failed' | 'refunded'
  final String? stripePaymentIntentId;

  // ─── NEW: Coupon fields ───
  final String? couponCode;
  final double discountAmount;

  // ─── Rider Initial Coordinates ───
  final double? riderLat;
  final double? riderLng;

  // ── Rider IDs from orders table ─────────────────────────────────────────
  final String? riderId;          // current assigned rider (orders.rider_id)
  final String? pickupRiderId;    // orders.pickup_rider_id
  final String? deliveryRiderId;  // orders.delivery_rider_id

  final String? riderName;
  final String? riderPhone;
  final String? riderAvatarUrl;
  final String? riderVehicleType;
  final String? riderVehiclePlate;
  final double? riderRating;
  final bool riderIsOnline;

  const OrderEntity({
    required this.id,
    required this.orderNumber,
    required this.userId,
    required this.serviceId,
    required this.serviceName,
    this.serviceImageUrl,
    required this.storeId,
    required this.storeName,
    required this.status,
    required this.itemCount,
    required this.totalPrice,
    required this.pickupAddress,
    this.deliveryAddress,
    this.pickupDate,
    this.pickupTime,
    this.deliveryDate,
    this.deliveryTime,
    this.specialInstructions,
    this.progress = 0.0,
    this.timeline = const [],
    required this.createdAt,
    this.paymentMethod = 'cash_on_delivery',
    this.paymentStatus = 'pending',
    this.stripePaymentIntentId,
    this.couponCode,
    this.discountAmount = 0.0,
    this.riderLat,
    this.riderLng,
    this.riderId,
    this.pickupRiderId,
    this.deliveryRiderId,
    this.riderName,
    this.riderPhone,
    this.riderAvatarUrl,
    this.riderVehicleType,
    this.riderVehiclePlate,
    this.riderRating,
    this.riderIsOnline = false,
  });

  bool get isActive => status != 'delivered' && status != 'cancelled';
  bool get isPaid => paymentStatus == 'paid';
  bool get isCashOnDelivery => paymentMethod == 'cash_on_delivery';

  @override
  List<Object?> get props => [
    id,
    orderNumber,
    status,
    progress,
    paymentStatus,
    couponCode,
    discountAmount,
    riderLat,
    riderLng,
    riderId,
    pickupRiderId,
    deliveryRiderId,
    riderIsOnline,
  ];
}