enum SubscriptionTier {
  free,
  basic,
  pro;

  String get label => switch (this) {
    SubscriptionTier.free => 'Free',
    SubscriptionTier.basic => 'Basic',
    SubscriptionTier.pro => 'Pro',
  };

  int? get songLimit => switch (this) {
    SubscriptionTier.free => 3,
    SubscriptionTier.basic => 20,
    SubscriptionTier.pro => null,
  };

  int? get videoLimit => switch (this) {
    SubscriptionTier.free => 1,
    SubscriptionTier.basic => 5,
    SubscriptionTier.pro => 20,
  };

  int? get lyricsLimit => switch (this) {
    SubscriptionTier.free => 5,
    SubscriptionTier.basic => null,
    SubscriptionTier.pro => null,
  };

  int get requestsPerMinute => switch (this) {
    SubscriptionTier.free => 10,
    SubscriptionTier.basic => 30,
    SubscriptionTier.pro => 60,
  };

  int get claudeInputTokens => switch (this) {
    SubscriptionTier.free => 800,
    SubscriptionTier.basic => 1500,
    SubscriptionTier.pro => 3000,
  };

  bool get canDownloadMp3 => this != SubscriptionTier.free;
  bool get canDownloadMp4 => this == SubscriptionTier.pro;
  bool get hasCommercialRights => this == SubscriptionTier.pro;

  String get videoQuality => switch (this) {
    SubscriptionTier.free => '480p',
    SubscriptionTier.basic => '720p',
    SubscriptionTier.pro => '1080p',
  };

  static SubscriptionTier fromValue(String? value) {
    return switch (value?.toLowerCase()) {
      'basic' => SubscriptionTier.basic,
      'pro' => SubscriptionTier.pro,
      _ => SubscriptionTier.free,
    };
  }
}
