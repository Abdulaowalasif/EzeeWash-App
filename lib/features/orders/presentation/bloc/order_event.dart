// lib/features/orders/bloc/orders_event.dart


import 'package:equatable/equatable.dart';

import '../../domain/entities/place_orders_params.dart';

sealed class OrdersEvent extends Equatable {
  const OrdersEvent();
  @override
  List<Object?> get props => [];
}

/// Fetch (or re-fetch) the current user's full order list.
final class OrdersLoadRequested extends OrdersEvent {
  const OrdersLoadRequested();
}

/// Submit a new laundry order. [params] carries all required fields.
final class OrderPlaceRequested extends OrdersEvent {
  final PlaceOrderParams params;
  const OrderPlaceRequested(this.params);
  @override
  List<Object> get props => [params];
}

/// Switch between the Active Orders and Order History tabs.
final class OrdersFilterToggled extends OrdersEvent {
  /// true  → show active orders
  /// false → show completed / cancelled orders
  final bool showActive;
  const OrdersFilterToggled(this.showActive);
  @override
  List<Object> get props => [showActive];
}

/// Internal — fired by the Supabase Realtime subscription.
/// Screens must NOT dispatch this event directly.
final class OrdersRealtimeTick extends OrdersEvent {
  const OrdersRealtimeTick();
}