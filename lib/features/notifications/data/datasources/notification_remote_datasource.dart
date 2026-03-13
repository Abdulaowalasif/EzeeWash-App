// lib/features/notifications/data/datasources/notifications_remote_datasource.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/notification_model.dart';

abstract class NotificationsRemoteDataSource {
  Future<List<NotificationModel>> getNotifications(String userId);
  Future<void> markRead(String notificationId);
  Future<void> markAllRead(String userId);
  Stream<List<Map<String, dynamic>>> watchNotifications(String userId);
}

class NotificationsRemoteDataSourceImpl implements NotificationsRemoteDataSource {
  final SupabaseClient _client;
  NotificationsRemoteDataSourceImpl(this._client);

  @override
  Future<List<NotificationModel>> getNotifications(String userId) async {
    try {
      final data = await _client
          .from(AppConstants.notificationsTable)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return (data as List).map((e) => NotificationModel.fromJson(e)).toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> markRead(String notificationId) async {
    try {
      await _client
          .from(AppConstants.notificationsTable)
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> markAllRead(String userId) async {
    try {
      await _client
          .from(AppConstants.notificationsTable)
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Stream<List<Map<String, dynamic>>> watchNotifications(String userId) {
    return _client
        .from(AppConstants.notificationsTable)
        .stream(primaryKey: ['id'])
        .eq('user_id', userId);
  }
}