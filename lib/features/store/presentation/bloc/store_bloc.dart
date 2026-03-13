// lib/features/stores/bloc/stores_bloc.dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ezeewash/features/store/presentation/bloc/store_state.dart';
import 'package:ezeewash/features/store/presentation/bloc/stores_event.dart';

import '../../../../core/utils/usecase.dart';
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

  Future<void> _onLoad(StoresLoadRequested event, Emitter<StoresState> emit) async {
    emit(const StoresLoading());
    final result = await getAllStoresUseCase(const NoParams());
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