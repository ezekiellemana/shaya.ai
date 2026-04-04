import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shaya_ai/core/app_constants.dart';
import 'package:shaya_ai/core/providers.dart';
import 'package:shaya_ai/shared/widgets/shaya_buttons.dart';
import 'package:shaya_ai/shared/widgets/shaya_chip.dart';
import 'package:shaya_ai/shared/widgets/shaya_scaffold.dart';
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
          ShayaTextField(
            controller: _topicController,
            label: 'Topic',
            hint: 'Hope after hardship',
          ),
          const SizedBox(height: 14),
          ShayaTextField(
            controller: _moodController,
            label: 'Mood',
            hint: 'Victorious',
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
          const SizedBox(height: 16),
          PrimaryGradientButton(
            label: 'Generate lyrics',
            isBusy: controller.isBusy,
            onPressed: _generate,
          ),
          const SizedBox(height: 16),
          if (controller.sections.isNotEmpty) ...[
            Text(
              controller.title,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < controller.sections.length; i++) ...[
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A35),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.sections[i].heading,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: TextEditingController(
                        text: controller.sections[i].content,
                      ),
                      maxLines: null,
                      onChanged: (value) => ref
                          .read(lyricsControllerProvider)
                          .updateSection(i, value),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => ref
                            .read(lyricsControllerProvider)
                            .improveSection(i),
                        child: const Text('Improve'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            Row(
              children: [
                Expanded(
                  child: SecondaryOutlineButton(
                    label: 'Translate',
                    icon: Icons.translate_rounded,
                    onPressed: () =>
                        ref.read(lyricsControllerProvider).translateLyrics(),
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
