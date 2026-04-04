import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shaya_ai/core/providers.dart';
import 'package:shaya_ai/shared/widgets/shaya_buttons.dart';
import 'package:shaya_ai/shared/widgets/shaya_scaffold.dart';
import 'package:shaya_ai/shared/widgets/shaya_text_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(appSessionControllerProvider);
    return ShayaScreenScaffold(
      title: 'Create your studio',
      subtitle: 'Register with email, verify your address, and start building.',
      showGlow: true,
      child: Column(
        children: [
          ShayaTextField(
            controller: _nameController,
            label: 'Display name',
            hint: 'Dodoma Creative',
          ),
          const SizedBox(height: 14),
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
          const SizedBox(height: 20),
          PrimaryGradientButton(
            label: 'Register',
            isBusy: session.isBusy,
            onPressed: _register,
          ),
          const SizedBox(height: 18),
          TextButton(
            onPressed: () => context.go('/login'),
            child: const Text('Already have an account? Login'),
          ),
        ],
      ),
    );
  }

  Future<void> _register() async {
    try {
      await ref
          .read(appSessionControllerProvider)
          .signUp(
            displayName: _nameController.text,
            email: _emailController.text,
            password: _passwordController.text,
          );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Account created. Check your email to verify your account.',
          ),
        ),
      );
      context.go('/login');
    } catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}
