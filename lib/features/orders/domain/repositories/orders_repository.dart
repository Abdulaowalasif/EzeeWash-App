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
}