import 'package:shaya_ai/shared/models/subscription_tier.dart';

class UserProfile {
  const UserProfile({
    required this.id,
    required this.displayName,
    required this.photoUrl,
    required this.subscriptionTier,
    required this.createdAt,
    required this.preferredGenres,
    required this.preferredMood,
  });

  final String id;
  final String displayName;
  final String? photoUrl;
  final SubscriptionTier subscriptionTier;
  final DateTime createdAt;
  final List<String> preferredGenres;
  final String? preferredMood;

  UserProfile copyWith({
    String? displayName,
    String? photoUrl,
    SubscriptionTier? subscriptionTier,
    List<String>? preferredGenres,
    String? preferredMood,
  }) {
    return UserProfile(
      id: id,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      createdAt: createdAt,
      preferredGenres: preferredGenres ?? this.preferredGenres,
      preferredMood: preferredMood ?? this.preferredMood,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      photoUrl: json['photo_url'] as String?,
      subscriptionTier: SubscriptionTier.fromValue(
        json['subscription_tier'] as String?,
      ),
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      preferredGenres: List<String>.from(
        json['preferred_genres'] as List<dynamic>? ?? const [],
      ),
      preferredMood: json['preferred_mood'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'display_name': displayName,
      'photo_url': photoUrl,
      'subscription_tier': subscriptionTier.name,
      'created_at': createdAt.toIso8601String(),
      'preferred_genres': preferredGenres,
      'preferred_mood': preferredMood,
    };
  }
}
