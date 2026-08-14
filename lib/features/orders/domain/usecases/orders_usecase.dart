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
  Future<Either<Failure, List<OrderEntity>>> call(NoParams params) {
    return repository.getOrders();
  }
}

class WatchOrdersUseCase {
  final OrdersRepository repository;
  WatchOrdersUseCase(this.repository);

  Stream<List<Map<String, dynamic>>> call(String userId) {
    return repository.watchOrders(userId);
  }
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

// ─── Cancel Order ─────────────────────────────────────────────────────────────

class CancelOrderUseCase implements UseCase<void, CancelOrderParams> {
  final OrdersRepository repository;
  CancelOrderUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(CancelOrderParams params) =>
      repository.cancelOrder(params.orderId);
}

class CancelOrderParams extends Equatable {
  final String orderId;
  const CancelOrderParams(this.orderId);
  @override
  List<Object> get props => [orderId];
}

// ─── Submit Service Review ────────────────────────────────────────────────────

class SubmitServiceReviewUseCase
    implements UseCase<void, SubmitServiceReviewParams> {
  final OrdersRepository repository;
  SubmitServiceReviewUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(SubmitServiceReviewParams params) =>
      repository.submitServiceReview(
        params.orderId,
        params.serviceId,
        params.rating,
        params.comment,
      );
}

class SubmitServiceReviewParams extends Equatable {
  final String orderId;
  final String serviceId;
  final double rating;
  final String? comment;

  const SubmitServiceReviewParams({
    required this.orderId,
    required this.serviceId,
    required this.rating,
    this.comment,
  });

  @override
  List<Object?> get props => [orderId, serviceId, rating, comment];
}

// ─── Submit Rider Rating ──────────────────────────────────────────────────────

class SubmitRiderRatingUseCase
    implements UseCase<void, SubmitRiderRatingParams> {
  final OrdersRepository repository;
  SubmitRiderRatingUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(SubmitRiderRatingParams params) =>
      repository.submitRiderRating(
        params.orderId,
        params.riderId,
        params.ratingType,
        params.stars,
        params.comment,
      );
}

class SubmitRiderRatingParams extends Equatable {
  final String orderId;
  final String riderId;
  final String ratingType;
  final double stars;
  final String? comment;

  const SubmitRiderRatingParams({
    required this.orderId,
    required this.riderId,
    required this.ratingType,
    required this.stars,
    this.comment,
  });

  @override
  List<Object?> get props => [orderId, riderId, ratingType, stars, comment];
}

// ─── Validate Coupon ──────────────────────────────────────────────────────────

class ValidateCouponUseCase implements UseCase<double, ValidateCouponParams> {
  final OrdersRepository repository;
  ValidateCouponUseCase(this.repository);

  @override
  Future<Either<Failure, double>> call(ValidateCouponParams params) =>
      repository.validateCoupon(params);
}

// ─── Create Payment Intent ────────────────────────────────────────────────────

class CreatePaymentIntentUseCase
    implements UseCase<String, CreatePaymentIntentParams> {
  final OrdersRepository repository;
  CreatePaymentIntentUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(CreatePaymentIntentParams params) =>
      repository.createPaymentIntent(params);
}
