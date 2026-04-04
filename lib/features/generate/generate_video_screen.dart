import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shaya_ai/core/app_constants.dart';
import 'package:shaya_ai/core/providers.dart';
import 'package:shaya_ai/shared/models/subscription_tier.dart';
import 'package:shaya_ai/shared/widgets/shaya_buttons.dart';
import 'package:shaya_ai/shared/widgets/shaya_chip.dart';
import 'package:shaya_ai/shared/widgets/shaya_scaffold.dart';
import 'package:shaya_ai/shared/widgets/shaya_text_field.dart';
import 'package:shaya_ai/shared/widgets/song_card.dart';

class GenerateVideoScreen extends ConsumerStatefulWidget {
  const GenerateVideoScreen({super.key});

  @override
  ConsumerState<GenerateVideoScreen> createState() =>
      _GenerateVideoScreenState();
}

class _GenerateVideoScreenState extends ConsumerState<GenerateVideoScreen> {
  final TextEditingController _promptController = TextEditingController();
  String? _selectedSongId;
  String _quality = AppConstants.videoQualities.first;
  bool _isBusy = false;

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final songs = ref.watch(librarySongsProvider).value ?? const [];
    final profile = ref.watch(currentUserProfileProvider).value;
    final tier = profile?.subscriptionTier ?? SubscriptionTier.free;
    final selectedSongMatches = _selectedSongId == null
        ? const []
        : songs.where((song) => song.id == _selectedSongId).toList();
    final selectedSong = selectedSongMatches.isEmpty
        ? null
        : selectedSongMatches.first;

    return ShayaScreenScaffold(
      title: 'Generate Video',
      subtitle:
          'Choose a song from your library and describe the visual scene.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (selectedSong != null)
            SongCard(song: selectedSong)
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedSongId,
                  hint: const Text('Pick a song from your library'),
                  items: songs
                      .where((song) => song.hasAudio)
                      .map(
                        (song) => DropdownMenuItem<String>(
                          value: song.id,
                          child: Text(song.title),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _selectedSongId = value),
                ),
              ),
            ),
          const SizedBox(height: 18),
          ShayaTextField(
            controller: _promptController,
            label: 'Visual prompt',
            hint: 'Sunset beach, slow motion, cinematic aerials',
            maxLines: 4,
          ),
          const SizedBox(height: 18),
          Text('Quality', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: AppConstants.videoQualities.map((quality) {
              final locked =
                  quality == '720p' && tier == SubscriptionTier.free ||
                  quality == '1080p' && tier != SubscriptionTier.pro;
              return Opacity(
                opacity: locked ? 0.4 : 1,
                child: IgnorePointer(
                  ignoring: locked,
                  child: ShayaChip(
                    label: quality,
                    selected: _quality == quality,
                    onTap: () => setState(() => _quality = quality),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          PrimaryGradientButton(
            label: 'Generate video',
            isBusy: _isBusy,
            onPressed: _selectedSongId == null ? null : _submit,
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _isBusy = true);
    try {
      await ref
          .read(songsRepositoryProvider)
          .generateVideo(
            songId: _selectedSongId!,
            visualPrompt: _promptController.text,
            quality: _quality,
          );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Video request submitted.')));
    } catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }
}
