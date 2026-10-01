import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:pure_live/modules/vod/models/models.dart';
import 'package:pure_live/exports/common_export.dart';

part 'music_library_controller.g.dart';

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
    this.likedSongs = const [],
    this.playlists = const [],
  });

  final List<MusicArchive> favorites;
  final List<MusicArchive> recents;

  final List<MusicTrack> likedSongs;

  final List<MusicUserPlaylist> playlists;

  /// Reactive favorite check for widgets holding the state.
  bool isFavorite(String bvid) => favorites.any((a) => a.bvid == bvid);

  bool isSongLiked(String trackId) => likedSongs.any((t) => t.id == trackId);

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
    List<MusicTrack>? likedSongs,
    List<MusicUserPlaylist>? playlists,
  }) {
    return MusicLibraryState(
      favorites: favorites ?? this.favorites,
      recents: recents ?? this.recents,
      likedSongs: likedSongs ?? this.likedSongs,
      playlists: playlists ?? this.playlists,
    );
  }
}

@Riverpod(keepAlive: true)
class MusicLibraryController extends _$MusicLibraryController {
  /// playlist shelf and not deletable. Its tracks live in their own key.
  static const String likedPlaylistId = 'liked';
  static const int _recentsCap = 50;

  @override
  MusicLibraryState build() {
    return MusicLibraryState(
      favorites: _load('musicFavorites'),
      recents: _load('musicRecents'),
      likedSongs: _loadTracks('musicLikedSongs'),
      playlists: _loadPlaylists(),
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

  // ---------------------------------------------------------------- song likes

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

  /// Empties a playlist's tracks, keeping the playlist itself on the shelf.
  void clearPlaylist(String id) {
    final at = state.playlists.indexWhere((p) => p.id == id);
    if (at < 0) return;
    _replacePlaylist(at, state.playlists[at].copyWith(tracks: const []));
  }

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
