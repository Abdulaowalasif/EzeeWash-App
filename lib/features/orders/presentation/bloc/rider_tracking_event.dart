// lib/features/orders/presentation/bloc/rider_tracking_event.dart
import 'package:equatable/equatable.dart';

sealed class RiderTrackingEvent extends Equatable {
  const RiderTrackingEvent();

  @override
  List<Object?> get props => [];
}

class RiderTrackingStarted extends RiderTrackingEvent {
  final String riderId;

  const RiderTrackingStarted(this.riderId);

  @override
  List<Object?> get props => [riderId];
}

class RiderTrackingUpdated extends RiderTrackingEvent {
  final Map<String, dynamic> riderRow;

  const RiderTrackingUpdated(this.riderRow);

  @override
  List<Object?> get props => [riderRow];
}
