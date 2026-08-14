import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/place_orders_params.dart';
import '../../domain/usecases/orders_usecase.dart';

// ─── States ──────────────────────────────────────────────────────────────────

abstract class CheckoutState extends Equatable {
  const CheckoutState();
  @override
  List<Object?> get props => [];
}

class CheckoutInitial extends CheckoutState {
  const CheckoutInitial();
}

class CheckoutCouponValidating extends CheckoutState {
  const CheckoutCouponValidating();
}

class CheckoutCouponValidated extends CheckoutState {
  final String couponCode;
  final double discountAmount;

  const CheckoutCouponValidated({
    required this.couponCode,
    required this.discountAmount,
  });

  @override
  List<Object?> get props => [couponCode, discountAmount];
}

class CheckoutCouponError extends CheckoutState {
  final String message;
  const CheckoutCouponError(this.message);
  @override
  List<Object?> get props => [message];
}

class CheckoutPaymentIntentCreating extends CheckoutState {
  const CheckoutPaymentIntentCreating();
}

class CheckoutPaymentIntentCreated extends CheckoutState {
  final String clientSecret;
  const CheckoutPaymentIntentCreated(this.clientSecret);
  @override
  List<Object?> get props => [clientSecret];
}

class CheckoutPaymentIntentError extends CheckoutState {
  final String message;
  const CheckoutPaymentIntentError(this.message);
  @override
  List<Object?> get props => [message];
}

// ─── Cubit ───────────────────────────────────────────────────────────────────

class CheckoutCubit extends Cubit<CheckoutState> {
  final ValidateCouponUseCase validateCouponUseCase;
  final CreatePaymentIntentUseCase createPaymentIntentUseCase;

  CheckoutCubit({
    required this.validateCouponUseCase,
    required this.createPaymentIntentUseCase,
  }) : super(const CheckoutInitial());

  Future<void> validateCoupon(ValidateCouponParams params) async {
    emit(const CheckoutCouponValidating());
    final result = await validateCouponUseCase(params);
    result.fold(
      (failure) => emit(CheckoutCouponError(failure.message)),
      (discount) => emit(
        CheckoutCouponValidated(
          couponCode: params.code,
          discountAmount: discount,
        ),
      ),
    );
  }

  void resetCoupon() {
    emit(const CheckoutInitial());
  }

  Future<void> createPaymentIntent(CreatePaymentIntentParams params) async {
    emit(const CheckoutPaymentIntentCreating());
    final result = await createPaymentIntentUseCase(params);
    result.fold(
      (failure) => emit(CheckoutPaymentIntentError(failure.message)),
      (clientSecret) => emit(CheckoutPaymentIntentCreated(clientSecret)),
    );
  }
}
