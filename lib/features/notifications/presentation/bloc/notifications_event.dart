// lib/features/notifications/bloc/notifications_event.dart
part of 'notifications_bloc.dart';

sealed class NotificationsEvent extends Equatable {
  const NotificationsEvent();
  @override
  List<Object?> get props => [];
}

/// Fetch (or re-fetch) the current user's notifications.
final class NotificationsLoadRequested extends NotificationsEvent {
  const NotificationsLoadRequested();
}

/// Mark a single notification as read.
final class NotificationMarkReadRequested extends NotificationsEvent {
  final String notificationId;
  const NotificationMarkReadRequested(this.notificationId);
  @override
  List<Object> get props => [notificationId];
}

/// Mark all unread notifications as read.
final class NotificationsMarkAllReadRequested extends NotificationsEvent {
  const NotificationsMarkAllReadRequested();
}

/// Internal — fired by the Supabase Realtime subscription.
/// Screens cannot dispatch this directly.
final class NotificationsRealtimeTick extends NotificationsEvent {
  const NotificationsRealtimeTick();
}

/// Clear notifications data on logout
final class NotificationsClearData extends NotificationsEvent {
  const NotificationsClearData();
}
