// lib/features/orders/bloc/orders_state.dart

import 'package:equatable/equatable.dart';

import '../../domain/entities/order_entity.dart';

sealed class OrdersState extends Equatable {
  const OrdersState();
  @override
  List<Object?> get props => [];
}

/// No load has been attempted yet (app just started).
final class OrdersInitial extends OrdersState {
  const OrdersInitial();
}

/// Fetching orders from the server — show a full-screen spinner.
/// Only emitted on the very first load; background refreshes via
/// realtime never emit this state.
final class OrdersLoading extends OrdersState {
  const OrdersLoading();
}

/// Orders loaded successfully.
///
/// [orders]     — complete list, newest first
/// [showActive] — which tab is currently selected (Active vs History)
final class OrdersLoaded extends OrdersState {
  final List<OrderEntity> orders;
  final bool showActive;

  const OrdersLoaded({required this.orders, required this.showActive});

  /// Orders that are still in progress (not delivered or cancelled).
  List<OrderEntity> get activeOrders =>
      orders.where((o) => o.isActive).toList();

  /// Orders that have been delivered or cancelled.
  List<OrderEntity> get completedOrders =>
      orders.where((o) => !o.isActive).toList();

  /// The list currently shown in the UI, based on the selected tab.
  List<OrderEntity> get displayedOrders =>
      showActive ? activeOrders : completedOrders;

  /// Badge count shown on the bottom navigation bar.
  int get activeCount => activeOrders.length;

  OrdersLoaded copyWith({
    List<OrderEntity>? orders,
    bool? showActive,
  }) =>
      OrdersLoaded(
        orders: orders ?? this.orders,
        showActive: showActive ?? this.showActive,
      );

  @override
  List<Object?> get props => [orders, showActive];
}

/// A place-order network request is in progress.
/// The submit button is disabled while in this state.
final class OrderPlacing extends OrdersState {
  const OrderPlacing();
}

/// Order was placed successfully.
/// [orderNumber] is shown on the booking confirmation screen.
final class OrderPlaced extends OrdersState {
  final String orderNumber;
  const OrderPlaced({required this.orderNumber});
  @override
  List<Object> get props => [orderNumber];
}

/// A load or place request failed.
/// [message] is safe to display directly in the UI.
final class OrdersError extends OrdersState {
  final String message;
  const OrdersError(this.message);
  @override
  List<Object> get props => [message];
}