// lib/features/auth/data/repositories/auth_repository_impl.dart
import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  AuthRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, UserEntity>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final user = await remoteDataSource.signInWithEmail(
        email: email,
        password: password,
      );
      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  // Returns Right(UserEntity) when session was created immediately.
  // Returns Right(null) when email confirmation is required.
  @override
  Future<Either<Failure, UserEntity?>> signUpWithEmail({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      final user = await remoteDataSource.signUpWithEmail(
        fullName: fullName,
        email: email,
        password: password,
      );
      return Right(user); // null is valid here — means "confirm your email"
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  // FIX: signInWithGoogle now returns Either<Failure, void>.
  //
  // The datasource just opens the OAuth browser flow and returns — no session
  // exists at this moment. The session will arrive via the deep-link callback
  // and be broadcast through authStateChanges. Returning void here prevents
  // the bloc from trying to use a non-existent UserEntity and emitting
  // AuthError("Google sign in failed") before the user has even picked an account.
  @override
  Future<Either<Failure, void>> signInWithGoogle() async {
    try {
      await remoteDataSource.signInWithGoogle();
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await remoteDataSource.signOut();
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity?>> getCurrentUser() async {
    try {
      final user = await remoteDataSource.getCurrentUser();
      return Right(user);
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> changePassword(String newPassword) async {
    try {
      await remoteDataSource.changePassword(newPassword);
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Stream<UserEntity?> get authStateChanges => remoteDataSource.authStateChanges;

  @override
  Future<Either<Failure, void>> resetPassword({required String email}) async {
    try {
      await remoteDataSource.resetPassword(email: email);
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }
}
