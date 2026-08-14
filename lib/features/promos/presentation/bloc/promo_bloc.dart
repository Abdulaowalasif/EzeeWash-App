import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/watch_promo_usecase.dart';
import 'promo_event.dart';
import 'promo_state.dart';

// lib/features/promos/presentation/bloc/promo_bloc.dart

class PromoBloc extends Bloc<PromoEvent, PromoState> {
  final GetPromosUseCase getPromosUseCase;

  PromoBloc({required this.getPromosUseCase}) : super(const PromoInitial()) {
    on<WatchPromosStarted>(_onWatchPromosStarted);
  }

  Future<void> _onWatchPromosStarted(
    WatchPromosStarted event,
    Emitter<PromoState> emit,
  ) async {
    if (!event.forceRefresh && state is PromoLoaded) {
      // Handled by repository cache
    } else {
      emit(const PromoLoading());
    }

    final result = await getPromosUseCase(
      GetPromosParams(forceRefresh: event.forceRefresh),
    );
    result.fold(
      (failure) => emit(PromoError(failure.message)),
      (promos) => emit(PromoLoaded(promos)),
    );
  }
}
