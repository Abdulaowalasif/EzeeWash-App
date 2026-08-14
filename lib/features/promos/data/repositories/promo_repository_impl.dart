import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/cache/repository_cache.dart';
import '../../domain/entities/promo_entity.dart';
import '../models/promo_model.dart';
import '../../domain/repositories/promo_repository.dart';
import '../datasources/promo_remote_datasource.dart';

class PromoRepositoryImpl implements PromoRepository {
  final PromoRemoteDataSource remoteDataSource;
  final RepositoryCache<List<PromoEntity>> _cache = RepositoryCache(
    cachePrefix: 'promos_list_',
    toJson: (list) => list.map((e) => (e as PromoModel).toJson()).toList(),
    fromJson: (json) => (json as List).map((e) => PromoModel.fromJson(e)).toList(),
  );

  PromoRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<PromoEntity>>> getPromos({
    bool forceRefresh = false,
  }) async {
    try {
      final promos = await _cache.get(
        'promos',
        () => remoteDataSource.getPromos(),
        ttl: const Duration(minutes: 60),
        forceRefresh: forceRefresh,
      );
      return Right(promos);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }
}
