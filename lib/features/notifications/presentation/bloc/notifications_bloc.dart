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

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final GetNotificationsUseCase getNotificationsUseCase;
  final MarkNotificationReadUseCase markReadUseCase;
  final MarkAllNotificationsReadUseCase markAllReadUseCase;
  final WatchNotificationsUseCase watchNotificationsUseCase;
  final SupabaseClient client; // Kept for auth context

  StreamSubscription? _realtimeSub;

  NotificationsBloc({
    required this.getNotificationsUseCase,
    required this.markReadUseCase,
    required this.markAllReadUseCase,
    required this.watchNotificationsUseCase,
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
    if (state is! NotificationsLoaded) {
      emit(const NotificationsLoading());
    }
    final result = await getNotificationsUseCase(const NoParams());
    result.fold(
      (failure) => emit(NotificationsError(failure.message)),
      (list) {
        emit(NotificationsLoaded(notifications: list));
        final userId = client.auth.currentUser?.id;
        if (userId != null) {
          _subscribeRealtime(userId);
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
      emit(
        NotificationsLoaded(
          notifications: cur.notifications
              .map(
                (n) =>
                    n.id == event.notificationId ? n.copyWith(isRead: true) : n,
              )
              .toList(),
        ),
      );
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
      emit(
        NotificationsLoaded(
          notifications: cur.notifications
              .map((n) => n.copyWith(isRead: true))
              .toList(),
        ),
      );
    }
    await markAllReadUseCase(const NoParams());

    // Re-fetch to reconcile global notification read status from SharedPreferences
    final result = await getNotificationsUseCase(const NoParams());
    result.fold(
      (_) {},
      (list) => emit(NotificationsLoaded(notifications: list)),
    );
  }

  bool _isFetchingRealtime = false;
  bool _needsRealtimeRefetch = false;

  /// Silent background refresh — never emits NotificationsLoading so
  /// the list never flickers a spinner on realtime ticks.
  Future<void> _onRealtimeTick(
    NotificationsRealtimeTick event,
    Emitter<NotificationsState> emit,
  ) async {
    if (_isFetchingRealtime) {
      _needsRealtimeRefetch = true;
      return;
    }

    _isFetchingRealtime = true;

    final result = await getNotificationsUseCase(const NoParams());
    result.fold(
      (_) {}, // silent fail — don't surface background errors
      (list) {
        if (!isClosed) {
          emit(NotificationsLoaded(notifications: list));
        }
      },
    );

    _isFetchingRealtime = false;
    if (_needsRealtimeRefetch) {
      _needsRealtimeRefetch = false;
      if (!isClosed) add(const NotificationsRealtimeTick());
    }
  }

  // ─── Realtime ─────────────────────────────────────────────────────────────

  void _subscribeRealtime(String userId) {
    _realtimeSub?.cancel();
    bool firstEvent = true; // skip the immediate snapshot on subscribe
    _realtimeSub = watchNotificationsUseCase(userId).listen((_) {
      // Supabase .stream() emits the current snapshot immediately on
      // subscribe. Skip it to avoid a redundant reload.
      if (firstEvent) {
        firstEvent = false;
        return;
      }
      if (!isClosed) add(const NotificationsRealtimeTick());
    }, onError: (_) {});
  }

  /// Call when the authenticated user changes (logout → re-login) so the
  /// realtime subscription is re-established for the new user.
  /// Also clears the loaded state so stale unread counts don't linger.
  void resetSubscription() {
    _realtimeSub?.cancel();
    _realtimeSub = null;
    // ignore: invalid_use_of_visible_for_testing_member
    emit(const NotificationsInitial());
  }

  @override
  Future<void> close() {
    _realtimeSub?.cancel();
    return super.close();
  }
}
