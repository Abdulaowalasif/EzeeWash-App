// lib/features/orders/domain/entities/place_order_params.dart
import 'package:equatable/equatable.dart';

enum PaymentMethod { cashOnDelivery, card }

/// Value object that carries all data needed to place an order.
class PlaceOrderParams extends Equatable {
  final String serviceId;
  final String storeId;
  final int itemCount;
  final double totalPrice;
  final String pickupAddress;
  final String? deliveryAddress;
  final DateTime? pickupDate;
  final String? pickupTime;
  final DateTime? deliveryDate;
  final String? deliveryTime;
  final String? specialInstructions;
  final PaymentMethod paymentMethod;

  const PlaceOrderParams({
    required this.serviceId,
    required this.storeId,
    required this.itemCount,
    required this.totalPrice,
    required this.pickupAddress,
    this.deliveryAddress,
    this.pickupDate,
    this.pickupTime,
    this.deliveryDate,
    this.deliveryTime,
    this.specialInstructions,
    this.paymentMethod = PaymentMethod.cashOnDelivery,
  });

  @override
  List<Object?> get props => [
    serviceId, storeId, itemCount, totalPrice,
    pickupAddress, pickupDate, deliveryDate, paymentMethod,
  ];
}