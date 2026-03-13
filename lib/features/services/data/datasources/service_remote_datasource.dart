// lib/features/services/data/datasources/services_remote_datasource.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/service_model.dart';

abstract class ServicesRemoteDataSource {
  /// Returns all active services, ordered by category.
  Future<List<ServiceModel>> getAllServices();

  /// Returns services in [category]. Pass 'All Services' to get everything.
  Future<List<ServiceModel>> getServicesByCategory(String category);

  /// Returns the single service with [id].
  Future<ServiceModel> getServiceById(String id);
}

class ServicesRemoteDataSourceImpl implements ServicesRemoteDataSource {
  final SupabaseClient _client;
  ServicesRemoteDataSourceImpl(this._client);

  @override
  Future<List<ServiceModel>> getAllServices() async {
    try {
      final data = await _client
          .from(AppConstants.servicesTable)
          .select()
          .eq('is_active', true)
          .order('category');
      return (data as List).map((e) => ServiceModel.fromJson(e)).toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<ServiceModel>> getServicesByCategory(String category) async {
    try {
      var query = _client
          .from(AppConstants.servicesTable)
          .select()
          .eq('is_active', true);

      if (category != 'All Services') {
        query = query.eq('category', category);
      }

      final data = await query.order('title');
      return (data as List).map((e) => ServiceModel.fromJson(e)).toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<ServiceModel> getServiceById(String id) async {
    try {
      final data = await _client
          .from(AppConstants.servicesTable)
          .select()
          .eq('id', id)
          .single();
      return ServiceModel.fromJson(data);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}