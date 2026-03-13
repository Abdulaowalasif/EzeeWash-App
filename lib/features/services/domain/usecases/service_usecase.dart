// lib/features/services/domain/usecases/services_usecases.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/usecase.dart';
import '../entities/service_entity.dart';
import '../repositories/service_repository.dart';

// ─── Get All Services ─────────────────────────────────────────────────────────

class GetAllServicesUseCase implements UseCase<List<ServiceEntity>, NoParams> {
  final ServicesRepository repository;
  GetAllServicesUseCase(this.repository);

  @override
  Future<Either<Failure, List<ServiceEntity>>> call(NoParams params) =>
      repository.getAllServices();
}

// ─── Get Services By Category ─────────────────────────────────────────────────

class GetServicesByCategoryUseCase
    implements UseCase<List<ServiceEntity>, CategoryParams> {
  final ServicesRepository repository;
  GetServicesByCategoryUseCase(this.repository);

  @override
  Future<Either<Failure, List<ServiceEntity>>> call(CategoryParams params) =>
      repository.getServicesByCategory(params.category);
}

class CategoryParams extends Equatable {
  final String category;
  const CategoryParams(this.category);
  @override
  List<Object> get props => [category];
}

// ─── Get Service By ID ────────────────────────────────────────────────────────

class GetServiceByIdUseCase implements UseCase<ServiceEntity, ServiceIdParams> {
  final ServicesRepository repository;
  GetServiceByIdUseCase(this.repository);

  @override
  Future<Either<Failure, ServiceEntity>> call(ServiceIdParams params) =>
      repository.getServiceById(params.id);
}

class ServiceIdParams extends Equatable {
  final String id;
  const ServiceIdParams(this.id);
  @override
  List<Object> get props => [id];
}