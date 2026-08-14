// lib/features/orders/data/repositories/orders_repository_impl.dart
import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/entities/place_orders_params.dart';
import '../../domain/repositories/orders_repository.dart';
import '../datasources/orders_remote_datasource.dart';

class OrdersRepositoryImpl implements OrdersRepository {
  final OrdersRemoteDataSource remoteDataSource;
  final SupabaseClient client;

  OrdersRepositoryImpl({required this.remoteDataSource, required this.client});

  @override
  Future<Either<Failure, List<OrderEntity>>> getOrders() async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return const Right([]);
    try {
      final orders = await remoteDataSource.getOrders(userId);
      return Right(orders);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, OrderEntity>> getOrderById(String orderId) async {
    try {
      final order = await remoteDataSource.getOrderById(orderId);
      return Right(order);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, OrderEntity>> placeOrder(
    PlaceOrderParams params,
  ) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return const Left(AuthFailure('Not authenticated'));
    try {
      final order = await remoteDataSource.placeOrder(userId, params);
      await remoteDataSource.insertTimelines(order.id);
      return Right(order);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> cancelOrder(String orderId) async {
    try {
      await remoteDataSource.cancelOrder(orderId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Stream<List<Map<String, dynamic>>> watchOrders(String userId) =>
      remoteDataSource.watchOrders(userId);

  @override
  Stream<Map<String, dynamic>?> watchRider(String riderId) =>
      remoteDataSource.watchRider(riderId);

  @override
  Future<Either<Failure, void>> submitServiceReview(
    String orderId,
    String serviceId,
    double rating,
    String? comment,
  ) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return const Left(AuthFailure('Not authenticated'));
    try {
      await remoteDataSource.submitServiceReview(
        orderId,
        serviceId,
        userId,
        rating,
        comment,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> submitRiderRating(
    String orderId,
    String riderId,
    String ratingType,
    double stars,
    String? comment,
  ) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return const Left(AuthFailure('Not authenticated'));
    try {
      await remoteDataSource.submitRiderRating(
        orderId,
        riderId,
        userId,
        ratingType,
        stars,
        comment,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, double>> validateCoupon(
    ValidateCouponParams params,
  ) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return const Left(AuthFailure('Not authenticated'));
    try {
      final discount = await remoteDataSource.validateCoupon(userId, params);
      return Right(discount);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> createPaymentIntent(
    CreatePaymentIntentParams params,
  ) async {
    try {
      final clientSecret = await remoteDataSource.createPaymentIntent(params);
      return Right(clientSecret);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }
}
