// lib/features/auth/data/models/user_model.dart

import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    super.fullName,
    super.email,
    super.phone,
    super.avatarUrl,
    super.address,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        fullName: json['full_name'] as String?,
        email: json['email'] as String?,
        phone: json['phone'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        address: json['address'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'email': email,
        'phone': phone,
        'avatar_url': avatarUrl,
        'address': address,
      };

  UserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    String? avatarUrl,
    String? address,
  }) =>
      UserModel(
        id: id ?? this.id,
        fullName: fullName ?? this.fullName,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        address: address ?? this.address,
      );
}