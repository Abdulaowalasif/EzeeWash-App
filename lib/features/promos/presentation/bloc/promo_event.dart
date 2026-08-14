import 'package:equatable/equatable.dart';

/// Base class for all promos events.
abstract class PromoEvent extends Equatable {
  const PromoEvent();

  @override
  List<Object?> get props => [];
}

// lib/features/promos/presentation/bloc/promo_event.dart
class WatchPromosStarted extends PromoEvent {
  final bool forceRefresh;
  const WatchPromosStarted({this.forceRefresh = false});
  @override
  List<Object?> get props => [forceRefresh];
}
