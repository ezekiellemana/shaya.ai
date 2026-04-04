import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shaya_ai/core/providers.dart';
import 'package:shaya_ai/shared/widgets/shaya_buttons.dart';
import 'package:shaya_ai/shared/widgets/shaya_scaffold.dart';

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
    return ShayaScreenScaffold(
      title: 'Settings',
      subtitle: 'Language, notifications, data export, and account actions.',
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Language',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'English', label: Text('English')),
                    ButtonSegment(value: 'Swahili', label: Text('Swahili')),
                  ],
                  selected: {_language},
                  onSelectionChanged: (selection) async {
                    setState(() => _language = selection.first);
                    await ref
                        .read(secureStoreProvider)
                        .saveAppLanguage(_language);
                  },
                ),
                const SizedBox(height: 20),
                SwitchListTile(
                  value: _notificationsEnabled,
                  onChanged: (value) async {
                    setState(() => _notificationsEnabled = value);
                    await ref
                        .read(secureStoreProvider)
                        .saveNotificationsEnabled(value);
                  },
                  title: const Text('Notifications'),
                ),
                const SizedBox(height: 20),
                SecondaryOutlineButton(
                  label: 'Export my data',
                  icon: Icons.ios_share_rounded,
                  onPressed: _exportData,
                ),
                const SizedBox(height: 12),
                DangerOutlineButton(
                  label: 'Delete account',
                  onPressed: _deleteAccount,
                ),
                const SizedBox(height: 12),
                PrimaryGradientButton(label: 'Logout', onPressed: _logout),
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Delete account requires an admin-backed flow and is left as a protected follow-up.',
        ),
      ),
    );
  }

  Future<void> _logout() async {
    await ref.read(appSessionControllerProvider).signOut();
    if (!mounted) {
      return;
    }
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}
