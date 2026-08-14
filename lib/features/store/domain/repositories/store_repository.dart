// lib/features/stores/domain/repositories/stores_repository.dart
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/store_entity.dart';

abstract class StoresRepository {
  Future<Either<Failure, List<StoreEntity>>> getAllStores({
    bool forceRefresh = false,
  });
  Future<Either<Failure, StoreEntity>> getStoreById(
    String id, {
    bool forceRefresh = false,
  });
}
