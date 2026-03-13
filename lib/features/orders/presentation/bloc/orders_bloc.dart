// lib/features/orders/bloc/orders_bloc.dart
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/utils/usecase.dart';
import '../../domain/usecases/orders_usecase.dart';
import 'order_event.dart';
import 'orders_state.dart';

class OrdersBloc extends Bloc<OrdersEvent, OrdersState> {
  final GetOrdersUseCase getOrdersUseCase;
  final GetOrderByIdUseCase getOrderByIdUseCase;
  final PlaceOrderUseCase placeOrderUseCase;
  final SupabaseClient client;

  StreamSubscription<List<Map<String, dynamic>>>? _realtimeSub;
  bool _subscribed = false;

  OrdersBloc({
    required this.getOrdersUseCase,
    required this.getOrderByIdUseCase,
    required this.placeOrderUseCase,
    required this.client,
  }) : super(const OrdersInitial()) {
    on<OrdersLoadRequested>(_onLoad);
    on<OrderPlaceRequested>(_onPlace);
    on<OrdersFilterToggled>(_onFilter);
    on<OrdersRealtimeTick>(_onRealtimeTick);
  }

  // ─── Load ──────────────────────────────────────────────────────────────────

  Future<void> _onLoad(
      OrdersLoadRequested event,
      Emitter<OrdersState> emit,
      ) async {
    // Preserve which tab was active so it doesn't reset to "Active" on
    // every background reload triggered after placing an order.
    final prevShowActive =
    state is OrdersLoaded ? (state as OrdersLoaded).showActive : true;

    emit(const OrdersLoading());

    final result = await getOrdersUseCase(const NoParams());
    result.fold(
          (failure) => emit(OrdersError(failure.message)),
          (orders) {
        emit(OrdersLoaded(orders: orders, showActive: prevShowActive));

        // Subscribe to realtime only once per session.
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

  // ─── Place ─────────────────────────────────────────────────────────────────

  Future<void> _onPlace(
      OrderPlaceRequested event,
      Emitter<OrdersState> emit,
      ) async {
    emit(const OrderPlacing());

    final result = await placeOrderUseCase(event.params);
    result.fold(
          (failure) {
        // Surface the real Supabase error message so FK / RLS / timeline
        // insert failures are debuggable without guessing.
        // The old mapping was hiding real causes behind misleading strings
        // (e.g. a timeline RLS rejection was shown as "Service or store not found").
        final raw = failure.message;
        final msg = raw.toLowerCase();
        if (msg.contains('jwt') || msg.contains('not authenticated')) {
          emit(const OrdersError(
              'Session expired. Please sign out and sign in again.'));
        } else if (msg.contains('row-level security') ||
            msg.contains('permission denied')) {
          // Include raw message so the exact table / policy is visible in debug
          emit(OrdersError('Permission denied: $raw'));
        } else {
          // Pass through verbatim — covers FK errors, timeline RLS, network, etc.
          emit(OrdersError(raw));
        }
      },
          (order) {
        // Emit OrderPlaced so place_order_screen's BlocListener can
        // navigate to the confirmation screen. We wait 600 ms before
        // reloading the list so this state is guaranteed to be processed
        // before being replaced by OrdersLoading.
        emit(OrderPlaced(orderNumber: order.orderNumber));
        Future.delayed(const Duration(milliseconds: 600), () {
          if (!isClosed) add(const OrdersLoadRequested());
        });
      },
    );
  }

  // ─── Filter ────────────────────────────────────────────────────────────────

  void _onFilter(
      OrdersFilterToggled event,
      Emitter<OrdersState> emit,
      ) {
    if (state is! OrdersLoaded) return;
    emit((state as OrdersLoaded).copyWith(showActive: event.showActive));
  }

  // ─── Realtime tick (silent background refresh) ─────────────────────────────

  Future<void> _onRealtimeTick(
      OrdersRealtimeTick event,
      Emitter<OrdersState> emit,
      ) async {
    // Do not interrupt the order-placement flow.
    if (state is OrderPlacing || state is OrderPlaced) return;

    final prevShowActive =
    state is OrdersLoaded ? (state as OrdersLoaded).showActive : true;

    final result = await getOrdersUseCase(const NoParams());
    result.fold(
          (_) {}, // silent fail — never surface background errors
          (orders) =>
          emit(OrdersLoaded(orders: orders, showActive: prevShowActive)),
    );
  }

  // ─── Realtime subscription ─────────────────────────────────────────────────

  void _subscribeRealtime(String userId) {
    _realtimeSub?.cancel();

    // _firstEvent: Supabase .stream() always emits the current snapshot
    // immediately on subscribe. We skip it to avoid a redundant reload
    // right on top of the one that just completed in _onLoad.
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
      onError: (_) {}, // swallow realtime errors silently
    );
  }

  @override
  Future<void> close() {
    _realtimeSub?.cancel();
    return super.close();
  }
}