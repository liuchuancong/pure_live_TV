import 'dart:async';
import 'fijk_view_holder.dart';
import '../utils/fijk_helper.dart';
import 'package:flutter/material.dart';
import 'package:flv_lzc/fijkplayer.dart';
import 'package:media_core/media_core.dart';
import '../core/playback_proxy_policy.dart';
import '../../services/settings/settings.dart';

/// [PlayerAdapter] implementation backed by the local flv_lzc
/// (fijkplayer) plugin — the IJK engine.
///
/// Engine semantics:
///
/// - source-scoped event acceptance and deferred native errors
///   (FijkState.error can arrive before setDataSource completes) —
///   provided by the base
/// - proxy option for the app-owned loopback input
/// - audio-only via the `disable-vid` player option
/// - the view is exposed through [FijkViewHolder] so the surface
///   layer can rebuild without owning the adapter
/// - an honest capability declaration ([defaultCapabilities]): the engine
///   has no decoded-frame signal, so `supportsVideoFrameProgress` is false
///   and the live video-frame watchdog stays disabled for this backend
///   instead of being fed a fabricated heartbeat.
final class FlvLzcPlayerAdapter extends PlayerAdapterBase {
  /// Creates the adapter.
  FlvLzcPlayerAdapter({super.id = 'ijk', super.capabilities = defaultCapabilities, FijkPlayer? player})
    : _injectedPlayer = player;

  final FijkPlayer? _injectedPlayer;
  late final FijkPlayer _player = _injectedPlayer ?? FijkPlayer();

  bool _sourceBuffering = false;
  bool _privateInput = false;

  Duration _lastDuration = Duration.zero;
  Duration _lastPosition = Duration.zero;

  StreamSubscription<Duration>? _positionSubscription;

  BoxFit _videoFit = BoxFit.contain;

  /// The underlying FijkPlayer.
  FijkPlayer get fijkPlayer => _player;

  /// The holder surface widgets bind to.
  FijkViewHolder get viewHolder => _viewHolder;
  final FijkViewHolder _viewHolder = FijkViewHolder();

  // ---------------------------------------------------------------------------
  // Engine contract
  // ---------------------------------------------------------------------------

  @override
  Future<void> onInitialize(PlayerAdapterContext context) async {
    _player.addListener(_onPlayerValue);

    _positionSubscription = _player.onCurrentPosUpdate.listen(_onPositionChanged);

    // The controller applies the audio-only preference after initialize,
    // but a preference that arrived earlier must not be lost either.
    if (audioOnly) {
      await _applyAudioOnly(true);
    }
  }

  @override
  bool get engineReportsOpenFailure => _player.value.state == FijkState.error;

  @override
  Future<void> onOpen(PlayerSource source) async {
    final privateInput = _privateInput;
    _privateInput = false;

    _lastPosition = Duration.zero;
    _lastDuration = Duration.zero;
    _sourceBuffering = false;

    if (_player.state != FijkState.idle) {
      await _player.reset();
    }

    if (isDisposed) return;

    await _player.setDataSource(source.uri.toString(), autoPlay: false);

    if (isDisposed) return;

    await _player.setOption(
      FijkOption.formatCategory,
      'http_proxy',
      PlaybackProxyPolicy.currentNativeUrl(privateInput: privateInput),
    );

    if (isDisposed) return;

    await FijkHelper.setFijkOption(
      _player,
      enableCodec: SettingsService.to.playerState.enableCodec,
      disableAudioOutput: false,
      headers: source.hasHeaders ? Map<String, String>.from(source.headers!.values) : null,
    );

    if (isDisposed) return;

    // `disable-vid` is a player option, and a new data source follows the
    // same path as a fresh prepare, so re-assert it here: the replays
    // media_core performs on its own (same-engine retry, line cycling,
    // recovery) never go back through the application.
    if (audioOnly) {
      await _applyAudioOnly(true);
    }

    await _player.start();
  }

  @override
  Future<void> onPlay() => _player.start();

  @override
  Future<void> onPause() => _player.pause();

  @override
  Future<void> onStop() async {
    _sourceBuffering = false;
    await _player.stop();
  }

  @override
  Future<void> onSeek(Duration position) => _player.seekTo(position.inMilliseconds);

  @override
  Future<void> onSetVolume(double volume) => _player.setVolume(volume.clamp(0.0, 1.0));

  @override
  Future<void> onSetRate(double rate) async {
    // soundtouch enables tempo processing for rates != 1.0.
    await _player.setOption(FijkOption.playerCategory, 'soundtouch', rate != 1.0 ? 1 : 0);
    await _player.setSpeed(rate);
  }

  @override
  Future<void> onClose() async {
    _sourceBuffering = false;
    _lastPosition = Duration.zero;
    _lastDuration = Duration.zero;

    await _player.reset();
  }

  @override
  Future<void> onDispose() async {
    _player.removeListener(_onPlayerValue);

    await _positionSubscription?.cancel();
    _positionSubscription = null;

    try {
      await _player.release();
    } catch (_) {
      // Release races surface here on some devices; disposal
      // continues regardless.
    }
  }

  // ---------------------------------------------------------------------------
  // TV extensions
  // ---------------------------------------------------------------------------

  /// Whether the next open bypasses the native proxy.
  ///
  /// The source manager supplies an app-owned loopback input; the
  /// proxy must not intercept it.
  void setPrivateInput(bool value) => _privateInput = value;

  /// Restricts playback to the audio track through IJKPlayer's
  /// `disable-vid` option: the decoder is switched off, the stream is not
  /// merely hidden.
  @override
  Future<void> onSetAudioOnly(bool audioOnly) => _applyAudioOnly(audioOnly);

  /// Applies the audio-only preference to the engine.
  Future<void> _applyAudioOnly(bool audioOnly) async {
    if (isDisposed) return;

    await _player.setOption(FijkOption.playerCategory, 'disable-vid', audioOnly ? 1 : 0);
  }

  /// Applies the viewport fit without wrapping the texture in a
  /// transformed widget.
  void setVideoFit(BoxFit fit) {
    _videoFit = fit;
    _viewHolder.updateFit(fit);
  }

  /// The current viewport fit.
  BoxFit get videoFit => _videoFit;

  // ---------------------------------------------------------------------------
  // Position progress
  // ---------------------------------------------------------------------------

  /// Receives frequent playback-position updates from FijkPlayer.
  ///
  /// This is playback-position progress only.
  /// It is intentionally NOT used as a decoded-frame heartbeat.
  void _onPositionChanged(Duration position) {
    if (!acceptsEngineEvents) return;

    if (position != _lastPosition) {
      _lastPosition = position;
      emitPositionChanged(position);
    }
  }

  // ---------------------------------------------------------------------------
  // Value listener
  // ---------------------------------------------------------------------------

  void _onPlayerValue() {
    if (!acceptsEngineEvents) return;

    final value = _player.value;
    final state = value.state;

    // Dimensions.
    final size = value.size;
    if (size != null) {
      emitVideoSizeChangedIfChanged(size.width.toInt(), size.height.toInt());
    }

    // Buffering updates drive loading, independent of state.
    // FijkState.started can persist through buffering.
    if (state == FijkState.asyncPreparing || state == FijkState.prepared) {
      if (!_sourceBuffering) {
        _sourceBuffering = true;
        emitBuffering(true);
      }
    }

    switch (state) {
      case FijkState.started:
        if (_sourceBuffering) {
          _sourceBuffering = false;
          emitBuffering(false);
        }
        emitPlaying();

      case FijkState.paused:
        emitPaused();

      case FijkState.completed:
      case FijkState.end:
        emitCompleted();

      case FijkState.error:
        final native = value.exception;
        reportEngineError(
          message:
              'fijk error ${native.code}: '
              '${native.message ?? 'native playback failure'}',
        );

      case FijkState.stopped:
      case FijkState.idle:
      case FijkState.initialized:
      case FijkState.asyncPreparing:
      case FijkState.prepared:
        break;
    }

    // Duration (live streams report zero).
    final duration = value.duration;
    if (duration > Duration.zero && duration != _lastDuration) {
      _lastDuration = duration;
      emitDurationChanged(duration);
    }
  }

  /// Capabilities of the IJK engine (flv_lzc / fijkplayer), as exposed by
  /// this adapter.
  ///
  /// The declaration is scoped to what the adapter actually produces or
  /// accepts today, not to what the FFmpeg-backed IJKPlayer exposes in the
  /// abstract. Backend features that are not yet surfaced through the adapter
  /// (track lists, metadata, chapter navigation, dynamic filters, …) stay
  /// false; they can be flipped on the same line as the subscription or
  /// command that makes them real.
  ///
  /// [PlayerAdapterCapabilities] is the single source of truth for what this
  /// adapter supports: this class declares no `supportsXxx` field or getter of
  /// its own, and the base reads the snapshot directly.
  ///
  /// Signal emits and their capability flags:
  ///
  /// - [PlayerAdapterEvent.videoSizeChanged] is produced from `FijkValue.size`,
  ///   which IJK reports once decoding starts and on every later change.
  /// - [PlayerAdapterEvent.videoFrameProgress] is **not** produced: FijkPlayer
  ///   publishes no per-frame callback, and the events it does expose
  ///   (`addListener` state / size changes, `onCurrentPosUpdate`) do not prove
  ///   that a frame was decoded at the current moment. Polling
  ///   [FijkState.started] is not that proof either — it only reports what the
  ///   player already believes. The flag therefore stays false and
  ///   [LiveWatchdogs] keeps its video-frame stall detector off for this
  ///   backend.
  static const PlayerAdapterCapabilities defaultCapabilities = PlayerAdapterCapabilities(
    // Core playback.
    //
    // Every command hook is implemented against FijkPlayer: start() /
    // pause() / stop() / seekTo() / setVolume() / setSpeed() (with soundtouch
    // enabled for rates != 1.0). Mute is setVolume(0.0).
    supportsLive: true,
    supportsSeek: true,
    supportsPause: true,
    supportsStop: true,
    supportsRateControl: true,
    supportsVolumeControl: true,
    supportsMuteControl: true,

    // `supportsAudioOnly` is true: IJKPlayer's `disable-vid` option stops
    // video decoding for the source instead of hiding the picture, and it
    // is re-applied on every open.
    supportsAudioOnly: true,

    // Video and rendering.
    //
    // `supportsVideoSizeChanged` is true because the adapter consumes
    // `FijkValue.size`.
    //
    // `supportsVideoFrameProgress` is false: IJKPlayer has no callback that
    // proves frame-level progress, and playback-position updates are not a
    // substitute. The live video-frame watchdog must therefore stay disabled
    // for this backend rather than be fed a fabricated heartbeat.
    //
    // The remaining video capabilities are not exposed through the adapter:
    // screenshots would need a custom renderer or a modified native layer, and
    // there is no reconfig / hwdec / filter surface.
    supportsVideoFrameProgress: false,
    supportsVideoSizeChanged: true,
    supportsVideoReconfig: false,
    supportsHwdecInfo: false,
    supportsVideoFilters: false,
    supportsScreenshot: false,

    // Audio.
    //
    // IJK can switch audio output and apply audio filters through setOption,
    // but the adapter exposes neither surface.
    supportsAudioReconfig: false,
    supportsAudioDeviceSelection: false,
    supportsAudioFilters: false,

    // Tracks and subtitles.
    //
    // The adapter can toggle the video track for audio-only playback, but it
    // has no track-list surface and does not forward subtitle payloads.
    supportsTrackSelection: false,
    supportsSubtitleTrack: false,
    supportsExternalSubtitle: false,

    // Playback state and buffering.
    //
    // Buffering transitions are reported without a ratio, so no buffering
    // progress is promised, and there is no cache or chapter surface.
    supportsCacheState: false,
    supportsBufferingProgress: false,
    supportsChapterControl: false,
    supportsLoop: false,

    // Metadata and playlist.
    //
    // getMediaInfo() could expose metadata, but the adapter does not
    // subscribe to it or publish it as a stream.
    supportsMetadata: false,
    supportsPlaylist: false,
    supportsPlaylistControl: false,

    // Diagnostics and integration.
    supportsClientMessage: false,
    supportsLogMessages: false,

    // Decoders.
    //
    // The flv_lzc build ships both the FFmpeg software decoder and the
    // MediaCodec hardware path, and the adapter can select between them.
    supportsHardwareDecoder: true,
    supportsSoftwareDecoder: true,

    // Presentation.
    //
    // PiP is not provided by IJKPlayer; fullscreen is a widget-level decision
    // the adapter does not veto.
    supportsPictureInPicture: false,
    supportsFullscreen: true,

    // Source matching.
    //
    // The FFmpeg build covers a wider protocol and format set than most
    // engines, including RTMP and RTSP.
    supportedProtocols: {'http', 'https', 'hls', 'rtmp', 'rtsp', 'udp', 'file', 'asset'},
    supportedFormats: {'mp4', 'mkv', 'webm', 'flv', 'm3u8', 'mov', 'avi', 'ts', 'h265', 'hevc'},
  );
}
