import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:pure_live/modules/media/api/bilibili_ugc_api.dart';
import 'package:pure_live/modules/media/models/bilibili_music_models.dart';
import 'package:pure_live/exports/common_export.dart';

part 'music_library_controller.g.dart';

/// A locally-created playlist (自建歌单): named by the user, tracks added
/// from the player, ordered in place. Persisted inside the library's Hive.
class MusicUserPlaylist {
  const MusicUserPlaylist({
    required this.id,
    required this.name,
    required this.createdAt,
    this.pinnedAt = 0,
    this.tracks = const [],
  });

  final String id;
  final String name;
  final int createdAt;
  final List<MusicTrack> tracks;

  /// 0 = not pinned; otherwise the timestamp of the pin, so the newest pin
  /// sorts first. The default liked playlist is not one of these.
  final int pinnedAt;

  MusicUserPlaylist copyWith({String? name, int? pinnedAt, List<MusicTrack>? tracks}) {
    return MusicUserPlaylist(
      id: id,
      name: name ?? this.name,
      createdAt: createdAt,
      pinnedAt: pinnedAt ?? this.pinnedAt,
      tracks: tracks ?? this.tracks,
    );
  }
}

/// The music library: favorites and recent plays, both persisted in Hive as
/// JSON string lists so the library survives restarts — the part that makes
/// music mode an application instead of a demo.
class MusicLibraryState {
  const MusicLibraryState({
    this.favorites = const [],
    this.recents = const [],
    this.followedUps = const [],
    this.likedSongs = const [],
    this.playlists = const [],
    this.excludedParts = const {},
  });

  final List<MusicArchive> favorites;
  final List<MusicArchive> recents;

  /// Followed uploaders (作者), separate from the album favorites.
  final List<MusicUp> followedUps;

  /// Songs hearted from the player — the 喜欢 list, one entry per part.
  final List<MusicTrack> likedSongs;

  /// Per-archive skipped parts (跳过分 P): bvid -> excluded cids. A part here
  /// vanishes from every queue the archive materializes into; when all parts
  /// of an archive are excluded the archive simply has nothing to play.
  final Map<String, List<int>> excludedParts;

  /// Locally created playlists (自建歌单).
  final List<MusicUserPlaylist> playlists;

  /// Reactive favorite check for widgets holding the state.
  bool isFavorite(String bvid) => favorites.any((a) => a.bvid == bvid);

  bool isFollowingUp(int mid) => followedUps.any((u) => u.mid == mid);

  bool isSongLiked(String trackId) => likedSongs.any((t) => t.id == trackId);

  List<int> excludedCids(String bvid) => excludedParts[bvid] ?? const [];

  /// The archive's parts with the excluded ones removed — the single filter
  /// every queue built from this archive must go through.
  List<MusicTrack> playableParts(MusicArchive archive) {
    final excluded = (excludedParts[archive.bvid] ?? const <int>[]).toSet();
    if (excluded.isEmpty) return archive.tracks;
    return archive.tracks.where((t) => !excluded.contains(t.part.cid)).toList();
  }

  /// User playlists in display order: pinned first (newest pin highest), the
  /// rest newest-created first. The default liked playlist is not in here —
  /// the playlist page mounts it on top by itself.
  List<MusicUserPlaylist> get orderedPlaylists {
    final pinned = playlists.where((p) => p.pinnedAt > 0).toList()
      ..sort((a, b) => b.pinnedAt.compareTo(a.pinnedAt));
    final rest = playlists.where((p) => p.pinnedAt <= 0).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return [...pinned, ...rest];
  }

  MusicLibraryState copyWith({
    List<MusicArchive>? favorites,
    List<MusicArchive>? recents,
    List<MusicUp>? followedUps,
    List<MusicTrack>? likedSongs,
    List<MusicUserPlaylist>? playlists,
    Map<String, List<int>>? excludedParts,
  }) {
    return MusicLibraryState(
      favorites: favorites ?? this.favorites,
      recents: recents ?? this.recents,
      followedUps: followedUps ?? this.followedUps,
      likedSongs: likedSongs ?? this.likedSongs,
      playlists: playlists ?? this.playlists,
      excludedParts: excludedParts ?? this.excludedParts,
    );
  }
}

@Riverpod(keepAlive: true)
class MusicLibraryController extends _$MusicLibraryController {
  /// The default 喜欢 playlist: the hearted songs, mounted on top of the
  /// playlist shelf and not deletable. Its tracks live in their own key.
  static const String likedPlaylistId = 'liked';
  static const int _recentsCap = 50;

  @override
  MusicLibraryState build() {
    return MusicLibraryState(
      favorites: _load('musicFavorites'),
      recents: _load('musicRecents'),
      followedUps: _loadUps('musicFollowedUps'),
      likedSongs: _loadTracks('musicLikedSongs'),
      playlists: _loadPlaylists(),
      excludedParts: _loadExcludedParts(),
    );
  }

  bool isFavorite(String bvid) => state.favorites.any((a) => a.bvid == bvid);

  /// Favorites toggle: front-insert on add, drop on remove, with a toast either way.
  void toggleFavorite(MusicArchive archive) {
    final next = List<MusicArchive>.from(state.favorites);
    final existing = next.indexWhere((a) => a.bvid == archive.bvid);
    if (existing >= 0) {
      next.removeAt(existing);
      ToastUtil.show(i18n('music_removed_favorite'));
    } else {
      next.insert(0, archive);
      ToastUtil.show(i18n('music_added_favorite'));
    }
    state = state.copyWith(favorites: List.unmodifiable(next));
    _persist('musicFavorites', next);
  }

  void removeFavorite(String bvid) {
    final next = List<MusicArchive>.from(state.favorites)..removeWhere((a) => a.bvid == bvid);
    state = state.copyWith(favorites: List.unmodifiable(next));
    _persist('musicFavorites', next);
  }

  void removeRecent(String bvid) {
    final next = List<MusicArchive>.from(state.recents)..removeWhere((a) => a.bvid == bvid);
    state = state.copyWith(recents: List.unmodifiable(next));
    _persist('musicRecents', next);
  }

  /// Called when a track actually starts playing: front-inserts the archive
  /// into Recently played, deduped and capped.
  void recordPlay(MusicArchive archive) {
    final next = List<MusicArchive>.from(state.recents)..removeWhere((a) => a.bvid == archive.bvid);
    next.insert(0, archive);
    if (next.length > _recentsCap) next.removeRange(_recentsCap, next.length);
    state = state.copyWith(recents: List.unmodifiable(next));
    _persist('musicRecents', next);
  }

  void clearRecents() {
    state = state.copyWith(recents: const []);
    _persist('musicRecents', const []);
  }

  /// Follow / unfollow an uploader. Front-insert on follow, keyed by mid.
  ///
  /// Writes through to the bilibili relation as well (best effort, when
  /// logged in): the UP-space page reads the platform's state, and a local-only
  /// follow would show up as 未关注 there.
  void toggleFollowUp(MusicUp up) {
    final next = List<MusicUp>.from(state.followedUps);
    final existing = next.indexWhere((u) => u.mid == up.mid);
    final bool following;
    if (existing >= 0) {
      next.removeAt(existing);
      following = false;
      ToastUtil.show(i18n('music_up_unfollowed'));
    } else {
      next.insert(0, up);
      following = true;
      ToastUtil.show(i18n('music_up_followed'));
    }
    state = state.copyWith(followedUps: List.unmodifiable(next));
    _persistUps('musicFollowedUps', next);
    final api = BilibiliUgcApi.instance;
    if (api.isLoggedIn) {
      api.setFollowing(up.mid, follow: following).catchError((Object _) {});
    }
  }

  // ---------------------------------------------------------------- song likes

  /// Hearts / unhearts a song (歌曲级红心). Liked songs live outside any
  /// album: they queue in their own order on the 喜欢 page.
  void toggleLikeSong(MusicTrack track) {
    final next = List<MusicTrack>.from(state.likedSongs);
    final existing = next.indexWhere((t) => t.id == track.id);
    if (existing >= 0) {
      next.removeAt(existing);
      ToastUtil.show(i18n('music_song_unliked'));
    } else {
      next.insert(0, track);
      ToastUtil.show(i18n('music_song_liked'));
    }
    state = state.copyWith(likedSongs: List.unmodifiable(next));
    _persistTracks('musicLikedSongs', next);
  }

  /// Unlikes without toggling — the 喜欢 page's removal must never re-add.
  void removeLikedSong(String trackId) {
    final next = List<MusicTrack>.from(state.likedSongs)..removeWhere((t) => t.id == trackId);
    if (next.length == state.likedSongs.length) return;
    state = state.copyWith(likedSongs: List.unmodifiable(next));
    _persistTracks('musicLikedSongs', next);
  }

  // ------------------------------------------------------------ local playlists

  String? createPlaylist(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;
    final now = DateTime.now().millisecondsSinceEpoch;
    final playlist = MusicUserPlaylist(id: 'pl_$now', name: trimmed, createdAt: now);
    state = state.copyWith(playlists: List.unmodifiable([playlist, ...state.playlists]));
    _persistPlaylists();
    ToastUtil.show(i18n('music_playlist_created'));
    return playlist.id;
  }

  void deletePlaylist(String id) {
    if (!state.playlists.any((p) => p.id == id)) return;
    state = state.copyWith(playlists: List.unmodifiable(state.playlists.where((p) => p.id != id)));
    _persistPlaylists();
    ToastUtil.show(i18n('music_playlist_deleted'));
  }

  /// Pins / unpins a playlist (置顶).
  void togglePlaylistPin(String id) {
    final at = state.playlists.indexWhere((p) => p.id == id);
    if (at < 0) return;
    final playlist = state.playlists[at];
    final pinning = playlist.pinnedAt <= 0;
    _replacePlaylist(at, playlist.copyWith(pinnedAt: pinning ? DateTime.now().millisecondsSinceEpoch : 0));
    ToastUtil.show(i18n(pinning ? 'music_pinned' : 'music_unpinned'));
  }

  void renamePlaylist(String id, String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final at = state.playlists.indexWhere((p) => p.id == id);
    if (at < 0) return;
    _replacePlaylist(at, state.playlists[at].copyWith(name: trimmed));
    ToastUtil.show(i18n('music_playlist_renamed'));
  }

  /// Moves a liked song to the top of the 喜欢 list (置顶).
  void pinLikedSong(String trackId) {
    final at = state.likedSongs.indexWhere((t) => t.id == trackId);
    if (at <= 0) return;
    final tracks = List<MusicTrack>.from(state.likedSongs);
    final track = tracks.removeAt(at);
    tracks.insert(0, track);
    state = state.copyWith(likedSongs: List.unmodifiable(tracks));
    _persistTracks('musicLikedSongs', tracks);
  }

  void addTrackToPlaylist(String id, MusicTrack track) {
    final at = state.playlists.indexWhere((p) => p.id == id);
    if (at < 0) return;
    final playlist = state.playlists[at];
    if (playlist.tracks.any((t) => t.id == track.id)) {
      ToastUtil.show(i18n('music_already_in_playlist'));
      return;
    }
    _replacePlaylist(at, playlist.copyWith(tracks: List.unmodifiable([...playlist.tracks, track])));
    ToastUtil.show(i18n('music_added_to_playlist'));
  }

  /// Batch-adds [tracks] to a playlist, silently skipping the ones it already
  /// holds — the batch save (关注 albums → 歌单) toasts a summary once instead
  /// of a toast per track. Returns how many actually landed.
  int addTracksToPlaylist(String id, List<MusicTrack> tracks) {
    final at = state.playlists.indexWhere((p) => p.id == id);
    if (at < 0) return 0;
    final playlist = state.playlists[at];
    final known = playlist.tracks.map((t) => t.id).toSet();
    final fresh = <MusicTrack>[];
    for (final track in tracks) {
      if (known.add(track.id)) fresh.add(track);
    }
    if (fresh.isEmpty) return 0;
    _replacePlaylist(at, playlist.copyWith(tracks: List.unmodifiable([...playlist.tracks, ...fresh])));
    return fresh.length;
  }

  void removeTrackFromPlaylist(String id, String trackId) {
    final at = state.playlists.indexWhere((p) => p.id == id);
    if (at < 0) return;
    final playlist = state.playlists[at];
    if (!playlist.tracks.any((t) => t.id == trackId)) return;
    _replacePlaylist(
      at,
      playlist.copyWith(tracks: List.unmodifiable(playlist.tracks.where((t) => t.id != trackId))),
    );
  }

  /// Moves a track by [delta] slots — the playlist page's 排序 step.
  void moveTrackInPlaylist(String id, int index, int delta) {
    final at = state.playlists.indexWhere((p) => p.id == id);
    if (at < 0) return;
    final tracks = List<MusicTrack>.from(state.playlists[at].tracks);
    final target = index + delta;
    if (index < 0 || index >= tracks.length || target < 0 || target >= tracks.length) return;
    final track = tracks.removeAt(index);
    tracks.insert(target, track);
    _replacePlaylist(at, state.playlists[at].copyWith(tracks: List.unmodifiable(tracks)));
  }

  void _replacePlaylist(int at, MusicUserPlaylist playlist) {
    final next = List<MusicUserPlaylist>.from(state.playlists)..[at] = playlist;
    state = state.copyWith(playlists: List.unmodifiable(next));
    _persistPlaylists();
  }

  List<MusicArchive> _load(String key) {
    try {
      final raw = HivePrefUtil.getStringList(key) ?? const [];
      return [
        for (final entry in raw)
          if (jsonDecode(entry) case final Map<String, dynamic> map) MusicArchive.fromJson(map),
      ];
    } catch (_) {
      return const [];
    }
  }

  void _persist(String key, List<MusicArchive> list) {
    HivePrefUtil.setStringList(key, [for (final a in list) jsonEncode(a.toJson())]);
  }

  List<MusicUp> _loadUps(String key) {
    try {
      final raw = HivePrefUtil.getStringList(key) ?? const [];
      return [
        for (final entry in raw)
          if (jsonDecode(entry) case final Map<String, dynamic> map)
            if (MusicUp.fromJson(map).mid > 0) MusicUp.fromJson(map),
      ];
    } catch (_) {
      return const [];
    }
  }

  void _persistUps(String key, List<MusicUp> list) {
    HivePrefUtil.setStringList(key, [for (final u in list) jsonEncode(u.toJson())]);
  }

  // ------------------------------------------------------------- 分 P 跳过

  List<int> excludedCids(String bvid) => state.excludedCids(bvid);

  void toggleExcludedPart(String bvid, int cid) {
    final map = {...state.excludedParts};
    final cids = [...(map[bvid] ?? const <int>[])];
    if (cids.contains(cid)) {
      cids.remove(cid);
    } else {
      cids.add(cid);
    }
    if (cids.isEmpty) {
      map.remove(bvid);
    } else {
      map[bvid] = cids;
    }
    state = state.copyWith(excludedParts: Map.unmodifiable(map));
    _persistExcludedParts(map);
  }

  Map<String, List<int>> _loadExcludedParts() {
    try {
      final raw = HivePrefUtil.getString('musicExcludedParts');
      if (raw == null || raw.isEmpty) return const {};
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) return const {};
      return {
        for (final entry in json.entries)
          entry.key: [
            for (final v in (entry.value as List?) ?? const <dynamic>[]) int.tryParse(v?.toString() ?? '') ?? 0,
          ]..remove(0),
      };
    } catch (_) {
      return const {};
    }
  }

  void _persistExcludedParts(Map<String, List<int>> map) {
    HivePrefUtil.setString('musicExcludedParts', jsonEncode(map));
  }

  /// Track-list codec shared by liked songs and local playlists: archives are
  /// stored once per bvid, tracks as `bvid#cid#page` refs into them. A ref
  /// whose archive or part has vanished is dropped, like the player's session.
  Map<String, dynamic> _encodeTracks(List<MusicTrack> tracks) {
    final archives = <String, MusicArchive>{};
    final order = <String>[];
    for (final track in tracks) {
      archives[track.archive.bvid] = track.archive;
      order.add('${track.archive.bvid}#${track.part.cid}#${track.part.page}');
    }
    return {
      'archives': [for (final archive in archives.values) archive.toJson()],
      'order': order,
    };
  }

  List<MusicTrack> _decodeTracks(Map<String, dynamic> json) {
    final archives = <String, MusicArchive>{
      for (final entry in (json['archives'] as List?) ?? const <dynamic>[])
        if (entry is Map<String, dynamic>) entry['bvid']?.toString() ?? '': MusicArchive.fromJson(entry),
    };
    final tracks = <MusicTrack>[];
    for (final ref in (json['order'] as List?) ?? const <dynamic>[]) {
      final parts = ref?.toString().split('#');
      if (parts == null || parts.length != 3) continue;
      final archive = archives[parts[0]];
      if (archive == null) continue;
      final cid = int.tryParse(parts[1]) ?? 0;
      final page = int.tryParse(parts[2]) ?? 1;
      MusicPart? part;
      if (archive.parts.isNotEmpty) {
        part = cid > 0 ? archive.parts.where((p) => p.cid == cid).firstOrNull : null;
        part ??= archive.parts.where((p) => p.page == page).firstOrNull;
        part ??= archive.parts.first;
      } else {
        part = MusicPart(cid: cid, page: page, title: archive.title, duration: archive.duration);
      }
      tracks.add(MusicTrack(archive: archive, part: part));
    }
    return tracks;
  }

  List<MusicTrack> _loadTracks(String key) {
    try {
      final raw = HivePrefUtil.getString(key);
      if (raw == null || raw.isEmpty) return const [];
      if (jsonDecode(raw) case final Map<String, dynamic> map) return _decodeTracks(map);
      return const [];
    } catch (_) {
      return const [];
    }
  }

  void _persistTracks(String key, List<MusicTrack> tracks) {
    HivePrefUtil.setString(key, jsonEncode(_encodeTracks(tracks)));
  }

  Map<String, dynamic> _encodePlaylist(MusicUserPlaylist playlist) => {
    'id': playlist.id,
    'name': playlist.name,
    'createdAt': playlist.createdAt,
    'pinnedAt': playlist.pinnedAt,
    ..._encodeTracks(playlist.tracks),
  };

  List<MusicUserPlaylist> _loadPlaylists() {
    try {
      final raw = HivePrefUtil.getStringList('musicUserPlaylists') ?? const [];
      final playlists = <MusicUserPlaylist>[];
      for (final entry in raw) {
        final json = jsonDecode(entry);
        if (json is! Map<String, dynamic>) continue;
        final id = json['id']?.toString() ?? '';
        if (id.isEmpty) continue;
        playlists.add(
          MusicUserPlaylist(
            id: id,
            name: json['name']?.toString() ?? '',
            createdAt: int.tryParse(json['createdAt']?.toString() ?? '') ?? 0,
            pinnedAt: int.tryParse(json['pinnedAt']?.toString() ?? '') ?? 0,
            tracks: _decodeTracks(json),
          ),
        );
      }
      return playlists;
    } catch (_) {
      return const [];
    }
  }

  void _persistPlaylists() {
    HivePrefUtil.setStringList('musicUserPlaylists', [
      for (final playlist in state.playlists) jsonEncode(_encodePlaylist(playlist)),
    ]);
  }
}
