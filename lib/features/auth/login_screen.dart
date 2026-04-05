import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shaya_ai/core/providers.dart';
import 'package:shaya_ai/core/theme.dart';
import 'package:shaya_ai/shared/widgets/shaya_buttons.dart';
import 'package:shaya_ai/shared/widgets/shaya_scaffold.dart';
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
    return ShayaScreenScaffold(
      title: 'Welcome back',
      subtitle: 'Sign in to generate songs, videos, and lyrics.',
      showGlow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (session.pendingVerificationEmail != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: kSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kPurpleLight.withValues(alpha: 0.25)),
              ),
              child: Text(
                'Verification email sent to ${session.pendingVerificationEmail}. Confirm it before logging in.',
                style: ShayaTextStyles.body,
              ),
            ),
            const SizedBox(height: 18),
          ],
          ShayaTextField(
            controller: _emailController,
            label: 'Email',
            hint: 'you@example.com',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 14),
          ShayaTextField(
            controller: _passwordController,
            label: 'Password',
            hint: 'Minimum 8 characters',
            obscureText: true,
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
          const SizedBox(height: 12),
          SecondaryOutlineButton(
            label: 'Continue with Google',
            icon: Icons.g_mobiledata_rounded,
            onPressed: _googleSignIn,
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('New here?', style: ShayaTextStyles.metadata),
              TextButton(
                onPressed: () => context.go('/register'),
                child: const Text('Create account'),
              ),
            ],
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
