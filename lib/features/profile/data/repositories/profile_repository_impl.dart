import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;
  final SupabaseClient client;

  ProfileRepositoryImpl({
    required this.remoteDataSource,
    required this.client,
  });

  String? get _userId => client.auth.currentUser?.id;

  @override
  Future<Either<Failure, ProfileEntity>> getProfile() async {
    final userId = _userId;
    if (userId == null) return const Left(AuthFailure('Not authenticated'));

    try {
      var profile = await remoteDataSource.getProfile(userId);

      if (profile == null) {
        // Auto-create profile from auth metadata
        final au = client.auth.currentUser!;
        profile = await remoteDataSource.upsertProfile(
          userId: userId,
          fullName: au.userMetadata?['full_name'] as String? ??
              au.email?.split('@').first,
          email: au.email,
        );
      }

      return Right(profile);
    } on ServerException {
      final au = client.auth.currentUser!;
      return Right(ProfileEntity(
        id: userId,
        email: au.email,
        fullName: au.userMetadata?['full_name'] as String?,
      ));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ProfileEntity>> updateProfile({
    String? fullName,
    String? phone,
    String? address,
    String? city,
  }) async {
    final userId = _userId;
    if (userId == null) return const Left(AuthFailure('Not authenticated'));

    try {
      final updated = await remoteDataSource.upsertProfile(
        userId: userId,
        fullName: fullName,
        phone: phone,
        address: address,
        city: city,
      );
      return Right(updated);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ProfileEntity>> updateAvatar(File imageFile) async {
    final userId = _userId;
    if (userId == null) return const Left(AuthFailure('Not authenticated'));

    try {
      // 1️⃣ Upload file → get signed URL
      final avatarUrl = await remoteDataSource.uploadAvatar(userId, imageFile);

      // 2️⃣ Persist avatar URL in profile row
      final updated = await remoteDataSource.upsertProfile(
        userId: userId,
        avatarUrl: avatarUrl,
      );

      return Right(updated);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }
}