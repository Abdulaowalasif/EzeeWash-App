import 'dart:io';

import 'package:equatable/equatable.dart';

import '../../domain/entities/address_entity.dart';

// lib/features/profile/bloc/profile_event.dart
sealed class ProfileEvent extends Equatable {
  const ProfileEvent();
  @override
  List<Object?> get props => [];
}

/// Fetch the current user's profile row from Supabase.
/// Dispatched automatically after login (see _AuthReactiveLoader in main.dart).
final class ProfileLoadRequested extends ProfileEvent {
  final bool forceRefresh;
  const ProfileLoadRequested({this.forceRefresh = false});
  @override
  List<Object?> get props => [forceRefresh];
}

/// Save one or more profile fields. Only non-null fields are written.
final class ProfileUpdateRequested extends ProfileEvent {
  final String? fullName;
  final String? phone;
  final AddressEntity? address;
  final String? city;

  const ProfileUpdateRequested({
    this.fullName,
    this.phone,
    this.address,
    this.city,
  });

  @override
  List<Object?> get props => [fullName, phone, address, city];
}

/// Upload a new avatar image and persist its public URL.
final class ProfileAvatarUpdateRequested extends ProfileEvent {
  final File imageFile;
  const ProfileAvatarUpdateRequested(this.imageFile);
  @override
  List<Object> get props => [imageFile.path];
}
