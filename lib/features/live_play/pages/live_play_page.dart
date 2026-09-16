import 'package:dpad/dpad.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/features/live_play/controllers/live_play_controller.dart';
import 'package:pure_live/features/live_play/models/live_play_args.dart';
import 'package:pure_live/features/live_play/states/live_play_state.dart';
import 'package:pure_live/features/live_play/widgets/panels/danmaku_settings_panel.dart';
import 'package:pure_live/features/live_play/widgets/panels/playlist_panel.dart';
import 'package:pure_live/features/live_play/widgets/panels/shield_panel.dart';
import 'package:pure_live/features/live_play/widgets/video_player/tv_video_surface.dart';
import 'package:pure_live/features/live_play/widgets/player_key_scope.dart';
import 'package:pure_live/features/live_play/player_panel_layout.dart';
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

    return PlayerKeyScope(
      args: args,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
        fit: StackFit.expand,
        children: [
          DpadRegion(
            memoryKey: 'live_play/video',
            child: TvVideoSurface(args: args),
          ),
          // The panel overlays the video instead of sitting beside it: playback
          // keeps the whole screen and the danmaku keep their geometry.
          if (state.showSidePanel)
            Positioned(
              top: 24.sp,
              bottom: 24.sp,
              left: PlayerPanelLayout.isLeft ? PlayerPanelLayout.offset.sp : null,
              right: PlayerPanelLayout.isLeft ? null : PlayerPanelLayout.offset.sp,
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
                    memoryKey: 'live_play/side-panel/${state.panel?.name ?? 'none'}',
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
    // The panel carries its own visible 返回 row now, so the old d-pad collapse
    // button is just a hint.
    final collapse = Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 10.sp),
      child: Text(
        i18nOr('ui_panel_keys', '↑↓ select · OK confirm · ← back'),
        style: AppTextStyles.t14W500.copyWith(color: tvTheme.secondaryTextColor),
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
      // No panel open (or the layout state did not record one yet).
      case null:
        return const SizedBox.shrink();
      case LivePlayPanel.playlist:
        return PlaylistPanel(key: const ValueKey('live-play-panel-playlist'), args: args);
      case LivePlayPanel.danmakuSettings:
        return DanmakuSettingsPanel(key: const ValueKey('live-play-panel-danmaku'), onClose: onTogglePanel);
      case LivePlayPanel.shield:
        return ShieldPanel(key: const ValueKey('live-play-panel-shield'), onClose: onTogglePanel);
    }
  }
}


