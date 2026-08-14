// lib/features/stores/domain/usecases/stores_usecases.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/usecase.dart';
import '../entities/store_entity.dart';
import '../repositories/store_repository.dart';

// ─── Get All Stores ───────────────────────────────────────────────────────────

class GetAllStoresUseCase
    implements UseCase<List<StoreEntity>, GetAllStoresParams> {
  final StoresRepository repository;
  GetAllStoresUseCase(this.repository);

  @override
  Future<Either<Failure, List<StoreEntity>>> call(GetAllStoresParams params) =>
      repository.getAllStores(forceRefresh: params.forceRefresh);
}

class GetAllStoresParams extends Equatable {
  final bool forceRefresh;
  const GetAllStoresParams({this.forceRefresh = false});
  @override
  List<Object> get props => [forceRefresh];
}

// ─── Get Store By ID ──────────────────────────────────────────────────────────

class GetStoreByIdUseCase implements UseCase<StoreEntity, StoreIdParams> {
  final StoresRepository repository;
  GetStoreByIdUseCase(this.repository);

  @override
  Future<Either<Failure, StoreEntity>> call(StoreIdParams params) =>
      repository.getStoreById(params.id, forceRefresh: params.forceRefresh);
}

class StoreIdParams extends Equatable {
  final String id;
  final bool forceRefresh;
  const StoreIdParams(this.id, {this.forceRefresh = false});
  @override
  List<Object> get props => [id, forceRefresh];
}
