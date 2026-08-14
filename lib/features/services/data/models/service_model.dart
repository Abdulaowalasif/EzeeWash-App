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
    id: j['id']?.toString() ?? '',
    category: j['category']?.toString() ?? '',
    title: j['title']?.toString() ?? '',
    description: j['description']?.toString(),
    price: double.tryParse(j['price']?.toString() ?? '0') ?? 0.0,
    duration: j['duration']?.toString(),
    imageUrl: j['image_url']?.toString(),
    tags: _parseTags(j['tags']),
    isActive: j['is_active'] == true || j['is_active'] == 'true',
    // Safely parse rating, defaulting to 0.0 if not present yet
    rating: double.tryParse(j['rating']?.toString() ?? '0') ?? 0.0,
  );

  static List<String> _parseTags(dynamic tags) {
    if (tags == null) return [];
    if (tags is List) return tags.map((e) => e.toString()).toList();
    if (tags is String) {
      final clean = tags.replaceAll('{', '').replaceAll('}', '');
      if (clean.isEmpty) return [];
      return clean.split(',').map((e) => e.trim().replaceAll('"', '')).toList();
    }
    return [];
  }

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
  }) => ServiceModel(
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
