// lib/features/profile/presentation/bloc/address_state.dart
import 'package:equatable/equatable.dart';
import '../../domain/entities/address_entity.dart';

abstract class AddressState extends Equatable {
  const AddressState();
  @override
  List<Object?> get props => [];
}

class AddressInitial extends AddressState {}

class AddressLoading extends AddressState {}

class AddressLoaded extends AddressState {
  final List<AddressEntity> addresses;
  const AddressLoaded(this.addresses);
  @override
  List<Object?> get props => [addresses];
}

class AddressError extends AddressState {
  final String message;
  const AddressError(this.message);
  @override
  List<Object?> get props => [message];
}
