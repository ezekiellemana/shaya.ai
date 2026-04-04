import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shaya_ai/core/providers.dart';
import 'package:shaya_ai/core/theme.dart';
import 'package:shaya_ai/shared/models/subscription_tier.dart';
import 'package:shaya_ai/shared/widgets/shaya_buttons.dart';
import 'package:shaya_ai/shared/widgets/shaya_scaffold.dart';

class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(subscriptionControllerProvider);
    return ShayaScreenScaffold(
      title: 'Subscription',
      subtitle: 'Choose the plan that matches your output volume and rights.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: SubscriptionTier.values.map((tier) {
                final selected = controller.selectedTier == tier;
                return Container(
                  width: 220,
                  margin: const EdgeInsets.only(right: 14),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: kSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected
                          ? kPurpleLight
                          : Colors.white.withValues(alpha: 0.08),
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (tier == SubscriptionTier.basic)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: kPrimaryPurple.withValues(alpha: 0.20),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text('POPULAR'),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        tier.label,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Songs: ${tier.songLimit?.toString() ?? 'Unlimited'}',
                      ),
                      Text(
                        'Videos: ${tier.videoLimit?.toString() ?? 'Unlimited'}',
                      ),
                      Text(
                        'Lyrics: ${tier.lyricsLimit?.toString() ?? 'Unlimited'}',
                      ),
                      Text(
                        'MP3 downloads: ${tier.canDownloadMp3 ? 'Yes' : 'No'}',
                      ),
                      Text(
                        'MP4 downloads: ${tier.canDownloadMp4 ? 'Yes' : 'No'}',
                      ),
                      Text(
                        'Commercial rights: ${tier.hasCommercialRights ? 'Yes' : 'No'}',
                      ),
                      const SizedBox(height: 16),
                      SecondaryOutlineButton(
                        label: selected ? 'Selected' : 'Choose plan',
                        onPressed: () => ref
                            .read(subscriptionControllerProvider)
                            .selectTier(tier),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 18),
          PrimaryGradientButton(
            label: 'Continue to payment',
            onPressed: () => context.push('/payment'),
          ),
        ],
      ),
    );
  }
}
