
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/promo_model.dart';

abstract class PromoRemoteDataSource {
  Stream<List<PromoModel>> watchPromos();
}


class PromoRemoteDataSourceImpl implements PromoRemoteDataSource {
  final SupabaseClient supabaseClient;

  PromoRemoteDataSourceImpl(this.supabaseClient);

  @override
  Stream<List<PromoModel>> watchPromos() {
    return supabaseClient
        .from('promos')
        .stream(primaryKey: ['id'])
        .order('created_at')
        .map((data) => data.map((json) => PromoModel.fromJson(json)).toList());
  }
}