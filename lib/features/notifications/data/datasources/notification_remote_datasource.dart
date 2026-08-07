// lib/features/notifications/data/datasources/notifications_remote_datasource.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Ensure this is in pubspec.yaml
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
  static const String _readGlobalKey = 'read_global_notifications';

  NotificationsRemoteDataSourceImpl(this._client);

  @override
  Future<List<NotificationModel>> getNotifications(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final readGlobalIds = prefs.getStringList(_readGlobalKey) ?? [];

      final data = await _client
          .from(AppConstants.notificationsTable)
          .select()
          .or('user_id.eq.$userId,user_id.is.null')
          .order('created_at', ascending: false);

      return (data as List).map((e) {
        final model = NotificationModel.fromJson(e);
        // If global notification, check local storage for read status
        if (model.userId == null) {
          final isReadLocally = readGlobalIds.contains(model.id);
          return model.copyWith(isRead: isReadLocally);
        }
        return model;
      }).toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> markRead(String notificationId) async {
    try {
      // 1. Update Database (For personal notifications)
      final response = await _client
          .from(AppConstants.notificationsTable)
          .update({'is_read': true})
          .eq('id', notificationId)
          .not('user_id', 'is', null) // Safety lock
          .select();

      // 2. Update Locally (If it was a global notification)
      if ((response as List).isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final currentRead = prefs.getStringList(_readGlobalKey) ?? [];
        if (!currentRead.contains(notificationId)) {
          currentRead.add(notificationId);
          await prefs.setStringList(_readGlobalKey, currentRead);
        }
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> markAllRead(String userId) async {
    try {
      // Mark personal notifications in DB
      await _client
          .from(AppConstants.notificationsTable)
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);

      // Mark global notifications as read locally via SharedPreferences
      final globalData = await _client
          .from(AppConstants.notificationsTable)
          .select('id')
          .isFilter('user_id', null);

      final globalIds =
          (globalData as List).map((e) => e['id'] as String).toList();

      if (globalIds.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final currentRead = prefs.getStringList(_readGlobalKey) ?? [];
        final merged = {...currentRead, ...globalIds}.toList();
        await prefs.setStringList(_readGlobalKey, merged);
      }
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