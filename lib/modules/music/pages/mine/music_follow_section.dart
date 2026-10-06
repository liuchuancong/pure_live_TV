import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/app/router/app/app_router.dart';
import 'package:pure_live/modules/vod/models/models.dart';
import 'package:pure_live/modules/vod/api/bilibili_music_api.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/modules/music/widgets/music_video_card.dart';
import 'package:pure_live/modules/vod/controllers/music_player_controller.dart';
import 'package:pure_live/services/theme_settings/theme_settings_controller.dart';
import 'package:pure_live/modules/music/pages/playlist/music_playlist_dialogs.dart';
import 'package:pure_live/modules/music/controllers/library/music_library_controller.dart';

/// The "following" section lists the followed albums only. Followed uploaders
/// are not shown here (nor stored locally): the account's follow list is
/// already fetched live through the uploader tab (`x/relation/followings`), so
/// a second, locally-persisted copy here only drifted from the server.
class MusicFollowSection extends ConsumerStatefulWidget {
  const MusicFollowSection({super.key});

  @override
  ConsumerState<MusicFollowSection> createState() => MusicFollowSectionState();
}

class MusicFollowSectionState extends ConsumerState<MusicFollowSection> {
  /// long press enters the mode, taps toggle, the bar saves to a playlist.
  bool _selectingAlbums = false;
  final Set<String> _selectedAlbums = <String>{};

  @override
  Widget build(BuildContext context) {
    final library = ref.watch(musicLibraryControllerProvider);
    final tvTheme = context.tvTheme;
    final accent = tvTheme.focusColor;

    if (library.favorites.isEmpty) {
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
        if (_selectingAlbums)
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
        Expanded(
          child: DpadRegion(
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
