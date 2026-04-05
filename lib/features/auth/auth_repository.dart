import 'package:shaya_ai/core/app_config.dart';
import 'package:shaya_ai/core/app_exception.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  AuthRepository({required SupabaseClient? client, required AppConfig config})
    : _client = client,
      _config = config;

  final SupabaseClient? _client;
  final AppConfig _config;

  Session? get currentSession => _client?.auth.currentSession;

  Stream<AuthState> get authStateChanges =>
      _client?.auth.onAuthStateChange ?? Stream<AuthState>.empty();

  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    return _clientOrThrow.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<AuthResponse> signUp({
    required String displayName,
    required String email,
    required String password,
  }) async {
    return _clientOrThrow.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'display_name': displayName.trim()},
      emailRedirectTo: _config.oauthRedirectUrl.isEmpty
          ? null
          : _config.oauthRedirectUrl,
    );
  }

  Future<void> signInWithGoogle() {
    if (!_config.isGoogleAuthEnabled) {
      throw AppException.configuration(
        'Google Sign-In is not enabled for this build yet.',
      );
    }
    return _clientOrThrow.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: _config.oauthRedirectUrl.isEmpty
          ? null
          : _config.oauthRedirectUrl,
    );
  }

  Future<void> requestPasswordReset(String email) {
    return _clientOrThrow.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: _config.passwordResetRedirectUrl.isEmpty
          ? null
          : _config.passwordResetRedirectUrl,
    );
  }

  Future<void> signOut() =>
      _clientOrThrow.auth.signOut(scope: SignOutScope.global);

  SupabaseClient get _clientOrThrow {
    final client = _client;
    if (client == null) {
      throw AppException.configuration(
        'Supabase is not configured. Provide SHAYA_SUPABASE_URL and SHAYA_SUPABASE_ANON_KEY.',
      );
    }
    return client;
  }
}
