import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shaya_ai/core/app_constants.dart';
import 'package:shaya_ai/core/providers.dart';
import 'package:shaya_ai/core/theme.dart';
import 'package:shaya_ai/shared/models/subscription_tier.dart';
import 'package:shaya_ai/shared/widgets/quota_bar.dart';
import 'package:shaya_ai/shared/widgets/shaya_buttons.dart';
import 'package:shaya_ai/shared/widgets/shaya_chip.dart';
import 'package:shaya_ai/shared/widgets/shaya_scaffold.dart';
import 'package:shaya_ai/shared/widgets/shaya_text_field.dart';

class GenerateMusicScreen extends ConsumerStatefulWidget {
  const GenerateMusicScreen({super.key});

  @override
  ConsumerState<GenerateMusicScreen> createState() =>
      _GenerateMusicScreenState();
}

class _GenerateMusicScreenState extends ConsumerState<GenerateMusicScreen> {
  final TextEditingController _promptController = TextEditingController();
  final TextEditingController _customTagsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(generateMusicControllerProvider).refreshQuota();
    });
  }

  @override
  void dispose() {
    _promptController.dispose();
    _customTagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(generateMusicControllerProvider);
    final profile = ref.watch(currentUserProfileProvider).value;
    final tier = profile?.subscriptionTier ?? SubscriptionTier.free;
    final quota = controller.quota ?? ref.watch(currentQuotaProvider).value;

    return ShayaScreenScaffold(
      title: 'Generate Music',
      subtitle: 'Write a prompt in English or Swahili and shape it with tags.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (quota != null) ...[
            QuotaBar(
              label: 'Songs this month',
              used: quota.songsGenerated,
              limit: tier.songLimit,
            ),
            const SizedBox(height: 18),
          ],
          ShayaTextField(
            controller: _promptController,
            label: 'Prompt',
            hint:
                'Example: Inspirational Bongo Flava anthem for sunrise in Dodoma',
            maxLines: 5,
          ),
          const SizedBox(height: 18),
          Text('Style tags', style: ShayaTextStyles.title),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppConstants.genreTags.map((tag) {
              return ShayaChip(
                label: tag,
                selected: controller.selectedTags.contains(tag),
                onTap: () =>
                    ref.read(generateMusicControllerProvider).toggleTag(tag),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          ShayaTextField(
            controller: _customTagsController,
            label: 'Custom tags',
            hint: 'Comma-separated tags',
          ),
          const SizedBox(height: 18),
          if (controller.errorMessage != null) ...[
            Text(
              controller.errorMessage!,
              style: ShayaTextStyles.body.copyWith(color: kDanger),
            ),
            const SizedBox(height: 10),
          ],
          PrimaryGradientButton(
            label: 'Generate',
            icon: Icons.auto_awesome_rounded,
            isBusy: controller.isBusy,
            onPressed: _submit,
          ),
          const SizedBox(height: 12),
          SecondaryOutlineButton(
            label: 'Generate video from library song',
            icon: Icons.video_call_rounded,
            onPressed: () => context.push('/generate/video'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(generateMusicControllerProvider)
          .submit(
            prompt: _promptController.text,
            extraTags: _customTagsController.text
                .split(',')
                .map((tag) => tag.trim())
                .where((tag) => tag.isNotEmpty)
                .toList(),
          );
      if (!mounted) {
        return;
      }
      await router.push('/player');
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}
