import 'dart:convert';
import 'package:pure_live/exports/common_export.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pure_live/modules/media/api/bilibili_ugc_api.dart';
import 'package:pure_live/modules/media/models/models.dart';
import 'package:pure_live/modules/music/controllers/playlist/music_playlist_sync_state.dart';

part 'music_playlist_sync_controller.g.dart';

/// The sync engine behind the synced playlists (bmsc's fav-list caching):
/// bilibili fav folders pulled down into music-module Hive keys so the
/// playlists open offline and survive restarts. Video never reads these keys —
/// the modules' local data stay strictly separated.
///
/// Also owns 排除分P: parts excluded from playlist playback, the bmsc
/// "excluded parts" feature.
@Riverpod(keepAlive: true)
class MusicPlaylistSyncController extends _$MusicPlaylistSyncController {
  static const String _foldersKey = 'musicSyncFolders';
  static const String _tracksKey = 'musicSyncFolderTracks';
  static const String _timesKey = 'musicSyncTimes';

  @override
  MusicPlaylistSyncState build() {
    return MusicPlaylistSyncState(folders: _loadFolders(), folderTracks: _loadTracks(), syncedAt: _loadTimes());
  }

  /// Pulls every folder and its content down to Hive. One slow pass, run from
  /// the playlist page's "同步全部" button.
  Future<void> syncAll() async {
    try {
      final folders = await BilibiliUgcApi.instance.getMyFavFolders();
      for (final folder in folders) {
        await syncFolder(folder.id, folderTitle: folder.title, folderCover: folder.cover);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString(), syncingFolderId: 0);
      ToastUtil.show(i18n('music_sync_failed'));
    }
  }

  /// Syncs one folder (the tile-level sync button / playlist refresh path).
  Future<void> syncFolder(int folderId, {String? folderTitle, String? folderCover}) async {
    if (state.syncingFolderId != 0) return;
    state = state.copyWith(syncingFolderId: folderId, error: '');
    try {
      final archives = <MusicArchive>[];
      for (var page = 1; page <= 25; page++) {
        final resources = await BilibiliUgcApi.instance.getFavResources(folderId, page: page, pageSize: 20);
        archives.addAll([
          for (final r in resources)
            if (!r.invalid) r.toArchive(),
        ]);
        if (resources.length < 20) break;
      }
      final tracks = {...state.folderTracks, folderId: List<MusicArchive>.unmodifiable(archives)};
      final times = {...state.syncedAt, folderId: DateTime.now()};
      final folders = [...state.folders];
      final at = folders.indexWhere((f) => f.id == folderId);
      final folder = FavFolder(
        id: folderId,
        title: folderTitle ?? (at >= 0 ? folders[at].title : '$folderId'),
        mediaCount: archives.length,
        cover: folderCover ?? (at >= 0 ? folders[at].cover : ''),
        isPublic: at >= 0 ? folders[at].isPublic : true,
      );
      if (at >= 0) {
        folders[at] = folder;
      } else {
        folders.insert(0, folder);
      }
      state = state.copyWith(folders: folders, folderTracks: tracks, syncedAt: times, syncingFolderId: 0);
      _persistAll();
    } catch (e) {
      state = state.copyWith(syncingFolderId: 0, error: e.toString());
      ToastUtil.show(i18n('music_sync_failed'));
    }
  }

  void removeFolder(int folderId) {
    state = state.copyWith(
      folders: [...state.folders]..removeWhere((f) => f.id == folderId),
      folderTracks: {...state.folderTracks}..remove(folderId),
      syncedAt: {...state.syncedAt}..remove(folderId),
    );
    _persistAll();
  }

  /// Drops a folder's synced tracks and its sync stamp; the folder itself
  /// stays on the shelf and can be synced down again.
  void clearFolderTracks(int folderId) {
    state = state.copyWith(
      folderTracks: {...state.folderTracks, folderId: const []},
      syncedAt: {...state.syncedAt}..remove(folderId),
    );
    _persistAll();
  }

  // ---------------------------------------------------------------- storage

  List<FavFolder> _loadFolders() {
    try {
      return [
        for (final entry in HivePrefUtil.getStringList(_foldersKey) ?? const <String>[])
          if (jsonDecode(entry) case final Map<String, dynamic> map) FavFolder.fromJson(map),
      ];
    } catch (_) {
      return const [];
    }
  }

  Map<int, List<MusicArchive>> _loadTracks() {
    try {
      final raw = HivePrefUtil.getString(_tracksKey);
      if (raw == null || raw.isEmpty) return {};
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      return {
        for (final entry in decoded.entries)
          ?int.tryParse(entry.key.toString()): [
            for (final item in (entry.value as List?) ?? const <dynamic>[])
              if (item is Map<String, dynamic>) MusicArchive.fromJson(item),
          ],
      };
    } catch (_) {
      return {};
    }
  }

  Map<int, DateTime> _loadTimes() {
    try {
      final raw = HivePrefUtil.getString(_timesKey);
      if (raw == null || raw.isEmpty) return {};
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      return {
        for (final entry in decoded.entries)
          ?int.tryParse(entry.key.toString()): DateTime.fromMillisecondsSinceEpoch(
            int.tryParse(entry.value.toString()) ?? 0,
          ),
      };
    } catch (_) {
      return {};
    }
  }

  void _persistAll() {
    HivePrefUtil.setStringList(_foldersKey, [for (final f in state.folders) jsonEncode(f.toJson())]);
    HivePrefUtil.setString(
      _tracksKey,
      jsonEncode({
        for (final entry in state.folderTracks.entries) entry.key.toString(): [for (final a in entry.value) a.toJson()],
      }),
    );
    HivePrefUtil.setString(
      _timesKey,
      jsonEncode({
        for (final entry in state.syncedAt.entries) entry.key.toString(): entry.value.millisecondsSinceEpoch,
      }),
    );
  }
}
