import 'package:pure_live/exports/exports.dart';
import 'package:pure_live/modules/vod/models/models.dart';
import 'package:pure_live/modules/music/services/music_lyric_service.dart';

/// The lyric picker: every candidate the chain found, one row each with the
/// source and the song name it claims. The row in force (the viewer's last
/// manual pick) is marked; picking a row remembers it for every later play of
/// this track.
class MusicLyricPickerDialog extends StatelessWidget {
  const MusicLyricPickerDialog({super.key, required this.track});

  final MusicTrack track;

  @override
  Widget build(BuildContext context) {
    final theme = context.tvTheme;
    final service = MusicLyricService.instance;

    return TvDialog(
      title: i18n('music_lyric_pick'),
      child: SizedBox(
        width: 720.ts(context),
        height: 560.ts(context),
        child: FutureBuilder<List<MusicLyricCandidate>>(
          future: service.fetchLyricCandidates(
            track.title,
            hint: track.archive.title,
            aid: track.archive.aid,
            bvid: track.archive.bvid,
            cid: track.part.cid,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  SizedBox(height: 16.ts(context)),
                  Text(
                    i18n('ui_loading'),
                    style: AppTextStyles.t18.copyWith(fontWeight: FontWeight.w300, color: theme.secondaryTextColor),
                  ),
                ],
              );
            }

            final candidates = snapshot.data ?? const <MusicLyricCandidate>[];
            if (candidates.isEmpty) {
              return Center(
                child: Text(
                  i18n('music_lyric_none'),
                  style: AppTextStyles.t18.copyWith(fontWeight: FontWeight.w300, color: theme.secondaryTextColor),
                ),
              );
            }

            final String current = service.manualLyric(track.title) ?? '';
            final int selected = candidates.indexWhere((c) => c.lyric.trim() == current.trim());

            return ListView.builder(
              itemCount: candidates.length,
              itemBuilder: (context, index) {
                final candidate = candidates[index];
                final String source = candidate.source == 'manual'
                    ? i18n('music_lyric_manual_source')
                    : candidate.source;
                return Padding(
                  padding: EdgeInsets.only(bottom: 10.sp),
                  child: TvDialogOptionTile(
                    title: candidate.title,
                    subtitle: '$source${candidate.artist.isEmpty ? '' : ' · ${candidate.artist}'}',
                    selected: index == selected,
                    // The list builds late (network candidates): without an
                    // explicit focus target the dialog's guard ran before any
                    // row existed and the remote landed nowhere.
                    autofocus: index == (selected >= 0 ? selected : 0),
                    onTap: () => Navigator.of(context).pop(candidate),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
