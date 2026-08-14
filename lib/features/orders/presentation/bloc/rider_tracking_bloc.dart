// lib/features/orders/presentation/bloc/rider_tracking_bloc.dart
import 'dart:async';
import 'package:bloc/bloc.dart';
import '../../domain/repositories/orders_repository.dart';
import 'rider_tracking_event.dart';
import 'rider_tracking_state.dart';

class RiderTrackingBloc extends Bloc<RiderTrackingEvent, RiderTrackingState> {
  final OrdersRepository repository;
  StreamSubscription? _sub;

  RiderTrackingBloc({required this.repository})
    : super(const RiderTrackingInitial()) {
    on<RiderTrackingStarted>(_onStarted);
    on<RiderTrackingUpdated>(_onUpdated);
  }

  void _onStarted(
    RiderTrackingStarted event,
    Emitter<RiderTrackingState> emit,
  ) {
    emit(const RiderTrackingLoading());
    _sub?.cancel();
    _sub = repository
        .watchRider(event.riderId)
        .listen(
          (data) {
            if (data != null) {
              add(RiderTrackingUpdated(data));
            }
          },
          onError: (e) {
            // Optionally handle error
          },
        );
  }

  void _onUpdated(
    RiderTrackingUpdated event,
    Emitter<RiderTrackingState> emit,
  ) {
    emit(RiderTrackingLoaded(event.riderRow));
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
