// lib/features/auth/bloc/auth_bloc.dart
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

    // Subscribe to Supabase auth state (session restore, token refresh, logout)
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
          // Email confirmation disabled — session exists, user is logged in.
          emit(AuthAuthenticated(user));
        } else {
          // Email confirmation enabled — session is null.
          // Show the "check your email" dialog in the screen.
          emit(AuthSignedUp(event.email));
        }
      },
    );
  }

  Future<void> _onGoogle(
      AuthGoogleSignInRequested event,
      Emitter<AuthState> emit,
      ) async {
    emit(const AuthLoading());

    final res = await authRepository.signInWithGoogle();

    res.fold(
          (f) => emit(AuthError(f.message)),
          (_) {
        // Do nothing
        // Supabase authStateChanges stream will emit the authenticated user
      },
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