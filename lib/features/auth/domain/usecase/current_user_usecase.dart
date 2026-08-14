// lib/features/auth/domain/usecases/get_current_user_usecase.dart
import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

// ─── Get Current User ─────────────────────────────────────────────────────────

class GetCurrentUserUseCase implements UseCase<UserEntity?, NoParams> {
  final AuthRepository repository;
  GetCurrentUserUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity?>> call(NoParams params) =>
      repository.getCurrentUser();
}
