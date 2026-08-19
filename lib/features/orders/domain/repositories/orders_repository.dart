// lib/features/orders/domain/repositories/orders_repository.dart
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/order_entity.dart';
import '../entities/place_orders_params.dart';

abstract class OrdersRepository {
  Future<Either<Failure, List<OrderEntity>>> getOrders();
  Future<Either<Failure, OrderEntity>> getOrderById(String orderId);
  Future<Either<Failure, OrderEntity>> placeOrder(PlaceOrderParams params);
  Future<Either<Failure, void>> cancelOrder(String orderId);
  Stream<List<Map<String, dynamic>>> watchOrders(String userId);
  Stream<Map<String, dynamic>?> watchRider(String riderId);
  Future<Either<Failure, void>> submitServiceReview(
    String orderId,
    String serviceId,
    double rating,
    String? comment,
  );
  Future<Either<Failure, void>> submitRiderRating(
    String orderId,
    String riderId,
    String ratingType,
    double stars,
    String? comment,
  );
  Future<Either<Failure, CouponValidationResult>> validateCoupon(ValidateCouponParams params);
  Future<Either<Failure, String>> createPaymentIntent(
    CreatePaymentIntentParams params,
  );
}
