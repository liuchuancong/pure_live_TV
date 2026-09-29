import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

import 'package:pure_live/app/router/app_router.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:pure_live/modules/media/models/models.dart';
import 'package:pure_live/modules/music/controllers/library/music_library_controller.dart';
import 'package:pure_live/modules/music/controllers/playlist/music_playlist_sync_controller.dart';
import 'package:pure_live/modules/music/pages/playlist/music_playlist_dialogs.dart';
import 'package:pure_live/modules/music/pages/playlist/music_playlist_import_dialog.dart';
import 'package:pure_live/modules/music/pages/playlist/music_user_playlist_detail_page.dart';

/// The playlist shelf, QQ music's 我的歌单 shape: the default 喜欢 playlist
/// mounted on top, then the locally created ones (置顶 first), then every
/// bilibili fav folder synced down. Cards speak the dynamics-card visual —
/// cover on top, name and count beneath. OK opens the track table; long press
/// opens the playlist menu (置顶 / 编辑 / 删除 — the liked playlist has none
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

    final liked = _PlaylistEntry(
      id: MusicLibraryController.likedPlaylistId,
      name: i18n('music_liked_playlist'),
      tracks: library.likedSongs,
      pinned: true,
      isLiked: true,
    );
    final entries = <_PlaylistEntry>[
      liked,
      for (final playlist in library.orderedPlaylists)
        _PlaylistEntry(
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
            padding: EdgeInsets.fromLTRB(24.sp, 16.sp, 24.sp, 8.sp),
            child: Row(
              children: [
                Text(
                  '${i18n('music_playlists')}（1）',
                  style: AppTextStyles.t22.copyWith(fontWeight: FontWeight.w700, color: accent),
                ),
                const Spacer(),
                TvButton(
                  title: i18n('music_import_playlist'),
                  icon: Icon(Icons.download_rounded, size: 24.sp),
                  size: TvButtonSize.mini,
                  onTap: () => showImportPlaylistDialog(context, ref),
                ),
                SizedBox(width: 12.sp),
                TvButton(
                  title: i18n('music_create_playlist'),
                  icon: Icon(Icons.playlist_add_rounded, size: 24.sp),
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
          padding: EdgeInsets.fromLTRB(24.sp, 16.sp, 24.sp, 8.sp),
          child: Row(
            children: [
              Text(
                '${i18n('music_playlists')}（${entries.length + sync.folders.length}）',
                style: AppTextStyles.t22.copyWith(fontWeight: FontWeight.w700, color: accent),
              ),
              const Spacer(),
              TvButton(
                title: i18n('music_create_playlist'),
                icon: Icon(Icons.playlist_add_rounded, size: 24.sp),
                size: TvButtonSize.mini,
                onTap: () => showPlaylistNameDialog(context, ref),
              ),
              SizedBox(width: 12.sp),
              if (sync.syncingFolderId != 0)
                SizedBox(
                  width: 28.sp,
                  height: 28.sp,
                  child: CircularProgressIndicator(strokeWidth: 3.sp, color: accent),
                )
              else
                TvButton(
                  title: i18n('music_sync_all'),
                  icon: Icon(Icons.sync_rounded, size: 24.sp),
                  size: TvButtonSize.mini,
                  isSecondary: true,
                  onTap: syncController.syncAll,
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(24.sp, 8.sp, 24.sp, 24.sp),
            children: [
              _shelfGrid(context, ref, entries, includeLoading: false),
              if (sync.folders.isNotEmpty) ...[
                SizedBox(height: 16.sp),
                Text(
                  '${i18n('music_playlists_title')}（${sync.folders.length}）',
                  style: AppTextStyles.t18.copyWith(fontWeight: FontWeight.w600, color: tvTheme.secondaryTextColor),
                ),
                SizedBox(height: 12.sp),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 16.w,
                    crossAxisSpacing: 16.w,
                    childAspectRatio: 1.15,
                  ),
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
                    return _FolderCard(
                      folder: folder,
                      cover: cover,
                      trackCount: tracks.length,
                      syncedAt: syncedAt,
                      isSyncing: isSyncing,
                      onOpen: () => MusicFavDetailRoute(folder).push(context),
                      onSync: () => syncController.syncFolder(folder.id),
                      onRemove: () => syncController.removeFolder(folder.id),
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

  Widget _shelfGrid(BuildContext context, WidgetRef ref, List<_PlaylistEntry> entries, {required bool includeLoading}) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 16.w,
        crossAxisSpacing: 16.w,
        childAspectRatio: 0.95,
      ),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return _PlaylistCard(
          entry: entry,
          onOpen: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => MusicUserPlaylistDetailPage(playlistId: entry.id)),
          ),
          onLongPress: entry.isLiked ? null : () => _showPlaylistMenu(context, ref, entry),
        );
      },
    );
  }

  /// Long press on a locally created playlist: 置顶 / 编辑 / 删除.
  Future<void> _showPlaylistMenu(BuildContext context, WidgetRef ref, _PlaylistEntry entry) async {
    final playlist = entry.playlist;
    if (playlist == null) return;
    final libraryController = ref.read(musicLibraryControllerProvider.notifier);

    await TvDialogUtils.show<void>(
      context: context,
      builder: (_) => TvDialog(
        title: playlist.name,
        cancelText: i18n('cancel'),
        width: 560.sp,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TvDialogOptionTile(
              title: i18n(playlist.pinnedAt > 0 ? 'music_unpin' : 'music_pin'),
              icon: Icon(
                playlist.pinnedAt > 0 ? Icons.vertical_align_bottom_rounded : Icons.vertical_align_top_rounded,
                size: 26.sp,
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
              icon: Icon(Icons.edit_outlined, size: 26.sp),
              showCheck: false,
              onTap: () {
                Navigator.of(context).pop();
                showPlaylistNameDialog(context, ref, playlist: playlist);
              },
            ),
            TvDialogOptionTile(
              title: i18n('music_delete_playlist'),
              icon: Icon(Icons.delete_outline_rounded, size: 26.sp),
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

/// One shelf entry as the page sees it — the liked head and the stored
/// playlists share a shape.
class _PlaylistEntry {
  const _PlaylistEntry({
    required this.id,
    required this.name,
    required this.tracks,
    required this.pinned,
    required this.isLiked,
    this.playlist,
  });

  final String id;
  final String name;
  final List<MusicTrack> tracks;
  final bool pinned;
  final bool isLiked;
  final MusicUserPlaylist? playlist;
}

/// The dynamics-card visual for a playlist: cover on top (the first track
/// that carries one), name and count beneath, a 置顶 badge when pinned.
class _PlaylistCard extends StatelessWidget {
  const _PlaylistCard({required this.entry, required this.onOpen, required this.onLongPress});

  final _PlaylistEntry entry;
  final VoidCallback onOpen;
  final VoidCallback? onLongPress;

  String get _cover {
    for (final track in entry.tracks) {
      if (track.archive.cover.isNotEmpty) return track.archive.cover;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final accent = tvTheme.focusColor;
    final cover = _cover;

    return TvFocusable(
      onTap: onOpen,
      onLongPress: onLongPress,
      builder: (context, focused, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  color: tvTheme.cardColor,
                  borderRadius: BorderRadius.circular(24.sp),
                  border: Border.all(color: focused ? accent : Colors.transparent, width: 2.sp),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: focused ? 0.4 : 0),
                      blurRadius: focused ? 18.sp : 0,
                      spreadRadius: 1.5.sp,
                    ),
                  ],
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24.sp),
                      child: cover.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: cover,
                              fit: BoxFit.cover,
                              memCacheWidth: 480,
                              errorWidget: (_, _, _) => _fallback(accent),
                            )
                          : _fallback(accent),
                    ),
                    if (entry.pinned)
                      Positioned(
                        left: 12.sp,
                        top: 12.sp,
                        child: Container(
                          padding: EdgeInsets.all(6.sp),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(10.sp),
                          ),
                          child: Icon(Icons.push_pin_rounded, size: 22.sp, color: Colors.white),
                        ),
                      ),
                    Positioned(
                      right: 12.sp,
                      bottom: 12.sp,
                      child: TvButton(excludeFocus: true, title: '${entry.tracks.length}', size: TvButtonSize.mini),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 4.sp),
              child: Row(
                children: [
                  if (entry.isLiked) ...[
                    Icon(Icons.favorite_rounded, size: 22.sp, color: accent),
                    SizedBox(width: 6.sp),
                  ],
                  Expanded(
                    child: Text(
                      entry.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.t16.copyWith(fontWeight: FontWeight.w600, color: tvTheme.primaryTextColor),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _fallback(Color accent) => Container(
    color: accent.withValues(alpha: 0.15),
    child: Icon(Icons.library_music_rounded, size: 64.sp, color: accent),
  );
}

class _FolderCard extends StatelessWidget {
  const _FolderCard({
    required this.folder,
    required this.cover,
    required this.trackCount,
    required this.syncedAt,
    required this.isSyncing,
    required this.onOpen,
    required this.onSync,
    required this.onRemove,
  });

  final FavFolder folder;
  final String cover;
  final int trackCount;
  final DateTime? syncedAt;
  final bool isSyncing;
  final VoidCallback onOpen;
  final VoidCallback onSync;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final accent = tvTheme.focusColor;
    final syncedAtLocal = syncedAt;

    return TvFocusable(
      autofocus: false,
      onTap: onOpen,
      onLongPress: onSync,
      builder: (context, focused, child) => AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: tvTheme.cardColor,
          borderRadius: BorderRadius.circular(16.sp),
          border: Border.all(color: focused ? accent : Colors.transparent, width: 2.5.sp),
          boxShadow: [BoxShadow(color: accent.withValues(alpha: focused ? 0.25 : 0), blurRadius: focused ? 18.sp : 0)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16.sp)),
                    child: cover.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: cover,
                            fit: BoxFit.cover,
                            memCacheWidth: 480,
                            errorWidget: (_, _, _) => _coverFallback(accent),
                          )
                        : _coverFallback(accent),
                  ),
                  Positioned(
                    right: 8.sp,
                    top: 8.sp,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.sp, vertical: 4.sp),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(10.sp),
                      ),
                      child: Text(
                        isSyncing ? '...' : '${folder.mediaCount}',
                        style: AppTextStyles.t14.copyWith(fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(10.sp),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    folder.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.t16.copyWith(fontWeight: FontWeight.w600, color: tvTheme.primaryTextColor),
                  ),
                  SizedBox(height: 4.sp),
                  Text(
                    syncedAtLocal == null
                        ? i18n('music_sync_not_yet')
                        : '${i18n('music_synced_at')} ${syncedAtLocal.month}/${syncedAtLocal.day}',
                    style: AppTextStyles.t14.copyWith(color: tvTheme.secondaryTextColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _coverFallback(Color accent) => Container(
    color: accent.withValues(alpha: 0.15),
    child: Icon(Icons.playlist_play_rounded, size: 64.sp, color: accent),
  );
}
