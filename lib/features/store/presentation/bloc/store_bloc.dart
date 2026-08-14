// lib/features/stores/bloc/stores_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:ezzewash/features/store/presentation/bloc/store_state.dart';
import 'package:ezzewash/features/store/presentation/bloc/stores_event.dart';

import '../../domain/usecases/stores_usecase.dart';

class StoresBloc extends Bloc<StoresEvent, StoresState> {
  final GetAllStoresUseCase getAllStoresUseCase;
  final GetStoreByIdUseCase getStoreByIdUseCase;

  StoresBloc({
    required this.getAllStoresUseCase,
    required this.getStoreByIdUseCase,
  }) : super(const StoresInitial()) {
    on<StoresLoadRequested>(_onLoad);
    on<StoreSelectedChanged>(_onSelected);
  }

  Future<void> _onLoad(
    StoresLoadRequested event,
    Emitter<StoresState> emit,
  ) async {
    if (!event.forceRefresh && state is StoresLoaded) {
      // Data is already handled by repository cache deduplication, don't flash loading
    } else {
      emit(const StoresLoading());
    }
    final result = await getAllStoresUseCase(
      GetAllStoresParams(forceRefresh: event.forceRefresh),
    );
    result.fold(
      (failure) => emit(StoresError(failure.message)),
      (stores) => emit(StoresLoaded(stores: stores)),
    );
  }

  void _onSelected(StoreSelectedChanged event, Emitter<StoresState> emit) {
    if (state is! StoresLoaded) return;
    emit((state as StoresLoaded).copyWith(selectedStoreId: event.storeId));
  }
}
