// lib/features/orders/data/datasources/orders_remote_datasource.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/place_orders_params.dart';
import '../models/order_model.dart';

abstract class OrdersRemoteDataSource {
  Future<List<OrderModel>> getOrders(String userId);
  Future<OrderModel> getOrderById(String orderId);
  Future<OrderModel> placeOrder(String userId, PlaceOrderParams params);
  Future<void> insertTimelines(String orderId);
  Future<void> cancelOrder(String orderId);
  Stream<List<Map<String, dynamic>>> watchOrders(String userId);
}

class OrdersRemoteDataSourceImpl implements OrdersRemoteDataSource {
  final SupabaseClient _client;
  OrdersRemoteDataSourceImpl(this._client);

  // FIX: Join the riders table three times using the foreign key names
  static const _select =
      '*, services(title,category,image_url), stores(name), order_timelines(*),'
      ' riders:rider_id(id,full_name,phone,avatar_url,vehicle_type,vehicle_plate,rating,is_online,current_lat,current_lng),'
      ' pickup_rider:pickup_rider_id(id,full_name,phone,avatar_url,vehicle_type,vehicle_plate,rating,is_online,current_lat,current_lng),'
      ' delivery_rider:delivery_rider_id(id,full_name,phone,avatar_url,vehicle_type,vehicle_plate,rating,is_online,current_lat,current_lng),'
      ' rider_locations(latitude,longitude,updated_at)'; // Note: Removed foreign key hint here as Supabase usually infers it if there's only one. If it throws an error, revert to 'rider_locations!rider_locations_order_id_fkey(...)'

  static const _selectNoTimeline =
      '*, services(title,category,image_url), stores(name),'
      ' riders:rider_id(id,full_name,phone,avatar_url,vehicle_type,vehicle_plate,rating,is_online,current_lat,current_lng),'
      ' pickup_rider:pickup_rider_id(id,full_name,phone,avatar_url,vehicle_type,vehicle_plate,rating,is_online,current_lat,current_lng),'
      ' delivery_rider:delivery_rider_id(id,full_name,phone,avatar_url,vehicle_type,vehicle_plate,rating,is_online,current_lat,current_lng),'
      ' rider_locations(latitude,longitude,updated_at)';

  @override
  Future<List<OrderModel>> getOrders(String userId) async {
    try {
      final data = await _client
          .from(AppConstants.ordersTable)
          .select(_select)
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (data as List).map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<OrderModel> getOrderById(String orderId) async {
    try {
      final data = await _client
          .from(AppConstants.ordersTable)
          .select(_select)
          .eq('id', orderId)
          .single();
      return OrderModel.fromJson(data);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<OrderModel> placeOrder(String userId, PlaceOrderParams params) async {
    try {
      String? _fmtDate(DateTime? d) {
        if (d == null) return null;
        return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      }

      await _client.from('profiles').upsert({'id': userId}, onConflict: 'id');

      final row = await _client
          .from(AppConstants.ordersTable)
          .insert({
        'user_id': userId,
        'service_id': params.serviceId,
        'store_id': params.storeId,
        'item_count': params.itemCount,
        'total_price': params.totalPrice,
        'pickup_address': params.pickupAddress,
        'delivery_address': params.deliveryAddress ?? params.pickupAddress,
        'pickup_date': _fmtDate(params.pickupDate),
        'pickup_time': params.pickupTime,
        'delivery_date': _fmtDate(params.deliveryDate),
        'delivery_time': params.deliveryTime,
        'special_instructions': params.specialInstructions,
        'status': AppConstants.orderPending,
        'progress': 0.0,
        'payment_method': params.paymentMethod.value,
        'payment_status': params.paymentMethod == PaymentMethod.stripe ? 'paid' : 'pending',
      })
          .select(_selectNoTimeline)
          .single();
      return OrderModel.fromJson(row);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> insertTimelines(String orderId) async {
    try {
      await _client.from(AppConstants.orderTimelinesTable).insert([
        {'order_id': orderId, 'title': 'Order Placed',       'description': 'Your order has been received',  'is_done': true,  'step_order': 1},
        {'order_id': orderId, 'title': 'Picked Up',          'description': 'Rider collected your laundry',  'is_done': false, 'step_order': 2},
        {'order_id': orderId, 'title': 'In Process',         'description': 'Being cleaned at the facility', 'is_done': false, 'step_order': 3},
        {'order_id': orderId, 'title': 'Ready for Delivery', 'description': 'Packed and ready to deliver',   'is_done': false, 'step_order': 4},
        {'order_id': orderId, 'title': 'Delivered',          'description': 'Order completed successfully',  'is_done': false, 'step_order': 5},
      ]);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> cancelOrder(String orderId) async {
    try {
      await _client
          .from(AppConstants.ordersTable)
          .update({'status': AppConstants.orderCancelled, 'progress': 0.0})
          .eq('id', orderId);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Stream<List<Map<String, dynamic>>> watchOrders(String userId) {
    return _client
        .from(AppConstants.ordersTable)
        .stream(primaryKey: ['id'])
        .eq('user_id', userId);
  }
}