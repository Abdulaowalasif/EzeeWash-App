// lib/features/orders/bloc/orders_bloc.dart
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/utils/usecase.dart';
import '../../domain/usecases/orders_usecase.dart';
import 'order_event.dart';
import 'orders_state.dart';

class OrdersBloc extends Bloc<OrdersEvent, OrdersState> {
  final GetOrdersUseCase getOrdersUseCase;
  final GetOrderByIdUseCase getOrderByIdUseCase;
  final PlaceOrderUseCase placeOrderUseCase;
  final CancelOrderUseCase cancelOrderUseCase;
  final SupabaseClient client;

  StreamSubscription? _realtimeSub;
  bool _subscribed = false;

  OrdersBloc({
    required this.getOrdersUseCase,
    required this.getOrderByIdUseCase,
    required this.placeOrderUseCase,
    required this.cancelOrderUseCase,
    required this.client,
  }) : super(const OrdersInitial()) {
    on<OrdersLoadRequested>(_onLoad);
    on<OrderPlaceRequested>(_onPlace);
    on<OrderCancelRequested>(_onCancel);
    on<OrdersFilterToggled>(_onFilter);
    on<OrdersRealtimeTick>(_onRealtimeTick);
  }

  // ─── Handlers ──────────────────────────────────────────────────────────────

  Future<void> _onLoad(
      OrdersLoadRequested event,
      Emitter<OrdersState> emit,
      ) async {
    final prevShowActive =
    state is OrdersLoaded ? (state as OrdersLoaded).showActive : true;

    emit(const OrdersLoading());
    final result = await getOrdersUseCase(const NoParams());
    result.fold(
          (failure) => emit(OrdersError(failure.message)),
          (orders) {
        emit(OrdersLoaded(orders: orders, showActive: prevShowActive));
        if (!_subscribed) {
          final userId = client.auth.currentUser?.id;
          if (userId != null) {
            _subscribed = true;
            _subscribeRealtime(userId);
          }
        }
      },
    );
  }

  Future<void> _onPlace(
      OrderPlaceRequested event,
      Emitter<OrdersState> emit,
      ) async {
    emit(const OrderPlacing());
    final result = await placeOrderUseCase(event.params);
    result.fold(
          (failure) {
        final msg = failure.message.toLowerCase();
        if (msg.contains('foreign key') ||
            msg.contains('violates') ||
            msg.contains('not present in table')) {
          emit(const OrdersError(
              'Service or store not found. Please restart the app.'));
        } else if (msg.contains('row-level security') ||
            msg.contains('policy') ||
            msg.contains('permission')) {
          emit(const OrdersError(
              'Permission denied. Please sign out and sign in again.'));
        } else if (msg.contains('jwt') || msg.contains('not authenticated')) {
          emit(const OrdersError(
              'Session expired. Please sign out and sign in again.'));
        } else {
          emit(OrdersError(failure.message));
        }
      },
          (order) {
        emit(OrderPlaced(orderNumber: order.orderNumber));
        Future.delayed(const Duration(milliseconds: 600), () {
          if (!isClosed) add(const OrdersLoadRequested());
        });
      },
    );
  }

  /// Cancel an order: update status to 'cancelled' in Supabase,
  /// then reload the list so the UI reflects the change immediately.
  Future<void> _onCancel(
      OrderCancelRequested event,
      Emitter<OrdersState> emit,
      ) async {
    // Preserve current list while the cancel request is in flight
    final prevState = state;
    final prevShowActive =
    state is OrdersLoaded ? (state as OrdersLoaded).showActive : false;

    emit(const OrderCancelling());

    final result = await cancelOrderUseCase(CancelOrderParams(event.orderId));

    result.fold(
          (failure) {
        // Restore the previous list so the screen doesn't go blank
        if (prevState is OrdersLoaded) {
          emit(prevState);
        }
        emit(OrdersError(failure.message));
      },
          (_) async {
        // Emit success so the screen can react (snackbar / pop)
        emit(const OrderCancelled());
        // Reload the list — cancelled order moves to Completed tab
        final reloadResult = await getOrdersUseCase(const NoParams());
        reloadResult.fold(
              (_) {},
              (orders) =>
              emit(OrdersLoaded(orders: orders, showActive: prevShowActive)),
        );
      },
    );
  }

  void _onFilter(
      OrdersFilterToggled event,
      Emitter<OrdersState> emit,
      ) {
    if (state is! OrdersLoaded) return;
    emit((state as OrdersLoaded).copyWith(showActive: event.showActive));
  }

  Future<void> _onRealtimeTick(
      OrdersRealtimeTick event,
      Emitter<OrdersState> emit,
      ) async {
    if (state is OrderPlacing ||
        state is OrderPlaced ||
        state is OrderCancelling) return;

    final prevShowActive =
    state is OrdersLoaded ? (state as OrdersLoaded).showActive : true;

    final result = await getOrdersUseCase(const NoParams());
    result.fold(
          (_) {},
          (orders) =>
          emit(OrdersLoaded(orders: orders, showActive: prevShowActive)),
    );
  }

  // ─── Realtime ─────────────────────────────────────────────────────────────

  void _subscribeRealtime(String userId) {
    _realtimeSub?.cancel();
    bool firstEvent = true;
    _realtimeSub = client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .listen(
          (_) {
        if (firstEvent) {
          firstEvent = false;
          return;
        }
        if (!isClosed) add(const OrdersRealtimeTick());
      },
      onError: (_) {},
    );
  }

  @override
  Future<void> close() {
    _realtimeSub?.cancel();
    return super.close();
  }
}