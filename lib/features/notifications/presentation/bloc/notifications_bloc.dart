// lib/features/notifications/bloc/notifications_bloc.dart
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/usecase.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/usecases/notification_usecase.dart';

part 'notifications_event.dart';
part 'notifications_state.dart';

/// Loads notifications, handles mark-read (single + bulk), and
/// keeps the list live via Supabase Realtime.
///
/// Realtime strategy (mirrors OrdersBloc):
///   - Subscribe ONCE after the first successful load (_subscribed guard).
///   - Skip the immediate snapshot Supabase emits on subscribe (firstEvent flag).
///   - Background ticks do a SILENT reload — never emit NotificationsLoading,
///     so the list never flickers a spinner on realtime updates.
///   - Mark-read is optimistic: state is updated immediately for a snappy UI,
///     then the DB write fires in the background.
class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final GetNotificationsUseCase getNotificationsUseCase;
  final MarkNotificationReadUseCase markReadUseCase;
  final MarkAllNotificationsReadUseCase markAllReadUseCase;
  final SupabaseClient client;

  StreamSubscription? _realtimeSub;
  bool _subscribed = false; // ← guard: subscribe only once

  NotificationsBloc({
    required this.getNotificationsUseCase,
    required this.markReadUseCase,
    required this.markAllReadUseCase,
    required this.client,
  }) : super(const NotificationsInitial()) {
    on<NotificationsLoadRequested>(_onLoad);
    on<NotificationMarkReadRequested>(_onMarkRead);
    on<NotificationsMarkAllReadRequested>(_onMarkAllRead);
    on<NotificationsRealtimeTick>(_onRealtimeTick);
  }

  // ─── Handlers ──────────────────────────────────────────────────────────────

  Future<void> _onLoad(
      NotificationsLoadRequested event,
      Emitter<NotificationsState> emit,
      ) async {
    emit(const NotificationsLoading());
    final result = await getNotificationsUseCase(const NoParams());
    result.fold(
          (_) => emit(const NotificationsLoaded(notifications: [])),
          (list) {
        emit(NotificationsLoaded(notifications: list));
        // Subscribe to realtime only once — not on every reload
        if (!_subscribed) {
          final userId = client.auth.currentUser?.id;
          if (userId != null) {
            _subscribed = true;
            _subscribeRealtime(userId);
          }
        }
      },
    );
  }

  Future<void> _onMarkRead(
      NotificationMarkReadRequested event,
      Emitter<NotificationsState> emit,
      ) async {
    // Optimistic update — instant UI response
    if (state is NotificationsLoaded) {
      final cur = state as NotificationsLoaded;
      emit(NotificationsLoaded(
        notifications: cur.notifications
            .map((n) => n.id == event.notificationId
            ? n.copyWith(isRead: true)
            : n)
            .toList(),
      ));
    }
    // Fire-and-forget — realtime will reconcile if it fails
    await markReadUseCase(MarkReadParams(event.notificationId));
  }

  Future<void> _onMarkAllRead(
      NotificationsMarkAllReadRequested event,
      Emitter<NotificationsState> emit,
      ) async {
    // Optimistic update
    if (state is NotificationsLoaded) {
      final cur = state as NotificationsLoaded;
      emit(NotificationsLoaded(
        notifications:
        cur.notifications.map((n) => n.copyWith(isRead: true)).toList(),
      ));
    }
    await markAllReadUseCase(const NoParams());
  }

  /// Silent background refresh — never emits NotificationsLoading so
  /// the list never flickers a spinner on realtime ticks.
  Future<void> _onRealtimeTick(
      NotificationsRealtimeTick event,
      Emitter<NotificationsState> emit,
      ) async {
    final result = await getNotificationsUseCase(const NoParams());
    result.fold(
          (_) {}, // silent fail — don't surface background errors
          (list) => emit(NotificationsLoaded(notifications: list)),
    );
  }

  // ─── Realtime ─────────────────────────────────────────────────────────────

  void _subscribeRealtime(String userId) {
    _realtimeSub?.cancel();
    bool firstEvent = true; // skip the immediate snapshot on subscribe
    _realtimeSub = client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .listen(
          (_) {
        // Supabase .stream() emits the current snapshot immediately on
        // subscribe. Skip it to avoid a redundant reload.
        if (firstEvent) {
          firstEvent = false;
          return;
        }
        if (!isClosed) add(const NotificationsRealtimeTick());
      },
      onError: (_) {},
    );
  }

  @override
  Future<void> close() {
    _realtimeSub?.cancel();
    return super.close();
  }
}