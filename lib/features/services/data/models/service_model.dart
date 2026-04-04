// lib/features/services/data/models/service_model.dart
import '../../domain/entities/service_entity.dart';

class ServiceModel extends ServiceEntity {
  const ServiceModel({
    required super.id,
    required super.category,
    required super.title,
    super.description,
    required super.price,
    super.duration,
    super.imageUrl,
    super.tags,
    super.isActive,
    super.rating,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> j) => ServiceModel(
    id: j['id'] as String,
    category: j['category'] as String,
    title: j['title'] as String,
    description: j['description'] as String?,
    price: (j['price'] as num).toDouble(),
    duration: j['duration'] as String?,
    imageUrl: j['image_url'] as String?,
    tags: List<String>.from(j['tags'] ?? []),
    isActive: j['is_active'] as bool? ?? true,
    // Safely parse rating, defaulting to 0.0 if not present yet
    rating: (j['rating'] as num?)?.toDouble() ?? 0.0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category,
    'title': title,
    'description': description,
    'price': price,
    'duration': duration,
    'image_url': imageUrl,
    'tags': tags,
    'is_active': isActive,
    'rating': rating,
  };

  ServiceModel copyWith({
    String? id,
    String? category,
    String? title,
    String? description,
    double? price,
    String? duration,
    String? imageUrl,
    List<String>? tags,
    bool? isActive,
    double? rating,
  }) =>
      ServiceModel(
        id: id ?? this.id,
        category: category ?? this.category,
        title: title ?? this.title,
        description: description ?? this.description,
        price: price ?? this.price,
        duration: duration ?? this.duration,
        imageUrl: imageUrl ?? this.imageUrl,
        tags: tags ?? this.tags,
        isActive: isActive ?? this.isActive,
        rating: rating ?? this.rating,
      );
}