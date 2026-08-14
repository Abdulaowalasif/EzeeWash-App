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

final class AuthAuthenticated extends AuthState {
  final UserEntity user;
  final bool fromSignUp;
  const AuthAuthenticated(this.user, {this.fromSignUp = false});

  @override
  List<Object> get props => [user, fromSignUp];
}

/// No active session — show the login screen.
final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

final class AuthSignedUp extends AuthState {
  final String email;
  const AuthSignedUp(this.email);

  @override
  List<Object> get props => [email];
}

class AuthPasswordChanged extends AuthState {
  const AuthPasswordChanged();
}

final class AuthPasswordResetSent extends AuthState {
  const AuthPasswordResetSent();
}

final class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);

  @override
  List<Object> get props => [message];
}
