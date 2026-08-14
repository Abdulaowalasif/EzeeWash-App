import 'package:equatable/equatable.dart';

import '../../domain/entities/promo_entity.dart';

/// Base class for all promos states.
abstract class PromoState extends Equatable {
  const PromoState();

  @override
  List<Object?> get props => [];
}

/// The initial state before any action is taken.
class PromoInitial extends PromoState {
  const PromoInitial();
}

/// The state while promos are being fetched from the database.
class PromoLoading extends PromoState {
  const PromoLoading();
}

/// The state when promos have been successfully fetched.
class PromoLoaded extends PromoState {
  final List<PromoEntity> promos;

  const PromoLoaded(this.promos);

  @override
  List<Object?> get props => [promos];
}

/// The state when an error occurs during fetching.
class PromoError extends PromoState {
  final String message;

  const PromoError(this.message);

  @override
  List<Object?> get props => [message];
}
