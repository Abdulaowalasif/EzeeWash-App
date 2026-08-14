// lib/features/stores/bloc/stores_event.dart

import 'package:equatable/equatable.dart';

abstract class StoresEvent extends Equatable {
  const StoresEvent();
  @override
  List<Object?> get props => [];
}

class StoresLoadRequested extends StoresEvent {
  final bool forceRefresh;
  const StoresLoadRequested({this.forceRefresh = false});
  @override
  List<Object?> get props => [forceRefresh];
}

class StoreSelectedChanged extends StoresEvent {
  final String? storeId;
  const StoreSelectedChanged(this.storeId);
  @override
  List<Object?> get props => [storeId];
}
