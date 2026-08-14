// lib/features/notifications/data/models/notification_model.dart
import '../../domain/entities/notification_entity.dart';

class NotificationModel extends NotificationEntity {
  const NotificationModel({
    required super.id,
    super.userId,
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
        userId: j['user_id'] as String?,
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

  @override
  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    String? type,
    String? orderId,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      orderId: orderId ?? this.orderId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
