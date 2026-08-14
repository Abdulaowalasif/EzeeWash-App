// lib/features/orders/presentation/bloc/rider_tracking_state.dart
import 'package:equatable/equatable.dart';

sealed class RiderTrackingState extends Equatable {
  const RiderTrackingState();

  @override
  List<Object?> get props => [];
}

class RiderTrackingInitial extends RiderTrackingState {
  const RiderTrackingInitial();
}

class RiderTrackingLoading extends RiderTrackingState {
  const RiderTrackingLoading();
}

class RiderTrackingLoaded extends RiderTrackingState {
  final Map<String, dynamic> riderRow;

  const RiderTrackingLoaded(this.riderRow);

  @override
  List<Object?> get props => [riderRow];
}
