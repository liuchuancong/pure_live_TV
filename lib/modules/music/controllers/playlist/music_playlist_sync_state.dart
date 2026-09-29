import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pure_live/modules/vod/models/models.dart';

part 'music_playlist_sync_state.freezed.dart';

/// The synced-playlist state (bmsc's fav-list caching): bilibili fav folders
/// pulled down into Hive so the playlists open offline and survive restarts.
@freezed
abstract class MusicPlaylistSyncState with _$MusicPlaylistSyncState {
  const factory MusicPlaylistSyncState({
    /// Cached fav folders (created ones; collected folders sync on demand).
    @Default([]) List<FavFolder> folders,

    /// Folder id → cached archives.
    @Default({}) Map<int, List<MusicArchive>> folderTracks,

    /// Folder id → time of the last full sync.
    @Default({}) Map<int, DateTime> syncedAt,

    /// The folder currently refreshing (0 = none).
    @Default(0) int syncingFolderId,

    /// Last sync error, surfaced on the playlist page.
    @Default('') String error,
  }) = _MusicPlaylistSyncState;
}
