import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:pure_live/modules/media/models/bilibili_music_models.dart';
import 'package:pure_live/exports/common_export.dart';

part 'music_library_controller.g.dart';

/// The music library: favorites and recent plays, both persisted in Hive as
/// JSON string lists so the library survives restarts — the part that makes
/// music mode an application instead of a demo.
class MusicLibraryState {
  const MusicLibraryState({this.favorites = const [], this.recents = const []});

  final List<MusicArchive> favorites;
  final List<MusicArchive> recents;

  /// Reactive favorite check for widgets holding the state.
  bool isFavorite(String bvid) => favorites.any((a) => a.bvid == bvid);

  MusicLibraryState copyWith({List<MusicArchive>? favorites, List<MusicArchive>? recents}) {
    return MusicLibraryState(favorites: favorites ?? this.favorites, recents: recents ?? this.recents);
  }
}

@Riverpod(keepAlive: true)
class MusicLibraryController extends _$MusicLibraryController {
  static const int _recentsCap = 50;

  @override
  MusicLibraryState build() {
    return MusicLibraryState(
      favorites: _load('musicFavorites'),
      recents: _load('musicRecents'),
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
}
