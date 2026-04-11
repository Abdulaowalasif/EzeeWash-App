import 'dart:async';
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
    // .stream() does not support joins, so we use a StreamController
    // backed by an initial fetch + a Realtime channel for live updates.
    final controller = StreamController<List<PromoModel>>();

    Future<void> fetch() async {
      try {
        // Since the app requires login, currentUser is guaranteed to be non-null here
        final userId = supabaseClient.auth.currentUser!.id;

        final data = await supabaseClient
            .from('promos')
            .select('*, services(title)') // JOIN to get service name
            .eq('is_active', true)
            .or('target_user_id.is.null,target_user_id.eq.$userId')
            .order('created_at');

        final promos = (data as List)
            .map((json) => PromoModel.fromJson(json as Map<String, dynamic>))
            .toList();

        if (!controller.isClosed) controller.add(promos);
      } catch (e) {
        if (!controller.isClosed) controller.addError(e);
      }
    }

    // Initial load
    fetch();

    // Listen for any change on the promos table and re-fetch
    final channel = supabaseClient
        .channel('promos_changes')
        .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'promos',
      callback: (_) => fetch(),
    )
        .subscribe();

    controller.onCancel = () {
      supabaseClient.removeChannel(channel);
      controller.close();
    };

    return controller.stream;
  }
}