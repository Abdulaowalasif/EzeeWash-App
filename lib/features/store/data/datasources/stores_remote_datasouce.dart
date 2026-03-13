// lib/features/stores/data/datasources/stores_remote_datasource.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/store_model.dart';

abstract class StoresRemoteDataSource {
  Future<List<StoreModel>> getAllStores();
  Future<StoreModel> getStoreById(String id);
}

class StoresRemoteDataSourceImpl implements StoresRemoteDataSource {
  final SupabaseClient _client;
  StoresRemoteDataSourceImpl(this._client);

  @override
  Future<List<StoreModel>> getAllStores() async {
    try {
      final data = await _client
          .from(AppConstants.storesTable)
          .select()
          .eq('is_active', true)
          .order('distance_km');
      return (data as List).map((e) => StoreModel.fromJson(e)).toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<StoreModel> getStoreById(String id) async {
    try {
      final data = await _client
          .from(AppConstants.storesTable)
          .select()
          .eq('id', id)
          .single();
      return StoreModel.fromJson(data);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}