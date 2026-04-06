class ShayaHeroTags {
  const ShayaHeroTags._();

  static String songArtwork(String songId) => 'song-artwork:$songId';

  static String playlistCover(String playlistId) =>
      'playlist-cover:$playlistId';

  static const profileAvatarCurrentUser = 'profile-avatar:current-user';
}
