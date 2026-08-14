import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/cache/repository_cache.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/entities/address_entity.dart';
import '../models/profile_model.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;
  final SupabaseClient client;
  final RepositoryCache<ProfileEntity> _cache = RepositoryCache(
    cachePrefix: 'profile_single_',
    toJson: (item) => (item as ProfileModel).toJson(),
    fromJson: (json) => ProfileModel.fromJson(json),
  );

  ProfileRepositoryImpl({required this.remoteDataSource, required this.client});

  String? get _userId => client.auth.currentUser?.id;

  @override
  Future<Either<Failure, ProfileEntity>> getProfile({
    bool forceRefresh = false,
  }) async {
    final userId = _userId;
    if (userId == null) return const Left(AuthFailure('Not authenticated'));

    try {
      final profile = await _cache.get(
        'profile_$userId',
        () async {
          var fetched = await remoteDataSource.getProfile(userId);
          if (fetched == null) {
            final au = client.auth.currentUser!;
            fetched = await remoteDataSource.upsertProfile(
              userId: userId,
              fullName:
                  au.userMetadata?['full_name'] as String? ??
                  au.email?.split('@').first,
              email: au.email,
            );
          }
          return fetched;
        },
        ttl: const Duration(minutes: 5),
        forceRefresh: forceRefresh,
      );

      return Right(profile);
    } on ServerException {
      final au = client.auth.currentUser!;
      return Right(
        ProfileEntity(
          id: userId,
          email: au.email,
          fullName: au.userMetadata?['full_name'] as String?,
        ),
      );
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ProfileEntity>> updateProfile({
    String? fullName,
    String? phone,
    AddressEntity? address,
    String? city,
  }) async {
    final userId = _userId;
    if (userId == null) return const Left(AuthFailure('Not authenticated'));

    try {
      final updated = await remoteDataSource.upsertProfile(
        userId: userId,
        fullName: fullName,
        phone: phone,
        address: address?.address,
        city: city ?? address?.city,
      );
      _cache.invalidate('profile_$userId');
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
      final avatarUrl = await remoteDataSource.uploadAvatar(userId, imageFile);
      final updated = await remoteDataSource.upsertProfile(
        userId: userId,
        avatarUrl: avatarUrl,
      );
      _cache.invalidate('profile_$userId');
      return Right(updated);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }
}
