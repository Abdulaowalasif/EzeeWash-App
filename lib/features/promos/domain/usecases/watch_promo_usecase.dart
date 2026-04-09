// lib/features/promos/domain/usecases/watch_promos_usecase.dart
import '../entities/promo_entity.dart';
import '../repositories/promo_repository.dart';

class WatchPromosUseCase {
  final PromoRepository repository;
  WatchPromosUseCase(this.repository);

  Stream<List<PromoEntity>> call() {
    return repository.watchPromos();
  }
}