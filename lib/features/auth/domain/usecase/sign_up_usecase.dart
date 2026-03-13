// lib/features/auth/domain/usecases/sign_up_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

// ─── Sign Up ──────────────────────────────────────────────────────────────────
// Returns UserEntity? — null means email confirmation is required.

class SignUpUseCase implements UseCase<UserEntity?, SignUpParams> {
  final AuthRepository repository;
  SignUpUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity?>> call(SignUpParams params) =>
      repository.signUpWithEmail(
        fullName: params.fullName,
        email: params.email,
        password: params.password,
      );
}

class SignUpParams extends Equatable {
  final String fullName;
  final String email;
  final String password;
  const SignUpParams({
    required this.fullName,
    required this.email,
    required this.password,
  });

  @override
  List<Object> get props => [fullName, email, password];
}
