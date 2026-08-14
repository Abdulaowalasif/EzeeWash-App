// lib/features/profile/data/datasources/profile_remote_datasource.dart
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/profile_model.dart';

abstract class ProfileRemoteDataSource {
  Future<ProfileModel?> getProfile(String userId);
  Future<ProfileModel> upsertProfile({
    required String userId,
    String? fullName,
    String? email,
    String? phone,
    String? address,
    String? city,
    String? avatarUrl,
  });
  Future<String> uploadAvatar(String userId, File imageFile);
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final SupabaseClient _client;
  ProfileRemoteDataSourceImpl(this._client);

  @override
  Future<ProfileModel?> getProfile(String userId) async {
    try {
      final data = await _client
          .from(AppConstants.profilesTable)
          .select('id, full_name, email, phone, avatar_url, address, city')
          .eq('id', userId)
          .maybeSingle();
      return data != null ? ProfileModel.fromJson(data) : null;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<ProfileModel> upsertProfile({
    required String userId,
    String? fullName,
    String? email,
    String? phone,
    String? address,
    String? city,
    String? avatarUrl,
  }) async {
    try {
      final payload = <String, dynamic>{'id': userId};
      if (fullName != null) payload['full_name'] = fullName;
      if (email != null) payload['email'] = email;
      if (phone != null) payload['phone'] = phone;
      if (address != null) payload['address'] = address;
      if (city != null) payload['city'] = city;
      if (avatarUrl != null) payload['avatar_url'] = avatarUrl;

      await _client
          .from(AppConstants.profilesTable)
          .upsert(payload, onConflict: 'id');

      final updated = await _client
          .from(AppConstants.profilesTable)
          .select('id, full_name, email, phone, avatar_url, address, city')
          .eq('id', userId)
          .single();
      return ProfileModel.fromJson(updated);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<String> uploadAvatar(String userId, File imageFile) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // Detect content type from file extension so non-jpg images
      // (png, webp) aren't rejected by the storage bucket.
      final ext = imageFile.path.split('.').last.toLowerCase();
      final contentType = switch (ext) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        'gif' => 'image/gif',
        _ => 'image/jpeg',
      };
      final safeExt = switch (ext) {
        'png' => 'png',
        'webp' => 'webp',
        _ => 'jpg',
      };

      // Path: {userId}/{timestamp}.{ext}
      // The storage RLS policy checks (storage.foldername(name))[1] = uid
      final filePath = '$userId/$timestamp.$safeExt';

      await _client.storage
          .from('avatars')
          .upload(
            filePath,
            imageFile,
            fileOptions: FileOptions(upsert: true, contentType: contentType),
          );

      // Cache-bust so the UI picks up the new image immediately
      final publicUrl = _client.storage.from('avatars').getPublicUrl(filePath);
      return '$publicUrl?t=$timestamp';
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
