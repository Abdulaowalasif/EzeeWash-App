// lib/features/auth/data/datasources/auth_remote_datasource.dart
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  });

  Future<UserModel?> signUpWithEmail({
    required String fullName,
    required String email,
    required String password,
  });

  Future<void> signInWithGoogle();

  Future<void> signOut();

  Future<UserModel?> getCurrentUser();

  Stream<UserModel?> get authStateChanges;

  Future<void> resetPassword({required String email});

  Future<void> changePassword(String newPassword);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final supa.SupabaseClient _client;

  AuthRemoteDataSourceImpl(this._client);

  // ─── Sign in ───────────────────────────────────────────────────────────────

  @override
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (res.user == null) throw AuthException('Sign in failed.');
      return await _loadOrCreateProfile(res.user!);
    } on supa.AuthApiException catch (e) {
      throw AuthException(_friendly(e.message));
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(_friendly(e.toString()));
    }
  }

  // ─── Sign up ───────────────────────────────────────────────────────────────

  @override
  Future<UserModel?> signUpWithEmail({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      final res = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );

      if (res.user == null) {
        throw AuthException('Registration failed. Please try again.');
      }

      if (res.session == null) return null;

      return await _fetchProfileOnly(res.user!, fallbackName: fullName);
    } on supa.AuthApiException catch (e) {
      throw AuthException(_friendly(e.message));
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(_friendly(e.toString()));
    }
  }

  // ─── Google ────────────────────────────────────────────────────────────────
  //
  // FIX: signInWithOAuth() just opens the system browser and returns
  // immediately — the Supabase session does NOT exist at this point.
  // Reading _client.auth.currentUser right after the call always returns
  // null, which previously caused an AuthException to be emitted ("Google
  // sign in failed") before the user even picked an account.
  //
  // The correct pattern is:
  //   1. Call signInWithOAuth — opens browser, returns void/future.
  //   2. Return normally (no user object).
  //   3. Let the authStateChanges stream (in AuthBloc) fire once Supabase
  //      processes the OAuth callback and creates the session.
  //
  // The return type is now Future<void> — the caller must NOT expect a
  // UserModel here. Auth state is propagated via the stream only.

  @override
  Future<void> signInWithGoogle() async {
    try {
      final webClientId = AppConstants.googleWebClientId;
      final iosClientId = AppConstants.googleIosClientId;

      if (webClientId.isEmpty ||
          webClientId == 'YOUR_WEB_CLIENT_ID_HERE') {
        throw AuthException(
          'Google Web Client ID is missing. Please update your .env file with a valid Client ID.',
        );
      }

      final googleSignIn = GoogleSignIn.instance;

      // Initialize Google Sign-In
      await googleSignIn.initialize(
        serverClientId: webClientId,
        clientId: Platform.isIOS &&
            iosClientId.isNotEmpty &&
            iosClientId != 'YOUR_IOS_CLIENT_ID_HERE'
            ? iosClientId
            : null,
      );

      // Authenticate the user
      final GoogleSignInAccount googleUser =
      await googleSignIn.authenticate();

      final GoogleSignInAuthentication googleAuth =
          googleUser.authentication;

      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw AuthException('No ID Token returned from Google Sign-In.');
      }

      await _client.auth.signInWithIdToken(
        provider: supa.OAuthProvider.google,
        idToken: idToken,
      );

      // Do NOT read currentUser here.
      // Listen to _client.auth.onAuthStateChange instead.
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        // User cancelled sign-in.
        return;
      }

      throw AuthException(
        e.description ?? 'Google Sign-In failed.',
      );
    } on supa.AuthApiException catch (e) {
      throw AuthException(_friendly(e.message));
    } catch (e, stackTrace) {
      debugPrint('Google Sign-In Error: $e');
      debugPrintStack(stackTrace: stackTrace);
      throw AuthException(e.toString());
    }
  }

  // ─── Reset password ────────────────────────────────────────────

  @override
  Future<void> resetPassword({required String email}) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } on supa.AuthApiException catch (e) {
      throw AuthException(_friendly(e.message));
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  // ─── Sign out ──────────────────────────────────────────────────────────────

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  // ─── Current user ──────────────────────────────────────────────────────────

  @override
  Future<UserModel?> getCurrentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    try {
      return await _loadOrCreateProfile(user);
    } catch (_) {
      return UserModel(
        id: user.id,
        email: user.email,
        fullName: user.userMetadata?['full_name'] as String?,
      );
    }
  }

  // ─── Change password ───────────────────────────────────────────────────────
  @override
  Future<void> changePassword(String newPassword) async {
    try {
      await _client.auth.updateUser(supa.UserAttributes(password: newPassword));
    } on supa.AuthApiException catch (e) {
      throw AuthException(_friendly(e.message));
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  // ─── Auth state stream ─────────────────────────────────────────────────────

  @override
  Stream<UserModel?> get authStateChanges =>
      _client.auth.onAuthStateChange.asyncMap((event) async {
        final authUser = event.session?.user;
        if (authUser == null) return null;
        try {
          return await _loadOrCreateProfile(authUser);
        } catch (_) {
          return UserModel(
            id: authUser.id,
            email: authUser.email,
            fullName: authUser.userMetadata?['full_name'] as String?,
          );
        }
      });

  // ─── Private helpers ───────────────────────────────────────────────────────

  Future<UserModel> _fetchProfileOnly(
    supa.User authUser, {
    String? fallbackName,
  }) async {
    final row1 = await _safeSelect(authUser.id);
    if (row1 != null) return UserModel.fromJson(row1);

    await Future.delayed(const Duration(milliseconds: 500));

    final row2 = await _safeSelect(authUser.id);
    if (row2 != null) return UserModel.fromJson(row2);

    return UserModel(
      id: authUser.id,
      email: authUser.email,
      fullName:
          fallbackName ??
          (authUser.userMetadata?['full_name'] as String?) ??
          authUser.email?.split('@').first,
    );
  }

  Future<UserModel> _loadOrCreateProfile(supa.User authUser) async {
    final existing = await _safeSelect(authUser.id);
    if (existing != null) return UserModel.fromJson(existing);

    try {
      await _client.from(AppConstants.profilesTable).upsert({
        'id': authUser.id,
        'email': authUser.email,
        'full_name':
            authUser.userMetadata?['full_name'] as String? ??
            authUser.email?.split('@').first,
      }, onConflict: 'id');
    } catch (_) {}

    final afterUpsert = await _safeSelect(authUser.id);
    if (afterUpsert != null) return UserModel.fromJson(afterUpsert);

    return UserModel(
      id: authUser.id,
      email: authUser.email,
      fullName: authUser.userMetadata?['full_name'] as String?,
    );
  }

  Future<Map<String, dynamic>?> _safeSelect(String userId) async {
    try {
      final rows = await _client
          .from(AppConstants.profilesTable)
          .select()
          .eq('id', userId)
          .limit(1);

      if ((rows as List).isEmpty) return null;
      return rows.first;
    } catch (_) {
      return null;
    }
  }

  // ─── User-friendly error messages ──────────────────────────────────────────

  String _friendly(String msg) {
    final m = msg.toLowerCase();
    if (m.contains('invalid login credentials') ||
        m.contains('invalid login')) {
      return 'Incorrect email or password.';
    }
    if (m.contains('email not confirmed')) {
      return 'Please confirm your email first, then sign in.';
    }
    if (m.contains('user already registered') ||
        m.contains('already been registered')) {
      return 'This email is already registered. Please sign in.';
    }
    if (m.contains('password should be at least')) {
      return 'Password must be at least 6 characters.';
    }
    if (m.contains('rate limit') || m.contains('too many requests')) {
      return 'Too many attempts. Please wait a moment.';
    }
    if (m.contains('network') || m.contains('socket')) {
      return 'Network error. Check your internet connection.';
    }
    return msg;
  }
}
