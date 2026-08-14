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
  Stream<Map<String, dynamic>?> watchRider(String riderId);
  Future<void> submitServiceReview(
    String orderId,
    String serviceId,
    String userId,
    double rating,
    String? comment,
  );
  Future<void> submitRiderRating(
    String orderId,
    String riderId,
    String userId,
    String ratingType,
    double stars,
    String? comment,
  );
  Future<double> validateCoupon(String userId, ValidateCouponParams params);
  Future<String> createPaymentIntent(CreatePaymentIntentParams params);
}

class OrdersRemoteDataSourceImpl implements OrdersRemoteDataSource {
  final SupabaseClient _client;
  OrdersRemoteDataSourceImpl(this._client);

  static const _select =
      '*, services(title,category,image_url), stores(name), order_timelines(title, description, event_time, is_done, step_order),'
      ' riders:rider_id(id,full_name,phone,avatar_url,vehicle_type,vehicle_plate,rating,is_online,current_lat,current_lng),'
      ' pickup_rider:pickup_rider_id(id,full_name,phone,avatar_url,vehicle_type,vehicle_plate,rating,is_online,current_lat,current_lng),'
      ' delivery_rider:delivery_rider_id(id,full_name,phone,avatar_url,vehicle_type,vehicle_plate,rating,is_online,current_lat,current_lng)';

  static const _selectNoTimeline =
      '*, services(title,category,image_url), stores(name),'
      ' riders:rider_id(id,full_name,phone,avatar_url,vehicle_type,vehicle_plate,rating,is_online,current_lat,current_lng),'
      ' pickup_rider:pickup_rider_id(id,full_name,phone,avatar_url,vehicle_type,vehicle_plate,rating,is_online,current_lat,current_lng),'
      ' delivery_rider:delivery_rider_id(id,full_name,phone,avatar_url,vehicle_type,vehicle_plate,rating,is_online,current_lat,current_lng)';

  static const _selectList =
      '*, services(title,category,image_url), stores(name)';

  @override
  Future<List<OrderModel>> getOrders(String userId) async {
    try {
      final data = await _client
          .from(AppConstants.ordersTable)
          .select(_selectNoTimeline)
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (data as List)
          .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
          .toList();
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
      String? fmtDate(DateTime? d) {
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
            'pickup_address':
                '${params.pickupAddress.address}${params.pickupAddress.city != null ? ', ${params.pickupAddress.city}' : ''}',
            'delivery_address': params.deliveryAddress != null
                ? '${params.deliveryAddress!.address}${params.deliveryAddress!.city != null ? ', ${params.deliveryAddress!.city}' : ''}'
                : '${params.pickupAddress.address}${params.pickupAddress.city != null ? ', ${params.pickupAddress.city}' : ''}',
            'pickup_date': fmtDate(params.pickupDate),
            'pickup_time': params.pickupTime,
            'delivery_date': fmtDate(params.deliveryDate),
            'delivery_time': params.deliveryTime,
            'special_instructions': params.specialInstructions,
            'status': AppConstants.orderPending,
            'progress': 0.0,
            'payment_method': params.paymentMethod.value,
            'payment_status': params.paymentMethod == PaymentMethod.stripe
                ? 'paid'
                : 'pending',

            // ─── NEW: Coupon insertion ───
            'coupon_code': params.couponCode,
            'discount_amount': params.discountAmount,
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
        {
          'order_id': orderId,
          'title': 'Order Placed',
          'description': 'Your order has been received',
          'is_done': true,
          'step_order': 1,
        },
        {
          'order_id': orderId,
          'title': 'Picked Up',
          'description': 'Rider collected your laundry',
          'is_done': false,
          'step_order': 2,
        },
        {
          'order_id': orderId,
          'title': 'In Process',
          'description': 'Being cleaned at the facility',
          'is_done': false,
          'step_order': 3,
        },
        {
          'order_id': orderId,
          'title': 'Ready for Delivery',
          'description': 'Packed and ready to deliver',
          'is_done': false,
          'step_order': 4,
        },
        {
          'order_id': orderId,
          'title': 'Delivered',
          'description': 'Order completed successfully',
          'is_done': false,
          'step_order': 5,
        },
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

  @override
  Stream<Map<String, dynamic>?> watchRider(String riderId) {
    return _client
        .from(AppConstants.ridersTable)
        .stream(primaryKey: ['id'])
        .eq('id', riderId)
        .map((data) => data.isNotEmpty ? data.first : null);
  }

  @override
  Future<void> submitServiceReview(
    String orderId,
    String serviceId,
    String userId,
    double rating,
    String? comment,
  ) async {
    try {
      await _client.from(AppConstants.reviewsTable).insert({
        'service_id': serviceId,
        'user_id': userId,
        'rating': rating,
        'comment': comment,
        'order_id': orderId,
      });
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> submitRiderRating(
    String orderId,
    String riderId,
    String userId,
    String ratingType,
    double stars,
    String? comment,
  ) async {
    try {
      await _client.from(AppConstants.riderRatingsTable).upsert({
        'order_id': orderId,
        'rider_id': riderId,
        'user_id': userId,
        'rating_type': ratingType,
        'stars': stars,
        'comment': comment,
      }, onConflict: 'order_id,rating_type');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<double> validateCoupon(
    String userId,
    ValidateCouponParams params,
  ) async {
    try {
      final rows = await _client
          .from('promos')
          .select(
            'id, code, valid_from, valid_until, usage_limit, times_used, target_user_id, target_service_id, min_order_amount, discount_type, discount_value, max_discount_amount',
          )
          .ilike('code', params.code)
          .eq('is_active', true)
          .limit(1);

      if (rows.isEmpty) {
        throw const ServerException('Invalid coupon code.');
      }

      final promo = rows.first;

      final previousOrdersWithCoupon = await _client
          .from(AppConstants.ordersTable)
          .select('id')
          .eq('user_id', userId)
          .ilike('coupon_code', params.code)
          .limit(1);

      if (previousOrdersWithCoupon.isNotEmpty) {
        throw const ServerException('You have already used this coupon.');
      }

      final validFrom = DateTime.parse(promo['valid_from'] as String);
      final validUntil = promo['valid_until'] != null
          ? DateTime.parse(promo['valid_until'] as String)
          : null;
      final nowDt = DateTime.now().toUtc();

      if (nowDt.isBefore(validFrom)) {
        throw const ServerException('This coupon is not active yet.');
      }
      if (validUntil != null && nowDt.isAfter(validUntil)) {
        throw const ServerException('This coupon has expired.');
      }

      final usageLimit = promo['usage_limit'] as int?;
      final timesUsed = promo['times_used'] as int? ?? 0;
      if (usageLimit != null && timesUsed >= usageLimit) {
        throw const ServerException('This coupon has reached its usage limit.');
      }

      final targetUserId = promo['target_user_id'] as String?;
      if (targetUserId != null && targetUserId != userId) {
        throw const ServerException(
          'This coupon is not valid for your account.',
        );
      }

      final targetServiceId = promo['target_service_id'] as String?;
      double baseAmountForDiscount = params.orderBeforeDiscount;

      if (targetServiceId != null) {
        if (!params.serviceIds.contains(targetServiceId)) {
          throw const ServerException(
            'This coupon does not apply to any of the selected services.',
          );
        }
        baseAmountForDiscount = params.serviceSubtotals[targetServiceId] ?? 0.0;
      }

      final minOrder = (promo['min_order_amount'] as num?)?.toDouble();
      if (minOrder != null && params.orderBeforeDiscount < minOrder) {
        throw ServerException(
          'Minimum order of ৳${minOrder.toStringAsFixed(0)} required.',
        );
      }

      final discountType = promo['discount_type'] as String;
      final discountValue = (promo['discount_value'] as num).toDouble();
      final maxDiscount = (promo['max_discount_amount'] as num?)?.toDouble();

      double discount;
      if (discountType == 'percentage') {
        discount = baseAmountForDiscount * discountValue / 100.0;
        if (maxDiscount != null && discount > maxDiscount) {
          discount = maxDiscount;
        }
      } else {
        discount = discountValue;
        if (discount > baseAmountForDiscount) {
          discount = baseAmountForDiscount;
        }
      }

      return discount.clamp(0.0, params.orderBeforeDiscount);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Could not validate coupon. Please try again.');
    }
  }

  @override
  Future<String> createPaymentIntent(CreatePaymentIntentParams params) async {
    try {
      final response = await _client.functions.invoke(
        'create-payment-intent',
        body: {
          'amount': params.amount,
          'currency': 'bdt',
          'orderId': 'TEMP-${DateTime.now().millisecondsSinceEpoch}',
          'description': 'EzeeWash - ${params.serviceTitle}',
        },
      );
      return response.data['clientSecret'] as String;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
