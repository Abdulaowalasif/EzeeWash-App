// lib/features/notifications/bloc/notifications_state.dart
part of 'notifications_bloc.dart';

sealed class NotificationsState extends Equatable {
  const NotificationsState();
  @override
  List<Object?> get props => [];
}

/// No load attempted yet.
final class NotificationsInitial extends NotificationsState {
  const NotificationsInitial();
}

/// Fetching notifications — show a loading indicator.
final class NotificationsLoading extends NotificationsState {
  const NotificationsLoading();
}

/// Notifications loaded successfully (or defaulted to empty on failure).
final class NotificationsLoaded extends NotificationsState {
  final List<NotificationEntity> notifications;
  const NotificationsLoaded({required this.notifications});

  /// Number of unread — drives the badge on the tab icon.
  int get unreadCount => notifications.where((n) => !n.isRead).length;

  bool get hasUnread => unreadCount > 0;

  @override
  List<Object?> get props => [notifications];
}

/// A non-recoverable load error — show a retry button.
final class NotificationsError extends NotificationsState {
  final String message;
  const NotificationsError(this.message);
  @override
  List<Object> get props => [message];
}
