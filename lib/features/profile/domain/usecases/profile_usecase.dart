// lib/features/profile/domain/usecases/profile_usecases.dart
import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/usecase.dart';
import '../entities/profile_entity.dart';
import '../entities/address_entity.dart';
import '../repositories/profile_repository.dart';

// ─── Get Profile ──────────────────────────────────────────────────────────────

class GetProfileUseCase implements UseCase<ProfileEntity, GetProfileParams> {
  final ProfileRepository repository;
  GetProfileUseCase(this.repository);

  @override
  Future<Either<Failure, ProfileEntity>> call(GetProfileParams params) =>
      repository.getProfile(forceRefresh: params.forceRefresh);
}

class GetProfileParams extends Equatable {
  final bool forceRefresh;
  const GetProfileParams({this.forceRefresh = false});
  @override
  List<Object> get props => [forceRefresh];
}

// ─── Update Profile ───────────────────────────────────────────────────────────

class UpdateProfileUseCase
    implements UseCase<ProfileEntity, UpdateProfileParams> {
  final ProfileRepository repository;
  UpdateProfileUseCase(this.repository);

  @override
  Future<Either<Failure, ProfileEntity>> call(UpdateProfileParams params) =>
      repository.updateProfile(
        fullName: params.fullName,
        phone: params.phone,
        address: params.address,
        city: params.city,
      );
}

class UpdateProfileParams extends Equatable {
  final String? fullName;
  final String? phone;
  final AddressEntity? address;
  final String? city;

  const UpdateProfileParams({
    this.fullName,
    this.phone,
    this.address,
    this.city,
  });

  @override
  List<Object?> get props => [fullName, phone, address, city];
}

// ─── Update Avatar ────────────────────────────────────────────────────────────

class UpdateAvatarUseCase
    implements UseCase<ProfileEntity, UpdateAvatarParams> {
  final ProfileRepository repository;
  UpdateAvatarUseCase(this.repository);

  @override
  Future<Either<Failure, ProfileEntity>> call(UpdateAvatarParams params) =>
      repository.updateAvatar(params.imageFile);
}

class UpdateAvatarParams extends Equatable {
  final File imageFile;
  const UpdateAvatarParams(this.imageFile);
  @override
  List<Object> get props => [imageFile];
}
