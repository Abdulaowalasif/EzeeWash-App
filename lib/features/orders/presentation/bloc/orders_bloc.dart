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
  final WatchOrdersUseCase watchOrdersUseCase;
  final GetOrderByIdUseCase getOrderByIdUseCase;
  final PlaceOrderUseCase placeOrderUseCase;
  final CancelOrderUseCase cancelOrderUseCase;
  final SubmitServiceReviewUseCase submitServiceReviewUseCase;
  final SubmitRiderRatingUseCase submitRiderRatingUseCase;
  final SupabaseClient client;

  StreamSubscription? _realtimeSub;
  String? _currentUserId;

  OrdersBloc({
    required this.getOrdersUseCase,
    required this.watchOrdersUseCase,
    required this.getOrderByIdUseCase,
    required this.placeOrderUseCase,
    required this.cancelOrderUseCase,
    required this.submitServiceReviewUseCase,
    required this.submitRiderRatingUseCase,
    required this.client,
  }) : super(const OrdersInitial()) {
    on<OrdersLoadRequested>(_onLoad);
    on<OrderPlaceRequested>(_onPlace);
    on<OrderCancelRequested>(_onCancel);
    on<OrdersFilterToggled>(_onFilter);
    on<OrdersRealtimeTick>(_onRealtimeTick);
    on<OrderSubmitServiceReview>(_onSubmitServiceReview);
    on<OrderSubmitRiderRating>(_onSubmitRiderRating);
    on<OrdersClearData>((event, emit) => emit(const OrdersInitial()));
  }

  // ─── Handlers ──────────────────────────────────────────────────────────────

  Future<void> _onLoad(
    OrdersLoadRequested event,
    Emitter<OrdersState> emit,
  ) async {
    final prevShowActive = state is OrdersLoaded
        ? (state as OrdersLoaded).showActive
        : true;

    if (state is! OrdersLoaded) {
      emit(const OrdersLoading());
    }
    final result = await getOrdersUseCase(const NoParams());
    result.fold((failure) => emit(OrdersError(failure.message)), (orders) {
      emit(OrdersLoaded(orders: orders, showActive: prevShowActive));

      // FIX: Always re-evaluate the realtime subscription on load.
      // We track the actual user ID instead of a simple boolean flag.
      // This ensures that if the session changes (logout -> login) or
      // the subscription dies, it correctly recreates the stream.
      final userId = client.auth.currentUser?.id;
      if (userId != null) {
        if (_currentUserId != userId || _realtimeSub == null) {
          _currentUserId = userId;
          _subscribeRealtime(userId);
        }
      }
    });
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
          emit(
            const OrdersError(
              'Service or store not found. Please restart the app.',
            ),
          );
        } else if (msg.contains('row-level security') ||
            msg.contains('policy') ||
            msg.contains('permission')) {
          emit(
            const OrdersError(
              'Permission denied. Please sign out and sign in again.',
            ),
          );
        } else if (msg.contains('jwt') || msg.contains('not authenticated')) {
          emit(
            const OrdersError(
              'Session expired. Please sign out and sign in again.',
            ),
          );
        } else {
          emit(OrdersError(failure.message));
        }
      },
      (order) {
        emit(OrderPlaced(orderId: order.id, orderNumber: order.orderNumber));
        // After placing, reload orders so the new order appears on
        // the OrderScreen immediately. The 600 ms delay gives Supabase time
        // to commit the row before we fetch.
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
    final prevShowActive = state is OrdersLoaded
        ? (state as OrdersLoaded).showActive
        : true;

    // Use the ID-specific state we discussed to prevent global loading
    emit(OrderCancelling(event.orderId));

    final result = await cancelOrderUseCase(CancelOrderParams(event.orderId));

    // Handle the result without nesting async closures inside fold if possible
    await result.fold(
      (failure) async {
        if (!emit.isDone) {
          emit(OrdersError(failure.message));
        }
      },
      (_) async {
        if (!emit.isDone) {
          emit(const OrderCancelled());
        }

        // Fetch fresh orders
        final reloadResult = await getOrdersUseCase(const NoParams());

        reloadResult.fold(
          (failure) {
            if (!emit.isDone) emit(OrdersError(failure.message));
          },
          (orders) {
            if (!emit.isDone) {
              emit(OrdersLoaded(orders: orders, showActive: prevShowActive));
            }
          },
        );
      },
    );
  }

  void _onFilter(OrdersFilterToggled event, Emitter<OrdersState> emit) {
    if (state is! OrdersLoaded) return;
    emit((state as OrdersLoaded).copyWith(showActive: event.showActive));
  }

  bool _isFetchingRealtime = false;
  bool _needsRealtimeRefetch = false;

  Future<void> _onRealtimeTick(
    OrdersRealtimeTick event,
    Emitter<OrdersState> emit,
  ) async {
    if (state is OrderPlacing ||
        state is OrderPlaced ||
        state is OrderCancelling) {
      return;
    }

    if (_isFetchingRealtime) {
      _needsRealtimeRefetch = true;
      return;
    }

    _isFetchingRealtime = true;

    final prevShowActive = state is OrdersLoaded
        ? (state as OrdersLoaded).showActive
        : true;

    final result = await getOrdersUseCase(const NoParams());
    result.fold((_) {}, (orders) {
      if (!isClosed) {
        emit(OrdersLoaded(orders: orders, showActive: prevShowActive));
      }
    });

    _isFetchingRealtime = false;
    if (_needsRealtimeRefetch) {
      _needsRealtimeRefetch = false;
      if (!isClosed) add(const OrdersRealtimeTick());
    }
  }

  // ─── Realtime ──────────────────────────────────────────────────────────────

  void _subscribeRealtime(String userId) {
    _realtimeSub?.cancel();
    bool firstEvent = true;

    _realtimeSub = watchOrdersUseCase(userId).listen(
      (_) {
        // Skip the initial snapshot that Supabase sends immediately on
        // subscription — we already have fresh data from the load above.
        if (firstEvent) {
          firstEvent = false;
          return;
        }
        if (!isClosed) add(const OrdersRealtimeTick());
      },
      onError: (error) {
        // FIX: Automatically attempt to reconnect if the stream silently dies
        Future.delayed(const Duration(seconds: 5), () {
          if (!isClosed && _currentUserId != null) {
            _subscribeRealtime(_currentUserId!);
          }
        });
      },
    );
  }

  // ─── Reset realtime subscription ───────────────────────────────────────────

  /// Call this when the authenticated user changes (logout → re-login) so the
  /// realtime subscription is re-established for the new user's orders.
  void resetSubscription() {
    _realtimeSub?.cancel();
    _realtimeSub = null;
    _currentUserId = null;
  }

  void dispose() {
    _realtimeSub?.cancel();
  }

  Future<void> _onSubmitServiceReview(
    OrderSubmitServiceReview event,
    Emitter<OrdersState> emit,
  ) async {
    final result = await submitServiceReviewUseCase(
      SubmitServiceReviewParams(
        orderId: event.orderId,
        serviceId: event.serviceId,
        rating: event.rating,
        comment: event.comment,
      ),
    );
    result.fold(
      (failure) => emit(OrdersError(failure.message)),
      (_) => emit(OrdersActionSuccess('Review submitted successfully')),
    );
  }

  Future<void> _onSubmitRiderRating(
    OrderSubmitRiderRating event,
    Emitter<OrdersState> emit,
  ) async {
    final result = await submitRiderRatingUseCase(
      SubmitRiderRatingParams(
        orderId: event.orderId,
        riderId: event.riderId,
        ratingType: event.ratingType,
        stars: event.stars,
        comment: event.comment,
      ),
    );
    result.fold(
      (failure) => emit(OrdersError(failure.message)),
      (_) => emit(OrdersActionSuccess('Rating submitted successfully')),
    );
  }

  @override
  Future<void> close() {
    _realtimeSub?.cancel();
    return super.close();
  }
}
