// lib/features/orders/data/models/order_model.dart
import '../../domain/entities/order_entity.dart';

class OrderTimelineStepModel extends OrderTimelineStep {
  const OrderTimelineStepModel({
    required super.title,
    super.description,
    super.eventTime,
    required super.isDone,
    required super.stepOrder,
  });

  factory OrderTimelineStepModel.fromJson(Map<String, dynamic> j) =>
      OrderTimelineStepModel(
        title: j['title'] as String,
        description: j['description'] as String?,
        eventTime: j['event_time'] != null
            ? DateTime.tryParse(j['event_time'] as String)
            : null,
        isDone: j['is_done'] as bool? ?? false,
        stepOrder: j['step_order'] as int,
      );

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'event_time': eventTime?.toIso8601String(),
    'is_done': isDone,
    'step_order': stepOrder,
  };
}

class OrderModel extends OrderEntity {
  const OrderModel({
    required super.id,
    required super.orderNumber,
    required super.userId,
    required super.serviceId,
    required super.serviceName,
    super.serviceImageUrl,
    required super.storeId,
    required super.storeName,
    required super.status,
    required super.itemCount,
    required super.totalPrice,
    required super.pickupAddress,
    super.deliveryAddress,
    super.pickupDate,
    super.pickupTime,
    super.deliveryDate,
    super.deliveryTime,
    super.specialInstructions,
    super.progress,
    super.timeline,
    required super.createdAt,
    super.paymentMethod,
    super.paymentStatus,
    super.stripePaymentIntentId,
    super.couponCode,
    super.discountAmount,
    super.riderLat,
    super.riderLng,
    super.riderId,
    super.pickupRiderId,
    super.deliveryRiderId,
    super.riderName,
    super.riderPhone,
    super.riderAvatarUrl,
    super.riderVehicleType,
    super.riderVehiclePlate,
    super.riderRating,
    super.riderIsOnline,
  });

  factory OrderModel.fromJson(Map<String, dynamic> j) {
    final steps = (j['order_timelines'] as List? ?? [])
        .map((t) => OrderTimelineStepModel.fromJson(t as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.stepOrder.compareTo(b.stepOrder));

    final serviceMap = j['services'] as Map?;
    final status = j['status'] as String? ?? 'pending';

    // ── FIX: Determine the active rider data based on status phase ──────────
    Map<String, dynamic>? activeRiderData;

    if (status == 'confirmed' || status == 'pending') {
      activeRiderData = j['pickup_rider'] as Map<String, dynamic>? ?? j['riders'] as Map<String, dynamic>?;
    } else if (status == 'ready' || status == 'out_for_delivery' || status == 'delivered') {
      activeRiderData = j['delivery_rider'] as Map<String, dynamic>? ?? j['riders'] as Map<String, dynamic>?;
    } else {
      activeRiderData = j['pickup_rider'] as Map<String, dynamic>? ??
          j['delivery_rider'] as Map<String, dynamic>? ??
          j['riders'] as Map<String, dynamic>?;
    }

    return OrderModel(
      id: j['id'] as String,
      orderNumber: j['order_number'] as String? ?? '',
      userId: j['user_id'] as String,
      serviceId: j['service_id'] as String,
      serviceName: serviceMap?['title'] as String? ?? 'Unknown',
      serviceImageUrl: serviceMap?['image_url'] as String?,
      storeId: j['store_id'] as String,
      storeName: (j['stores'] as Map?)?['name'] as String? ?? 'Unknown',
      status: status,
      itemCount: j['item_count'] as int? ?? 1,
      totalPrice: (j['total_price'] as num?)?.toDouble() ?? 0.0,
      pickupAddress: j['pickup_address'] as String? ?? '',
      deliveryAddress: j['delivery_address'] as String?,
      pickupDate: j['pickup_date'] != null
          ? DateTime.tryParse(j['pickup_date'] as String)
          : null,
      pickupTime: j['pickup_time'] as String?,
      deliveryDate: j['delivery_date'] != null
          ? DateTime.tryParse(j['delivery_date'] as String)
          : null,
      deliveryTime: j['delivery_time'] as String?,
      specialInstructions: j['special_instructions'] as String?,
      progress: (j['progress'] as num?)?.toDouble() ?? 0.0,
      timeline: steps,
      createdAt: j['created_at'] != null
          ? DateTime.parse(j['created_at'] as String)
          : DateTime.now(),
      paymentMethod: j['payment_method'] as String? ?? 'cash_on_delivery',
      paymentStatus: j['payment_status'] as String? ?? 'pending',
      stripePaymentIntentId: j['stripe_payment_intent_id'] as String?,

      // ─── NEW: Parse Coupon Fields ───
      couponCode: j['coupon_code'] as String?,
      discountAmount: (j['discount_amount'] as num?)?.toDouble() ?? 0.0,

      riderLat: (activeRiderData?['current_lat'] as num?)?.toDouble(),
      riderLng: (activeRiderData?['current_lng'] as num?)?.toDouble(),

      // ── Rider profile mapped to entities ────────────────────────────────────
      riderId:           j['rider_id']              as String?,
      pickupRiderId:     j['pickup_rider_id']       as String?,
      deliveryRiderId:   j['delivery_rider_id']     as String?,
      riderName:         activeRiderData?['full_name']     as String?,
      riderPhone:        activeRiderData?['phone']         as String?,
      riderAvatarUrl:    activeRiderData?['avatar_url']    as String?,
      riderVehicleType:  activeRiderData?['vehicle_type']  as String?,
      riderVehiclePlate: activeRiderData?['vehicle_plate'] as String?,
      riderRating:       (activeRiderData?['rating'] as num?)?.toDouble(),
      riderIsOnline:     activeRiderData?['is_online']     as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'order_number': orderNumber,
    'user_id': userId,
    'service_id': serviceId,
    'store_id': storeId,
    'status': status,
    'item_count': itemCount,
    'total_price': totalPrice,
    'pickup_address': pickupAddress,
    'delivery_address': deliveryAddress,
    'pickup_date': pickupDate != null
        ? '${pickupDate!.year}-${pickupDate!.month.toString().padLeft(2, '0')}-${pickupDate!.day.toString().padLeft(2, '0')}'
        : null,
    'pickup_time': pickupTime,
    'delivery_date': deliveryDate != null
        ? '${deliveryDate!.year}-${deliveryDate!.month.toString().padLeft(2, '0')}-${deliveryDate!.day.toString().padLeft(2, '0')}'
        : null,
    'delivery_time': deliveryTime,
    'special_instructions': specialInstructions,
    'progress': progress,
    'payment_method': paymentMethod,
    'payment_status': paymentStatus,
    'coupon_code': couponCode,
    'discount_amount': discountAmount,
    'rider_latitude': riderLat,
    'rider_longitude': riderLng,
  };
}