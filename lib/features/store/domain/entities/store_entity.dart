// lib/features/stores/domain/entities/store_entity.dart
import 'package:equatable/equatable.dart';

class StoreEntity extends Equatable {
  final String id;
  final String name;
  final String address;
  final String? city;
  final String? phone;
  final double? distanceKm;
  final double? latitude;
  final double? longitude;
  final bool isActive;

  const StoreEntity({
    required this.id,
    required this.name,
    required this.address,
    this.city,
    this.phone,
    this.distanceKm,
    this.latitude,
    this.longitude,
    this.isActive = true,
  });

  String get distanceLabel => distanceKm != null ? '${distanceKm!.toStringAsFixed(1)} km' : '';

  @override
  List<Object?> get props => [id, name, address, isActive];
}