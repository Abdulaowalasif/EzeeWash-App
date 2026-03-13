// lib/features/profile/data/models/profile_model.dart
import '../../domain/entities/profile_entity.dart';

class ProfileModel extends ProfileEntity {
  const ProfileModel({
    required super.id,
    super.fullName,
    super.email,
    super.phone,
    super.avatarUrl,
    super.address,
    super.city,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> j) => ProfileModel(
    id: j['id'] as String,
    fullName: j['full_name'] as String?,
    email: j['email'] as String?,
    phone: j['phone'] as String?,
    avatarUrl: j['avatar_url'] as String?,
    address: j['address'] as String?,
    city: j['city'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'full_name': fullName,
    'email': email,
    'phone': phone,
    'avatar_url': avatarUrl,
    'address': address,
    'city': city,
  };

  ProfileModel copyWithModel({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    String? avatarUrl,
    String? address,
    String? city,
  }) =>
      ProfileModel(
        id: id ?? this.id,
        fullName: fullName ?? this.fullName,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        address: address ?? this.address,
        city: city ?? this.city,
      );
}