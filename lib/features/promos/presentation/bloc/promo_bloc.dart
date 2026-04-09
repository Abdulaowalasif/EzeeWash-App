import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/watch_promo_usecase.dart';
import 'promo_event.dart';
import 'promo_state.dart';

// lib/features/promos/presentation/bloc/promo_bloc.dart

class PromoBloc extends Bloc<PromoEvent, PromoState> {
  final WatchPromosUseCase watchPromosUseCase;
  StreamSubscription? _promoSubscription; // To manage the stream lifecycle

  PromoBloc({required this.watchPromosUseCase}) : super(const PromoInitial()) {
    on<WatchPromosStarted>(_onWatchPromosStarted);
    on<PromosUpdated>(_onPromosUpdated); // New event for stream data
  }

  Future<void> _onWatchPromosStarted(WatchPromosStarted event, Emitter<PromoState> emit) async {
    emit(const PromoLoading());

    // Cancel any existing subscription
    await _promoSubscription?.cancel();

    // Start listening to the stream
    _promoSubscription = watchPromosUseCase().listen(
          (promos) => add(PromosUpdated(promos)),
      onError: (error) => emit(PromoError(error.toString())),
    );
  }

  void _onPromosUpdated(PromosUpdated event, Emitter<PromoState> emit) {
    emit(PromoLoaded(event.promos));
  }

  @override
  Future<void> close() {
    _promoSubscription?.cancel(); // Always cancel streams to avoid memory leaks
    return super.close();
  }
}