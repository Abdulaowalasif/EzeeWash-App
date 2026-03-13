// lib/features/services/domain/entities/service_entity.dart
import 'package:equatable/equatable.dart';

class ServiceEntity extends Equatable {
  final String id;
  final String category;
  final String title;
  final String? description;
  final double price;
  final String? duration;
  final String? imageUrl;
  final List<String> tags;
  final bool isActive;

  const ServiceEntity({
    required this.id,
    required this.category,
    required this.title,
    this.description,
    required this.price,
    this.duration,
    this.imageUrl,
    this.tags = const [],
    this.isActive = true,
  });

  @override
  List<Object?> get props => [id, category, title, price, isActive];
}
