import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/usecase.dart';
import '../entities/promo_entity.dart';
import '../repositories/promo_repository.dart';

class GetPromosUseCase implements UseCase<List<PromoEntity>, GetPromosParams> {
  final PromoRepository repository;
  GetPromosUseCase(this.repository);

  @override
  Future<Either<Failure, List<PromoEntity>>> call(GetPromosParams params) {
    return repository.getPromos(forceRefresh: params.forceRefresh);
  }
}

class GetPromosParams extends Equatable {
  final bool forceRefresh;
  const GetPromosParams({this.forceRefresh = false});
  @override
  List<Object> get props => [forceRefresh];
}
