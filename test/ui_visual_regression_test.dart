import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shaya_ai/core/theme.dart';
import 'package:shaya_ai/shared/models/song.dart';
import 'package:shaya_ai/shared/widgets/shaya_motion.dart';
import 'package:shaya_ai/shared/widgets/shaya_skeletons.dart';
import 'package:shaya_ai/shared/widgets/song_artwork.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UI visual regression', () {
    testWidgets('home feed skeleton matches golden', (tester) async {
      await _pumpGoldenFrame(
        tester,
        const Key('home-skeleton'),
        const Padding(
          padding: EdgeInsets.all(24),
          child: ShayaHomeFeedSkeleton(),
        ),
      );

      await expectLater(
        find.byKey(const Key('home-skeleton')),
        matchesGoldenFile('goldens/home_feed_skeleton.png'),
      );
    });

    testWidgets('settings skeleton matches golden', (tester) async {
      await _pumpGoldenFrame(
        tester,
        const Key('settings-skeleton'),
        const Padding(
          padding: EdgeInsets.all(24),
          child: ShayaSettingsSkeleton(),
        ),
      );

      await expectLater(
        find.byKey(const Key('settings-skeleton')),
        matchesGoldenFile('goldens/settings_skeleton.png'),
      );
    });

    testWidgets('payment placeholder skeleton matches golden', (tester) async {
      await _pumpGoldenFrame(
        tester,
        const Key('payment-skeleton'),
        const Padding(
          padding: EdgeInsets.all(24),
          child: ShayaPaymentPlaceholderSkeleton(),
        ),
      );

      await expectLater(
        find.byKey(const Key('payment-skeleton')),
        matchesGoldenFile('goldens/payment_placeholder_skeleton.png'),
      );
    });

    testWidgets('song artwork hero transition matches golden', (tester) async {
      await _setSurfaceSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: shayaTheme,
          home: const _HeroHarness(),
        ),
      );

      await tester.tap(find.byKey(const Key('hero-source')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      await expectLater(
        find.byKey(const Key('hero-stage')),
        matchesGoldenFile('goldens/song_artwork_hero_transition.png'),
      );
    });
  });
}

Future<void> _pumpGoldenFrame(
  WidgetTester tester,
  Key repaintKey,
  Widget child,
) async {
  await _setSurfaceSize(tester);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: shayaTheme,
      home: Scaffold(
        backgroundColor: kBgDark,
        body: SafeArea(
          child: RepaintBoundary(
            key: repaintKey,
            child: SingleChildScrollView(child: child),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _setSurfaceSize(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(430, 932);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

class _HeroHarness extends StatelessWidget {
  const _HeroHarness();

  static final _song = Song(
    id: 'hero-song',
    userId: 'user-1',
    title: 'Hero Song',
    prompt: 'A premium Afrofuturist cue',
    audioUrl: '',
    videoUrl: null,
    thumbnailUrl: '',
    genre: ['Afropop'],
    mood: 'Bright',
    duration: 132,
    isPublic: true,
    contentKind: SongContentKind.song,
    lyricsTitle: null,
    lyricsLanguage: null,
    lyricsSections: [],
    createdAt: DateTime.utc(2026, 4, 6),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgDark,
      body: RepaintBoundary(
        key: const Key('hero-stage'),
        child: Navigator(
          onGenerateRoute: (_) => PageRouteBuilder<void>(
            pageBuilder: (context, animation, secondaryAnimation) =>
                _HeroSourcePage(
                  onOpen: () {
                    Navigator.of(context).push(
                      PageRouteBuilder<void>(
                        transitionDuration: const Duration(milliseconds: 320),
                        reverseTransitionDuration: const Duration(
                          milliseconds: 220,
                        ),
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            const _HeroDestinationPage(),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                              return FadeTransition(
                                opacity: animation,
                                child: child,
                              );
                            },
                      ),
                    );
                  },
                ),
          ),
        ),
      ),
    );
  }
}

class _HeroSourcePage extends StatelessWidget {
  const _HeroSourcePage({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        key: const Key('hero-source'),
        onTap: onOpen,
        child: Container(
          width: 120,
          height: 120,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: kGradCard,
          ),
          child: Center(
            child: ShayaSongArtwork(
              song: _HeroHarness._song,
              size: 92,
              radius: 24,
              heroTag: ShayaHeroTags.songArtwork('hero-song'),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroDestinationPage extends StatelessWidget {
  const _HeroDestinationPage();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 260,
        height: 260,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(36),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          gradient: const LinearGradient(
            colors: [Color(0xFF160A2E), Color(0xFF0F101E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: ShayaSongArtwork(
            song: _HeroHarness._song,
            size: 220,
            radius: 30,
            heroTag: ShayaHeroTags.songArtwork('hero-song'),
          ),
        ),
      ),
    );
  }
}
