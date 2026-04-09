import '../entities/promo_entity.dart';

abstract class PromoRepository {
  Stream<List<PromoEntity>> watchPromos();
}