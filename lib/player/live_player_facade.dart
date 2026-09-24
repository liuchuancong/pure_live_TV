import 'dart:async';
import 'models/player_engine.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart' hide Rx;
import 'package:media_core/media_core.dart';
import '../services/settings/settings.dart';
import 'core/live_room_volume_manager.dart';
import 'core/playback_header_resolver.dart';
import '../app/consts/app_theme_consts.dart';
import '../shared/models/live_room/live_room.dart';
import 'package:media_core_media_kit/media_core_media_kit.dart';
import 'package:media_core_ijk_player/media_core_ijk_player.dart';
import 'package:media_core_better_player/media_core_video_player.dart';

/// App-facing facade over media_core's [LivePlaybackController].
///
/// Keeps the surface the features already consume — BehaviorSubject
/// state, videoKey bumps, engine switching, fit and volume — while
/// the watchdog / line / engine recovery runs inside media_core.
///
/// Playback state and errors are surfaced as-is: [PlayerState] and
/// [PlayerFailure]. No app-side wrapper types are introduced.
///
/// ```text
/// features ──▶ LivePlayerFacade ──▶ LivePlaybackController (media_core)
///                    │                     └── PlayerKernel / adapters
///                    └── PlayerVideo.build() (owned by each adapter)
/// ```
final class LivePlayerFacade {
  /// Creates the facade.
  LivePlayerFacade(PlayerKernel kernel, {required PlayerEngine defaultEngine, this._onPreferredEngineChanged})
    : _controller = LivePlaybackController(kernel),
      preferredEngine = defaultEngine {
    _bindController();
  }

  /// The engine the app prefers for the next session.
  PlayerEngine preferredEngine;

  final LivePlaybackController _controller;

  // Callback stored through the initializer list.
  // ignore: prefer_initializing_formals
  final void Function(PlayerEngine engine)? _onPreferredEngineChanged;

  // ---------------------------------------------------------------------------
  // Rx state (the legacy surface)
  // ---------------------------------------------------------------------------

  final _stateSubject = BehaviorSubject<PlayerState>.seeded(const PlayerState());

  final _playingSubject = BehaviorSubject<bool>.seeded(false);

  final _errorSubject = PublishSubject<PlayerFailure>();

  final _widthSubject = BehaviorSubject<int?>.seeded(null);

  final _heightSubject = BehaviorSubject<int?>.seeded(null);

  final videoFitIndex = BehaviorSubject<int>.seeded(0);

  final videoKey = BehaviorSubject<ValueKey>.seeded(const ValueKey('video_0'));

  final isVerticalVideo = BehaviorSubject<bool>.seeded(false);

  /// Audio-only playback mode, as the play page sees it.
  ///
  /// Seeded from the persisted setting so a room entered after a settings
  /// restore (backup / WebDAV / LAN sync) starts in the right mode.
  final _audioOnlySubject = BehaviorSubject<bool>.seeded(SettingsService.to.playerState.audioOnly);

  /// Audio-only playback mode stream.
  Stream<bool> get onAudioOnlyChanged => _audioOnlySubject.stream;

  StreamSubscription<PlayerFailure>? _errorSub;
  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<PlayerAdapterEvent>? _adapterSub;

  bool _disposed = false;

  // ---------------------------------------------------------------------------
  // Last playback request
  // ---------------------------------------------------------------------------

  /// The last complete source request handed to media_core.
  ///
  /// Keeping the request as one object prevents the URL, fallback lines,
  /// headers and room metadata from drifting apart during an engine switch.
  LiveSourceRequest? _lastRequest;

  // ---------------------------------------------------------------------------
  // Handle / adapter binding
  // ---------------------------------------------------------------------------

  /// The handle whose adapter events are currently bound.
  ///
  /// The controller creates its handle inside its first open(), so binding
  /// before play() would not bind anything. We therefore check the handle
  /// whenever the facade interacts with the controller.
  PlayerHandle? _boundHandle;

  /// Whether the adapter last reported buffering.
  ///
  /// media_core declares buffering the moment open() returns, and that is not
  /// the adapter's opinion. For a live stream it can also be the last state
  /// change there ever is, which leaves the spinner on screen over a picture
  /// that is playing fine. Only the adapter's own report separates the two.
  bool _adapterBuffering = false;

  // ---------------------------------------------------------------------------
  // Engine switch coordination
  // ---------------------------------------------------------------------------

  /// Monotonically increasing token used to invalidate stale engine switches.
  ///
  /// If the user switches engines several times quickly, an older async switch
  /// must not reopen a source after a newer switch has already started.
  int _engineSwitchGeneration = 0;

  int _videoKeyGeneration = 0;

  // ---------------------------------------------------------------------------
  // Streams (the legacy surface)
  // ---------------------------------------------------------------------------

  Stream<PlayerState> get onStateChanged => _stateSubject.stream;

  Stream<bool> get onPlaying => _playingSubject.stream;

  Stream<PlayerFailure> get onError => _errorSubject.stream;

  bool get initialized => !_stateSubject.value.disposed;

  bool get isPlayingNow => _playingSubject.value;

  /// The underlying media_core controller.
  LivePlaybackController get controller => _controller;

  // ---------------------------------------------------------------------------
  // Controller binding
  // ---------------------------------------------------------------------------

  /// Binds the controller-level streams.
  ///
  /// Controller streams live for the lifetime of the facade, so these
  /// subscriptions are created once instead of being recreated on every play.
  void _bindController() {
    _stateSub = _controller.onStateChanged.listen(_onLiveStateChanged);

    _errorSub = _controller.onError.listen((failure) {
      if (_disposed) return;
      _errorSubject.add(failure);
    });
  }

  /// Makes sure the current controller handle has its adapter events bound.
  void _bindCurrentHandle() {
    if (_disposed) return;

    final handle = _controller.handle;

    if (handle == null) {
      return;
    }

    if (identical(handle, _boundHandle)) {
      return;
    }

    _boundHandle = handle;
    _bindAdapter(handle);
  }

  void _bindAdapter(PlayerHandle handle) {
    unawaited(_adapterSub?.cancel());

    _adapterBuffering = false;

    _adapterSub = handle.adapter.events.listen(_onAdapterEvent, onError: (Object _) {});
  }

  void _onAdapterEvent(PlayerAdapterEvent event) {
    if (_disposed) return;

    if (event is PlayerAdapterPlaying) {
      _adapterBuffering = false;
      _playingSubject.add(true);
      _syncBackgroundVideoSuspension(true);
      return;
    }

    if (event is PlayerAdapterPaused) {
      _playingSubject.add(false);
      // A pause is not the end of the room, and ExoPlayer reports one for every
      // buffering hiccup (`onIsPlayingChanged` is playWhenReady && READY). Only
      // [PlayerAdapterStopped] and close() release the background wallpaper:
      // toggling it here tore the wallpaper's decoder down and rebuilt it on
      // every rebuffer, which flickered on Android TV.
      return;
    }

    if (event is PlayerAdapterStopped) {
      _adapterBuffering = false;
      _playingSubject.add(false);
      _syncBackgroundVideoSuspension(false);
      return;
    }

    if (event case PlayerAdapterBuffering(buffering: final buffering)) {
      _adapterBuffering = buffering;
      return;
    }

    if (event case PlayerAdapterVideoSizeChanged(width: final width, height: final height)) {
      _widthSubject.add(width);
      _heightSubject.add(height);
      isVerticalVideo.add(height >= width);
    }
  }

  /// 在 Android TV 上表现为两边画面一起闪）。
  void _syncBackgroundVideoSuspension(bool playing) {
    try {
      unawaited(SettingsService.to.bg.setPlaybackActive(playing));
    } catch (_) {
      // 设置未就绪（例如启动早期的测试环境）时忽略：壁纸层保持原状即可。
    }
  }

  void _onLiveStateChanged(PlayerState state) {
    if (_disposed) return;

    // media_core raises buffering the moment open() returns, and for a live
    // stream that declaration can be the last state change there ever is -
    // which pins the spinner over a picture that is playing fine. Only a
    // buffering state reported by the adapter itself is considered real.
    //
    // When media_core reports synthetic buffering while the adapter is already
    // playing, mirror the state as playing so the controller/UI does not remain
    // stuck in buffering.
    if (state.playback == PlayerPlaybackState.buffering && !_adapterBuffering) {
      _stateSubject.add(state.copyWith(playback: PlayerPlaybackState.playing));
      return;
    }

    _stateSubject.add(state);
  }

  // ---------------------------------------------------------------------------
  // Playback
  // ---------------------------------------------------------------------------

  /// Starts playing [url] with [playUrls] as fallback lines.
  Future<void> play(String url, List<String> playUrls, Map<String, String> headers, {LiveRoom? room}) async {
    if (_disposed) {
      throw StateError('LivePlayerFacade has already been disposed');
    }

    final sourceUrl = url.trim();

    if (sourceUrl.isEmpty) {
      throw ArgumentError('Remote playback source is empty');
    }

    // With no explicit headers, resolve them per platform (UA /
    // referer the live site requires).
    Map<String, String> effectiveHeaders = headers;

    if (headers.isEmpty && room != null && room.platform.isNotEmpty) {
      effectiveHeaders = await PlaybackHeaderResolver.resolve(
        platform: room.platform,
        roomId: room.roomId,
        roomHeaders: room.httpHeaders,
      );
    }

    final urls = <String>[
      if (playUrls.isEmpty) sourceUrl else ...[sourceUrl, ...playUrls.where((value) => value != sourceUrl)],
    ];

    final request = LiveSourceRequest(urls: urls, headers: effectiveHeaders, title: room?.title);

    // Remember the complete request before opening it.
    //
    // An engine switch can happen immediately after play() returns, so the
    // replay path must have the exact same source information available.
    _lastRequest = request;

    await _controller.play(request);

    // The controller creates the handle during open().
    // Bind it immediately after play has created it.
    _bindCurrentHandle();

    // Apply the audio-only preference to the freshly bound adapter.
    //
    // The controller remembers it, so engine switch and recovery paths inside
    // media_core can re-apply it without the app having to duplicate that
    // logic.
    await setAudioOnly(SettingsService.to.playerState.audioOnly);

    if (room != null) {
      final volume = LiveRoomVolumeManager.getRoomVolume(room.platform, room.roomId).clamp(0.0, 1.0);

      await setVolume(volume);
    }

    // Some adapters can replace their handle during the open/recovery path.
    // Check once more after all adapter configuration has completed.
    _bindCurrentHandle();
  }

  /// Replays the current source.
  Future<void> retry() async {
    if (_disposed) return;

    await _controller.retry();
    _bindCurrentHandle();
  }

  /// Toggles play/pause.
  Future<void> togglePlayPause() async {
    if (_disposed) return;

    await _controller.togglePlayPause();
    _bindCurrentHandle();
  }

  /// Pauses playback.
  Future<void> pause() async {
    if (_disposed) return;

    await _controller.pause();
  }

  /// Resumes playback.
  Future<void> resume() async {
    if (_disposed) return;

    await _controller.resume();
    _bindCurrentHandle();
  }

  /// Stops playback and releases the player.
  Future<void> close() async {
    if (_disposed) return;

    _syncBackgroundVideoSuspension(false);

    await _controller.close();

    _boundHandle = null;
    _adapterBuffering = false;
    _playingSubject.add(false);

    await _adapterSub?.cancel();
    _adapterSub = null;
  }

  /// Sets the volume (0.0–1.0).
  /// Sets the volume (0.0–1.0).
  Future<void> setVolume(double volume) async {
    if (_disposed) {
      return;
    }

    final normalized = volume.clamp(0.0, 1.0);

    await _controller.setVolume(normalized);
  }

  /// Whether playback is restricted to the audio track.
  bool get isAudioOnly => _audioOnlySubject.value;

  /// Restricts playback to the audio track.
  ///
  /// [isAudioOnlySubject] is the surface the UI listens to: the audio-only
  /// panel replaces the video surface on the play page, and it has to
  /// appear even when the active engine cannot switch its video track off
  /// (see `BetterPlayerAdapter`). The track switch itself is the
  /// controller's business — it stores the preference, applies it to the
  /// adapter that declares [PlayerAdapterCapabilities.supportsAudioOnly],
  /// and re-applies it whenever a new adapter is bound.
  Future<void> setAudioOnly(bool audioOnly) async {
    if (_disposed) return;

    if (_audioOnlySubject.value != audioOnly) {
      _audioOnlySubject.add(audioOnly);
    }

    await _controller.setAudioOnly(audioOnly);
  }

  // ---------------------------------------------------------------------------
  // Engine switching
  // ---------------------------------------------------------------------------

  /// Switches the engine, disposing the player that runs now.
  ///
  /// [resumeCurrentSource] re-opens the remembered room; the
  /// settings page passes false so the last room does not restart
  /// behind the settings screen.
  ///
  /// The source is replayed through [play] rather than through
  /// `LivePlaybackController.retry()`, because closing the controller clears
  /// the URL that `retry()` needs and it then returns without doing anything.
  Future<void> switchEngine(PlayerEngine engine, {bool isManual = false, bool resumeCurrentSource = true}) async {
    if (_disposed) return;

    final generation = ++_engineSwitchGeneration;

    preferredEngine = engine;

    if (isManual) {
      _onPreferredEngineChanged?.call(engine);
    }

    final request = _lastRequest;

    // Unmount the surface first: bumping the key rebuilds [TvVideoSurface]
    // against a null handle so the retired `Video` widget leaves the tree
    // instead of rebuilding on the adapter this call is about to dispose.
    _bumpVideoKey();

    await close();

    // A newer switch has already started.
    if (_disposed || generation != _engineSwitchGeneration) {
      return;
    }

    // Keep this delay because Android TV Surface / Texture teardown may still
    // be in progress when the controller is closed.
    await Future.delayed(const Duration(seconds: 1));

    // Another switch may have started during the teardown delay.
    if (_disposed || generation != _engineSwitchGeneration) {
      return;
    }

    if (!resumeCurrentSource || request == null || request.urls.isEmpty) {
      return;
    }

    await play(
      request.urls.first,
      request.urls.length > 1 ? request.urls.sublist(1) : const <String>[],
      request.headers,
      room: _lastRoomFromRequest,
    );
  }

  /// Returns the engine currently in use.
  PlayerEngine get currentEngine {
    switch (_controller.backendId) {
      case 'ijk':
        return PlayerEngine.fijk;
      case 'exo':
        return PlayerEngine.betterPlayer;
      default:
        return PlayerEngine.mediaKit;
    }
  }

  // ---------------------------------------------------------------------------
  // Request metadata
  // ---------------------------------------------------------------------------

  /// The current facade does not store a second room object.
  ///
  /// Room title is already carried by [LiveSourceRequest]. If the app needs
  /// room-specific volume after an engine switch, that information should
  /// eventually move into the request itself rather than being duplicated
  /// beside it.
  LiveRoom? get _lastRoomFromRequest => null;

  // ---------------------------------------------------------------------------
  // Fit
  // ---------------------------------------------------------------------------

  /// Changes the viewport fit by index into the app fit list.
  void changeVideoFit(int index) {
    final fitList = AppThemeConsts.videoFitList;

    if (index < 0 || index >= fitList.length) {
      return;
    }

    videoFitIndex.add(index);
    _applyVideoFit(fitList[index]);
  }

  void _applyVideoFit(BoxFit fit) {
    final adapter = _controller.handle?.adapter;

    if (adapter is MediaKitPlayerAdapter) {
      adapter.setVideoFit(fit);
      return;
    }

    if (adapter is FlvLzcPlayerAdapter) {
      adapter.setVideoFit(fit);
      return;
    }

    if (adapter is BetterPlayerAdapter) {
      adapter.setVideoFit(fit);
    }
  }

  // ---------------------------------------------------------------------------
  // Video widget
  // ---------------------------------------------------------------------------

  /// Builds the current video widget.
  ///
  /// Returns a black placeholder while no player is active.
  Widget getVideoWidget(int fitIndex, {Widget? controls, required List<BoxFit> fitList}) {
    return Container(
      color: Colors.black,
      child: StreamBuilder<ValueKey>(
        stream: videoKey.stream,
        initialData: videoKey.value,
        builder: (context, _) {
          final handle = _controller.handle;
          final adapter = handle?.adapter;

          if (adapter == null) {
            return const ColoredBox(color: Colors.black);
          }

          return KeyedSubtree(key: ValueKey('${videoKey.value}_${adapter.id}'), child: _buildAdapterView(adapter));
        },
      ),
    );
  }

  /// Builds the live surface of [adapter].
  Widget _buildAdapterView(PlayerAdapter adapter) {
    if (adapter case final PlayerVideo video) {
      return video.build();
    }

    return const ColoredBox(color: Colors.black);
  }

  void _bumpVideoKey() {
    videoKey.add(ValueKey('video_${++_videoKeyGeneration}'));
  }

  // ---------------------------------------------------------------------------
  // Presentation visibility (watchdog hint)
  // ---------------------------------------------------------------------------

  /// Marks whether the current route owns the mounted video
  /// presentation; hidden presentations stop frame watchdogs.
  void setVideoPresentationVisible(bool visible) {
    if (_disposed) return;

    _controller.setPresentationVisible(visible);
  }

  // ---------------------------------------------------------------------------
  // Dispose
  // ---------------------------------------------------------------------------

  /// Releases the facade.
  Future<void> dispose() async {
    if (_disposed) return;

    _disposed = true;
    ++_engineSwitchGeneration;

    await _stateSub?.cancel();
    await _errorSub?.cancel();
    await _adapterSub?.cancel();

    _stateSub = null;
    _errorSub = null;
    _adapterSub = null;

    _boundHandle = null;
    _adapterBuffering = false;

    await _controller.dispose();

    await _stateSubject.close();
    await _playingSubject.close();
    await _errorSubject.close();
    await _widthSubject.close();
    await _heightSubject.close();
    await isVerticalVideo.close();
    await videoFitIndex.close();
    await videoKey.close();
    await _audioOnlySubject.close();
  }
}
