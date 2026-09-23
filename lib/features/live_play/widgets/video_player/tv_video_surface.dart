import 'package:pure_live/player/index.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/widgets/index.dart';
import 'package:pure_live/shared/utils/text_util.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/models/live_room/live_room.dart';
import 'package:pure_live/features/live_play/models/live_play_args.dart';
import 'package:pure_live/features/live_play/widgets/danmaku/danmaku_overlay.dart';
import 'package:pure_live/features/live_play/controllers/live_play_controller.dart';
import 'package:pure_live/features/live_play/widgets/video_player/video_controller_panel.dart';
import 'package:pure_live/features/live_play/widgets/video_player/playback_failure_overlay.dart';
import 'package:pure_live/features/live_play/widgets/placeholder/not_living_video_widget.dart';
import 'package:pure_live/features/live_play/widgets/video_player/audio_only_surface.dart';

/// Video surface: a Stack of the PlayerManager video layer, the flame_barrage
/// overlay, loading/error overlays and an auto-hiding D-pad control panel.
///
/// Remote key layout, ported from handleKeyNoPanel in the legacy app:
/// - Up / Down: previous / next channel, wrapping through the playlist or
///   watch history
/// - Left: double press to follow or unfollow
/// - Right: open the playlist panel
/// - OK: show the bottom control bar
///
/// Every direction key is consumed here so focus cannot escape the player and
/// leave the remote apparently dead.

/// The audience read-out of the info bar.
///
/// Plain [LiveRoom.watching] rather than the settings-driven policy: this is a
/// glanceable badge next to the streamer's name, and a missing value must simply
/// not render instead of saying "unknown".
String _audienceText(LiveRoom room) {
  final String raw = room.watching.trim().isNotEmpty ? room.watching.trim() : room.onlineViewers.trim();
  if (raw.isEmpty) return '';
  final String readable = readableCount(raw);
  return readable.isEmpty ? '' : readable;
}

/// A small label pill for the room-info bar: the platform badge (accent filled)
/// and the audience read-out (plain).
class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label, this.icon, this.accent, this.filled = false});

  final String label;
  final IconData? icon;
  final Color? accent;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final Color color = accent ?? Colors.white;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.sp, vertical: 3.sp),
      decoration: BoxDecoration(
        color: filled ? color.withValues(alpha: 0.22) : Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8.sp),
        border: Border.all(color: filled ? color.withValues(alpha: 0.75) : Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 16.sp, color: Colors.white70), SizedBox(width: 4.sp)],
          Text(label, style: AppTextStyles.t16W600.copyWith(color: filled ? Colors.white : Colors.white70)),
        ],
      ),
    );
  }
}

class TvVideoSurface extends ConsumerStatefulWidget {
  final LivePlayArgs args;

  const TvVideoSurface({super.key, required this.args});

  @override
  ConsumerState<TvVideoSurface> createState() => _TvVideoSurfaceState();
}

class _TvVideoSurfaceState extends ConsumerState<TvVideoSurface> {
  /// The player manager, or null until [GlobalPlayerService] has finished
  /// initializing.
  ///
  /// `GlobalPlayerService.playerManager` is a `late final` field: reading it
  /// before initialization throws `LateInitializationError`, and a build that
  /// throws tears down whatever the previous build had mounted — which disposed
  /// media_kit's video output and made the next successful frame create a new
  /// one. That is the whole `VideoOutputManager.create` → `dispose` →
  /// `Resize 0x0` → `Surface.release()` NPE sequence in logcat. Never read the
  /// field without this check.
  LivePlayerFacade? get _playerManagerOrNull =>
      GlobalPlayerService.instance.initialized ? GlobalPlayerService.instance.livePlayer : null;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(livePlayControllerProvider(widget.args));
    final controller = ref.read(livePlayControllerProvider(widget.args).notifier);
    final tvTheme = context.tvTheme;

    // Room-detail loading is a business-level concern: it is not a player
    // state, so it is derived from LivePlayState's own fields.
    final bool loadingDetail = state.room == null && state.detailError == null;

    // Show the spinner while the detail request or the player itself is
    // still working. Playback progress comes exclusively from media_core's
    // PlayerState; there is no local LivePlayStatus.
    //
    // Only the *first* connection of a room paints it. Switching quality or CDN
    // line reopens the source on the same native player, so the reference client
    // never shows an overlay there — it is what makes its switch read as a
    // silent background update. The TV used to key this off the raw
    // opening/buffering state, so every switch and every live re-buffer flashed a
    // spinner (and, with it, a visible gap) over the picture.
    final bool showLoading =
        !loadingDetail &&
        !state.isOffline &&
        !state.hasStartedPlayback &&
        (state.playerState.opening || state.playerState.buffering);

    // A single error flag for the overlay: business failures (detail / stream
    // URL / play() throwing) surface through errorMessage or detailError;
    // terminal playback failures from media_core surface through
    // playerState.hasError (the controller also mirrors them into errorMessage
    // via ErrorFormatter).
    // 离线不是错误：房间信息拿到了，只是没在播，所以走占位页而不是失败层。
    final bool showError =
        !state.isOffline && (state.errorMessage != null || state.detailError != null || state.playerState.hasError);

    // The video widget stays mounted for the whole session, and the surface is
    // simply black until the player service is up.
    //
    // It used to be replaced by a black `Container` whenever `showError` was
    // true, and the manager getter threw while the service was still starting.
    // Either way the previously mounted `Video` was torn down, which disposed
    // media_kit's video output and made the next frame create a new one — the
    // `VideoOutputManager.create` → `dispose` → `Resize 0x0` → `Surface.release()`
    // NPE sequence in logcat (an output destroyed before it ever had a surface).
    // The failure overlay is drawn on top of the surface instead.
    final LivePlayerFacade? manager = _playerManagerOrNull;
    // The surface listens to `videoKey` on purpose: an engine switch bumps the
    // key, and this rebuild is what unmounts the `Video` widget of the retired
    // controller *before* PlayerManager destroys it. Without the listener the
    // old subtree survived until the next unrelated state change and kept
    // throwing "A ValueNotifier<int?> was used after being disposed".
    final Widget video = manager != null
        ? StreamBuilder<ValueKey>(
            stream: manager.videoKey.stream,
            initialData: manager.videoKey.value,
            builder: (context, _) => manager.getVideoWidget(state.fitIndex, fitList: kLivePlayFitList),
          )
        : const ColoredBox(color: Colors.black);

    // Audio-only mode: the picture is replaced by the room panel, but the video
    // widget is only hidden, never unmounted — tearing it down disposes the
    // engine's video output and the restore would then have to rebuild the
    // whole texture. The listener mirrors what the settings page pushes into the
    // player, so the panel appears the moment the switch flips.
    final Widget videoLayer = manager == null
        ? video
        : StreamBuilder<bool>(
            stream: manager.onAudioOnlyChanged,
            initialData: manager.isAudioOnly,
            builder: (context, snapshot) {
              final bool audioOnly = snapshot.data ?? false;
              return Stack(
                fit: StackFit.expand,
                children: [
                  Offstage(offstage: audioOnly, child: video),
                  if (audioOnly) AudioOnlySurface(room: state.room),
                ],
              );
            },
          );

    final children = <Widget>[
      // The video area is NOT a d-pad node any more: the whole player is key
      // handled by [LivePlayPage], exactly like the reference player. Keys reach
      // it through the page-level [Focus], so nothing here competes for focus.
      Stack(
        fit: StackFit.expand,
        children: [
          videoLayer,
          DanmakuOverlay(args: widget.args),
          if (showLoading && !showError)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  tvInlineLoading(context, size: 36.sp),
                  SizedBox(height: 12.sp),
                  Text(
                    loadingDetail ? i18n('ui_loading_room_info') : i18n('ui_buffering'),
                    style: AppTextStyles.t16W500.copyWith(color: tvTheme.secondaryTextColor),
                  ),
                ],
              ),
            ),
          // Room info and the wall clock in **one** floating card: avatar, title
          // and a metadata line (platform, streamer, audience) on the left, the
          // clock behind a divider on the right. Two cards side by side read as
          // two unrelated read-outs instead of one room banner.
          if (!showError && state.room != null && state.showControls)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: IgnorePointer(
                child: Container(
                  padding: EdgeInsets.fromLTRB(20.sp, 12.sp, 20.sp, 18.sp),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black.withValues(alpha: 0.72), Colors.black.withValues(alpha: 0.0)],
                    ),
                  ),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 12.sp),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.42),
                      borderRadius: BorderRadius.circular(18.sp),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                    ),
                    child: Row(
                      children: [
                        TvCommonAvatar(
                          avatarUrl: state.room!.avatar,
                          fallbackName: state.room!.nick,
                          radius: 30.sp,
                        ),
                        SizedBox(width: 14.sp),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                state.room!.title.trim().isNotEmpty
                                    ? state.room!.title.trim()
                                    : i18n('untitled_room'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.t28W600.copyWith(color: Colors.white),
                              ),
                              SizedBox(height: 8.sp),
                              Row(
                                children: [
                                  if (state.room!.platform.isNotEmpty) ...[
                                    _InfoPill(
                                      label: state.room!.platform.toUpperCase(),
                                      accent: tvTheme.focusColor,
                                      filled: true,
                                    ),
                                    SizedBox(width: 10.sp),
                                  ],
                                  if (state.room!.nick.isNotEmpty)
                                    Flexible(
                                      child: Text(
                                        state.room!.nick,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTextStyles.t18W500.copyWith(color: Colors.white70),
                                      ),
                                    ),
                                  if (state.room!.nick.isNotEmpty && _audienceText(state.room!).isNotEmpty)
                                    SizedBox(width: 10.sp),
                                  if (_audienceText(state.room!).isNotEmpty)
                                    _InfoPill(label: _audienceText(state.room!), icon: Icons.whatshot_rounded),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 18.sp),
                        Container(width: 1.sp, height: 44.sp, color: Colors.white.withValues(alpha: 0.14)),
                        SizedBox(width: 18.sp),
                        // Wall clock: a live stream has no duration, so the time a
                        // viewer glances up for is the time of day.
                        Icon(RemixIcons.time_line, size: 24.sp, color: Colors.white70),
                        SizedBox(width: 8.sp),
                        TvDigitalClock(
                          format: 'HH:mm',
                          style: AppTextStyles.t28W600.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ), // Channel name toast shown after an up/down switch.
          if (state.showChannelBanner)
            Positioned(
              left: 0,
              right: 0,
              top: 64.sp,
              child: IgnorePointer(
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 24.sp, vertical: 12.sp),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(12.sp),
                      border: Border.all(color: tvTheme.focusColor.withValues(alpha: 0.6)),
                    ),
                    child: Text(
                      state.channelBanner!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.t24W600.copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ];

    if (showError) {
      children.add(
        Positioned.fill(
          child: PlaybackFailureOverlay(
            message: state.errorMessage ?? i18n('multiview_play_failed'),
            onRetry: controller.retry,
            onRefreshRoom: controller.refreshRoom,
          ),
        ),
      );
    } else if (state.isOffline) {
      // 未开播：占位页自带两个可聚焦按钮（切换直播间 / 重新检测），
      // 所以这里不再挂底部控制条——否则两套焦点互相抢。
      children.add(Positioned.fill(child: NotLivingVideoWidget(args: widget.args)));
    } else if (state.showControls) {
      // Flush to the bottom edge: the bar's own black band is the anchor, and
      // floating it above the edge left a strip of live picture under it.
      children.add(Positioned(left: 0, right: 0, bottom: 0, child: VideoControllerPanel(args: widget.args)));
    }

    // The quality / line read-out that used to sit on the right edge is gone:
    // both live on the control bar, which is where the user picks them, and a
    // permanent copy over the picture is one more thing competing with the
    // stream. A switch in progress is still reported — by the bar's own pill,
    // whose glyph turns into a ring while it applies.

    return Stack(fit: StackFit.expand, children: children);
  }
}
