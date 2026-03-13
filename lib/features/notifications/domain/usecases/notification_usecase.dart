// lib/features/notifications/domain/usecases/notifications_usecases.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/usecase.dart';
import '../entities/notification_entity.dart';
import '../repositories/notification_repositories.dart';


// ─── Get Notifications ────────────────────────────────────────────────────────

class GetNotificationsUseCase
    implements UseCase<List<NotificationEntity>, NoParams> {
  final NotificationsRepository repository;
  GetNotificationsUseCase(this.repository);

  @override
  Future<Either<Failure, List<NotificationEntity>>> call(NoParams params) =>
      repository.getNotifications();
}

// ─── Mark One Read ────────────────────────────────────────────────────────────

class MarkNotificationReadUseCase
    implements UseCase<void, MarkReadParams> {
  final NotificationsRepository repository;
  MarkNotificationReadUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(MarkReadParams params) =>
      repository.markRead(params.notificationId);
}

class MarkReadParams extends Equatable {
  final String notificationId;
  const MarkReadParams(this.notificationId);
  @override
  List<Object> get props => [notificationId];
}

// ─── Mark All Read ────────────────────────────────────────────────────────────

class MarkAllNotificationsReadUseCase implements UseCase<void, NoParams> {
  final NotificationsRepository repository;
  MarkAllNotificationsReadUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) =>
      repository.markAllRead();
}