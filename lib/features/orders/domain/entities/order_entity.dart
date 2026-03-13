// lib/features/orders/domain/entities/order_entity.dart
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
  final String? serviceImageUrl; // ← service image from services.image_url
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
  });

  bool get isActive => status != 'delivered' && status != 'cancelled';

  @override
  List<Object?> get props => [id, orderNumber, status, progress];
}