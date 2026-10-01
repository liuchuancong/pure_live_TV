import 'package:pure_live/exports/exports.dart';
import 'package:pure_live/modules/vod/models/models.dart';

/// newBV's 字幕 tab: pick one of the archive's CC tracks or switch them off.
class VideoSubtitleMenu extends StatelessWidget {
  const VideoSubtitleMenu({
    super.key,
    required this.tracks,
    required this.selected,
    required this.onPick,
    required this.onClose,
  });

  final List<SubtitleTrack> tracks;

  /// The live track, null when subtitles are off.
  final SubtitleTrack? selected;
  final ValueChanged<SubtitleTrack?> onPick;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final accent = tvTheme.focusColor;

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(20.ts(context)),
        border: Border.all(color: accent.withValues(alpha: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.all(16.ts(context)),
            child: Row(
              children: [
                Icon(Icons.closed_caption_outlined, size: 26.ts(context), color: accent),
                SizedBox(width: 10.ts(context)),
                Expanded(
                  child: Text(
                    i18n('video_subtitle_title'),
                    style: AppTextStyles.t18.copyWith(fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
                TvIconButton(
                  icon: const Icon(Icons.close_rounded),
                  size: TvIconButtonSize.small,
                  isSecondary: true,
                  onTap: onClose,
                ),
              ],
            ),
          ),
          _TrackTile(
            label: i18n('video_subtitle_off'),
            isCurrent: selected == null,
            autofocus: selected == null,
            onTap: () => onPick(null),
          ),
          for (final track in tracks)
            _TrackTile(
              label: track.lanDoc.isEmpty ? track.lan : track.lanDoc,
              isCurrent: selected?.lan == track.lan,
              autofocus: false,
              onTap: () => onPick(track),
            ),
          SizedBox(height: 8.ts(context)),
        ],
      ),
    );
  }
}

class _TrackTile extends StatelessWidget {
  const _TrackTile({
    required this.label,
    required this.isCurrent,
    required this.autofocus,
    required this.onTap,
  });

  final String label;
  final bool isCurrent;
  final bool autofocus;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = context.tvTheme.focusColor;
    return Padding(
      padding: EdgeInsets.only(left: 12.sp, right: 12.sp, bottom: 8.sp),
      child: TvFocusable(
        autofocus: autofocus,
        onTap: onTap,
        builder: (context, focused, child) => AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: 56.ts(context),
          padding: EdgeInsets.symmetric(horizontal: 14.ts(context)),
          decoration: BoxDecoration(
            color: isCurrent ? accent.withValues(alpha: 0.22) : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12.ts(context)),
            border: Border.all(color: focused ? accent : Colors.transparent, width: 2.ts(context)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.t16.copyWith(
                    fontWeight: FontWeight.w500,
                    color: isCurrent ? accent : Colors.white,
                  ),
                ),
              ),
              if (isCurrent) Icon(Icons.check_rounded, size: 22.ts(context), color: accent),
            ],
          ),
        ),
      ),
    );
  }
}
