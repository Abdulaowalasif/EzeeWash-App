import 'package:equatable/equatable.dart';

abstract class NotificationsEvent extends Equatable {
  const NotificationsEvent();
  @override
  List<Object?> get props => [];
}

class NotificationsLoadRequested extends NotificationsEvent {
  const NotificationsLoadRequested();
}

class NotificationMarkRead extends NotificationsEvent {
  final String notificationId;
  const NotificationMarkRead(this.notificationId);

  @override
  List<Object> get props => [notificationId];
}

class NotificationMarkAllRead extends NotificationsEvent {
  const NotificationMarkAllRead();
}

class NotificationsRealtimeUpdated extends NotificationsEvent {
  final List<Map<String, dynamic>> data;
  const NotificationsRealtimeUpdated(this.data);

  @override
  List<Object> get props => [data];
}