import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shaya_ai/core/app_constants.dart';
import 'package:shaya_ai/core/providers.dart';
import 'package:shaya_ai/shared/widgets/shaya_buttons.dart';
import 'package:shaya_ai/shared/widgets/shaya_chip.dart';
import 'package:shaya_ai/shared/widgets/shaya_scaffold.dart';
import 'package:shaya_ai/shared/widgets/shaya_surfaces.dart';
import 'package:shaya_ai/shared/widgets/shaya_text_field.dart';

class LyricsScreen extends ConsumerStatefulWidget {
  const LyricsScreen({super.key});

  @override
  ConsumerState<LyricsScreen> createState() => _LyricsScreenState();
}

class _LyricsScreenState extends ConsumerState<LyricsScreen> {
  final TextEditingController _topicController = TextEditingController();
  final TextEditingController _moodController = TextEditingController();
  String _language = AppConstants.lyricLanguages.first;

  @override
  void dispose() {
    _topicController.dispose();
    _moodController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(lyricsControllerProvider);
    return ShayaScreenScaffold(
      title: 'Lyrics Assistant',
      subtitle: 'Generate, edit, improve, and translate structured lyrics.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShayaSurfaceCard(
            showGlow: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShayaSectionHeader(
                  title: 'Creative seed',
                  subtitle:
                      'Set the subject, mood, and language before drafting.',
                ),
                const SizedBox(height: 16),
                ShayaTextField(
                  controller: _topicController,
                  label: 'Topic',
                  hint: 'Hope after hardship',
                  prefixIcon: Icons.menu_book_rounded,
                ),
                const SizedBox(height: 14),
                ShayaTextField(
                  controller: _moodController,
                  label: 'Mood',
                  hint: 'Victorious',
                  prefixIcon: Icons.emoji_emotions_outlined,
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AppConstants.lyricLanguages.map((language) {
                    return ShayaChip(
                      label: language,
                      selected: _language == language,
                      isMood: true,
                      onTap: () => setState(() => _language = language),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),
                PrimaryGradientButton(
                  label: 'Generate lyrics',
                  isBusy: controller.isBusy,
                  onPressed: _generate,
                ),
              ],
            ),
          ),
          if (controller.sections.isNotEmpty) ...[
            const SizedBox(height: 18),
            ShayaSurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShayaSectionHeader(
                    title: controller.title,
                    subtitle:
                        'Refine individual sections or turn the draft into music.',
                  ),
                  const SizedBox(height: 14),
                  for (var i = 0; i < controller.sections.length; i++) ...[
                    ShayaSurfaceCard(
                      radius: 18,
                      padding: const EdgeInsets.all(16),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.04),
                          Colors.white.withValues(alpha: 0.02),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            controller.sections[i].heading,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: TextEditingController(
                              text: controller.sections[i].content,
                            ),
                            maxLines: null,
                            onChanged: (value) => ref
                                .read(lyricsControllerProvider)
                                .updateSection(i, value),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () => ref
                                  .read(lyricsControllerProvider)
                                  .improveSection(i),
                              icon: const Icon(
                                Icons.auto_fix_high_rounded,
                                size: 18,
                              ),
                              label: const Text('Improve'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (i != controller.sections.length - 1)
                      const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: SecondaryOutlineButton(
                          label: 'Translate',
                          icon: Icons.translate_rounded,
                          onPressed: () => ref
                              .read(lyricsControllerProvider)
                              .translateLyrics(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: PrimaryGradientButton(
                          label: 'Generate music',
                          onPressed: _generateMusicFromLyrics,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _generate() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(lyricsControllerProvider)
          .generateLyrics(
            topic: _topicController.text,
            mood: _moodController.text,
            language: _language,
          );
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _generateMusicFromLyrics() async {
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(lyricsControllerProvider).generateMusicFromLyrics();
      if (!mounted) {
        return;
      }
      await router.push('/player');
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}
