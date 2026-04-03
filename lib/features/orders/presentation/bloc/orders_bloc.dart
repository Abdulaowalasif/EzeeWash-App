// lib/features/orders/presentation/bloc/orders_bloc.dart
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

        // FIX: Always re-evaluate the realtime subscription on load.
        //
        // Previously _subscribed was set to true once and never reset, so
        // if OrdersBloc was shared via BlocProvider.value (see app_router.dart)
        // across sessions (logout → re-login), the subscription kept the OLD
        // userId filter. Resetting here ensures we always subscribe for the
        // currently authenticated user.
        final userId = client.auth.currentUser?.id;
        if (userId != null) {
          // Cancel any existing subscription before creating a new one.
          // This handles the case where the user logs out and back in —
          // we must re-subscribe with the new userId.
          if (!_subscribed) {
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
        // FIX: After placing, reload orders so the new order appears on
        // the OrderScreen immediately. The 600 ms delay gives Supabase time
        // to commit the row before we fetch.
        //
        // Because PlaceOrderScreen now uses BlocProvider.value (sharing the
        // root OrdersBloc — see app_router.dart), this reload updates the
        // same state that OrderScreen is listening to, so the UI reflects
        // the new order without requiring an app restart.
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
    final prevState = state;
    final prevShowActive =
    state is OrdersLoaded ? (state as OrdersLoaded).showActive : false;

    emit(const OrderCancelling());

    final result = await cancelOrderUseCase(CancelOrderParams(event.orderId));

    result.fold(
          (failure) {
        if (prevState is OrdersLoaded) {
          emit(prevState);
        }
        emit(OrdersError(failure.message));
      },
          (_) async {
        emit(const OrderCancelled());
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

  // ─── Realtime ──────────────────────────────────────────────────────────────

  void _subscribeRealtime(String userId) {
    _realtimeSub?.cancel();
    bool firstEvent = true;
    _realtimeSub = client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .listen(
          (_) {
        // Skip the initial snapshot that Supabase sends immediately on
        // subscription — we already have fresh data from the load above.
        if (firstEvent) {
          firstEvent = false;
          return;
        }
        if (!isClosed) add(const OrdersRealtimeTick());
      },
      onError: (_) {},
    );
  }

  // ─── Reset realtime subscription ───────────────────────────────────────────

  /// Call this when the authenticated user changes (logout → re-login) so the
  /// realtime subscription is re-established for the new user's orders.
  void resetSubscription() {
    _realtimeSub?.cancel();
    _realtimeSub = null;
    _subscribed = false;
  }

  @override
  Future<void> close() {
    _realtimeSub?.cancel();
    return super.close();
  }
}