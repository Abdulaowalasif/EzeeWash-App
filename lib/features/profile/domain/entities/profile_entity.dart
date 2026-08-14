import 'package:equatable/equatable.dart';

import 'address_entity.dart';

class ProfileEntity extends Equatable {
  final String id;
  final String? fullName;
  final String? email;
  final String? phone;
  final String? avatarUrl;
  final AddressEntity? address;
  final String? city;

  const ProfileEntity({
    required this.id,
    this.fullName,
    this.email,
    this.phone,
    this.avatarUrl,
    this.address,
    this.city,
  });

  ProfileEntity copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    String? avatarUrl,
    AddressEntity? address,
    String? city,
  }) => ProfileEntity(
    id: id ?? this.id,
    fullName: fullName ?? this.fullName,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    address: address ?? this.address,
    city: city ?? this.city,
  );

  @override
  List<Object?> get props => [
    id,
    fullName,
    email,
    phone,
    avatarUrl,
    address,
    city,
  ];
}
