import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/app/router/app_router.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/modules/vod/models/models.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pure_live/modules/vod/api/bilibili_ugc_api.dart';
import 'package:pure_live/modules/vod/api/bilibili_music_api.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/modules/music/widgets/music_video_card.dart';
import 'package:pure_live/modules/vod/controllers/music_player_controller.dart';
import 'package:pure_live/services/theme_settings/theme_settings_controller.dart';
import 'package:pure_live/modules/music/pages/playlist/music_playlist_dialogs.dart';
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

/// album tab keeps the QQ-music song table, the artist tab lists the UPs.
class MusicFollowSection extends ConsumerStatefulWidget {
  const MusicFollowSection({super.key});

  @override
  ConsumerState<MusicFollowSection> createState() => MusicFollowSectionState();
}

class MusicFollowSectionState extends ConsumerState<MusicFollowSection> {
  int _tab = 0;

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
            Icon(Icons.favorite_border_rounded, size: 72.ts(context), color: accent.withValues(alpha: 0.5)),
            SizedBox(height: 14.ts(context)),
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
          padding: EdgeInsets.fromLTRB(20.ts(context), 16.ts(context), 20.ts(context), 10.ts(context)),
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
            padding: EdgeInsets.fromLTRB(24.ts(context), 0, 24.ts(context), 10.ts(context)),
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
                SizedBox(width: 12.ts(context)),
                TvButton(
                  title: i18n('cancel'),
                  size: TvButtonSize.mini,
                  isSecondary: true,
                  onTap: () => setState(() {
                    _selectingAlbums = false;
                    _selectedAlbums.clear();
                  }),
                ),
                SizedBox(width: 12.ts(context)),
                TvButton(
                  title: i18n('music_save_to_playlist'),
                  icon: Icon(Icons.playlist_add_rounded, size: 22.ts(context)),
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
                      padding: EdgeInsets.all(24.ts(context)),
                      gridDelegate: ThemeSettingsController.cardGridDelegate(context, ref),
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
                                    width: 44.ts(context),
                                    height: 44.ts(context),
                                    decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                                    child: Icon(Icons.check_rounded, size: 28.ts(context), color: Colors.white),
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
                      padding: EdgeInsets.all(24.ts(context)),
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
                        return MusicAuthorCard(
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
      width: 560.ts(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TvDialogOptionTile(
            title: i18n('music_play_album'),
            icon: Icon(Icons.play_circle_fill_rounded, size: 26.ts(context)),
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
            icon: Icon(Icons.favorite_border_rounded, size: 26.ts(context)),
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
      width: 560.ts(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TvDialogOptionTile(
            title: i18n('music_unfollow_up'),
            icon: Icon(Icons.person_remove_outlined, size: 26.ts(context)),
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
class MusicAuthorCard extends ConsumerWidget {
  const MusicAuthorCard({super.key, required this.up, required this.onTap, required this.onLongPress});

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
          padding: EdgeInsets.symmetric(horizontal: 14.ts(context), vertical: 12.ts(context)),
          decoration: BoxDecoration(
            color: focused ? tvTheme.focusedCardColor : Colors.transparent,
            borderRadius: BorderRadius.circular(16.ts(context)),
            border: Border.all(color: focused ? accent : Colors.transparent, width: 2.ts(context)),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: up.face.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: up.face,
                        width: 84.ts(context),
                        height: 84.ts(context),
                        fit: BoxFit.cover,
                        memCacheWidth: 240,
                        errorWidget: (_, _, _) => _fallback(context, accent),
                      )
                    : _fallback(context, accent),
              ),
              SizedBox(width: 14.ts(context)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      up.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.t18.copyWith(
                        fontWeight: FontWeight.w600,
                        color: focused ? tvTheme.onFocusedCard : tvTheme.primaryTextColor,
                      ),
                    ),
                    if (sign.asData?.value.isNotEmpty == true) ...[
                      SizedBox(height: 4.ts(context)),
                      Text(
                        sign.asData!.value,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.t14.copyWith(
                          fontWeight: FontWeight.w500,
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

  Widget _fallback(BuildContext context, Color accent) => Container(
    width: 84.ts(context),
    height: 84.ts(context),
    color: accent.withValues(alpha: 0.15),
    child: Icon(Icons.person_outline_rounded, size: 44.ts(context), color: accent),
  );
}
