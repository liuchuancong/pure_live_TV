import 'package:pure_live/exports/common_export.dart';

/// Music mode sections. The section rail itself lives in the home sidebar —
/// this file only names them, so the mode swaps the whole navigation instead
/// of nesting its own.
///
/// `nowPlaying` is appended last: the section index is persisted as the enum
/// index, so reordering would silently retarget every saved selection.
enum MusicSection { favorites, daily, recents, playlists, dynamics, history, ranking, followedUps, search, nowPlaying }

/// on their own (a single-section group renders bare, no tab bar), then the
const List<List<MusicSection>> kMusicRailGroups = [
  [MusicSection.nowPlaying],
  [MusicSection.search],
  [MusicSection.playlists],
  [MusicSection.daily, MusicSection.dynamics, MusicSection.ranking],
  [MusicSection.favorites, MusicSection.followedUps, MusicSection.recents, MusicSection.history],
];

/// Which rail group [section] belongs to.
int musicRailIndexFor(MusicSection section) =>
    kMusicRailGroups.indexWhere((group) => group.contains(section));

/// The tab-bar label of one section (two-character forms, the rail's short keys).
String musicSectionTabLabel(MusicSection section) => switch (section) {
  MusicSection.search => i18n('music_tab_search'),
  MusicSection.daily => i18n('music_short_daily'),
  MusicSection.dynamics => i18n('music_dynamics'),
  MusicSection.ranking => i18n('music_short_ranking'),
  MusicSection.favorites => i18n('music_favorites'),
  MusicSection.recents => i18n('music_short_recents'),
  MusicSection.playlists => i18n('music_short_playlists'),
  MusicSection.history => i18n('music_short_history'),
  MusicSection.followedUps => i18n('music_tab_ups'),
  MusicSection.nowPlaying => i18n('music_now_playing'),
};
