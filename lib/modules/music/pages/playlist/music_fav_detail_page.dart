import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

import 'package:pure_live/app/router/app_router.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:pure_live/modules/media/models/bilibili_music_models.dart';
import 'package:pure_live/modules/media/models/bilibili_ugc_models.dart';
import 'package:pure_live/modules/media/controllers/music_player_controller.dart';
import 'package:pure_live/modules/music/controllers/playlist/music_playlist_sync_controller.dart';

/// One synced playlist's track table (bmsc's fav detail): an in-list search
/// filter, play all with the excluded parts filtered out, and the 排除分P
/// toggle on the focused tile.
class MusicFavDetailPage extends ConsumerStatefulWidget {
  const MusicFavDetailPage({super.key, required this.folder});

  final FavFolder folder;

  @override
  ConsumerState<MusicFavDetailPage> createState() => _MusicFavDetailPageState();
}

class _MusicFavDetailPageState extends ConsumerState<MusicFavDetailPage> {
  final TextEditingController _filter = TextEditingController();

  @override
  void dispose() {
    _filter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final folder = widget.folder;
    final sync = ref.watch(musicPlaylistSyncControllerProvider);
    final tvTheme = context.tvTheme;
    final keyword = _filter.text.trim().toLowerCase();
    final sources = sync.folderTracks[folder.id] ?? const <MusicArchive>[];
    final tracks = <MusicTrack>[
      for (final archive in sources)
        if (keyword.isEmpty ||
            archive.title.toLowerCase().contains(keyword) ||
            archive.upName.toLowerCase().contains(keyword))
          ...archive.tracks,
    ];

    return TvPageScaffold(
      title: folder.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(24.sp, 12.sp, 24.sp, 8.sp),
            child: Row(
              children: [
                Text(
                  '${tracks.length} ${i18n('music_tracks_unit')}',
                  style: AppTextStyles.t18W500.copyWith(color: tvTheme.secondaryTextColor),
                ),
                SizedBox(width: 16.sp),
                SizedBox(
                  width: 320.sp,
                  child: TvInputField(
                    controller: _filter,
                    hint: i18n('music_playlist_filter_hint'),
                    height: 56.sp,
                    maxLines: 1,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                SizedBox(width: 16.sp),
                Text(
                  i18n('music_excluded_hint'),
                  style: AppTextStyles.t14.copyWith(color: tvTheme.secondaryTextColor),
                ),
                const Spacer(),
                TvButton(
                  title: i18n('music_play_all'),
                  icon: Icon(Icons.play_circle_fill_rounded, size: 26.sp),
                  size: TvButtonSize.mini,
                  onTap: tracks.isEmpty
                      ? null
                      : () => _playAll(context, ref, tracks),
                ),
                SizedBox(width: 12.sp),
                TvButton(
                  title: i18n('music_sync_this'),
                  icon: Icon(Icons.sync_rounded, size: 24.sp),
                  size: TvButtonSize.mini,
                  isSecondary: true,
                  onTap: () => ref.read(musicPlaylistSyncControllerProvider.notifier).syncFolder(folder.id),
                ),
              ],
            ),
          ),
          Expanded(
            child: tracks.isEmpty
                ? AppStatusView(type: AppStatusType.empty, title: i18n('music_sync_not_yet'), subtitle: '')
                : ListView.builder(
                    padding: EdgeInsets.fromLTRB(24.sp, 4.sp, 24.sp, 24.sp),
                    itemCount: tracks.length,
                    itemBuilder: (context, index) => _TrackRow(
                      track: tracks[index],
                      index: index,
                      excluded: ref
                          .read(musicPlaylistSyncControllerProvider.notifier)
                          .excludedParts(tracks[index].archive.bvid)
                          .contains(tracks[index].part.cid),
                      onPlay: () => _playFrom(context, ref, tracks, index),
                      onToggleExcluded: () => ref
                          .read(musicPlaylistSyncControllerProvider.notifier)
                          .toggleExcludedPart(tracks[index].archive.bvid, tracks[index].part.cid),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _playAll(BuildContext context, WidgetRef ref, List<MusicTrack> tracks) {
    final filtered = ref.read(musicPlaylistSyncControllerProvider.notifier).filterExcluded(tracks);
    ref.read(musicPlayerControllerProvider.notifier).playQueue(filtered);
    const MusicPlayerRoute().push(context);
  }

  void _playFrom(BuildContext context, WidgetRef ref, List<MusicTrack> tracks, int index) {
    final filtered = ref.read(musicPlaylistSyncControllerProvider.notifier).filterExcluded(tracks);
    final at = filtered.indexWhere((t) => t.id == tracks[index].id);
    ref.read(musicPlayerControllerProvider.notifier).playQueue(filtered, startIndex: at < 0 ? 0 : at);
    const MusicPlayerRoute().push(context);
  }
}

class _TrackRow extends StatelessWidget {
  const _TrackRow({
    required this.track,
    required this.index,
    required this.excluded,
    required this.onPlay,
    required this.onToggleExcluded,
  });

  final MusicTrack track;
  final int index;
  final bool excluded;
  final VoidCallback onPlay;
  final VoidCallback onToggleExcluded;

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final accent = tvTheme.focusColor;

    return TvFocusable(
      onTap: onPlay,
      onLongPress: onToggleExcluded,
      builder: (context, focused, child) => AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        margin: EdgeInsets.only(bottom: 8.sp),
        height: 72.sp,
        padding: EdgeInsets.symmetric(horizontal: 16.sp),
        decoration: BoxDecoration(
          color: excluded ? tvTheme.cardColor.withValues(alpha: 0.4) : tvTheme.cardColor,
          borderRadius: BorderRadius.circular(14.sp),
          border: Border.all(color: focused ? accent : Colors.transparent, width: 2.sp),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 44.sp,
              child: Text(
                '${index + 1}',
                style: AppTextStyles.t18W500.copyWith(color: tvTheme.secondaryTextColor),
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.t16W500.copyWith(
                      color: excluded ? tvTheme.secondaryTextColor : tvTheme.primaryTextColor,
                    ),
                  ),
                  Text(
                    track.archive.upName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.t14.copyWith(color: tvTheme.secondaryTextColor),
                  ),
                ],
              ),
            ),
            if (focused)
              TvIconButton(
                icon: Icon(excluded ? Icons.filter_alt_off_rounded : Icons.filter_alt_rounded),
                label: i18n(excluded ? 'music_exclude_off' : 'music_exclude_on'),
                size: TvIconButtonSize.small,
                isSecondary: true,
                onTap: onToggleExcluded,
              ),
          ],
        ),
      ),
    );
  }
}
