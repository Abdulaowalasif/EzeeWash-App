import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/watch_promo_usecase.dart';
import 'promo_event.dart';
import 'promo_state.dart';

// lib/features/promos/presentation/bloc/promo_bloc.dart

class PromoBloc extends Bloc<PromoEvent, PromoState> {
  final WatchPromosUseCase watchPromosUseCase;
  StreamSubscription? _sub;

  PromoBloc({required this.watchPromosUseCase}) : super(const PromoInitial()) {
    on<WatchPromosStarted>(_onWatchPromosStarted);
  }

  Future<void> _onWatchPromosStarted(
    WatchPromosStarted event,
    Emitter<PromoState> emit,
  ) async {
    if (!event.forceRefresh && state is PromoLoaded) {
      // Keep existing state, but we will still subscribe below
    } else {
      emit(const PromoLoading());
    }

    _sub?.cancel();
    await emit.forEach(
      watchPromosUseCase(),
      onData: (result) {
        return result.fold(
          (failure) => PromoError(failure.message),
          (promos) => PromoLoaded(promos),
        );
      },
      onError: (e, s) => PromoError(e.toString()),
    );
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
