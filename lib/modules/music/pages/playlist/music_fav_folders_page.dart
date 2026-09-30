import 'package:flutter/material.dart';
import 'package:pure_live/app/router/app_router.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/modules/vod/models/models.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/modules/music/widgets/music_playlist_cards.dart';
import 'package:pure_live/services/theme_settings/theme_settings_controller.dart';
import 'package:pure_live/modules/music/pages/playlist/music_playlist_dialogs.dart';
import 'package:pure_live/modules/music/pages/playlist/music_playlist_import_dialog.dart';
import 'package:pure_live/modules/music/controllers/library/music_library_controller.dart';
import 'package:pure_live/modules/music/pages/playlist/music_user_playlist_detail_page.dart';
import 'package:pure_live/modules/music/controllers/playlist/music_playlist_sync_controller.dart';

/// bilibili fav folder synced down. Cards speak the dynamics-card visual —
/// cover on top, name and count beneath. OK opens the track table; long press
/// of those, it is the shelf's fixed head).
class MusicFavFoldersPage extends ConsumerWidget {
  const MusicFavFoldersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sync = ref.watch(musicPlaylistSyncControllerProvider);
    final syncController = ref.read(musicPlaylistSyncControllerProvider.notifier);
    final library = ref.watch(musicLibraryControllerProvider);
    final tvTheme = context.tvTheme;
    final accent = tvTheme.focusColor;

    final liked = MusicPlaylistEntry(
      id: MusicLibraryController.likedPlaylistId,
      name: i18n('music_liked_playlist'),
      tracks: library.likedSongs,
      pinned: true,
      isLiked: true,
    );
    final entries = <MusicPlaylistEntry>[
      liked,
      for (final playlist in library.orderedPlaylists)
        MusicPlaylistEntry(
          id: playlist.id,
          name: playlist.name,
          tracks: playlist.tracks,
          pinned: playlist.pinnedAt > 0,
          isLiked: false,
          playlist: playlist,
        ),
    ];

    if (library.playlists.isEmpty && sync.folders.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(24.ts(context), 16.ts(context), 24.ts(context), 8.ts(context)),
            child: Row(
              children: [
                Text(
                  '${i18n('music_playlists')}（1）',
                  style: AppTextStyles.t22.copyWith(fontWeight: FontWeight.w700, color: accent),
                ),
                const Spacer(),
                TvButton(
                  title: i18n('music_import_playlist'),
                  icon: Icon(Icons.download_rounded, size: 24.ts(context)),
                  size: TvButtonSize.mini,
                  onTap: () => showImportPlaylistDialog(context, ref),
                ),
                SizedBox(width: 12.ts(context)),
                TvButton(
                  title: i18n('music_create_playlist'),
                  icon: Icon(Icons.playlist_add_rounded, size: 24.ts(context)),
                  size: TvButtonSize.mini,
                  onTap: () => showPlaylistNameDialog(context, ref),
                ),
              ],
            ),
          ),
          Expanded(child: _shelfGrid(context, ref, entries, includeLoading: false)),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(24.ts(context), 16.ts(context), 24.ts(context), 8.ts(context)),
          child: Row(
            children: [
              Text(
                '${i18n('music_playlists')}（${entries.length + sync.folders.length}）',
                style: AppTextStyles.t22.copyWith(fontWeight: FontWeight.w700, color: accent),
              ),
              const Spacer(),
              // but this is the header people actually live in: a shelf that
              // already has playlists must not lose the import entry.
              TvButton(
                title: i18n('music_import_playlist'),
                icon: Icon(Icons.download_rounded, size: 24.ts(context)),
                size: TvButtonSize.mini,
                onTap: () => showImportPlaylistDialog(context, ref),
              ),
              SizedBox(width: 12.ts(context)),
              TvButton(
                title: i18n('music_create_playlist'),
                icon: Icon(Icons.playlist_add_rounded, size: 24.ts(context)),
                size: TvButtonSize.mini,
                onTap: () => showPlaylistNameDialog(context, ref),
              ),
              SizedBox(width: 12.ts(context)),
              if (sync.syncingFolderId != 0)
                SizedBox(
                  width: 28.ts(context),
                  height: 28.ts(context),
                  child: CircularProgressIndicator(strokeWidth: 3.ts(context), color: accent),
                )
              else
                TvButton(
                  title: i18n('music_sync_all'),
                  icon: Icon(Icons.sync_rounded, size: 24.ts(context)),
                  size: TvButtonSize.mini,
                  isSecondary: true,
                  onTap: syncController.syncAll,
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(24.ts(context), 8.ts(context), 24.ts(context), 24.ts(context)),
            children: [
              _shelfGrid(context, ref, entries, includeLoading: false),
              if (sync.folders.isNotEmpty) ...[
                SizedBox(height: 16.ts(context)),
                Text(
                  '${i18n('music_playlists_title')}（${sync.folders.length}）',
                  style: AppTextStyles.t18.copyWith(fontWeight: FontWeight.w600, color: tvTheme.secondaryTextColor),
                ),
                SizedBox(height: 12.ts(context)),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: ThemeSettingsController.cardGridDelegate(context, ref),
                  itemCount: sync.folders.length,
                  itemBuilder: (context, index) {
                    final folder = sync.folders[index];
                    final tracks = sync.folderTracks[folder.id] ?? const [];
                    final syncedAt = sync.syncedAt[folder.id];
                    final isSyncing = sync.syncingFolderId == folder.id;
                    // Folder art first; a bare folder falls to the first
                    // archive that carries a cover, like the local cards.
                    var cover = folder.cover;
                    if (cover.isEmpty) {
                      for (final archive in tracks) {
                        if (archive.cover.isNotEmpty) {
                          cover = archive.cover;
                          break;
                        }
                      }
                    }
                    return MusicFolderCard(
                      folder: folder,
                      cover: cover,
                      trackCount: tracks.length,
                      syncedAt: syncedAt,
                      isSyncing: isSyncing,
                      onOpen: () => MusicFavDetailRoute(folder).push(context),
                      onMenu: () => _showFolderMenu(context, ref, folder),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _shelfGrid(
    BuildContext context,
    WidgetRef ref,
    List<MusicPlaylistEntry> entries, {
    required bool includeLoading,
  }) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: TvAdaptiveGrid.media(
        context,
        // Six columns, not four: a playlist cover needs no detail to read, and
        // QQ music's shelf is dense — four turned every card into a poster.
        crossAxisCount: 6,
        mainAxisSpacing: 16.w,
        crossAxisSpacing: 16.w,
        childAspectRatio: 1.5,
      ),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return MusicPlaylistCard(
          entry: entry,
          onOpen: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => MusicUserPlaylistDetailPage(playlistId: entry.id))),
          onLongPress: entry.isLiked ? null : () => _showPlaylistMenu(context, ref, entry),
        );
      },
    );
  }

  Future<void> _showPlaylistMenu(BuildContext context, WidgetRef ref, MusicPlaylistEntry entry) async {
    final playlist = entry.playlist;
    if (playlist == null) return;
    final libraryController = ref.read(musicLibraryControllerProvider.notifier);

    await TvDialogUtils.show<void>(
      context: context,
      builder: (_) => TvDialog(
        title: playlist.name,
        cancelText: i18n('cancel'),
        width: 560.ts(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TvDialogOptionTile(
              title: i18n(playlist.pinnedAt > 0 ? 'music_unpin' : 'music_pin'),
              icon: Icon(
                playlist.pinnedAt > 0 ? Icons.vertical_align_bottom_rounded : Icons.vertical_align_top_rounded,
                size: 26.ts(context),
              ),
              showCheck: false,
              autofocus: true,
              onTap: () {
                Navigator.of(context).pop();
                libraryController.togglePlaylistPin(playlist.id);
              },
            ),
            TvDialogOptionTile(
              title: i18n('music_edit_playlist'),
              icon: Icon(Icons.edit_outlined, size: 26.ts(context)),
              showCheck: false,
              onTap: () {
                Navigator.of(context).pop();
                showPlaylistNameDialog(context, ref, playlist: playlist);
              },
            ),
            TvDialogOptionTile(
              title: i18n('music_clear_tracks'),
              icon: Icon(Icons.clear_all_rounded, size: 26.ts(context)),
              showCheck: false,
              onTap: () {
                Navigator.of(context).pop();
                _confirmClearPlaylist(context, ref, playlist);
              },
            ),
            TvDialogOptionTile(
              title: i18n('music_delete_playlist'),
              icon: Icon(Icons.delete_outline_rounded, size: 26.ts(context)),
              showCheck: false,
              onTap: () {
                Navigator.of(context).pop();
                _confirmDeletePlaylist(context, ref, playlist);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmClearPlaylist(BuildContext context, WidgetRef ref, MusicUserPlaylist playlist) async {
    await TvDialogUtils.show<void>(
      context: context,
      builder: (_) => TvDialog(
        title: i18n('music_clear_tracks'),
        confirmText: i18n('ui_confirm'),
        cancelText: i18n('cancel'),
        onConfirm: () {
          ref.read(musicLibraryControllerProvider.notifier).clearPlaylist(playlist.id);
          Navigator.of(context).pop();
        },
        child: Text(
          i18n('music_clear_tracks_confirm'),
          style: AppTextStyles.t20.copyWith(height: 1.5, color: context.tvTheme.primaryTextColor),
        ),
      ),
    );
  }

  /// re-syncable from the bilibili account, so neither action confirms — the
  /// local playlists' menu does, those tracks exist only here.
  Future<void> _showFolderMenu(BuildContext context, WidgetRef ref, FavFolder folder) async {
    final syncController = ref.read(musicPlaylistSyncControllerProvider.notifier);

    await TvDialogUtils.show<void>(
      context: context,
      builder: (_) => TvDialog(
        title: folder.title,
        cancelText: i18n('cancel'),
        width: 560.ts(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TvDialogOptionTile(
              title: i18n('music_sync_folder'),
              icon: Icon(Icons.sync_rounded, size: 26.ts(context)),
              showCheck: false,
              autofocus: true,
              onTap: () {
                Navigator.of(context).pop();
                syncController.syncFolder(folder.id);
              },
            ),
            TvDialogOptionTile(
              title: i18n('music_clear_tracks'),
              icon: Icon(Icons.clear_all_rounded, size: 26.ts(context)),
              showCheck: false,
              onTap: () {
                Navigator.of(context).pop();
                syncController.clearFolderTracks(folder.id);
              },
            ),
            TvDialogOptionTile(
              title: i18n('music_delete_playlist'),
              icon: Icon(Icons.delete_outline_rounded, size: 26.ts(context)),
              showCheck: false,
              onTap: () {
                Navigator.of(context).pop();
                syncController.removeFolder(folder.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeletePlaylist(BuildContext context, WidgetRef ref, MusicUserPlaylist playlist) async {
    await TvDialogUtils.show<void>(
      context: context,
      builder: (_) => TvDialog(
        title: i18n('music_delete_playlist'),
        confirmText: i18n('ui_confirm'),
        cancelText: i18n('cancel'),
        onConfirm: () {
          ref.read(musicLibraryControllerProvider.notifier).deletePlaylist(playlist.id);
          Navigator.of(context).pop();
        },
        child: Text(
          i18n('music_delete_playlist_confirm'),
          style: AppTextStyles.t20.copyWith(height: 1.5, color: context.tvTheme.primaryTextColor),
        ),
      ),
    );
  }
}
