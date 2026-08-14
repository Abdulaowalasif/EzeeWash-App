// lib/features/notifications/domain/repositories/notifications_repository.dart
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/notification_entity.dart';

abstract class NotificationsRepository {
  Future<Either<Failure, List<NotificationEntity>>> getNotifications();
  Future<Either<Failure, void>> markRead(String notificationId);
  Future<Either<Failure, void>> markAllRead();
  Stream<List<Map<String, dynamic>>> watchNotifications(String userId);
}
