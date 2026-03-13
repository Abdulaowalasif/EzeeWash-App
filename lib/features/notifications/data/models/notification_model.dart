// lib/features/notifications/data/models/notification_model.dart
import '../../domain/entities/notification_entity.dart';

class NotificationModel extends NotificationEntity {
  const NotificationModel({
    required super.id,
    required super.userId,
    required super.title,
    required super.body,
    required super.type,
    super.orderId,
    required super.isRead,
    required super.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> j) =>
      NotificationModel(
        id: j['id'] as String,
        userId: j['user_id'] as String,
        title: j['title'] as String,
        body: j['body'] as String,
        type: j['type'] as String? ?? 'general',
        orderId: j['order_id'] as String?,
        isRead: j['is_read'] as bool? ?? false,
        createdAt: j['created_at'] != null
            ? DateTime.parse(j['created_at'] as String)
            : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'title': title,
    'body': body,
    'type': type,
    'order_id': orderId,
    'is_read': isRead,
    'created_at': createdAt.toIso8601String(),
  };
}