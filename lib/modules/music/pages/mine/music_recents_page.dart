import 'package:dpad/dpad.dart';
import 'package:pure_live/exports/exports.dart';
import 'package:pure_live/modules/vod/models/models.dart';
import 'package:pure_live/modules/music/music_section.dart';
import 'package:pure_live/modules/music/widgets/music_song_row.dart';
import 'package:pure_live/modules/music/widgets/music_song_menu.dart';
import 'package:pure_live/modules/music/services/music_list_reveal.dart';
import 'package:pure_live/modules/vod/controllers/music_player_controller.dart';
import 'package:pure_live/modules/music/controllers/library/music_library_controller.dart';

/// with a Now-playing / Play all / Clear header and long-press removal (the
/// song menu). The liked songs live on the follow page's albums tab.
class MusicRecentsPage extends ConsumerStatefulWidget {
  const MusicRecentsPage({super.key});

  @override
  ConsumerState<MusicRecentsPage> createState() => MusicRecentsPageState();
}

class MusicRecentsPageState extends ConsumerState<MusicRecentsPage> {
  final MusicListReveal _reveal = MusicListReveal();

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const section = MusicSection.recents;
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
              size: 72.ts(context),
              color: accent.withValues(alpha: 0.5),
            ),
            SizedBox(height: 14.ts(context)),
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
          padding: EdgeInsets.fromLTRB(20.ts(context), 16.ts(context), 20.ts(context), 10.ts(context)),
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
                icon: Icon(Icons.music_note_rounded, size: 24.ts(context)),
                size: TvButtonSize.mini,
                isSecondary: true,
                onTap: () => const MusicPlayerRoute().push(context),
              ),
              SizedBox(width: 12.ts(context)),
              TvButton(
                title: i18n('music_play_all'),
                icon: Icon(Icons.play_circle_fill_rounded, size: 28.ts(context)),
                size: TvButtonSize.mini,
                onTap: () => _play(context, ref, tracks, 0),
              ),
              if (!isFavorites) ...[
                SizedBox(width: 12.ts(context)),
                TvButton(
                  title: i18n('music_clear_recents'),
                  icon: Icon(Icons.delete_outline_rounded, size: 24.ts(context)),
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
              separatorBuilder: (_, _) => SizedBox(height: 4.ts(context)),
              itemBuilder: (context, index) {
                final track = tracks[index];
                _reveal.bindRow(track, context);
                return MusicSongRow(
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
    _reveal.reveal(this.context, tracks, ref.read(musicPlayerControllerProvider).currentMusic);
  }
}
