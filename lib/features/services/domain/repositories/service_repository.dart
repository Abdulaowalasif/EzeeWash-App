// lib/features/services/domain/repositories/services_repository.dart
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/service_entity.dart';

abstract class ServicesRepository {
  Future<Either<Failure, List<ServiceEntity>>> getAllServices({
    bool forceRefresh = false,
  });
  Future<Either<Failure, List<ServiceEntity>>> getServicesByCategory(
    String category, {
    bool forceRefresh = false,
  });
  Future<Either<Failure, ServiceEntity>> getServiceById(
    String id, {
    bool forceRefresh = false,
  });
}
