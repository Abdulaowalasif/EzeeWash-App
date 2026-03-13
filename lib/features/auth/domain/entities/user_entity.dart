// lib/features/auth/domain/entities/user_entity.dart
import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String? fullName;
  final String? email;
  final String? phone;
  final String? avatarUrl;
  final String? address;

  const UserEntity({
    required this.id,
    this.fullName,
    this.email,
    this.phone,
    this.avatarUrl,
    this.address,
  });

  @override
  List<Object?> get props => [id, fullName, email, phone, avatarUrl, address];
}