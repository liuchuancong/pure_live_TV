import 'package:dpad/dpad.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/features/live_play/controllers/live_play_controller.dart';
import 'package:pure_live/features/live_play/models/live_play_args.dart';
import 'package:pure_live/features/live_play/states/live_play_state.dart';
import 'package:pure_live/features/live_play/widgets/danmaku/danmaku_list_view.dart';
import 'package:pure_live/features/live_play/widgets/panels/danmaku_settings_panel.dart';
import 'package:pure_live/features/live_play/widgets/panels/playlist_panel.dart';
import 'package:pure_live/features/live_play/widgets/panels/shield_panel.dart';
import 'package:pure_live/features/live_play/widgets/video_player/tv_video_surface.dart';
import 'package:pure_live/shared/models/live_room/live_room.dart';
import 'package:pure_live/shared/widgets/tv_common_avatar.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';

/// Landscape live playback page.
///
/// Left: video surface ([TvVideoSurface]); pressing OK on the D-pad opens the
/// control panel. Right: one of four panels — room info, playlist,
/// danmaku settings or danmaku filter (see [LivePlayPanel]).
class LivePlayPage extends ConsumerWidget {
  final LivePlayArgs args;

  const LivePlayPage({super.key, required this.args});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(livePlayControllerProvider(args));
    final controller = ref.read(livePlayControllerProvider(args).notifier);
    final tvTheme = context.tvTheme;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: DpadRegion(
                memoryKey: 'live_play/video',
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    TvVideoSurface(args: args),
                    // While the panel is collapsed, keep a touch-reachable way to reopen it; a
                    // remote uses the right key or the bottom bar.
                    if (!state.showSidePanel)
                      Positioned(
                        right: 16.sp,
                        bottom: 16.sp,
                        child: DpadFocusable(
                          effects: [
                            DpadScaleEffect(scale: 1.05),
                            DpadGlowEffect(color: tvTheme.focusColor.withValues(alpha: 0.5)),
                          ],
                          onSelect: () => controller.openPanel(LivePlayPanel.info),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 14.sp, vertical: 8.sp),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(8.sp),
                              border: Border.all(color: tvTheme.secondaryTextColor.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              i18n('ui_expand_panel'),
                              style: AppTextStyles.t14W500.copyWith(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (state.showSidePanel)
              Container(
                width: 360.sp,
                color: tvTheme.backgroundColor,
                child: DpadRegion(
                  // Each panel remembers its own focus and returns to the previous row.
                  memoryKey: 'live_play/side-panel/${state.panel.name}',
                  child: _SidePanel(
                    state: state,
                    controller: controller,
                    args: args,
                    onTogglePanel: controller.toggleSidePanel,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Side panel container. The content is chosen by [LivePlayState.panel].
///
/// A [Key] forces the subtree to rebuild when the panel changes, so the new
/// panel's `autofocus` row can take focus.
class _SidePanel extends ConsumerWidget {
  final LivePlayState state;
  final LivePlayController controller;
  final LivePlayArgs args;
  final VoidCallback onTogglePanel;

  const _SidePanel({required this.state, required this.controller, required this.args, required this.onTogglePanel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tvTheme = context.tvTheme;

    // Collapse button in the panel corner: it keeps a remote path back to the
    // video area.
    final collapse = Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 10.sp),
      child: DpadFocusable(
        effects: [
          DpadScaleEffect(scale: 1.03),
          DpadGlowEffect(color: tvTheme.focusColor.withValues(alpha: 0.4)),
        ],
        onSelect: onTogglePanel,
        child: Container(
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(vertical: 8.sp),
          decoration: BoxDecoration(color: tvTheme.cardColor, borderRadius: BorderRadius.circular(8.sp)),
          child: Text(
            i18n('ui_collapse_panel'),
            style: AppTextStyles.t14W500.copyWith(color: tvTheme.secondaryTextColor),
          ),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: _buildContent(context)),
        collapse,
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (state.panel) {
      case LivePlayPanel.info:
        return _InfoPanel(
          key: const ValueKey('live-play-panel-info'),
          state: state,
          controller: controller,
          args: args,
        );
      case LivePlayPanel.playlist:
        return PlaylistPanel(key: const ValueKey('live-play-panel-playlist'), args: args);
      case LivePlayPanel.danmakuSettings:
        return const DanmakuSettingsPanel(key: ValueKey('live-play-panel-danmaku'));
      case LivePlayPanel.shield:
        return const ShieldPanel(key: ValueKey('live-play-panel-shield'));
    }
  }
}

/// Room info, quality and line pickers, and the danmaku list.
class _InfoPanel extends ConsumerWidget {
  final LivePlayState state;
  final LivePlayController controller;
  final LivePlayArgs args;

  const _InfoPanel({super.key, required this.state, required this.controller, required this.args});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tvTheme = context.tvTheme;
    final room = state.room;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Room info header.
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 14.sp),
          child: Row(
            children: [
              TvCommonAvatar(avatarUrl: room?.avatar, radius: 24.sp, fallbackName: room?.nick),
              SizedBox(width: 12.sp),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room?.nick ?? (state.detailError ?? i18n('refresh_loading')),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.t18W600.copyWith(color: tvTheme.primaryTextColor),
                    ),
                    SizedBox(height: 4.sp),
                    Text(
                      _audienceLine(room),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.t14W500.copyWith(color: tvTheme.secondaryTextColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.sp),
          child: Text(
            room?.title ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.t14W500.copyWith(color: tvTheme.secondaryTextColor),
          ),
        ),
        SizedBox(height: 12.sp),
        Divider(height: 1, color: tvTheme.secondaryTextColor.withValues(alpha: 0.2)),
        SizedBox(height: 8.sp),
        _SectionLabel(text: i18n('recorder_stage_quality')),
        _ChipRow(
          memoryKey: 'live_play/chips/quality',
          labels: state.qualities.map((q) => q.quality).toList(growable: false),
          selectedIndex: state.qualityIndex,
          onSelect: controller.changeQuality,
        ),
        SizedBox(height: 8.sp),
        _SectionLabel(text: i18n('multiview_line_selector')),
        _ChipRow(
          memoryKey: 'live_play/chips/line',
          labels: [for (var i = 0; i < state.playUrls.length; i++) i18n('multiview_line', args: {'index': '${i + 1}'})],
          selectedIndex: state.lineIndex,
          onSelect: controller.changeLine,
        ),
        SizedBox(height: 8.sp),
        Divider(height: 1, color: tvTheme.secondaryTextColor.withValues(alpha: 0.2)),
        Expanded(
          child: state.playUrls.isEmpty ? const SizedBox.shrink() : DanmakuListView(args: args),
        ),
      ],
    );
  }

  String _audienceLine(LiveRoom? room) {
    if (room == null) return '';
    final watching = room.watching;
    final followers = room.followers;
    final parts = <String>[
      if (watching.isNotEmpty)
      i18n('audience_viewers_label', args: {'value': watching}),
      if (followers.isNotEmpty)
      '${i18n('audience_followers')} $followers',
    ];
    return parts.join(' · ');
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 4.sp),
      child: Text(text, style: AppTextStyles.t14W600.copyWith(color: tvTheme.secondaryTextColor)),
    );
  }
}

class _ChipRow extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final String memoryKey;

  const _ChipRow({
    required this.labels,
    required this.selectedIndex,
    required this.onSelect,
    required this.memoryKey,
  });

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    if (labels.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 4.sp),
        child: Text(i18n('ui_none'), style: AppTextStyles.t14W500.copyWith(color: tvTheme.secondaryTextColor)),
      );
    }
    return SizedBox(
      height: 48.sp,
      child: DpadRegion(
        memoryKey: memoryKey,
        horizontalEdge: DpadEdgeBehavior.wrap,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 16.sp),
          itemCount: labels.length,
          separatorBuilder: (_, _) => SizedBox(width: 8.sp),
          itemBuilder: (context, index) {
            final selected = index == selectedIndex;
            return DpadFocusable(
              effects: [
                DpadScaleEffect(scale: 1.05),
                DpadGlowEffect(color: tvTheme.focusColor.withValues(alpha: 0.5)),
              ],
              onSelect: () => onSelect(index),
              child: Container(
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(horizontal: 14.sp),
                decoration: BoxDecoration(
                  color: selected ? tvTheme.focusColor.withValues(alpha: 0.25) : tvTheme.cardColor,
                  borderRadius: BorderRadius.circular(8.sp),
                  border: Border.all(
                    color: selected ? tvTheme.focusColor : tvTheme.secondaryTextColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  labels[index],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.t14W500.copyWith(color: selected ? tvTheme.focusColor : tvTheme.primaryTextColor),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
