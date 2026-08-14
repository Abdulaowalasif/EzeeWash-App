// lib/features/orders/bloc/orders_state.dart
import 'package:equatable/equatable.dart';

import '../../domain/entities/order_entity.dart';

sealed class OrdersState extends Equatable {
  const OrdersState();
  @override
  List<Object?> get props => [];
}

/// No load attempted yet.
final class OrdersInitial extends OrdersState {
  const OrdersInitial();
}

/// Fetching orders — show a loading indicator.
final class OrdersLoading extends OrdersState {
  const OrdersLoading();
}

/// Orders loaded successfully.
final class OrdersLoaded extends OrdersState {
  final List<OrderEntity> orders;
  final bool showActive;

  const OrdersLoaded({required this.orders, required this.showActive});

  List<OrderEntity> get activeOrders =>
      orders.where((o) => o.isActive).toList();

  List<OrderEntity> get completedOrders =>
      orders.where((o) => !o.isActive).toList();

  List<OrderEntity> get displayedOrders =>
      showActive ? activeOrders : completedOrders;

  int get activeCount => activeOrders.length;

  OrdersLoaded copyWith({List<OrderEntity>? orders, bool? showActive}) =>
      OrdersLoaded(
        orders: orders ?? this.orders,
        showActive: showActive ?? this.showActive,
      );

  @override
  List<Object?> get props => [orders, showActive];
}

/// A place-order request is in progress.
final class OrderPlacing extends OrdersState {
  const OrderPlacing();
}

/// Order placed successfully.
final class OrderPlaced extends OrdersState {
  final String orderId;
  final String orderNumber;
  const OrderPlaced({required this.orderId, required this.orderNumber});
  @override
  List<Object> get props => [orderId, orderNumber];
}

/// A cancel request is in progress — disable the cancel button.
// Change this line
final class OrderCancelling extends OrdersState {
  final String orderId; // Add this
  const OrderCancelling(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

/// Emitted when an action like submitting a review succeeds.
final class OrdersActionSuccess extends OrdersState {
  final String message;
  final int timestamp;
  
  OrdersActionSuccess(this.message) : timestamp = DateTime.now().millisecondsSinceEpoch;

  @override
  List<Object?> get props => [message, timestamp];
}

/// An order was successfully cancelled.
final class OrderCancelled extends OrdersState {
  const OrderCancelled();
}

/// Load, place, or cancel failed.
final class OrdersError extends OrdersState {
  final String message;
  const OrdersError(this.message);
  @override
  List<Object> get props => [message];
}
