import 'package:shaya_ai/shared/models/subscription_tier.dart';

class UsageQuota {
  const UsageQuota({
    required this.userId,
    required this.month,
    required this.songsGenerated,
    required this.videosGenerated,
    required this.lyricsGenerated,
    required this.lastRequestAt,
  });

  final String userId;
  final String month;
  final int songsGenerated;
  final int videosGenerated;
  final int lyricsGenerated;
  final DateTime? lastRequestAt;

  factory UsageQuota.fromJson(Map<String, dynamic> json) {
    return UsageQuota(
      userId: json['user_id'] as String? ?? '',
      month: json['month'] as String? ?? '',
      songsGenerated: json['songs_generated'] as int? ?? 0,
      videosGenerated: json['videos_generated'] as int? ?? 0,
      lyricsGenerated: json['lyrics_generated'] as int? ?? 0,
      lastRequestAt: DateTime.tryParse(
        json['last_request_at'] as String? ?? '',
      ),
    );
  }

  int remainingSongs(SubscriptionTier tier) {
    if (tier.songLimit == null) {
      return -1;
    }
    return (tier.songLimit! - songsGenerated).clamp(0, tier.songLimit!);
  }

  int remainingVideos(SubscriptionTier tier) {
    if (tier.videoLimit == null) {
      return -1;
    }
    return (tier.videoLimit! - videosGenerated).clamp(0, tier.videoLimit!);
  }

  int remainingLyrics(SubscriptionTier tier) {
    if (tier.lyricsLimit == null) {
      return -1;
    }
    return (tier.lyricsLimit! - lyricsGenerated).clamp(0, tier.lyricsLimit!);
  }
}
