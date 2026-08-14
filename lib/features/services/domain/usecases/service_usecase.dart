// lib/features/services/domain/usecases/services_usecases.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/usecase.dart';
import '../entities/service_entity.dart';
import '../repositories/service_repository.dart';

// ─── Get All Services ─────────────────────────────────────────────────────────

class GetAllServicesUseCase
    implements UseCase<List<ServiceEntity>, GetAllServicesParams> {
  final ServicesRepository repository;
  GetAllServicesUseCase(this.repository);

  @override
  Future<Either<Failure, List<ServiceEntity>>> call(
    GetAllServicesParams params,
  ) => repository.getAllServices(forceRefresh: params.forceRefresh);
}

class GetAllServicesParams extends Equatable {
  final bool forceRefresh;
  const GetAllServicesParams({this.forceRefresh = false});
  @override
  List<Object> get props => [forceRefresh];
}

// ─── Get Services By Category ─────────────────────────────────────────────────

class GetServicesByCategoryUseCase
    implements UseCase<List<ServiceEntity>, CategoryParams> {
  final ServicesRepository repository;
  GetServicesByCategoryUseCase(this.repository);

  @override
  Future<Either<Failure, List<ServiceEntity>>> call(CategoryParams params) =>
      repository.getServicesByCategory(
        params.category,
        forceRefresh: params.forceRefresh,
      );
}

class CategoryParams extends Equatable {
  final String category;
  final bool forceRefresh;
  const CategoryParams(this.category, {this.forceRefresh = false});
  @override
  List<Object> get props => [category, forceRefresh];
}

// ─── Get Service By ID ────────────────────────────────────────────────────────

class GetServiceByIdUseCase implements UseCase<ServiceEntity, ServiceIdParams> {
  final ServicesRepository repository;
  GetServiceByIdUseCase(this.repository);

  @override
  Future<Either<Failure, ServiceEntity>> call(ServiceIdParams params) =>
      repository.getServiceById(params.id, forceRefresh: params.forceRefresh);
}

class ServiceIdParams extends Equatable {
  final String id;
  final bool forceRefresh;
  const ServiceIdParams(this.id, {this.forceRefresh = false});
  @override
  List<Object> get props => [id, forceRefresh];
}
