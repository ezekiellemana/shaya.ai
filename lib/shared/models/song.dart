import 'package:shaya_ai/shared/models/lyric_section.dart';

enum SongContentKind { song, lyrics }

class Song {
  const Song({
    required this.id,
    required this.userId,
    required this.title,
    required this.prompt,
    required this.audioUrl,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.genre,
    required this.mood,
    required this.duration,
    required this.isPublic,
    required this.contentKind,
    required this.lyricsTitle,
    required this.lyricsLanguage,
    required this.lyricsSections,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String title;
  final String prompt;
  final String audioUrl;
  final String? videoUrl;
  final String thumbnailUrl;
  final List<String> genre;
  final String? mood;
  final int duration;
  final bool isPublic;
  final SongContentKind contentKind;
  final String? lyricsTitle;
  final String? lyricsLanguage;
  final List<LyricSection> lyricsSections;
  final DateTime createdAt;

  bool get hasVideo => videoUrl != null && videoUrl!.isNotEmpty;
  bool get hasAudio => audioUrl.isNotEmpty;
  bool get hasLyrics => lyricsSections.isNotEmpty;

  factory Song.fromJson(Map<String, dynamic> json) {
    final sections = (json['lyrics_sections'] as List<dynamic>? ?? const [])
        .map(
          (section) => LyricSection.fromJson(section as Map<String, dynamic>),
        )
        .toList();

    return Song(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      prompt: json['prompt'] as String? ?? '',
      audioUrl: json['audio_url'] as String? ?? '',
      videoUrl: json['video_url'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String? ?? '',
      genre: List<String>.from(json['genre'] as List<dynamic>? ?? const []),
      mood: json['mood'] as String?,
      duration: json['duration'] as int? ?? 0,
      isPublic: json['is_public'] as bool? ?? false,
      contentKind: switch (json['content_kind'] as String? ?? 'song') {
        'lyrics' => SongContentKind.lyrics,
        _ => SongContentKind.song,
      },
      lyricsTitle: json['lyrics_title'] as String?,
      lyricsLanguage: json['lyrics_language'] as String?,
      lyricsSections: sections,
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'prompt': prompt,
      'audio_url': audioUrl,
      'video_url': videoUrl,
      'thumbnail_url': thumbnailUrl,
      'genre': genre,
      'mood': mood,
      'duration': duration,
      'is_public': isPublic,
      'content_kind': contentKind.name,
      'lyrics_title': lyricsTitle,
      'lyrics_language': lyricsLanguage,
      'lyrics_sections': lyricsSections
          .map((section) => section.toJson())
          .toList(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
