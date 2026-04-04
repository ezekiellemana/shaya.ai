class AppConfig {
  const AppConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.oauthRedirectUrl,
    required this.passwordResetRedirectUrl,
  });

  final String supabaseUrl;
  final String supabaseAnonKey;
  final String oauthRedirectUrl;
  final String passwordResetRedirectUrl;

  bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static AppConfig fromEnvironment() {
    return const AppConfig(
      supabaseUrl: String.fromEnvironment('SHAYA_SUPABASE_URL'),
      supabaseAnonKey: String.fromEnvironment('SHAYA_SUPABASE_ANON_KEY'),
      oauthRedirectUrl: String.fromEnvironment('SHAYA_OAUTH_REDIRECT_URL'),
      passwordResetRedirectUrl: String.fromEnvironment(
        'SHAYA_PASSWORD_RESET_REDIRECT_URL',
      ),
    );
  }
}
