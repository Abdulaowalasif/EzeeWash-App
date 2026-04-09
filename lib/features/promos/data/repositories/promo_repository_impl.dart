import '../../domain/entities/promo_entity.dart';
import '../../domain/repositories/promo_repository.dart';
import '../datasources/promo_remote_datasource.dart';

class PromoRepositoryImpl implements PromoRepository {
  final PromoRemoteDataSource remoteDataSource;

  PromoRepositoryImpl(this.remoteDataSource);

  @override
  Stream<List<PromoEntity>> watchPromos() {
    return remoteDataSource.watchPromos();
  }
}
