import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shaya_ai/core/providers.dart';
import 'package:shaya_ai/core/theme.dart';
import 'package:shaya_ai/shared/models/subscription_tier.dart';
import 'package:shaya_ai/shared/widgets/shaya_buttons.dart';
import 'package:shaya_ai/shared/widgets/shaya_scaffold.dart';
import 'package:shaya_ai/shared/widgets/shaya_surfaces.dart';

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
          const ShayaSurfaceCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.workspace_premium_rounded, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Upgrade only when it adds real value to your workflow. Your selection flow stays the same.',
                    style: ShayaTextStyles.body,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: SubscriptionTier.values.map((tier) {
                final selected = controller.selectedTier == tier;
                final highlight = switch (tier) {
                  SubscriptionTier.free => kSurface,
                  SubscriptionTier.basic => kPrimaryPurple,
                  SubscriptionTier.pro => kCyan,
                };
                return SizedBox(
                  width: 272,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: ShayaSurfaceCard(
                      showGlow: selected,
                      borderColor: selected
                          ? highlight.withValues(alpha: 0.38)
                          : null,
                      gradient: selected
                          ? LinearGradient(
                              colors: [
                                highlight.withValues(alpha: 0.22),
                                kSurfaceDark.withValues(alpha: 0.92),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (tier == SubscriptionTier.basic)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: kPrimaryPurple.withValues(
                                      alpha: 0.20,
                                    ),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    'POPULAR',
                                    style: ShayaTextStyles.tag.copyWith(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              const Spacer(),
                              if (selected)
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: Colors.white,
                                ),
                            ],
                          ),
                          if (tier == SubscriptionTier.basic)
                            const SizedBox(height: 12),
                          Text(
                            tier.label,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(switch (tier) {
                            SubscriptionTier.free =>
                              'Best for exploring the studio and validating ideas.',
                            SubscriptionTier.basic =>
                              'Balanced output, downloads, and smoother creator workflows.',
                            SubscriptionTier.pro =>
                              'Maximum generation volume, higher-quality exports, and full rights.',
                          }, style: ShayaTextStyles.body),
                          const SizedBox(height: 18),
                          _FeatureLine(
                            'Songs',
                            tier.songLimit?.toString() ?? 'Unlimited',
                          ),
                          _FeatureLine(
                            'Videos',
                            tier.videoLimit?.toString() ?? 'Unlimited',
                          ),
                          _FeatureLine(
                            'Lyrics',
                            tier.lyricsLimit?.toString() ?? 'Unlimited',
                          ),
                          _FeatureLine(
                            'MP3 downloads',
                            tier.canDownloadMp3 ? 'Yes' : 'No',
                          ),
                          _FeatureLine(
                            'MP4 downloads',
                            tier.canDownloadMp4 ? 'Yes' : 'No',
                          ),
                          _FeatureLine(
                            'Commercial rights',
                            tier.hasCommercialRights ? 'Yes' : 'No',
                          ),
                          const SizedBox(height: 18),
                          SecondaryOutlineButton(
                            label: selected ? 'Selected' : 'Choose plan',
                            onPressed: () => ref
                                .read(subscriptionControllerProvider)
                                .selectTier(tier),
                          ),
                        ],
                      ),
                    ),
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

class _FeatureLine extends StatelessWidget {
  const _FeatureLine(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(child: Text(label, style: ShayaTextStyles.body)),
          Text(
            value,
            style: ShayaTextStyles.metadata.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
