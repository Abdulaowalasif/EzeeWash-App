// lib/features/orders/domain/usecases/orders_usecases.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/usecase.dart';
import '../entities/order_entity.dart';
import '../entities/place_orders_params.dart';
import '../repositories/orders_repository.dart';

// ─── Get All Orders ───────────────────────────────────────────────────────────

class GetOrdersUseCase implements UseCase<List<OrderEntity>, NoParams> {
  final OrdersRepository repository;
  GetOrdersUseCase(this.repository);

  @override
  Future<Either<Failure, List<OrderEntity>>> call(NoParams params) =>
      repository.getOrders();
}

// ─── Get Single Order ─────────────────────────────────────────────────────────

class GetOrderByIdUseCase implements UseCase<OrderEntity, OrderIdParams> {
  final OrdersRepository repository;
  GetOrderByIdUseCase(this.repository);

  @override
  Future<Either<Failure, OrderEntity>> call(OrderIdParams params) =>
      repository.getOrderById(params.orderId);
}

class OrderIdParams extends Equatable {
  final String orderId;
  const OrderIdParams(this.orderId);
  @override
  List<Object> get props => [orderId];
}

// ─── Place Order ──────────────────────────────────────────────────────────────

class PlaceOrderUseCase implements UseCase<OrderEntity, PlaceOrderParams> {
  final OrdersRepository repository;
  PlaceOrderUseCase(this.repository);

  @override
  Future<Either<Failure, OrderEntity>> call(PlaceOrderParams params) =>
      repository.placeOrder(params);
}