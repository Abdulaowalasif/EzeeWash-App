// lib/features/auth/bloc/auth_event.dart
part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

/// Emitted on app start to restore a persisted session.
final class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

/// Emitted when the user submits the email/password sign-in form.
final class AuthSignInRequested extends AuthEvent {
  final String email;
  final String password;
  const AuthSignInRequested({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}

/// Emitted when the user submits the registration form.
final class AuthSignUpRequested extends AuthEvent {
  final String fullName;
  final String email;
  final String password;
  const AuthSignUpRequested({
    required this.fullName,
    required this.email,
    required this.password,
  });

  @override
  List<Object> get props => [fullName, email, password];
}

/// Emitted when the user taps "Continue with Google".
final class AuthGoogleSignInRequested extends AuthEvent {
  const AuthGoogleSignInRequested();
}

/// Emitted when the user taps "Sign Out".
final class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

/// Internal — emitted by the Supabase auth stream subscription.
/// Kept private (prefixed with `_`) so screens cannot dispatch it directly.
final class AuthStreamChanged extends AuthEvent {
  final UserEntity? user;
  const AuthStreamChanged(this.user);

  @override
  List<Object?> get props => [user];
}