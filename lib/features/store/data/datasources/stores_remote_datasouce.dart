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

  static const _selectList =
      'id, name, address, city, phone, distance_km, latitude, longitude, is_active, logo_url, open_hour, close_hour, slot_capacity, slot_interval_hours, pickup_buffer_hours, advance_booking_days';

  @override
  Future<List<StoreModel>> getAllStores() async {
    try {
      final data = await _client
          .from(AppConstants.storesTable)
          .select(_selectList)
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
          .select('$_selectList, store_slot_bookings(id, store_id, slot_date, slot_hour, slot_type, order_count, unit_count)')
          .eq('id', id)
          .single();
      return StoreModel.fromJson(data);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
