import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shaya_ai/core/providers.dart';
import 'package:shaya_ai/shared/widgets/shaya_buttons.dart';
import 'package:shaya_ai/shared/widgets/shaya_scaffold.dart';
import 'package:shaya_ai/shared/widgets/shaya_text_field.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(appSessionControllerProvider);
    return ShayaScreenScaffold(
      title: 'Reset your password',
      subtitle: 'We will email a single-use reset link.',
      child: Column(
        children: [
          ShayaTextField(
            controller: _emailController,
            label: 'Email',
            hint: 'you@example.com',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 20),
          PrimaryGradientButton(
            label: 'Send reset link',
            isBusy: session.isBusy,
            onPressed: _sendReset,
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.go('/login'),
            child: const Text('Back to login'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendReset() async {
    try {
      await ref
          .read(appSessionControllerProvider)
          .requestPasswordReset(_emailController.text);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent.')),
      );
      context.go('/login');
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}
