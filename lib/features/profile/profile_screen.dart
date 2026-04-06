import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shaya_ai/core/providers.dart';
import 'package:shaya_ai/core/theme.dart';
import 'package:shaya_ai/shared/models/user_profile.dart';
import 'package:shaya_ai/shared/widgets/async_state_view.dart';
import 'package:shaya_ai/shared/widgets/quota_bar.dart';
import 'package:shaya_ai/shared/widgets/shaya_buttons.dart';
import 'package:shaya_ai/shared/widgets/shaya_scaffold.dart';
import 'package:shaya_ai/shared/widgets/shaya_surfaces.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  bool _isUpdatingAvatar = false;
  bool _isSavingName = false;

  @override
  Widget build(BuildContext context) {
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
            return const AsyncStateView(
              title: 'Profile unavailable',
              message: 'Sign in to view your profile.',
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShayaSurfaceCard(
                showGlow: true,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProfileAvatar(
                      profile: profile,
                      busy: _isUpdatingAvatar,
                      onTap: _isUpdatingAvatar
                          ? null
                          : () => _pickAvatar(profile),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.displayName,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Creative profile',
                            style: ShayaTextStyles.metadata,
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color: kPrimaryPurple.withValues(alpha: 0.16),
                              border: Border.all(
                                color: kPrimaryPurple.withValues(alpha: 0.18),
                              ),
                            ),
                            child: Text(
                              'Plan: ${profile.subscriptionTier.label}',
                              style: ShayaTextStyles.tag.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              TextButton.icon(
                                onPressed: _isSavingName
                                    ? null
                                    : () => _renameProfile(profile.displayName),
                                icon: _isSavingName
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.edit_rounded),
                                label: const Text('Edit name'),
                              ),
                              TextButton.icon(
                                onPressed: _isUpdatingAvatar
                                    ? null
                                    : () => _pickAvatar(profile),
                                icon: _isUpdatingAvatar
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.photo_library_rounded),
                                label: const Text('Change photo'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const ShayaSectionHeader(
                title: 'Creative output',
                subtitle: 'A quick snapshot of what you have produced so far.',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _StatTile(
                    label: 'Songs',
                    value: '${stats?.songsGenerated ?? 0}',
                    icon: Icons.music_note_rounded,
                  ),
                  _StatTile(
                    label: 'Videos',
                    value: '${stats?.videosGenerated ?? 0}',
                    icon: Icons.movie_creation_outlined,
                  ),
                  _StatTile(
                    label: 'Lyrics',
                    value: '${stats?.lyricsGenerated ?? 0}',
                    icon: Icons.lyrics_rounded,
                    removeRightMargin: true,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (quota != null) ...[
                const ShayaSectionHeader(
                  title: 'Plan usage',
                  subtitle:
                      'Monthly limits refresh according to your subscription tier.',
                ),
                const SizedBox(height: 12),
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
              ShayaSurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ShayaSectionHeader(
                      title: 'Account actions',
                      subtitle: 'Manage your plan and app-level settings.',
                    ),
                    const SizedBox(height: 16),
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
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AsyncStateView(
          title: 'Profile unavailable',
          message: error.toString(),
          tone: ShayaStateTone.error,
        ),
      ),
    );
  }

  Future<void> _renameProfile(String currentName) async {
    final controller = TextEditingController(text: currentName);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Your display name'),
        ),
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

    setState(() => _isSavingName = true);
    try {
      await ref.read(profileRepositoryProvider).updateDisplayName(name.trim());
      ref.invalidate(currentUserProfileProvider);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Name updated.')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingName = false);
      }
    }
  }

  Future<void> _pickAvatar(UserProfile profile) async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
      maxWidth: 1600,
    );
    if (image == null || !mounted) {
      return;
    }

    setState(() => _isUpdatingAvatar = true);
    try {
      await ref.read(profileRepositoryProvider).uploadAvatar(image);
      ref.invalidate(currentUserProfileProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${profile.displayName} photo updated.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdatingAvatar = false);
      }
    }
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.profile,
    required this.busy,
    required this.onTap,
  });

  final UserProfile profile;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onTap,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: profile.photoUrl == null
                    ? const LinearGradient(
                        colors: [Color(0xFF7B2FBE), Color(0xFFE040FB)],
                      )
                    : null,
                color: profile.photoUrl == null
                    ? null
                    : Colors.white.withValues(alpha: 0.06),
                border: Border.all(color: kPurpleLight.withValues(alpha: 0.35)),
                boxShadow: [
                  BoxShadow(
                    color: kPrimaryPurple.withValues(alpha: 0.25),
                    blurRadius: 24,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: ClipOval(
                child: profile.photoUrl == null
                    ? const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 40,
                      )
                    : CachedNetworkImage(
                        imageUrl: profile.photoUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) => const Icon(
                          Icons.person_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                        placeholder: (_, _) => Container(
                          color: Colors.white.withValues(alpha: 0.05),
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ),
        Positioned(
          right: 0,
          bottom: -4,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black,
              border: Border.all(color: kPurpleLight.withValues(alpha: 0.7)),
            ),
            child: busy
                ? const Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.edit_rounded, size: 16, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    this.removeRightMargin = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool removeRightMargin;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.only(right: removeRightMargin ? 0 : 8),
        child: ShayaSurfaceCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: kPurpleLight, size: 20),
              const SizedBox(height: 14),
              Text(value, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text(label, style: ShayaTextStyles.metadata),
            ],
          ),
        ),
      ),
    );
  }
}
