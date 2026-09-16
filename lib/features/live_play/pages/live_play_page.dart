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

/// Fullscreen live playback page.
///
/// The video always fills the screen (a TV room is fullscreen, period): the
/// room info, playlist, danmaku settings and danmaku filter panels (see
/// [LivePlayPanel]) float over it as an overlay card on the right instead of
/// squeezing the video into a column.
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
      body: Stack(
        fit: StackFit.expand,
        children: [
          DpadRegion(
            memoryKey: 'live_play/video',
            child: TvVideoSurface(args: args),
          ),
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
          // The panel overlays the video instead of sitting beside it: playback
          // keeps the whole screen and the danmaku keep their geometry.
          if (state.showSidePanel)
            Positioned(
              top: 24.sp,
              bottom: 24.sp,
              right: 24.sp,
              width: 400.sp,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20.sp),
                child: Container(
                  decoration: BoxDecoration(
                    color: tvTheme.backgroundColor.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(20.sp),
                    border: Border.all(color: tvTheme.focusColor.withValues(alpha: 0.35)),
                  ),
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
              ),
            ),
        ],
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
        // 清晰度 / 线路 / 画面比例 / 播放器内核 live in the fullscreen control
        // bar's dialogs, next to where playback is controlled; duplicating the
        // first two here fought the panel for space on a TV screen.
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

