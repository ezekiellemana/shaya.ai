import 'package:flutter/material.dart';
import 'package:shaya_ai/shared/widgets/shaya_surfaces.dart';

class AsyncStateView extends StatelessWidget {
  const AsyncStateView({
    super.key,
    required this.message,
    this.title,
    this.actionLabel,
    this.onAction,
    this.icon,
    this.tone = ShayaStateTone.neutral,
    this.artworkVariant = ShayaArtworkVariant.generic,
  });

  final String message;
  final String? title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? icon;
  final ShayaStateTone tone;
  final ShayaArtworkVariant artworkVariant;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: ShayaStateCard(
          title: title,
          message: message,
          actionLabel: actionLabel,
          onAction: onAction,
          icon: icon,
          tone: tone,
          artworkVariant: artworkVariant,
        ),
      ),
    );
  }
}
