import 'package:cached_network_image/cached_network_image.dart';
import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

import 'package:pure_live/app/router/app_router.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:pure_live/modules/media/models/bilibili_ugc_models.dart';
import 'package:pure_live/modules/music/controllers/playlist/music_playlist_sync_controller.dart';

/// The synced-playlist shelf (bmsc's fav screen): every bilibili fav folder
/// that has been pulled down, with a per-folder sync and a sync-all. The
/// content is cached in the music module's own Hive keys — nothing here is
/// shared with video.
class MusicFavFoldersPage extends ConsumerWidget {
  const MusicFavFoldersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sync = ref.watch(musicPlaylistSyncControllerProvider);
    final syncController = ref.read(musicPlaylistSyncControllerProvider.notifier);
    final tvTheme = context.tvTheme;
    final accent = tvTheme.focusColor;

    if (sync.folders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.playlist_add_check_rounded, size: 88.sp, color: tvTheme.secondaryTextColor),
            SizedBox(height: 16.sp),
            Text(i18n('music_sync_empty'), style: AppTextStyles.t20W600.copyWith(color: tvTheme.primaryTextColor)),
            SizedBox(height: 8.sp),
            Text(
              i18n('music_sync_empty_hint'),
              style: AppTextStyles.t14.copyWith(color: tvTheme.secondaryTextColor),
            ),
            SizedBox(height: 24.sp),
            TvButton(
              title: i18n('music_sync_all'),
              icon: Icon(Icons.sync_rounded, size: 26.sp),
              onTap: syncController.syncAll,
            ),
          ],
        ),
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
                '${i18n('music_playlists_title')}（${sync.folders.length}）',
                style: AppTextStyles.t22W700.copyWith(color: accent),
              ),
              const Spacer(),
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
                  onTap: syncController.syncAll,
                ),
            ],
          ),
        ),
        Expanded(
          child: DpadRegion(
            horizontalEdge: DpadEdgeBehavior.leave,
            child: GridView.builder(
              padding: EdgeInsets.fromLTRB(24.sp, 8.sp, 24.sp, 24.sp),
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
                return _FolderCard(
                  folder: folder,
                  trackCount: tracks.length,
                  syncedAt: syncedAt,
                  isSyncing: isSyncing,
                  onOpen: () => MusicFavDetailRoute(folder).push(context),
                  onSync: () => syncController.syncFolder(folder.id),
                  onRemove: () => syncController.removeFolder(folder.id),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _FolderCard extends StatelessWidget {
  const _FolderCard({
    required this.folder,
    required this.trackCount,
    required this.syncedAt,
    required this.isSyncing,
    required this.onOpen,
    required this.onSync,
    required this.onRemove,
  });

  final FavFolder folder;
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
                    child: folder.cover.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: folder.cover,
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
                        style: AppTextStyles.t14W600.copyWith(color: Colors.white),
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
                    style: AppTextStyles.t16W600.copyWith(color: tvTheme.primaryTextColor),
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
