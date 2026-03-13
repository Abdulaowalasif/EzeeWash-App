// lib/features/stores/data/models/store_model.dart
import '../../domain/entities/store_entity.dart';

class StoreModel extends StoreEntity {
  const StoreModel({
    required super.id,
    required super.name,
    required super.address,
    super.city,
    super.phone,
    super.distanceKm,
    super.latitude,
    super.longitude,
    super.isActive,
  });

  factory StoreModel.fromJson(Map<String, dynamic> j) => StoreModel(
    id: j['id'] as String,
    name: j['name'] as String,
    address: j['address'] as String,
    city: j['city'] as String?,
    phone: j['phone'] as String?,
    distanceKm: (j['distance_km'] as num?)?.toDouble(),
    latitude: (j['latitude'] as num?)?.toDouble(),
    longitude: (j['longitude'] as num?)?.toDouble(),
    isActive: j['is_active'] as bool? ?? true,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'address': address,
    'city': city,
    'phone': phone,
    'distance_km': distanceKm,
    'latitude': latitude,
    'longitude': longitude,
    'is_active': isActive,
  };
}