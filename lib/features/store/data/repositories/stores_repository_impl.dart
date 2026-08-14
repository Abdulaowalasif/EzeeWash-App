// lib/features/stores/data/repositories/stores_repository_impl.dart
import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/cache/repository_cache.dart';
import '../../domain/entities/store_entity.dart';
import '../models/store_model.dart';
import '../../domain/repositories/store_repository.dart';
import '../datasources/stores_remote_datasouce.dart';

class StoresRepositoryImpl implements StoresRepository {
  final StoresRemoteDataSource remoteDataSource;
  final RepositoryCache<List<StoreEntity>> _listCache = RepositoryCache(
    cachePrefix: 'stores_list_',
    toJson: (list) => list.map((e) => (e as StoreModel).toJson()).toList(),
    fromJson: (json) => (json as List).map((e) => StoreModel.fromJson(e)).toList(),
  );
  
  final RepositoryCache<StoreEntity> _singleCache = RepositoryCache(
    cachePrefix: 'stores_single_',
    toJson: (item) => (item as StoreModel).toJson(),
    fromJson: (json) => StoreModel.fromJson(json),
  );

  StoresRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<StoreEntity>>> getAllStores({
    bool forceRefresh = false,
  }) async {
    try {
      final stores = await _listCache.get(
        'all_stores',
        () => remoteDataSource.getAllStores(),
        ttl: const Duration(minutes: 30),
        forceRefresh: forceRefresh,
      );
      return Right(stores);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, StoreEntity>> getStoreById(
    String id, {
    bool forceRefresh = false,
  }) async {
    try {
      final store = await _singleCache.get(
        'store_$id',
        () => remoteDataSource.getStoreById(id),
        ttl: const Duration(minutes: 30),
        forceRefresh: forceRefresh,
      );
      return Right(store);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }
}
