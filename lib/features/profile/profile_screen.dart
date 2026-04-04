import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shaya_ai/core/providers.dart';
import 'package:shaya_ai/shared/widgets/quota_bar.dart';
import 'package:shaya_ai/shared/widgets/shaya_buttons.dart';
import 'package:shaya_ai/shared/widgets/shaya_scaffold.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    final statsAsync = ref.watch(currentProfileStatsProvider);
    final quotaAsync = ref.watch(currentQuotaProvider);

    return ShayaScreenScaffold(
      title: 'Profile',
      subtitle: 'Your plan, stats, and creative limits.',
      showGlow: true,
      child: profileAsync.when(
        data: (profile) {
          final stats = statsAsync.value;
          final quota = quotaAsync.value;
          if (profile == null) {
            return const Text('Sign in to view your profile.');
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF7B2FBE), Color(0xFFE040FB)],
                      ),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.displayName,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 6),
                        Text('Plan: ${profile.subscriptionTier.label}'),
                        TextButton(
                          onPressed: () =>
                              _renameProfile(context, ref, profile.displayName),
                          child: const Text('Edit name'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _StatTile(
                    label: 'Songs',
                    value: '${stats?.songsGenerated ?? 0}',
                  ),
                  _StatTile(
                    label: 'Videos',
                    value: '${stats?.videosGenerated ?? 0}',
                  ),
                  _StatTile(
                    label: 'Lyrics',
                    value: '${stats?.lyricsGenerated ?? 0}',
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (quota != null) ...[
                QuotaBar(
                  label: 'Songs',
                  used: quota.songsGenerated,
                  limit: profile.subscriptionTier.songLimit,
                ),
                const SizedBox(height: 12),
                QuotaBar(
                  label: 'Videos',
                  used: quota.videosGenerated,
                  limit: profile.subscriptionTier.videoLimit,
                ),
                const SizedBox(height: 12),
                QuotaBar(
                  label: 'Lyrics',
                  used: quota.lyricsGenerated,
                  limit: profile.subscriptionTier.lyricsLimit,
                ),
                const SizedBox(height: 18),
              ],
              PrimaryGradientButton(
                label: 'Upgrade plan',
                onPressed: () => context.push('/subscription'),
              ),
              const SizedBox(height: 10),
              SecondaryOutlineButton(
                label: 'Settings',
                icon: Icons.settings_rounded,
                onPressed: () => context.push('/settings'),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Text(error.toString()),
      ),
    );
  }

  Future<void> _renameProfile(
    BuildContext context,
    WidgetRef ref,
    String currentName,
  ) async {
    final controller = TextEditingController(text: currentName);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit name'),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.trim().isEmpty) {
      return;
    }
    await ref.read(profileRepositoryProvider).updateDisplayName(name.trim());
    ref.invalidate(currentUserProfileProvider);
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 6),
            Text(label),
          ],
        ),
      ),
    );
  }
}
