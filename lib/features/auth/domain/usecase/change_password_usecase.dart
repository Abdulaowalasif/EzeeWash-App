import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/usecase.dart';
import '../repositories/auth_repository.dart';

class ChangePasswordUseCase implements UseCase<void, String> {
  final AuthRepository repository;

  ChangePasswordUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String newPassword) async {
    return await repository.changePassword(newPassword);
  }
}
