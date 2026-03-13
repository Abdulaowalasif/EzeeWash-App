// lib/features/notifications/data/repositories/notifications_repository_impl.dart
import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notification_repositories.dart';
import '../datasources/notification_remote_datasource.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  final NotificationsRemoteDataSource remoteDataSource;
  final SupabaseClient client;

  NotificationsRepositoryImpl({
    required this.remoteDataSource,
    required this.client,
  });

  @override
  Future<Either<Failure, List<NotificationEntity>>> getNotifications() async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return const Right([]);
    try {
      final list = await remoteDataSource.getNotifications(userId);
      return Right(list);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markRead(String notificationId) async {
    try {
      await remoteDataSource.markRead(notificationId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markAllRead() async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return const Right(null);
    try {
      await remoteDataSource.markAllRead(userId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Stream<List<Map<String, dynamic>>> watchNotifications(String userId) =>
      remoteDataSource.watchNotifications(userId);
}