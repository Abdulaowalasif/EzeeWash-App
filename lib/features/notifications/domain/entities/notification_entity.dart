// lib/features/notifications/domain/entities/notification_entity.dart
import 'package:equatable/equatable.dart';

class NotificationEntity extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type;
  final String? orderId;
  final bool isRead;
  final DateTime createdAt;

  const NotificationEntity({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.orderId,
    required this.isRead,
    required this.createdAt,
  });

  NotificationEntity copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    String? type,
    String? orderId,
    bool? isRead,
    DateTime? createdAt,
  }) =>
      NotificationEntity(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        title: title ?? this.title,
        body: body ?? this.body,
        type: type ?? this.type,
        orderId: orderId ?? this.orderId,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  List<Object?> get props => [id, isRead];
}