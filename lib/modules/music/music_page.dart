import 'dart:async';
import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:media_core/media_core.dart';
import 'package:pure_live/app/router/app_router.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/features/home/home_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pure_live/modules/media/api/bilibili_ugc_api.dart';
import 'package:pure_live/modules/media/api/bilibili_music_api.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/modules/media/pages/ugc_dynamics_page.dart';
import 'package:pure_live/modules/music/widgets/music_song_menu.dart';
import 'package:pure_live/modules/media/widgets/music_video_card.dart';
import 'package:pure_live/modules/media/models/models.dart';
import 'package:pure_live/modules/music/services/music_list_reveal.dart';
import 'package:pure_live/modules/media/controllers/music_player_controller.dart';
import 'package:pure_live/services/theme_settings/theme_settings_controller.dart';
import 'package:pure_live/modules/music/pages/music_follow_pane.dart';
import 'package:pure_live/modules/music/pages/playlist/music_fav_folders_page.dart';
import 'package:pure_live/modules/music/pages/playlist/music_playlist_dialogs.dart';
import 'package:pure_live/modules/music/services/daily_recommendation_service.dart';
import 'package:pure_live/modules/music/pages/discover/music_cloud_history_page.dart';
import 'package:pure_live/modules/music/controllers/library/music_library_controller.dart';

/// The UP's signature line for the artist cards, cached in Hive: one wbi
/// request per UP, once ever — the caption is static.
final musicUpSignProvider = FutureProvider.family<String, int>((ref, mid) async {
  final cached = HivePrefUtil.getString('musicUpSign_$mid');
  if (cached != null) return cached;
  try {
    final sign = await BilibiliUgcApi.instance.getUserSign(mid);
    await HivePrefUtil.setString('musicUpSign_$mid', sign);
    return sign;
  } catch (_) {
    return '';
  }
});

/// Music mode sections. The section rail itself lives in the home sidebar —
/// this file only builds section content, so the mode swaps the whole
/// navigation instead of nesting its own.
enum MusicSection { favorites, daily, recents, playlists, dynamics, history, ranking, followedUps, search }

/// The rail's four destinations, newBV's top-tab pattern: 搜索 and 歌单 on
/// their own (a single-section group renders bare, no tab bar), then the
/// discovery tabs (每日/动态/排行) and the library tabs (关注/最近/云端).
/// The rail highlights the group; the content pane's tab bar picks the section.
const List<List<MusicSection>> kMusicRailGroups = [
  [MusicSection.search],
  [MusicSection.playlists],
  [MusicSection.daily, MusicSection.dynamics, MusicSection.ranking],
  [MusicSection.favorites, MusicSection.recents, MusicSection.history, MusicSection.followedUps],
];

/// Which rail group [section] belongs to.
int musicRailIndexFor(MusicSection section) =>
    kMusicRailGroups.indexWhere((group) => group.contains(section));

/// The tab-bar label of one section (two-character forms, the rail's short keys).
String _musicSectionTabLabel(MusicSection section) => switch (section) {
  MusicSection.search => i18n('music_tab_search'),
  MusicSection.daily => i18n('music_short_daily'),
  MusicSection.dynamics => i18n('music_dynamics'),
  MusicSection.ranking => i18n('music_short_ranking'),
  MusicSection.favorites => i18n('music_favorites'),
  MusicSection.recents => i18n('music_short_recents'),
  MusicSection.playlists => i18n('music_short_playlists'),
  MusicSection.history => i18n('music_short_history'),
  MusicSection.followedUps => i18n('music_tab_follow'),
};

/// Content of one music section. The section rail lives in the home sidebar;
/// login is enforced by the home shell's BilibiliLoginGate, not here.
///
/// A multi-section group carries the newBV-style top tab bar: it names the
/// group's sections and swaps the content below; single-section groups
/// (搜索) render bare.
class MusicSectionView extends ConsumerWidget {
  const MusicSectionView({super.key, required this.section});

  final MusicSection section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = kMusicRailGroups[musicRailIndexFor(section)];
    final Widget content = switch (section) {
      MusicSection.favorites => const _FollowSection(key: ValueKey('music_favorites')),
      MusicSection.daily => const _DailySection(key: ValueKey('music_daily')),
      MusicSection.recents => _SongListSection(key: const ValueKey('music_recents'), section: MusicSection.recents),
      MusicSection.playlists => const MusicFavFoldersPage(key: ValueKey('music_playlists')),
      MusicSection.dynamics => const UgcDynamicsPage(key: ValueKey('music_dynamics')),
      MusicSection.history => const MusicCloudHistoryPage(key: ValueKey('music_history')),
      MusicSection.followedUps => const MusicFollowPane(key: ValueKey('music_followed_ups')),
      MusicSection.ranking => const _RankingSection(key: ValueKey('music_ranking')),
      MusicSection.search => const _SearchSection(key: ValueKey('music_search')),
    };

    if (group.length == 1) return content;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(24.sp, 12.sp, 24.sp, 0),
          child: TvTabBar(
            tabs: [for (final s in group) TvTabItemData(title: _musicSectionTabLabel(s))],
            currentIndex: group.indexOf(section),
            showRefreshLine: false,
            onTabChange: (index) => ref.read(musicSectionIndexProvider.notifier).change(group[index].index),
          ),
        ),
        Expanded(child: content),
      ],
    );
  }
}


/// Favorites / Recently played: the QQ music song-table — index, cover, title+singer,
/// duration — with a Play all header and long-press removal.
class _SongListSection extends ConsumerStatefulWidget {
  const _SongListSection({super.key, required this.section});

  final MusicSection section;

  @override
  ConsumerState<_SongListSection> createState() => _SongListSectionState();
}

class _SongListSectionState extends ConsumerState<_SongListSection> {
  final MusicListReveal _reveal = MusicListReveal();

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final section = widget.section;
    final library = ref.watch(musicLibraryControllerProvider);
    final libraryController = ref.read(musicLibraryControllerProvider.notifier);
    final tvTheme = context.tvTheme;
    final accent = tvTheme.focusColor;
    final archives = section == MusicSection.favorites ? library.favorites : library.recents;
    final isFavorites = section == MusicSection.favorites;

    final tracks = [for (final archive in archives) ...archive.tracks];

    if (archives.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isFavorites ? Icons.favorite_border_rounded : Icons.history_rounded,
              size: 72.sp,
              color: accent.withValues(alpha: 0.5),
            ),
            SizedBox(height: 14.sp),
            Text(
              i18n(isFavorites ? 'music_empty_favorites' : 'music_empty_recents'),
              style: AppTextStyles.t18.copyWith(fontWeight: FontWeight.w500, color: tvTheme.secondaryTextColor),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(20.sp, 16.sp, 20.sp, 10.sp),
          child: Row(
            children: [
              Text(
                // The list shows every track of every archive flattened, so the
                // count must be the row count, not the archive count.
                '${i18n(isFavorites ? 'music_favorites' : 'music_recents')}（${tracks.length}）',
                style: AppTextStyles.t24.copyWith(fontWeight: FontWeight.w700, color: tvTheme.primaryTextColor),
              ),
              const Spacer(),
              // One press from anywhere above the long list: the mini bar's
              // destination is the full player anyway.
              TvButton(
                title: i18n('music_now_playing'),
                icon: Icon(Icons.music_note_rounded, size: 24.sp),
                size: TvButtonSize.mini,
                isSecondary: true,
                onTap: () => const MusicPlayerRoute().push(context),
              ),
              SizedBox(width: 12.sp),
              TvButton(
                title: i18n('music_play_all'),
                icon: Icon(Icons.play_circle_fill_rounded, size: 28.sp),
                size: TvButtonSize.mini,
                onTap: () => _play(context, ref, tracks, 0),
              ),
              if (!isFavorites) ...[
                SizedBox(width: 12.sp),
                TvButton(
                  title: i18n('music_clear_recents'),
                  icon: Icon(Icons.delete_outline_rounded, size: 24.sp),
                  size: TvButtonSize.mini,
                  isSecondary: true,
                  onTap: () => libraryController.clearRecents(),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: DpadRegion(
            verticalEdge: DpadEdgeBehavior.leave,
            horizontalEdge: DpadEdgeBehavior.leave,
            child: ListView.separated(
              padding: EdgeInsets.only(left: 20.sp, right: 20.sp, bottom: 16.sp, top: 16.sp),
              itemCount: tracks.length,
              separatorBuilder: (_, _) => SizedBox(height: 4.sp),
              itemBuilder: (context, index) {
                final track = tracks[index];
                _reveal.bindRow(track, context);
                return _SongRow(
                  track: track,
                  index: index,
                  focusNode: _reveal.nodeFor(track),
                  onPlay: () => _play(context, ref, tracks, index),
                  onRemove: () => showMusicSongMenu(
                    context,
                    ref,
                    track: track,
                    remove: isFavorites ? MusicSongMenuRemove.none : MusicSongMenuRemove.recent,
                    removeLabelKey: 'music_remove_from_recent',
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _play(BuildContext context, WidgetRef ref, List<MusicTrack> tracks, int startIndex) async {
    ref.read(musicPlayerControllerProvider.notifier).playQueue(tracks, startIndex: startIndex);
    await const MusicPlayerRoute().push(context);
    // Back from the player: the list meets the viewer at the playing row.
    if (!mounted) return;
    _reveal.reveal(this.context, tracks, ref.read(musicPlayerControllerProvider).current);
  }
}

/// One song row in the bmsc TrackTile shape, at TV size: a wide cover, the
/// title, then icon-led metadata lines — album over author, and for multi-P
/// archives the part count (with the excluded count in red, like the
/// reference's `(-n)`) and the duration. Long press removes it from the list.
class _SongRow extends ConsumerWidget {
  const _SongRow({
    required this.track,
    required this.index,
    required this.onPlay,
    required this.onRemove,
    this.focusNode,
  });

  final MusicTrack track;
  final int index;
  final VoidCallback onPlay;
  final VoidCallback onRemove;

  /// External node for callers that steer focus programmatically (the playing
  /// row on return from the player). Null keeps DpadFocusable's own.
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tvTheme = context.tvTheme;
    final accent = tvTheme.focusColor;
    final state = ref.watch(musicPlayerControllerProvider);
    final library = ref.watch(musicLibraryControllerProvider);
    final isCurrent = state.current?.archive.bvid == track.archive.bvid && state.current?.part.page == track.part.page;
    final isMulti = track.archive.parts.length > 1;
    final excludedCount = library.excludedCids(track.archive.bvid).length;

    return TvFocusable(
      onTap: onPlay,
      onLongPress: onRemove,
      focusNode: focusNode,
      builder: (context, focused, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          // Content-sized, like the reference's tile: a fixed height overflowed
          // by a pixel once the three text lines scaled past it.
          padding: EdgeInsets.symmetric(horizontal: 14.sp, vertical: 10.sp),
          decoration: BoxDecoration(
            color: isCurrent
                ? accent.withValues(alpha: 0.14)
                : focused
                ? tvTheme.cardColor
                : tvTheme.cardColor.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(14.sp),
            border: Border.all(color: focused ? accent : Colors.transparent, width: 2.sp),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 44.sp,
                child: isCurrent
                    ? Icon(Icons.graphic_eq_rounded, size: 30.sp, color: accent)
                    : Text('${index + 1}', style: AppTextStyles.t16.copyWith(fontWeight: FontWeight.w500, color: tvTheme.secondaryTextColor)),
              ),
              SizedBox(width: 8.sp),
              ClipRRect(
                borderRadius: BorderRadius.circular(10.sp),
                child: CachedNetworkImage(
                  imageUrl: track.archive.cover,
                  width: 132.sp,
                  height: 120.sp,
                  fit: BoxFit.cover,
                  memCacheWidth: 320,
                  errorWidget: (_, _, _) => Container(
                    color: accent.withValues(alpha: 0.12),
                    child: Icon(Icons.music_note_rounded, size: 30.sp, color: accent),
                  ),
                ),
              ),
              SizedBox(width: 16.sp),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.t18.copyWith(fontWeight: FontWeight.w600, color: isCurrent ? accent : tvTheme.primaryTextColor),
                    ),
                    SizedBox(height: 4.sp),
                    Row(
                      children: [
                        Icon(Icons.album_rounded, size: 18.sp, color: tvTheme.secondaryTextColor),
                        SizedBox(width: 4.sp),
                        Flexible(
                          child: Text(
                            track.archive.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.t16.copyWith(fontWeight: FontWeight.w500, color: tvTheme.secondaryTextColor),
                          ),
                        ),
                        SizedBox(width: 10.sp),
                        Icon(Icons.person_outline_rounded, size: 18.sp, color: tvTheme.secondaryTextColor),
                        SizedBox(width: 4.sp),
                        Flexible(
                          child: Text(
                            track.archive.upName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.t16.copyWith(fontWeight: FontWeight.w500, color: tvTheme.secondaryTextColor),
                          ),
                        ),
                      ],
                    ),
                    if (isMulti) ...[
                      SizedBox(height: 2.sp),
                      Row(
                        children: [
                          Icon(Icons.playlist_play_rounded, size: 18.sp, color: tvTheme.secondaryTextColor),
                          SizedBox(width: 4.sp),
                          Text(
                            'P${track.part.page}/${track.archive.parts.length}',
                            style: AppTextStyles.t16.copyWith(fontWeight: FontWeight.w500, color: tvTheme.secondaryTextColor),
                          ),
                          if (excludedCount > 0)
                            Text(
                              ' (-$excludedCount)',
                              style: AppTextStyles.t16.copyWith(fontWeight: FontWeight.w500, color: tvTheme.focusColor),
                            ),
                          SizedBox(width: 10.sp),
                          Icon(Icons.schedule_rounded, size: 18.sp, color: tvTheme.secondaryTextColor),
                          SizedBox(width: 4.sp),
                          Text(
                            MusicVideoCard.formatDuration(
                              track.part.duration > 0 ? track.part.duration : track.archive.duration,
                            ),
                            style: AppTextStyles.t16.copyWith(fontWeight: FontWeight.w500, color: tvTheme.secondaryTextColor),
                          ),
                        ],
                      ),
                    ] else ...[
                      SizedBox(height: 2.sp),
                      Row(
                        children: [
                          Icon(Icons.schedule_rounded, size: 18.sp, color: tvTheme.secondaryTextColor),
                          SizedBox(width: 4.sp),
                          Text(
                            MusicVideoCard.formatDuration(track.archive.duration),
                            style: AppTextStyles.t16.copyWith(fontWeight: FontWeight.w500, color: tvTheme.secondaryTextColor),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 关注: followed albums and followed uploaders, split by the tab bar — the
/// album tab keeps the QQ-music song table, the artist tab lists the UPs.
class _FollowSection extends ConsumerStatefulWidget {
  const _FollowSection({super.key});

  @override
  ConsumerState<_FollowSection> createState() => _FollowSectionState();
}

class _FollowSectionState extends ConsumerState<_FollowSection> {
  int _tab = 0;

  /// The album tab's multi-select save (关注 albums into one playlist):
  /// long press enters the mode, taps toggle, the bar saves to a playlist.
  bool _selectingAlbums = false;
  final Set<String> _selectedAlbums = <String>{};

  @override
  Widget build(BuildContext context) {
    final library = ref.watch(musicLibraryControllerProvider);
    final tvTheme = context.tvTheme;
    final accent = tvTheme.focusColor;

    if (library.favorites.isEmpty && library.followedUps.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite_border_rounded, size: 72.sp, color: accent.withValues(alpha: 0.5)),
            SizedBox(height: 14.sp),
            Text(
              i18n('music_empty_favorites'),
              style: AppTextStyles.t18.copyWith(fontWeight: FontWeight.w500, color: tvTheme.secondaryTextColor),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(20.sp, 16.sp, 20.sp, 10.sp),
          child: TvTabBar(
            tabs: [
              TvTabItemData(title: '${i18n('music_follow_albums')}（${library.favorites.length}）'),
              TvTabItemData(title: '${i18n('music_follow_ups')}（${library.followedUps.length}）'),
            ],
            currentIndex: _tab,
            onTabChange: (index) => setState(() => _tab = index),
          ),
        ),
        if (_selectingAlbums && _tab == 0)
          Padding(
            padding: EdgeInsets.fromLTRB(24.sp, 0, 24.sp, 10.sp),
            child: Row(
              children: [
                Text(
                  '${i18n('music_selected')} ${_selectedAlbums.length}',
                  style: AppTextStyles.t16.copyWith(fontWeight: FontWeight.w600, color: accent),
                ),
                const Spacer(),
                TvButton(
                  title: i18n('music_select_all'),
                  size: TvButtonSize.mini,
                  onTap: () => setState(() {
                    _selectedAlbums
                      ..clear()
                      ..addAll([for (final a in library.favorites) a.bvid]);
                  }),
                ),
                SizedBox(width: 12.sp),
                TvButton(
                  title: i18n('cancel'),
                  size: TvButtonSize.mini,
                  isSecondary: true,
                  onTap: () => setState(() {
                    _selectingAlbums = false;
                    _selectedAlbums.clear();
                  }),
                ),
                SizedBox(width: 12.sp),
                TvButton(
                  title: i18n('music_save_to_playlist'),
                  icon: Icon(Icons.playlist_add_rounded, size: 22.sp),
                  size: TvButtonSize.mini,
                  onTap: _selectedAlbums.isEmpty ? null : () => _saveSelectedToPlaylist(),
                ),
              ],
            ),
          ),
        if (_tab == 0)
          Expanded(
            child: library.favorites.isEmpty
                ? Center(
                    child: Text(
                      i18n('music_empty_favorites'),
                      style: AppTextStyles.t18.copyWith(fontWeight: FontWeight.w500, color: tvTheme.secondaryTextColor),
                    ),
                  )
                : DpadRegion(
                    horizontalEdge: DpadEdgeBehavior.leave,
                    child: GridView.builder(
                      padding: EdgeInsets.all(24.sp),
                      gridDelegate: TvAdaptiveGrid.media(
                        context,
                        crossAxisCount: 4,
                        mainAxisSpacing: 16.w,
                        crossAxisSpacing: 16.w,
                        childAspectRatio: 1.05,
                      ),
                      itemCount: library.favorites.length,
                      itemBuilder: (context, index) {
                        final archive = library.favorites[index];
                        final selected = _selectedAlbums.contains(archive.bvid);
                        void toggle() => setState(() {
                          selected ? _selectedAlbums.remove(archive.bvid) : _selectedAlbums.add(archive.bvid);
                        });
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            MusicVideoCard(
                              archive: archive,
                              // Selection mode retasks the taps: OK toggles
                              // the check instead of opening the detail page.
                              onTap: _selectingAlbums ? toggle : () => MusicArchiveRoute(archive).push(context),
                              onLongPress: () {
                                if (_selectingAlbums) {
                                  toggle();
                                  return;
                                }
                                _confirmUnfollowArchive(context, ref, archive);
                              },
                            ),
                            if (selected)
                              Positioned(
                                left: 10.sp,
                                top: 10.sp,
                                child: IgnorePointer(
                                  child: Container(
                                    width: 44.sp,
                                    height: 44.sp,
                                    decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                                    child: Icon(Icons.check_rounded, size: 28.sp, color: Colors.white),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
          )
        else
          Expanded(
            child: library.followedUps.isEmpty
                ? Center(
                    child: Text(
                      i18n('music_empty_ups'),
                      style: AppTextStyles.t18.copyWith(fontWeight: FontWeight.w500, color: tvTheme.secondaryTextColor),
                    ),
                  )
                : DpadRegion(
                    horizontalEdge: DpadEdgeBehavior.leave,
                    child: GridView.builder(
                      padding: EdgeInsets.all(24.sp),
                      gridDelegate: TvAdaptiveGrid.media(
                        context,
                        crossAxisCount: 4,
                        mainAxisSpacing: 16.w,
                        crossAxisSpacing: 16.w,
                        childAspectRatio: 3.0,
                      ),
                      itemCount: library.followedUps.length,
                      itemBuilder: (context, index) {
                        final up = library.followedUps[index];
                        return _AuthorCard(
                          up: up,
                          onTap: () => UgcUserSpaceRoute(up.mid, up.name).push(context),
                          onLongPress: () => _confirmUnfollowUp(context, ref, up),
                        );
                      },
                    ),
                  ),
          ),
      ],
    );
  }
/// Saves the selected albums into one playlist: every album's full part
  /// list is fetched (search stubs carry no cids) and added with silent
  /// dedupe — the toast reports added and skipped in one line.
  Future<void> _saveSelectedToPlaylist() async {
    final library = ref.read(musicLibraryControllerProvider);
    final archives = library.favorites.where((a) => _selectedAlbums.contains(a.bvid)).toList();
    if (archives.isEmpty) return;
    final id = await showPlaylistPicker(context, ref);
    if (id == null || !mounted) return;
    final libraryController = ref.read(musicLibraryControllerProvider.notifier);
    var added = 0;
    var skipped = 0;
    for (final archive in archives) {
      try {
        final detail = await BilibiliMusicApi.instance.getArchiveDetail(archive.bvid);
        final tracks = detail.tracks;
        final landed = libraryController.addTracksToPlaylist(id, tracks);
        added += landed;
        skipped += tracks.length - landed;
      } catch (_) {
        skipped += 1;
      }
    }
    if (!mounted) return;
    ToastUtil.show(i18n('music_added_skipped', args: {'added': '$added', 'skipped': '$skipped'}));
    setState(() {
      _selectingAlbums = false;
      _selectedAlbums.clear();
    });
  }

}


/// Long press on a followed album: one explicit row, not a silent side effect.
Future<void> _confirmUnfollowArchive(BuildContext context, WidgetRef ref, MusicArchive archive) async {
  await TvDialogUtils.show<void>(
    context: context,
    builder: (_) => TvDialog(
      title: archive.title,
      cancelText: i18n('cancel'),
      width: 560.sp,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TvDialogOptionTile(
            title: i18n('music_play_album'),
            icon: Icon(Icons.play_circle_fill_rounded, size: 26.sp),
            showCheck: false,
            autofocus: true,
            onTap: () {
              Navigator.of(context).pop();
              ref.read(musicPlayerControllerProvider.notifier).playQueue(archive.tracks);
              const MusicPlayerRoute().push(context);
            },
          ),
          TvDialogOptionTile(
            title: i18n('music_unfollow_album'),
            icon: Icon(Icons.favorite_border_rounded, size: 26.sp),
            showCheck: false,
            onTap: () {
              Navigator.of(context).pop();
              ref.read(musicLibraryControllerProvider.notifier).removeFavorite(archive.bvid);
              ToastUtil.show(i18n('music_removed_favorite'));
            },
          ),
        ],
      ),
    ),
  );
}

/// Long press on a followed artist: unfollows after an explicit confirm row.
Future<void> _confirmUnfollowUp(BuildContext context, WidgetRef ref, MusicUp up) async {
  await TvDialogUtils.show<void>(
    context: context,
    builder: (_) => TvDialog(
      title: up.name,
      cancelText: i18n('cancel'),
      width: 560.sp,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TvDialogOptionTile(
            title: i18n('music_unfollow_up'),
            icon: Icon(Icons.person_remove_outlined, size: 26.sp),
            showCheck: false,
            autofocus: true,
            onTap: () {
              Navigator.of(context).pop();
              ref.read(musicLibraryControllerProvider.notifier).toggleFollowUp(up);
            },
          ),
        ],
      ),
    ),
  );
}

/// The followed-UP card in the area-card visual: square avatar, name beneath.
/// The followed-UP cell, newBV's user-card shape: a horizontal row — circular
/// avatar left, the name over the signature line right, no card chrome; the
/// focus paints the whole row. The sign is fetched once and cached.
class _AuthorCard extends ConsumerWidget {
  const _AuthorCard({required this.up, required this.onTap, required this.onLongPress});

  final MusicUp up;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tvTheme = context.tvTheme;
    final accent = tvTheme.focusColor;
    final sign = ref.watch(musicUpSignProvider(up.mid));

    return TvFocusable(
      onTap: onTap,
      onLongPress: onLongPress,
      builder: (context, focused, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(horizontal: 14.sp, vertical: 12.sp),
          decoration: BoxDecoration(
            color: focused ? tvTheme.focusedCardColor : Colors.transparent,
            borderRadius: BorderRadius.circular(16.sp),
            border: Border.all(color: focused ? accent : Colors.transparent, width: 2.sp),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: up.face.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: up.face,
                        width: 84.sp,
                        height: 84.sp,
                        fit: BoxFit.cover,
                        memCacheWidth: 240,
                        errorWidget: (_, _, _) => _fallback(accent),
                      )
                    : _fallback(accent),
              ),
              SizedBox(width: 14.sp),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      up.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.t18.copyWith(fontWeight: FontWeight.w600, 
                        color: focused ? tvTheme.onFocusedCard : tvTheme.primaryTextColor,
                      ),
                    ),
                    if (sign.asData?.value.isNotEmpty == true) ...[
                      SizedBox(height: 4.sp),
                      Text(
                        sign.asData!.value,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.t14.copyWith(fontWeight: FontWeight.w500, 
                          color: focused ? tvTheme.onFocusedCardSecondary : tvTheme.secondaryTextColor,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _fallback(Color accent) => Container(
    width: 84.sp,
    height: 84.sp,
    color: accent.withValues(alpha: 0.15),
    child: Icon(Icons.person_outline_rounded, size: 44.sp, color: accent),
  );
}

class _RankingSection extends ConsumerStatefulWidget {
  const _RankingSection({super.key});

  @override
  ConsumerState<_RankingSection> createState() => _RankingSectionState();
}

class _RankingSectionState extends ConsumerState<_RankingSection> {
  late final PagingParam<MusicArchive> _param = PagingParam<MusicArchive>(
    mode: PagingMode.serverAll,
    pageSize: 12,
    keepAlive: true,
    fetchAll: () => BilibiliMusicApi.instance.getMusicRanking(),
  );

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeSettingsControllerProvider);
    return BasePagedTvView<MusicArchive>(
      key: const ValueKey('music_ranking_grid'),
      param: _param,
      getNotifier: () => ref.read(pagingCoreProvider(_param).notifier),
      gridDelegate: TvAdaptiveGrid.media(
        context,
        crossAxisCount: themeState.denseRoomLayout,
        mainAxisSpacing: themeState.mainAxisSpacing.w,
        crossAxisSpacing: themeState.crossAxisSpacing.w,
        childAspectRatio: ThemeSettingsController.roomCardAspectRatio(themeState.denseRoomLayout) + 0.14,
      ),
      itemBuilder: (context, archive, index) =>
          MusicVideoCard(archive: archive, onTap: () => MusicArchiveRoute(archive).push(context)),
    );
  }
}

/// 每日推荐: the bmsc brute-force engine — the default fav folder's videos
/// seed related-video searches, one music pick per seed, cached for the day.
/// The folder button re-pins the source, a card's long press re-rolls one slot.
class _DailySection extends ConsumerStatefulWidget {
  const _DailySection({super.key});

  @override
  ConsumerState<_DailySection> createState() => _DailySectionState();
}

class _DailySectionState extends ConsumerState<_DailySection> {
  List<MusicArchive>? _recs;
  bool _loading = true;
  bool _lock = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool force = false}) async {
    if (_lock) return;
    _lock = true;
    if (mounted) setState(() => _loading = true);
    final recs = await DailyRecommendationService.dailyRecommendations(force: force);
    if (!mounted) return;
    setState(() {
      if (recs != null) _recs = recs;
      _loading = false;
      _lock = false;
    });
  }

  /// One slot re-rolls from a fresh folder seed; the day's cache follows.
  Future<void> _regenerateAt(int index) async {
    final fresh = await DailyRecommendationService.regenerateOne(
      existingBvids: [for (final v in _recs ?? const <MusicArchive>[]) v.bvid],
    );
    if (!mounted) return;
    if (fresh == null) {
      ToastUtil.show(i18n('music_daily_no_more'));
      return;
    }
    setState(() {
      final recs = [...?_recs];
      if (index < recs.length) recs[index] = fresh;
      _recs = recs;
    });
    unawaited(DailyRecommendationService.saveCache(_recs ?? const []));
    ToastUtil.show(i18n('music_daily_rerolled'));
  }

  Future<void> _pickFolder() async {
    try {
      final folders = await BilibiliUgcApi.instance.getMyFavFolders();
      if (!mounted) return;
      final current = DailyRecommendationService.defaultFolder()?.id;
      await TvDialogUtils.show<void>(
        context: context,
        builder: (_) => TvDialog(
          title: i18n('music_pick_folder'),
          cancelText: i18n('cancel'),
          width: 640.sp,
          child: SizedBox(
            height: 480.sp,
            child: folders.isEmpty
                ? Center(
                    child: Text(
                      i18n('music_no_folders'),
                      style: AppTextStyles.t16.copyWith(fontWeight: FontWeight.w500, color: context.tvTheme.secondaryTextColor),
                    ),
                  )
                : ListView.builder(
                    itemCount: folders.length,
                    itemBuilder: (context, index) {
                      final fav = folders[index];
                      return TvDialogOptionTile(
                        title: fav.title,
                        subtitle: '${fav.mediaCount}',
                        selected: current == fav.id,
                        onTap: () {
                          Navigator.of(context).pop();
                          unawaited(DailyRecommendationService.setDefaultFolder(fav));
                          _load(force: true);
                        },
                      );
                    },
                  ),
          ),
        ),
      );
    } catch (_) {
      if (mounted) ToastUtil.show(i18n('load_failed'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final folder = DailyRecommendationService.defaultFolder();
    final tvTheme = context.tvTheme;
    final accent = tvTheme.focusColor;

    final header = Padding(
      padding: EdgeInsets.fromLTRB(24.sp, 16.sp, 24.sp, 8.sp),
      child: Row(
        children: [
          TvButton(
            title: folder?.title ?? i18n('music_pick_folder'),
            icon: Icon(Icons.folder_outlined, size: 24.sp),
            size: TvButtonSize.mini,
            isSecondary: true,
            onTap: _pickFolder,
          ),
          const Spacer(),
          TvButton(
            title: i18n('music_regenerate'),
            icon: Icon(Icons.refresh_rounded, size: 24.sp),
            size: TvButtonSize.mini,
            isSecondary: true,
            onTap: folder == null || _loading ? null : () => _load(force: true),
          ),
        ],
      ),
    );

    if (folder == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.folder_off_outlined, size: 72.sp, color: accent.withValues(alpha: 0.5)),
                  SizedBox(height: 14.sp),
                  Text(
                    i18n('music_daily_need_folder'),
                    style: AppTextStyles.t18.copyWith(fontWeight: FontWeight.w500, color: tvTheme.secondaryTextColor),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    final recs = _recs ?? const <MusicArchive>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        Expanded(
          child: _loading && recs.isEmpty
              ? Center(
                  child: AppStatusView(type: AppStatusType.loading, title: '', subtitle: ''),
                )
              : recs.isEmpty
              ? Center(
                  child: AppStatusView(type: AppStatusType.empty, title: i18n('music_daily_empty')),
                )
              : DpadRegion(
                  horizontalEdge: DpadEdgeBehavior.leave,
                  child: GridView.builder(
                    padding: EdgeInsets.all(24.sp),
                    gridDelegate: TvAdaptiveGrid.media(
                      context,
                      crossAxisCount: 4,
                      mainAxisSpacing: 16.w,
                      crossAxisSpacing: 16.w,
                      childAspectRatio: 1.05,
                    ),
                    itemCount: recs.length,
                    itemBuilder: (context, index) {
                      final archive = recs[index];
                      return MusicVideoCard(
                        archive: archive,
                        onTap: () => MusicArchiveRoute(archive).push(context),
                        onLongPress: () => _confirmReroll(index),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _confirmReroll(int index) async {
    await TvDialogUtils.show<void>(
      context: context,
      builder: (_) => TvDialog(
        title: i18n('music_re_recommend'),
        cancelText: i18n('cancel'),
        width: 560.sp,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TvDialogOptionTile(
              title: i18n('music_re_recommend'),
              icon: Icon(Icons.refresh_rounded, size: 26.sp),
              showCheck: false,
              autofocus: true,
              onTap: () {
                Navigator.of(context).pop();
                _regenerateAt(index);
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Search over the video site, grid results like the other discovery views.
class _SearchSection extends ConsumerStatefulWidget {
  const _SearchSection({super.key});

  @override
  ConsumerState<_SearchSection> createState() => _SearchSectionState();
}

class _SearchSectionState extends ConsumerState<_SearchSection> {
  final TextEditingController _controller = TextEditingController();
  final Map<String, PagingParam<MusicArchive>> _params = {};
  String _submittedKeyword = '';
  List<Hotword> _hotwords = [];

  @override
  void initState() {
    super.initState();
    _loadHotwords();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadHotwords() async {
    try {
      final words = await BilibiliUgcApi.instance.getHotwords();
      if (!mounted) return;
      setState(() => _hotwords = words);
    } catch (_) {}
  }

  void _submit(String keyword) {
    final trimmed = keyword.trim();
    if (trimmed.isEmpty) return;
    setState(() => _submittedKeyword = trimmed);
  }

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final accent = tvTheme.focusColor;
    final themeState = ref.watch(themeSettingsControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(20.sp, 16.sp, 20.sp, 8.sp),
          child: Row(
            children: [
              SizedBox(
                width: 520.sp,
                child: TvInputField(
                  controller: _controller,
                  hint: i18n('music_search_hint'),
                  height: 64.sp,
                  maxLines: 1,
                  onSubmitted: _submit,
                ),
              ),
              SizedBox(width: 16.sp),
              TvButton(
                title: i18n('music_tab_search'),
                icon: Icon(Icons.search_rounded, size: 28.sp),
                size: TvButtonSize.mini,
                onTap: () => _submit(_controller.text),
              ),
            ],
          ),
        ),
        Expanded(
          child: _submittedKeyword.isEmpty
              ? DpadRegion(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(24.sp),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_hotwords.isEmpty)
                          Center(
                            child: Text(
                              i18n('music_search_empty_hint'),
                              style: AppTextStyles.t18.copyWith(fontWeight: FontWeight.w500, color: tvTheme.secondaryTextColor),
                            ),
                          )
                        else ...[
                          Row(
                            children: [
                              Icon(Icons.local_fire_department_rounded, size: 26.sp, color: accent),
                              SizedBox(width: 8.sp),
                              Text(i18n('video_search_hotwords'), style: AppTextStyles.t20.copyWith(fontWeight: FontWeight.w600, color: accent)),
                            ],
                          ),
                          SizedBox(height: 16.sp),
                          Wrap(
                            spacing: 12.sp,
                            runSpacing: 12.sp,
                            children: [
                              for (final (index, word) in _hotwords.indexed)
                                TvFocusable(
                                  autofocus: index == 0,
                                  onTap: () => _submit(word.keyword),
                                  builder: (context, focused, child) => AnimatedContainer(
                                    duration: const Duration(milliseconds: 120),
                                    padding: EdgeInsets.symmetric(horizontal: 20.sp, vertical: 10.sp),
                                    decoration: BoxDecoration(
                                      color: tvTheme.cardColor,
                                      borderRadius: BorderRadius.circular(24.sp),
                                      border: Border.all(color: focused ? accent : Colors.transparent, width: 2.sp),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '${index + 1}',
                                          style: AppTextStyles.t14.copyWith(fontWeight: FontWeight.w700, 
                                            color: index < 3 ? Colors.redAccent : tvTheme.secondaryTextColor,
                                          ),
                                        ),
                                        SizedBox(width: 8.sp),
                                        Text(
                                          word.keyword,
                                          style: AppTextStyles.t16.copyWith(fontWeight: FontWeight.w500, color: tvTheme.primaryTextColor),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              : Builder(
                  builder: (context) {
                    final keyword = _submittedKeyword;
                    final param = _params.putIfAbsent(
                      keyword,
                      () => PagingParam<MusicArchive>(
                        mode: PagingMode.serverRemote,
                        pageSize: 20,
                        keepAlive: true,
                        fetchRemote: (page, size) =>
                            BilibiliMusicApi.instance.searchVideos(keyword, page: page, pageSize: size),
                      ),
                    );
                    return BasePagedTvView<MusicArchive>(
                      key: ValueKey('music_search_$keyword'),
                      param: param,
                      getNotifier: () => ref.read(pagingCoreProvider(param).notifier),
                      gridDelegate: TvAdaptiveGrid.media(
                        context,
                        crossAxisCount: themeState.denseRoomLayout,
                        mainAxisSpacing: themeState.mainAxisSpacing.w,
                        crossAxisSpacing: themeState.crossAxisSpacing.w,
                        childAspectRatio:
                            ThemeSettingsController.roomCardAspectRatio(themeState.denseRoomLayout) + 0.14,
                      ),
                      itemBuilder: (context, archive, index) =>
                          MusicVideoCard(archive: archive, onTap: () => MusicArchiveRoute(archive).push(context)),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class MusicMiniBar extends ConsumerWidget {
  const MusicMiniBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(musicPlayerControllerProvider);
    if (!state.hasQueue) return const SizedBox.shrink();
    final controller = ref.read(musicPlayerControllerProvider.notifier);
    final library = ref.watch(musicLibraryControllerProvider);
    final tvTheme = context.tvTheme;
    final accent = tvTheme.focusColor;
    final track = state.current;
    final isLiked = track != null && library.isSongLiked(track.id);
    return DpadRegion(
      child: Container(
        margin: EdgeInsets.all(12.sp),
        padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 10.sp),
        decoration: BoxDecoration(
          color: tvTheme.cardColor,
          borderRadius: BorderRadius.circular(20.sp),
          border: Border.all(color: accent.withValues(alpha: 0.35)),
        ),
        child: StreamBuilder<PlaybackState>(
          stream: controller.playbackStream,
          builder: (context, snapshot) {
            final playback = snapshot.data;
            final position = playback?.position ?? Duration.zero;
            final duration = playback?.duration ?? Duration.zero;
            final isPlaying = playback?.isPlaying ?? false;
            final progress = duration > Duration.zero ? (position.inMilliseconds / duration.inMilliseconds) : 0.0;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TvFocusable(
                        onTap: () => const MusicPlayerRoute().push(context),
                        builder: (context, focused, child) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 120),
                            padding: EdgeInsets.symmetric(horizontal: 10.sp, vertical: 6.sp),
                            decoration: BoxDecoration(
                              color: focused ? accent.withValues(alpha: 0.18) : Colors.transparent,
                              borderRadius: BorderRadius.circular(12.sp),
                              border: Border.all(color: focused ? accent : Colors.transparent, width: 2.sp),
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10.sp),
                                  child: CachedNetworkImage(
                                    imageUrl: track?.archive.cover ?? '',
                                    width: 124.sp,
                                    height: 80.sp,
                                    fit: BoxFit.cover,
                                    memCacheWidth: 320,
                                    errorWidget: (_, _, _) =>
                                        Icon(Icons.music_note_rounded, size: 28.sp, color: accent),
                                  ),
                                ),
                                SizedBox(width: 14.sp),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        track?.title ?? i18n('music_player_title'),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTextStyles.t18.copyWith(fontWeight: FontWeight.w700, color: tvTheme.primaryTextColor),
                                      ),
                                      SizedBox(height: 2.sp),
                                      Text(
                                        track?.archive.upName ?? '',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTextStyles.t14.copyWith(fontWeight: FontWeight.w500, color: tvTheme.secondaryTextColor),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 12.sp),
                                Text(
                                  '${MusicVideoCard.formatDuration(position.inSeconds)} / ${MusicVideoCard.formatDuration(duration.inSeconds)}',
                                  style: AppTextStyles.t14.copyWith(fontWeight: FontWeight.w500, color: tvTheme.secondaryTextColor),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(width: 8.sp),
                    TvIconButton(
                      icon: Icon(isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded),
                      size: TvIconButtonSize.medium,
                      onTap: () {
                        if (track != null) {
                          ref.read(musicLibraryControllerProvider.notifier).toggleLikeSong(track);
                        }
                      },
                    ),
                    SizedBox(width: 6.sp),
                    TvIconButton(
                      icon: const Icon(Icons.playlist_add_rounded),
                      size: TvIconButtonSize.medium,
                      isSecondary: true,
                      onTap: () {
                        final current = state.current;
                        if (current != null) showAddToPlaylistDialog(context, ref, current);
                      },
                    ),
                    SizedBox(width: 6.sp),
                    TvIconButton(
                      icon: const Icon(Icons.skip_previous_rounded),
                      size: TvIconButtonSize.medium,
                      isSecondary: true,
                      onTap: () => controller.previous(),
                    ),
                    SizedBox(width: 6.sp),
                    TvIconButton(
                      icon: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                      size: TvIconButtonSize.large,
                      onTap: () => controller.togglePlayPause(),
                    ),
                    SizedBox(width: 6.sp),
                    TvIconButton(
                      icon: const Icon(Icons.skip_next_rounded),
                      size: TvIconButtonSize.medium,
                      isSecondary: true,
                      onTap: () => controller.next(),
                    ),
                    SizedBox(width: 6.sp),
                  ],
                ),
                SizedBox(height: 6.sp),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3.sp),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 6.sp,
                    backgroundColor: tvTheme.secondaryTextColor.withValues(alpha: 0.25),
                    color: accent,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
