import 'package:equatable/equatable.dart';

import '../../domain/entities/promo_entity.dart';

/// Base class for all promos events.
abstract class PromoEvent extends Equatable {
  const PromoEvent();

  @override
  List<Object?> get props => [];
}

// lib/features/promos/presentation/bloc/promo_event.dart
class WatchPromosStarted extends PromoEvent {}

class PromosUpdated extends PromoEvent {
  final List<PromoEntity> promos;
  const PromosUpdated(this.promos);
}