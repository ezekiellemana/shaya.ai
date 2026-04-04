import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shaya_ai/core/app_constants.dart';
import 'package:shaya_ai/core/providers.dart';
import 'package:shaya_ai/shared/widgets/shaya_scaffold.dart';
import 'package:shaya_ai/shared/widgets/song_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _activeQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ShayaScreenScaffold(
      title: 'Search',
      subtitle: 'Search your songs by title, mood, or genre.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _activeQuery = value),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search_rounded),
              hintText: 'Search your library',
            ),
          ),
          const SizedBox(height: 18),
          Text('Genres', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.8,
            children: AppConstants.genreTags.map((genre) {
              return GestureDetector(
                onTap: () {
                  _searchController.text = genre;
                  setState(() => _activeQuery = genre);
                },
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF220A3E), Color(0xFF0D1B3E)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(child: Text(genre)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          FutureBuilder(
            future: ref
                .read(songsRepositoryProvider)
                .searchLibrary(_activeQuery),
            builder: (context, snapshot) {
              final songs = snapshot.data ?? const [];
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Results',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 10),
                  if (songs.isEmpty)
                    const Text('No matching songs yet.')
                  else
                    Column(
                      children: songs.map((song) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: SongCard(
                            song: song,
                            onTap: () async {
                              final router = GoRouter.of(context);
                              await ref
                                  .read(playerControllerProvider)
                                  .loadSong(song, queue: songs.cast());
                              if (!mounted) {
                                return;
                              }
                              await router.push('/player');
                            },
                          ),
                        );
                      }).toList(),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
