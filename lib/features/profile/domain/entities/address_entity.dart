// lib/features/profile/domain/entities/address_entity.dart
import 'package:equatable/equatable.dart';

class AddressEntity extends Equatable {
  final String? id;
  final String label;
  final String address;
  final String? city;
  final bool isDefault;

  const AddressEntity({
    this.id,
    required this.label,
    required this.address,
    this.city,
    this.isDefault = false,
  });

  @override
  List<Object?> get props => [id, label, address, city, isDefault];
}
