// lib/features/notifications/bloc/notifications_bloc.dart
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../data/models/notification_model.dart';
import 'notifications_event.dart';
import 'notifications_state.dart';


class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final SupabaseClient _client;
  StreamSubscription? _realtimeSub;

  NotificationsBloc(this._client) : super(const NotificationsInitial()) {
    on<NotificationsLoadRequested>(_onLoad);
    on<NotificationMarkRead>(_onMarkRead);
    on<NotificationMarkAllRead>(_onMarkAllRead);
    on<NotificationsRealtimeUpdated>(_onRealtime);
  }

  Future<void> _onLoad(
    NotificationsLoadRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(const NotificationsLoading());
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      final data = await _client
          .from(AppConstants.notificationsTable)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final notifications = (data as List)
          .map((e) => NotificationModel.fromJson(e))
          .toList();

      emit(NotificationsLoaded(notifications: notifications));

      // Realtime
      _realtimeSub?.cancel();
      _realtimeSub = _client
          .from(AppConstants.notificationsTable)
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .listen((data) => add(NotificationsRealtimeUpdated(data)));
    } catch (e) {
      emit(NotificationsError(e.toString()));
    }
  }

  Future<void> _onMarkRead(
    NotificationMarkRead event,
    Emitter<NotificationsState> emit,
  ) async {
    if (state is! NotificationsLoaded) return;
    await _client
        .from(AppConstants.notificationsTable)
        .update({'is_read': true})
        .eq('id', event.notificationId);
  }

  Future<void> _onMarkAllRead(
    NotificationMarkAllRead event,
    Emitter<NotificationsState> emit,
  ) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await _client
        .from(AppConstants.notificationsTable)
        .update({'is_read': true})
        .eq('user_id', userId)
        .eq('is_read', false);
  }

  void _onRealtime(
    NotificationsRealtimeUpdated event,
    Emitter<NotificationsState> emit,
  ) {
    final notifications = event.data
        .map((e) => NotificationModel.fromJson(e))
        .toList();
    emit(NotificationsLoaded(notifications: notifications));
  }

  @override
  Future<void> close() {
    _realtimeSub?.cancel();
    return super.close();
  }
}
