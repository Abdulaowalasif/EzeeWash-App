// lib/features/auth/domain/repositories/auth_repository.dart
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> signInWithEmail({
    required String email,
    required String password,
  });

  /// Returns a [UserEntity] when signup succeeded and a session was created
  /// immediately (email confirmation is disabled in Supabase).
  ///
  /// Returns null when Supabase requires email confirmation — the user must
  /// click the link in their inbox before they can sign in.
  Future<Either<Failure, UserEntity?>> signUpWithEmail({
    required String fullName,
    required String email,
    required String password,
  });

  // FIX: Return type changed from Future<Either<Failure, UserEntity>> to
  // Future<Either<Failure, void>>.
  //
  // signInWithOAuth (Google) only LAUNCHES the browser — it does not return
  // a session. The session arrives asynchronously via the deep-link callback
  // and is surfaced through the authStateChanges stream.
  // Returning a UserEntity here was impossible without reading currentUser
  // immediately (which was always null at that point, causing the AuthException).
  Future<Either<Failure, void>> signInWithGoogle();

  Future<Either<Failure, void>> signOut();

  Future<Either<Failure, UserEntity?>> getCurrentUser();

  Stream<UserEntity?> get authStateChanges;
}