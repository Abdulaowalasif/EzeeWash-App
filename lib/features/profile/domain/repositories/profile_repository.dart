// lib/features/profile/domain/repositories/profile_repository.dart
import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/profile_entity.dart';

abstract class ProfileRepository {
  Future<Either<Failure, ProfileEntity>> getProfile();
  Future<Either<Failure, ProfileEntity>> updateProfile({
    String? fullName,
    String? phone,
    String? address,
    String? city,
  });
  Future<Either<Failure, ProfileEntity>> updateAvatar(File imageFile);
}