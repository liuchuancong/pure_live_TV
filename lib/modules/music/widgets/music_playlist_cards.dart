import 'package:pure_live/exports/exports.dart';
import 'package:pure_live/modules/vod/models/models.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pure_live/modules/music/controllers/library/music_library_controller.dart';

/// One shelf entry as the page sees it — the liked head and the stored
/// playlists share a shape.
class MusicPlaylistEntry {
  const MusicPlaylistEntry({
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

class MusicPlaylistCard extends StatelessWidget {
  const MusicPlaylistCard({super.key, required this.entry, required this.onOpen, required this.onLongPress});

  final MusicPlaylistEntry entry;
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
                  borderRadius: BorderRadius.circular(24.ts(context)),
                  border: Border.all(color: focused ? accent : Colors.transparent, width: 2.ts(context)),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: focused ? 0.4 : 0),
                      blurRadius: focused ? 18.ts(context) : 0,
                      spreadRadius: 1.5.ts(context),
                    ),
                  ],
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24.ts(context)),
                      child: cover.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: cover,
                              fit: BoxFit.cover,
                              memCacheWidth: 480,
                              errorWidget: (_, _, _) => _fallback(context, accent),
                            )
                          : _fallback(context, accent),
                    ),
                    if (entry.pinned)
                      Positioned(
                        left: 12.sp,
                        top: 12.sp,
                        child: TvCoverChip(icon: Icons.push_pin_rounded, label: ''),
                      ),
                    Positioned(
                      right: 12.sp,
                      bottom: 12.sp,
                      child: TvCoverChip(label: '${entry.tracks.length}'),
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
                    Icon(Icons.favorite_rounded, size: 22.ts(context), color: accent),
                    SizedBox(width: 6.ts(context)),
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

  Widget _fallback(BuildContext context, Color accent) => Container(
    color: accent.withValues(alpha: 0.15),
    child: Icon(Icons.library_music_rounded, size: 64.ts(context), color: accent),
  );
}

class MusicFolderCard extends StatelessWidget {
  const MusicFolderCard({
    super.key,
    required this.folder,
    required this.cover,
    required this.trackCount,
    required this.syncedAt,
    required this.isSyncing,
    required this.onOpen,
    required this.onMenu,
  });

  final FavFolder folder;
  final String cover;
  final int trackCount;
  final DateTime? syncedAt;
  final bool isSyncing;
  final VoidCallback onOpen;

  /// the page — the card itself only opens.
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final accent = tvTheme.focusColor;
    final syncedAtLocal = syncedAt;

    return TvFocusable(
      autofocus: false,
      onTap: onOpen,
      onLongPress: onMenu,
      builder: (context, focused, child) => AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: tvTheme.cardColor,
          borderRadius: BorderRadius.circular(16.ts(context)),
          border: Border.all(color: focused ? accent : Colors.transparent, width: 2.5.ts(context)),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: focused ? 0.25 : 0),
              blurRadius: focused ? 18.ts(context) : 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16.ts(context))),
                    child: cover.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: cover,
                            fit: BoxFit.cover,
                            memCacheWidth: 480,
                            errorWidget: (_, _, _) => _coverFallback(context, accent),
                          )
                        : _coverFallback(context, accent),
                  ),
                  Positioned(
                    right: 8.sp,
                    top: 8.sp,
                    child: TvCoverChip(label: isSyncing ? '...' : '${folder.mediaCount}'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(10.ts(context)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    folder.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.t16.copyWith(fontWeight: FontWeight.w600, color: tvTheme.primaryTextColor),
                  ),
                  SizedBox(height: 4.ts(context)),
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

  Widget _coverFallback(BuildContext context, Color accent) => Container(
    color: accent.withValues(alpha: 0.15),
    child: Icon(Icons.playlist_play_rounded, size: 64.ts(context), color: accent),
  );
}
