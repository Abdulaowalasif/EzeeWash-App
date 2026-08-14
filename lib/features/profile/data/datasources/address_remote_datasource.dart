import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/address_model.dart';
import '../../domain/entities/address_entity.dart';

abstract class AddressRemoteDataSource {
  Future<List<AddressModel>> getAddresses(String userId);
  Future<void> insertAddress(String userId, AddressEntity address);
  Future<void> updateAddress(AddressEntity address);
  Future<void> deleteAddress(String id);
  Future<void> setDefaultAddress(String userId, String id);
}

class AddressRemoteDataSourceImpl implements AddressRemoteDataSource {
  final SupabaseClient _client;

  AddressRemoteDataSourceImpl(this._client);

  @override
  Future<List<AddressModel>> getAddresses(String userId) async {
    try {
      final data = await _client
          .from(AppConstants.addressesTable)
          .select('id, user_id, label, address, city, is_default, created_at')
          .eq('user_id', userId)
          .order('created_at');
      return (data as List).map((e) => AddressModel.fromJson(e)).toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> insertAddress(String userId, AddressEntity address) async {
    try {
      await _client.from(AppConstants.addressesTable).insert({
        'user_id': userId,
        'label': address.label,
        'address': address.address,
        'city': address.city,
        'is_default': false,
      });
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> updateAddress(AddressEntity address) async {
    try {
      await _client
          .from(AppConstants.addressesTable)
          .update({
            'label': address.label,
            'address': address.address,
            'city': address.city,
          })
          .eq('id', address.id!);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> deleteAddress(String id) async {
    try {
      await _client.from(AppConstants.addressesTable).delete().eq('id', id);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> setDefaultAddress(String userId, String id) async {
    try {
      await _client
          .from(AppConstants.addressesTable)
          .update({'is_default': false})
          .eq('user_id', userId);
      await _client
          .from(AppConstants.addressesTable)
          .update({'is_default': true})
          .eq('id', id);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
