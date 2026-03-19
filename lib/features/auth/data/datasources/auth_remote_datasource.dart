// lib/features/auth/data/datasources/auth_remote_datasource.dart
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> signInWithEmail(
      {required String email, required String password});
  Future<UserModel?> signUpWithEmail(
      {required String fullName,
        required String email,
        required String password});
  Future<UserModel> signInWithGoogle();
  Future<void> signOut();
  Future<UserModel?> getCurrentUser();
  Stream<UserModel?> get authStateChanges;
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
  // Returns null when email confirmation is required (no session yet).
  // Returns UserModel when confirmation is disabled (session exists immediately).
  //
  // Root cause of "cannot coerce the result to a single json object":
  //   Supabase's handle_new_user trigger inserts into profiles immediately
  //   on auth.users INSERT. If the app then also calls _loadOrCreateProfile
  //   which does its own upsert, the profile table ends up with a duplicate
  //   or the select returns multiple rows — PostgREST cannot coerce that
  //   into a single object.
  //
  // Fix: after signup, if a session exists, query profiles with .limit(1)
  // instead of calling the full _loadOrCreateProfile upsert path.

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

      // Email confirmation required — no session yet, cannot touch DB via RLS.
      // The handle_new_user trigger will create the profile after confirmation.
      // Return null to signal the caller to show a "check your email" message.
      if (res.session == null) return null;

      // Session exists (email confirmation disabled in Supabase dashboard).
      // The trigger has already inserted the profile row. Just fetch it.
      // DO NOT upsert here — that would conflict with the trigger row and
      // produce the "cannot coerce to single JSON object" error.
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

  @override
  Future<UserModel> signInWithGoogle() async {
    try {
      await _client.auth.signInWithOAuth(
        supa.OAuthProvider.google,
        redirectTo: 'io.supabase.flutter://login-callback',
      );

      final user = _client.auth.currentUser;

      if (user == null) {
        throw const AuthException('Google sign in failed.');
      }

      return await _loadOrCreateProfile(user);

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

  /// Fetch profile only — does NOT upsert. Used after signup where the
  /// trigger has already created the row. Waits up to 1 second for the
  /// trigger to complete if the first fetch returns null.
  Future<UserModel> _fetchProfileOnly(
      supa.User authUser, {
        String? fallbackName,
      }) async {
    // Attempt 1 — immediate fetch
    final row1 = await _safeSelect(authUser.id);
    if (row1 != null) return UserModel.fromJson(row1);

    // The trigger may still be in-flight. Give it a moment.
    await Future.delayed(const Duration(milliseconds: 500));

    // Attempt 2 — retry
    final row2 = await _safeSelect(authUser.id);
    if (row2 != null) return UserModel.fromJson(row2);

    // Fallback — build from auth metadata (safe, no DB call)
    return UserModel(
      id: authUser.id,
      email: authUser.email,
      fullName: fallbackName ??
          (authUser.userMetadata?['full_name'] as String?) ??
          authUser.email?.split('@').first,
    );
  }

  /// Fetch + upsert path — used for sign-in and Google OAuth where we
  /// want to ensure the profile exists. NOT called after signUp().
  Future<UserModel> _loadOrCreateProfile(supa.User authUser) async {
    // 1. Try fetch first
    final existing = await _safeSelect(authUser.id);
    if (existing != null) return UserModel.fromJson(existing);

    // 2. Profile missing — upsert (session is active, RLS passes)
    try {
      await _client.from(AppConstants.profilesTable).upsert({
        'id': authUser.id,
        'email': authUser.email,
        'full_name': authUser.userMetadata?['full_name'] as String? ??
            authUser.email?.split('@').first,
      }, onConflict: 'id');
    } catch (_) {}

    // 3. Fetch after upsert
    final afterUpsert = await _safeSelect(authUser.id);
    if (afterUpsert != null) return UserModel.fromJson(afterUpsert);

    // 4. Ultimate fallback
    return UserModel(
      id: authUser.id,
      email: authUser.email,
      fullName: authUser.userMetadata?['full_name'] as String?,
    );
  }

  /// Safe single-row select — returns null instead of throwing on empty.
  /// Uses .limit(1) to avoid "cannot coerce to single JSON object" when
  /// PostgREST returns more than one row.
  Future<Map<String, dynamic>?> _safeSelect(String userId) async {
    try {
      final rows = await _client
          .from(AppConstants.profilesTable)
          .select()
          .eq('id', userId)
          .limit(1);

      if (rows == null || (rows as List).isEmpty) return null;
      return rows.first as Map<String, dynamic>;
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