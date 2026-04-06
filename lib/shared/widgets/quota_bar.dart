import 'package:flutter/material.dart';
import 'package:shaya_ai/core/theme.dart';
import 'package:shaya_ai/shared/widgets/shaya_surfaces.dart';

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
    final remainingCount = limit == null
        ? null
        : (limit! - used).clamp(0, limit!);
    final remaining = limit == null ? 'Unlimited' : '$remainingCount left';
    final accent = limit == null
        ? kCyan
        : ratio >= 0.85
        ? kDanger
        : ratio >= 0.65
        ? kWarning
        : kPurpleLight;

    return ShayaSurfaceCard(
      padding: const EdgeInsets.all(16),
      borderColor: accent.withValues(alpha: 0.16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: ShayaTextStyles.body),
              Text(
                remaining,
                style: ShayaTextStyles.metadata.copyWith(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            limit == null
                ? 'Unlimited access enabled.'
                : '$used of $limit used',
            style: ShayaTextStyles.metadata,
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 12,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: Colors.white.withValues(alpha: 0.08)),
                  FractionallySizedBox(
                    widthFactor: limit == null ? 1 : ratio,
                    alignment: Alignment.centerLeft,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            accent,
                            accent == kCyan ? kPurpleLight : kCyan,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
