import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/promo_model.dart';
import '../../../../core/errors/exceptions.dart';

abstract class PromoRemoteDataSource {
  Future<List<PromoModel>> getPromos();
  Stream<void> watchPromosChanges();
}

class PromoRemoteDataSourceImpl implements PromoRemoteDataSource {
  final SupabaseClient supabaseClient;

  PromoRemoteDataSourceImpl(this.supabaseClient);

  @override
  Future<List<PromoModel>> getPromos() async {
    try {
      final userId = supabaseClient.auth.currentUser!.id;

      final data = await supabaseClient
          .from('promos')
          .select('id, code, description, discount_type, discount_value, max_discount_amount, min_order_amount, target_user_id, usage_limit, times_used, valid_from, valid_until, is_active, created_at, target_service_id, banner_url, services(title)')
          .eq('is_active', true)
          .or('target_user_id.is.null,target_user_id.eq.$userId')
          .order('created_at');

      return (data as List)
          .map((json) => PromoModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Stream<void> watchPromosChanges() {
    late final StreamController<void> controller;
    RealtimeChannel? channel;

    controller = StreamController<void>.broadcast(
      onListen: () {
        channel = supabaseClient.channel('public:promos');
        channel!.onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'promos',
          callback: (_) {
            controller.add(null);
          },
        ).subscribe();
      },
      onCancel: () {
        if (channel != null) {
          supabaseClient.removeChannel(channel!);
        }
      },
    );

    return controller.stream;
  }
}
