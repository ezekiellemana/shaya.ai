import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shaya_ai/core/app_exception.dart';
import 'package:shaya_ai/core/providers.dart';
import 'package:shaya_ai/core/theme.dart';
import 'package:shaya_ai/shared/widgets/shaya_buttons.dart';
import 'package:shaya_ai/shared/widgets/shaya_scaffold.dart';
import 'package:shaya_ai/shared/widgets/shaya_surfaces.dart';
import 'package:shaya_ai/shared/widgets/shaya_text_field.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _language = 'English';
  bool _notificationsEnabled = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSettings());
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(appSessionControllerProvider);

    return ShayaScreenScaffold(
      title: 'Settings',
      subtitle: 'Language, notifications, data export, and account actions.',
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShayaSurfaceCard(
                  showGlow: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ShayaSectionHeader(
                        title: 'Preferences',
                        subtitle:
                            'Tune the app language and notification behavior without affecting your saved data.',
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Language',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 10),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'English',
                            label: Text('English'),
                          ),
                          ButtonSegment(
                            value: 'Swahili',
                            label: Text('Swahili'),
                          ),
                        ],
                        selected: {_language},
                        onSelectionChanged: (selection) async {
                          setState(() => _language = selection.first);
                          await ref
                              .read(secureStoreProvider)
                              .saveAppLanguage(_language);
                        },
                      ),
                      const SizedBox(height: 18),
                      ShayaSurfaceCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        radius: 18,
                        child: SwitchListTile(
                          value: _notificationsEnabled,
                          onChanged: (value) async {
                            setState(() => _notificationsEnabled = value);
                            await ref
                                .read(secureStoreProvider)
                                .saveNotificationsEnabled(value);
                          },
                          title: const Text('Notifications'),
                          subtitle: const Text(
                            'Keep alerts for generation updates and account events.',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                ShayaSurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ShayaSectionHeader(
                        title: 'Data and account',
                        subtitle:
                            'Export your data, sign out safely, or permanently delete your account.',
                      ),
                      const SizedBox(height: 16),
                      SecondaryOutlineButton(
                        label: 'Export my data',
                        icon: Icons.ios_share_rounded,
                        onPressed: session.isBusy ? null : _exportData,
                      ),
                      const SizedBox(height: 12),
                      DangerOutlineButton(
                        label: session.isBusy
                            ? 'Deleting account...'
                            : 'Delete account',
                        onPressed: session.isBusy ? null : _deleteAccount,
                      ),
                      const SizedBox(height: 12),
                      PrimaryGradientButton(
                        label: 'Logout',
                        onPressed: session.isBusy ? null : _logout,
                        isBusy: session.isBusy,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _loadSettings() async {
    final store = ref.read(secureStoreProvider);
    _language = await store.readAppLanguage();
    _notificationsEnabled = await store.readNotificationsEnabled();
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _exportData() async {
    final data = await ref.read(profileRepositoryProvider).exportUserData();
    await SharePlus.instance.share(
      ShareParams(text: data, subject: 'Shaya AI export'),
    );
  }

  Future<void> _deleteAccount() async {
    final user = ref.read(supabaseClientProvider)?.auth.currentUser;
    if (user == null) {
      _showMessage('Please sign in again before deleting your account.');
      return;
    }

    final provider = '${user.appMetadata['provider'] ?? 'email'}'.toLowerCase();
    final request = await showDialog<_DeleteAccountRequest>(
      context: context,
      builder: (context) => _DeleteAccountDialog(
        email: user.email ?? '',
        requiresPassword: provider == 'email',
      ),
    );

    if (request == null) {
      return;
    }

    try {
      await ref
          .read(appSessionControllerProvider)
          .deleteAccount(
            confirmationText: request.confirmationText,
            password: request.password,
          );
      if (!mounted) {
        return;
      }
      _showMessage('Your account has been permanently deleted.');
      context.go('/login');
    } on AppException catch (error) {
      _showMessage(error.message);
    }
  }

  Future<void> _logout() async {
    await ref.read(appSessionControllerProvider).signOut();
    if (!mounted) {
      return;
    }
    context.go('/login');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog({
    required this.email,
    required this.requiresPassword,
  });

  final String email;
  final bool requiresPassword;

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _confirmationController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _confirmationController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: kSurfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        'Delete account',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ShayaSurfaceCard(
              padding: const EdgeInsets.all(16),
              borderColor: kDanger.withValues(alpha: 0.20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This permanently removes your profile, playlists, saved lyrics, quota history, and avatar from Shaya AI.',
                    style: ShayaTextStyles.body,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Type DELETE to confirm this action.',
                    style: ShayaTextStyles.metadata,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ShayaTextField(
              controller: _confirmationController,
              label: 'Confirmation',
              hint: 'Type DELETE',
              prefixIcon: Icons.warning_amber_rounded,
            ),
            if (widget.requiresPassword) ...[
              const SizedBox(height: 12),
              Text(
                'For ${widget.email}, enter your current password before deleting the account.',
                style: ShayaTextStyles.metadata,
              ),
              const SizedBox(height: 12),
              ShayaTextField(
                controller: _passwordController,
                label: 'Current password',
                hint: 'Required for email accounts',
                obscureText: true,
                prefixIcon: Icons.lock_outline_rounded,
              ),
            ],
            if (_errorText != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorText!,
                style: ShayaTextStyles.metadata.copyWith(color: kDanger),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: ShayaTextStyles.body.copyWith(color: kBodyText),
          ),
        ),
        TextButton(
          onPressed: _submit,
          child: Text(
            'Delete',
            style: ShayaTextStyles.body.copyWith(color: kDanger),
          ),
        ),
      ],
    );
  }

  void _submit() {
    final confirmation = _confirmationController.text.trim();
    final password = _passwordController.text.trim();

    if (confirmation != 'DELETE') {
      setState(() => _errorText = 'Type DELETE exactly to continue.');
      return;
    }

    if (widget.requiresPassword && password.isEmpty) {
      setState(() => _errorText = 'Enter your current password to continue.');
      return;
    }

    Navigator.of(context).pop(
      _DeleteAccountRequest(
        confirmationText: confirmation,
        password: password.isEmpty ? null : password,
      ),
    );
  }
}

class _DeleteAccountRequest {
  const _DeleteAccountRequest({
    required this.confirmationText,
    required this.password,
  });

  final String confirmationText;
  final String? password;
}
