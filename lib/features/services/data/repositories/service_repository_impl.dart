// lib/features/services/data/repositories/services_repository_impl.dart
import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/service_entity.dart';
import '../../domain/repositories/service_repository.dart';
import '../datasources/service_remote_datasource.dart';


class ServicesRepositoryImpl implements ServicesRepository {
  final ServicesRemoteDataSource remoteDataSource;
  ServicesRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<ServiceEntity>>> getAllServices() async {
    try {
      final services = await remoteDataSource.getAllServices();
      return Right(services);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ServiceEntity>>> getServicesByCategory(
      String category) async {
    try {
      final services = await remoteDataSource.getServicesByCategory(category);
      return Right(services);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ServiceEntity>> getServiceById(String id) async {
    try {
      final service = await remoteDataSource.getServiceById(id);
      return Right(service);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }
}