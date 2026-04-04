class Playlist {
  const Playlist({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.isPublic,
    required this.songIds,
    required this.createdAt,
  });

  final String id;
  final String ownerId;
  final String name;
  final bool isPublic;
  final List<String> songIds;
  final DateTime createdAt;

  Playlist copyWith({String? name, bool? isPublic, List<String>? songIds}) {
    return Playlist(
      id: id,
      ownerId: ownerId,
      name: name ?? this.name,
      isPublic: isPublic ?? this.isPublic,
      songIds: songIds ?? this.songIds,
      createdAt: createdAt,
    );
  }

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'] as String? ?? '',
      ownerId: json['owner_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      isPublic: json['is_public'] as bool? ?? false,
      songIds: List<String>.from(
        json['song_ids'] as List<dynamic>? ?? const [],
      ),
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'name': name,
      'is_public': isPublic,
      'song_ids': songIds,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
