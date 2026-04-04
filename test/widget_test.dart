import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shaya_ai/core/theme.dart';
import 'package:shaya_ai/shared/models/subscription_tier.dart';
import 'package:shaya_ai/shared/widgets/quota_bar.dart';

void main() {
  test('subscription tiers expose SRS limits', () {
    expect(SubscriptionTier.free.songLimit, 3);
    expect(SubscriptionTier.basic.videoLimit, 5);
    expect(SubscriptionTier.pro.canDownloadMp4, isTrue);
  });

  testWidgets('quota bar renders label and remaining usage', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: shayaTheme,
        home: const Scaffold(
          body: QuotaBar(label: 'Songs this month', used: 1, limit: 3),
        ),
      ),
    );

    expect(find.text('Songs this month'), findsOneWidget);
    expect(find.text('2 left'), findsOneWidget);
  });
}
