// lib/features/profile/presentation/bloc/address_event.dart
import 'package:equatable/equatable.dart';
import '../../domain/entities/address_entity.dart';

abstract class AddressEvent extends Equatable {
  const AddressEvent();
  @override
  List<Object?> get props => [];
}

class AddressLoadRequested extends AddressEvent {}

class AddressSaveRequested extends AddressEvent {
  final AddressEntity address;
  const AddressSaveRequested(this.address);
  @override
  List<Object?> get props => [address];
}

class AddressDeleteRequested extends AddressEvent {
  final String id;
  const AddressDeleteRequested(this.id);
  @override
  List<Object?> get props => [id];
}

class AddressSetDefault extends AddressEvent {
  final String id;
  const AddressSetDefault(this.id);
  @override
  List<Object?> get props => [id];
}
