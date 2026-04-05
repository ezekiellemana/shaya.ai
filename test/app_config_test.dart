import 'package:flutter_test/flutter_test.dart';
import 'package:shaya_ai/core/app_config.dart';

void main() {
  test('Google auth stays disabled until explicitly enabled', () {
    const config = AppConfig(
      supabaseUrl: 'https://example.supabase.co',
      supabaseAnonKey: 'anon-key',
      oauthRedirectUrl: 'shayaai://auth-callback',
      passwordResetRedirectUrl: 'shayaai://auth-callback/reset',
      googleAuthEnabled: false,
    );

    expect(config.isGoogleAuthEnabled, isFalse);
  });

  test('Google auth needs both the flag and redirect URL', () {
    const enabledConfig = AppConfig(
      supabaseUrl: 'https://example.supabase.co',
      supabaseAnonKey: 'anon-key',
      oauthRedirectUrl: 'shayaai://auth-callback',
      passwordResetRedirectUrl: 'shayaai://auth-callback/reset',
      googleAuthEnabled: true,
    );
    const missingRedirectConfig = AppConfig(
      supabaseUrl: 'https://example.supabase.co',
      supabaseAnonKey: 'anon-key',
      oauthRedirectUrl: '',
      passwordResetRedirectUrl: 'shayaai://auth-callback/reset',
      googleAuthEnabled: true,
    );

    expect(enabledConfig.isGoogleAuthEnabled, isTrue);
    expect(missingRedirectConfig.isGoogleAuthEnabled, isFalse);
  });
}
