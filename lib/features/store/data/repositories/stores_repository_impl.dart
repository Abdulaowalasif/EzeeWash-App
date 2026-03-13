// lib/features/stores/data/repositories/stores_repository_impl.dart
import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/store_entity.dart';
import '../../domain/repositories/store_repository.dart';
import '../datasources/stores_remote_datasouce.dart';

class StoresRepositoryImpl implements StoresRepository {
  final StoresRemoteDataSource remoteDataSource;
  StoresRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<StoreEntity>>> getAllStores() async {
    try {
      final stores = await remoteDataSource.getAllStores();
      return Right(stores);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, StoreEntity>> getStoreById(String id) async {
    try {
      final store = await remoteDataSource.getStoreById(id);
      return Right(store);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }
}