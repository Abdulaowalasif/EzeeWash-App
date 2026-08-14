// lib/features/services/data/repositories/services_repository_impl.dart
import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/cache/repository_cache.dart';
import '../../domain/entities/service_entity.dart';
import '../models/service_model.dart';
import '../../domain/repositories/service_repository.dart';
import '../datasources/service_remote_datasource.dart';

class ServicesRepositoryImpl implements ServicesRepository {
  final ServicesRemoteDataSource remoteDataSource;
  final RepositoryCache<List<ServiceEntity>> _listCache = RepositoryCache(
    cachePrefix: 'services_list_',
    toJson: (list) => list.map((e) => (e as ServiceModel).toJson()).toList(),
    fromJson: (json) => (json as List).map((e) => ServiceModel.fromJson(e)).toList(),
  );
  
  final RepositoryCache<ServiceEntity> _singleCache = RepositoryCache(
    cachePrefix: 'services_single_',
    toJson: (item) => (item as ServiceModel).toJson(),
    fromJson: (json) => ServiceModel.fromJson(json),
  );

  ServicesRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<ServiceEntity>>> getAllServices({
    bool forceRefresh = false,
  }) async {
    try {
      final services = await _listCache.get(
        'all_services',
        () => remoteDataSource.getAllServices(),
        ttl: const Duration(minutes: 30),
        forceRefresh: forceRefresh,
      );
      return Right(services);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ServiceEntity>>> getServicesByCategory(
    String category, {
    bool forceRefresh = false,
  }) async {
    try {
      final services = await _listCache.get(
        'services_$category',
        () => remoteDataSource.getServicesByCategory(category),
        ttl: const Duration(minutes: 30),
        forceRefresh: forceRefresh,
      );
      return Right(services);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ServiceEntity>> getServiceById(
    String id, {
    bool forceRefresh = false,
  }) async {
    try {
      final service = await _singleCache.get(
        'service_$id',
        () => remoteDataSource.getServiceById(id),
        ttl: const Duration(minutes: 30),
        forceRefresh: forceRefresh,
      );
      return Right(service);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }
}
