// lib/features/auth/bloc/auth_state.dart
part of 'auth_bloc.dart';

sealed class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

/// Before the first [AuthCheckRequested] completes.
final class AuthInitial extends AuthState {
  const AuthInitial();
}

/// An async auth operation is in progress — show a loading indicator.
final class AuthLoading extends AuthState {
  const AuthLoading();
}

/// The user is signed in. [user] holds their identity.
final class AuthAuthenticated extends AuthState {
  final UserEntity user;
  const AuthAuthenticated(this.user);

  @override
  List<Object> get props => [user];
}

/// No active session — show the login screen.
final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Signup succeeded but email confirmation is required before signing in.
/// [email] is shown in the "check your email" UI.
final class AuthSignedUp extends AuthState {
  final String email;
  const AuthSignedUp(this.email);

  @override
  List<Object> get props => [email];
}

/// An auth operation failed. [message] is safe to show in a SnackBar.
final class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);

  @override
  List<Object> get props => [message];
}