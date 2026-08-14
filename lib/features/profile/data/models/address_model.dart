// lib/features/profile/data/models/address_model.dart
import '../../domain/entities/address_entity.dart';

class AddressModel extends AddressEntity {
  const AddressModel({
    super.id,
    required super.label,
    required super.address,
    super.city,
    super.isDefault = false,
  });

  factory AddressModel.fromJson(Map<String, dynamic> j) => AddressModel(
    id: j['id'] as String?,
    label: j['label'] as String? ?? 'Home',
    address: j['address'] as String? ?? '',
    city: j['city'] as String?,
    isDefault: j['is_default'] as bool? ?? false,
  );

  factory AddressModel.fromEntity(AddressEntity entity) {
    return AddressModel(
      id: entity.id,
      label: entity.label,
      address: entity.address,
      city: entity.city,
      isDefault: entity.isDefault,
    );
  }

  Map<String, dynamic> toJson() => {
    'label': label,
    'address': address,
    if (city != null) 'city': city,
    'is_default': isDefault,
  };
}
