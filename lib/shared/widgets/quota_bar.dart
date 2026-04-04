import 'package:flutter/material.dart';
import 'package:shaya_ai/core/theme.dart';

class QuotaBar extends StatelessWidget {
  const QuotaBar({
    super.key,
    required this.label,
    required this.used,
    required this.limit,
  });

  final String label;
  final int used;
  final int? limit;

  @override
  Widget build(BuildContext context) {
    final ratio = limit == null || limit == 0
        ? 0.0
        : (used / limit!).clamp(0.0, 1.0);
    final remaining = limit == null ? 'Unlimited' : '${limit! - used} left';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: ShayaTextStyles.body),
            Text(remaining, style: ShayaTextStyles.metadata),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 10,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(color: Colors.white.withValues(alpha: 0.08)),
                FractionallySizedBox(
                  widthFactor: limit == null ? 1 : ratio,
                  alignment: Alignment.centerLeft,
                  child: DecoratedBox(
                    decoration: const BoxDecoration(gradient: kGradAccent),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
