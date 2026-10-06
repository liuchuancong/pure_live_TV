import 'package:pure_live/exports/exports.dart';
import 'package:pure_live/modules/vod/models/models.dart';

/// newBV's subtitle tab: pick one of the archive's CC tracks or switch them
/// off, then tune the overlay's appearance (size / opacity / bottom spacing) —
/// the same three [VideoSettingsModel] knobs the CC layer renders with, so
/// edits apply live.
class VideoSubtitleMenu extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final tvTheme = context.tvTheme;
    final accent = tvTheme.focusColor;
    final settings = ref.watch(videoSettingsControllerProvider);
    final controller = ref.read(videoSettingsControllerProvider.notifier);

    void setSize(int delta) => controller.updateSettings(
      settings.copyWith(
        subtitleFontSize: (settings.subtitleFontSize + delta).clamp(8, 48),
      ),
    );
    void setOpacity(int delta) => controller.updateSettings(
      settings.copyWith(
        subtitleBgOpacity: (settings.subtitleBgOpacity * 100 + delta).clamp(0, 100) / 100,
      ),
    );
    void setPadding(int delta) => controller.updateSettings(
      settings.copyWith(
        subtitleBottomPadding: (settings.subtitleBottomPadding + delta).clamp(0, 48),
      ),
    );

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
          SizedBox(height: 4.ts(context)),
          _AdjustRow(
            icon: Icons.format_size_rounded,
            label: i18n('video_subtitle_size'),
            valueText: '${settings.subtitleFontSize}sp',
            onPrev: () => setSize(-2),
            onNext: () => setSize(2),
          ),
          _AdjustRow(
            icon: Icons.opacity_rounded,
            label: i18n('video_subtitle_bg'),
            valueText: '${(settings.subtitleBgOpacity * 100).round()}%',
            onPrev: () => setOpacity(-5),
            onNext: () => setOpacity(5),
          ),
          _AdjustRow(
            icon: Icons.vertical_align_bottom_rounded,
            label: i18n('video_subtitle_padding'),
            valueText: '${settings.subtitleBottomPadding}dp',
            onPrev: () => setPadding(-2),
            onNext: () => setPadding(2),
          ),
          SizedBox(height: 8.ts(context)),
        ],
      ),
    );
  }
}

/// A `label  ‹ value ›` row: LEFT/RIGHT focus a chevron button, OK nudges the
/// setting by one step — the player menu's take on newBV's StepLessMenuItem.
class _AdjustRow extends StatelessWidget {
  const _AdjustRow({
    required this.icon,
    required this.label,
    required this.valueText,
    required this.onPrev,
    required this.onNext,
  });

  final IconData icon;
  final String label;
  final String valueText;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final accent = context.tvTheme.focusColor;
    return Padding(
      padding: EdgeInsets.only(left: 12.sp, right: 12.sp, bottom: 8.sp),
      child: Container(
        height: 56.ts(context),
        padding: EdgeInsets.symmetric(horizontal: 14.ts(context)),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12.ts(context)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22.ts(context), color: Colors.white70),
            SizedBox(width: 10.ts(context)),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.t16.copyWith(fontWeight: FontWeight.w500, color: Colors.white),
              ),
            ),
            _Chevron(icon: Icons.chevron_left_rounded, onTap: onPrev),
            SizedBox(
              width: 64.ts(context),
              child: Text(
                valueText,
                textAlign: TextAlign.center,
                style: AppTextStyles.t16.copyWith(fontWeight: FontWeight.w600, color: accent),
              ),
            ),
            _Chevron(icon: Icons.chevron_right_rounded, onTap: onNext),
          ],
        ),
      ),
    );
  }
}

class _Chevron extends StatelessWidget {
  const _Chevron({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = context.tvTheme.focusColor;
    return TvFocusable(
      onTap: onTap,
      builder: (context, focused, child) => Container(
        width: 40.ts(context),
        height: 40.ts(context),
        decoration: BoxDecoration(
          color: focused ? accent.withValues(alpha: 0.28) : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10.ts(context)),
          border: Border.all(color: focused ? accent : Colors.transparent, width: 2.ts(context)),
        ),
        child: Icon(icon, size: 24.ts(context), color: Colors.white),
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
