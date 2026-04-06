import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shaya_ai/core/providers.dart';
import 'package:shaya_ai/core/theme.dart';
import 'package:shaya_ai/shared/widgets/shaya_buttons.dart';
import 'package:shaya_ai/shared/widgets/shaya_scaffold.dart';
import 'package:shaya_ai/shared/widgets/shaya_surfaces.dart';
import 'package:shaya_ai/shared/widgets/shaya_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(appSessionControllerProvider);
    final appConfig = ref.watch(appConfigProvider);
    return ShayaScreenScaffold(
      title: 'Welcome back',
      subtitle: 'Sign in to generate songs, videos, and lyrics.',
      showGlow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (session.pendingVerificationEmail != null) ...[
            ShayaStateCard(
              title: 'Verify your email',
              message:
                  'Verification email sent to ${session.pendingVerificationEmail}. Confirm it before logging in.',
              tone: ShayaStateTone.neutral,
            ),
            const SizedBox(height: 18),
          ],
          ShayaSurfaceCard(
            showGlow: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Access your studio',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  'Pick up where you left off, manage your library, and generate your next release.',
                  style: ShayaTextStyles.metadata,
                ),
                const SizedBox(height: 20),
                ShayaTextField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'you@example.com',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.mail_outline_rounded,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),
                ShayaTextField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: 'Minimum 8 characters',
                  obscureText: true,
                  prefixIcon: Icons.lock_outline_rounded,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.go('/forgot-password'),
                    child: const Text('Forgot password?'),
                  ),
                ),
                const SizedBox(height: 8),
                PrimaryGradientButton(
                  label: 'Login',
                  isBusy: session.isBusy,
                  onPressed: _submit,
                ),
                if (appConfig.isGoogleAuthEnabled) ...[
                  const SizedBox(height: 12),
                  SecondaryOutlineButton(
                    label: 'Continue with Google',
                    icon: Icons.g_mobiledata_rounded,
                    onPressed: _googleSignIn,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          ShayaSurfaceCard(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                const Icon(Icons.nightlife_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'New here? Create an account and verify your email to unlock the full studio.',
                    style: ShayaTextStyles.body,
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/register'),
                  child: const Text('Create account'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    try {
      await ref
          .read(appSessionControllerProvider)
          .signIn(
            email: _emailController.text,
            password: _passwordController.text,
          );
      if (!mounted) {
        return;
      }
      context.go('/home');
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(error.toString());
    }
  }

  Future<void> _googleSignIn() async {
    try {
      await ref.read(appSessionControllerProvider).signInWithGoogle();
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(error.toString());
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
