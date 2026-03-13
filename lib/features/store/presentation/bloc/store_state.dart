// lib/features/stores/bloc/stores_state.dart
import 'package:equatable/equatable.dart';
import '../../domain/entities/store_entity.dart';

abstract class StoresState extends Equatable {
  const StoresState();
  @override
  List<Object?> get props => [];
}

class StoresInitial extends StoresState {
  const StoresInitial();
}

class StoresLoading extends StoresState {
  const StoresLoading();
}

class StoresLoaded extends StoresState {
  final List<StoreEntity> stores;
  final String? selectedStoreId;

  const StoresLoaded({required this.stores, this.selectedStoreId});

  StoreEntity? get selectedStore =>
      selectedStoreId != null
          ? stores.firstWhere((s) => s.id == selectedStoreId,
          orElse: () => stores.first)
          : null;

  StoresLoaded copyWith({List<StoreEntity>? stores, String? selectedStoreId}) =>
      StoresLoaded(
        stores: stores ?? this.stores,
        selectedStoreId: selectedStoreId ?? this.selectedStoreId,
      );

  @override
  List<Object?> get props => [stores, selectedStoreId];
}

class StoresError extends StoresState {
  final String message;
  const StoresError(this.message);
  @override
  List<Object> get props => [message];
}