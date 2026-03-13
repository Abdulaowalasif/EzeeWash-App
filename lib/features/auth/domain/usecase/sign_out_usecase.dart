// lib/features/auth/domain/usecases/sign_out_usecase.dart
import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/usecase.dart';
import '../repositories/auth_repository.dart';


// ─── Sign Out ─────────────────────────────────────────────────────────────────

class SignOutUseCase implements UseCase<void, NoParams> {
  final AuthRepository repository;
  SignOutUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) => repository.signOut();
}