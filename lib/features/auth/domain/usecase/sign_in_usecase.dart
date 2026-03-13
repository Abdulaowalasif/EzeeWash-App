// lib/features/auth/domain/usecases/sign_in_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

// ─── Sign In ──────────────────────────────────────────────────────────────────

class SignInUseCase implements UseCase<UserEntity, SignInParams> {
  final AuthRepository repository;
  SignInUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(SignInParams params) =>
      repository.signInWithEmail(
          email: params.email, password: params.password);
}

class SignInParams extends Equatable {
  final String email;
  final String password;
  const SignInParams({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}



