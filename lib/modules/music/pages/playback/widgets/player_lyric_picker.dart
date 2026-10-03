import 'package:pure_live/exports/exports.dart';
import 'package:pure_live/modules/vod/models/models.dart';
import 'package:pure_live/modules/music/services/music_lyric_service.dart';

/// Step 1: pick a lyric source. Groups every candidate the chain found by
/// [MusicLyricCandidate.source] and shows one row per source with the count of
/// candidates it carries. Picking a source closes this dialog; the caller then
/// opens step 2 with the candidates that belong to that source.
class MusicLyricSourcePickerDialog extends StatelessWidget {
  const MusicLyricSourcePickerDialog({super.key, required this.track});

  final MusicTrack track;

  @override
  Widget build(BuildContext context) {
    final theme = context.tvTheme;
    final service = MusicLyricService.instance;

    return TvDialog(
      title: i18n('music_lyric_source_title'),
      child: SizedBox(
        width: 600.ts(context),
        height: 480.ts(context),
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

            // Group by source, preserving the order candidates appeared
            // (the chain's priority: manual → BGM → LRC → netease).
            final grouped = <String, List<MusicLyricCandidate>>{};
            for (final c in candidates) {
              grouped.putIfAbsent(c.source, () => []).add(c);
            }
            final sources = grouped.keys.toList();

            return ListView.builder(
              itemCount: sources.length,
              itemBuilder: (context, index) {
                final source = sources[index];
                final count = grouped[source]!.length;
                final String label = source == 'manual'
                    ? i18n('music_lyric_manual_source')
                    : source;
                return Padding(
                  padding: EdgeInsets.only(bottom: 10.sp),
                  child: TvDialogOptionTile(
                    title: label,
                    subtitle: '$count ${i18n("music_lyric_pick")}',
                    selected: false,
                    autofocus: index == 0,
                    onTap: () => Navigator.of(context).pop(grouped[source]),
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

/// Step 2: pick one lyric from a single source. The caller passes the
/// candidates that belong to the source the viewer picked in step 1.
class MusicLyricCandidatePickerDialog extends StatelessWidget {
  const MusicLyricCandidatePickerDialog({super.key, required this.track, required this.candidates});

  final MusicTrack track;
  final List<MusicLyricCandidate> candidates;

  @override
  Widget build(BuildContext context) {
    final theme = context.tvTheme;
    final service = MusicLyricService.instance;

    final String sourceLabel = candidates.isNotEmpty
        ? (candidates.first.source == 'manual'
            ? i18n('music_lyric_manual_source')
            : candidates.first.source)
        : '';

    return TvDialog(
      title: '$sourceLabel · ${i18n("music_lyric_pick")}',
      child: SizedBox(
        width: 720.ts(context),
        height: 560.ts(context),
        child: Builder(
          builder: (context) {
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
                return Padding(
                  padding: EdgeInsets.only(bottom: 10.sp),
                  child: TvDialogOptionTile(
                    title: candidate.title,
                    subtitle: candidate.artist.isEmpty ? '' : candidate.artist,
                    selected: index == selected,
                    // The list is small and known up front: focus the current
                    // pick (or the first row) so the remote lands somewhere
                    // visible without a traversal hunt.
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
