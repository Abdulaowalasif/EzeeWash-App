// lib/features/auth/presentation/bloc/auth_bloc.dart
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/utils/usecase.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecase/current_user_usecase.dart';
import '../../domain/usecase/sign_in_usecase.dart';
import '../../domain/usecase/sign_out_usecase.dart';
import '../../domain/usecase/sign_up_usecase.dart';
part 'auth_event.dart';
part 'auth_state.dart';


class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SignInUseCase signInUseCase;
  final SignUpUseCase signUpUseCase;
  final SignOutUseCase signOutUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final AuthRepository authRepository;

  StreamSubscription<UserEntity?>? _authSub;

  // Suppresses the authStateChanges stream during email/password flows where
  // the bloc already emits AuthAuthenticated or AuthError directly. This
  // prevents a duplicate AuthAuthenticated (or a race-condition AuthError)
  // from being emitted by the stream at the same time.
  //
  // IMPORTANT: _suppressStream must remain FALSE for the Google OAuth flow.
  // Google OAuth works entirely through the stream — the datasource just opens
  // a browser and returns; it never hands us a UserEntity directly. If we
  // suppressed the stream during Google sign-in, the AuthAuthenticated state
  // would never arrive.
  bool _suppressStream = false;

  AuthBloc({
    required this.signInUseCase,
    required this.signUpUseCase,
    required this.signOutUseCase,
    required this.getCurrentUserUseCase,
    required this.authRepository,
  }) : super(const AuthInitial()) {
    on<AuthCheckRequested>(_onCheck);
    on<AuthSignInRequested>(_onSignIn);
    on<AuthSignUpRequested>(_onSignUp);
    on<AuthGoogleSignInRequested>(_onGoogle);
    on<AuthSignOutRequested>(_onSignOut);
    on<AuthStreamChanged>(_onStreamEvent);
    on<AuthForgotPasswordRequested>(_onForgotPassword);

    // Subscribe to Supabase auth state changes.
    // This handles:
    //   • Google OAuth callback  → emits AuthAuthenticated
    //   • Session restore on cold start
    //   • Token refresh
    //   • Remote/token-expiry logout
    _authSub = authRepository.authStateChanges.listen((user) {
      if (!_suppressStream) add(AuthStreamChanged(user));
    });
  }

  // ─── Handlers ──────────────────────────────────────────────────────────────

  Future<void> _onCheck(
      AuthCheckRequested event,
      Emitter<AuthState> emit,
      ) async {
    emit(const AuthLoading());
    final res = await getCurrentUserUseCase(const NoParams());
    res.fold(
          (_) => emit(const AuthUnauthenticated()),
          (user) => user != null
          ? emit(AuthAuthenticated(user))
          : emit(const AuthUnauthenticated()),
    );
  }

  Future<void> _onSignIn(
      AuthSignInRequested event,
      Emitter<AuthState> emit,
      ) async {
    _suppressStream = true;
    emit(const AuthLoading());
    final res = await signInUseCase(
      SignInParams(email: event.email, password: event.password),
    );
    _suppressStream = false;
    res.fold(
          (f) => emit(AuthError(f.message)),
          (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> _onSignUp(
      AuthSignUpRequested event,
      Emitter<AuthState> emit,
      ) async {
    _suppressStream = true;
    emit(const AuthLoading());
    final res = await signUpUseCase(SignUpParams(
      fullName: event.fullName,
      email: event.email,
      password: event.password,
    ));
    _suppressStream = false;

    res.fold(
          (f) => emit(AuthError(f.message)),
          (user) {
        if (user != null) {
          emit(AuthAuthenticated(user, fromSignUp: true));
        } else {
          emit(AuthSignedUp(event.email));
        }
      },
    );
  }

  // FIX: Google OAuth handler.
  //
  // Previous bug: after calling signInWithGoogle() the bloc tried to use a
  // UserEntity that didn't exist yet (the browser hadn't even opened), emitting
  // AuthError("Google sign in failed") immediately.
  //
  // Correct flow:
  //   1. Emit AuthLoading so the UI shows a spinner.
  //   2. Call authRepository.signInWithGoogle() — this merely opens the system
  //      browser. It returns Either<Failure, void>, NOT a UserEntity.
  //   3. If the repository itself threw (e.g. the OAuth URL couldn't be built),
  //      emit AuthError.
  //   4. Otherwise stay in AuthLoading — do NOT emit AuthAuthenticated here.
  //   5. When the user selects their Google account and is redirected back, the
  //      Supabase SDK fires onAuthStateChange. The _authSub listener above
  //      (which is NOT suppressed for Google) dispatches AuthStreamChanged,
  //      which calls _onStreamEvent → emits AuthAuthenticated.
  //   6. The GoRouter refreshListenable picks up AuthAuthenticated and
  //      redirects to the home screen.
  Future<void> _onGoogle(
      AuthGoogleSignInRequested event,
      Emitter<AuthState> emit,
      ) async {
    // ✅ Do NOT set _suppressStream = true here.
    // The Google session arrives via the stream; suppressing it would mean
    // AuthAuthenticated is never emitted and the user stays stuck on the
    // login screen after a successful OAuth.
    emit(const AuthLoading());

    final res = await authRepository.signInWithGoogle();

    res.fold(
          (f) {
        // Only reach here if signInWithOAuth itself threw (e.g. no internet,
        // invalid OAuth config). Show the error to the user.
        emit(AuthError(f.message));
      },
          (_) {
        // ✅ Browser launched successfully. Stay in AuthLoading.
        // _authSub (stream) is not suppressed, so it will emit
        // AuthAuthenticated once the OAuth callback completes.
      },
    );
  }

  Future<void> _onForgotPassword(
      AuthForgotPasswordRequested event,
      Emitter<AuthState> emit,
      ) async {
    emit(const AuthLoading());
    final res = await authRepository.resetPassword(email: event.email);
    res.fold(
          (f) => emit(AuthError(f.message)),
          (_) => emit(const AuthPasswordResetSent()),
    );
  }

  Future<void> _onSignOut(
      AuthSignOutRequested event,
      Emitter<AuthState> emit,
      ) async {
    _suppressStream = true;
    await signOutUseCase(const NoParams());
    _suppressStream = false;
    emit(const AuthUnauthenticated());
  }

  void _onStreamEvent(
      AuthStreamChanged event,
      Emitter<AuthState> emit,
      ) {
    if (event.user != null) {
      emit(AuthAuthenticated(event.user!));
    } else if (state is AuthAuthenticated) {
      // Only go to unauthenticated if we were previously authenticated
      // (handles token expiry / remote logout), not on cold start.
      emit(const AuthUnauthenticated());
    }
  }

  @override
  Future<void> close() {
    _authSub?.cancel();
    return super.close();
  }
}