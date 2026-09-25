import 'dart:async';
import 'models/player_engine.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart' hide Rx;
import 'package:media_core/media_core.dart';
import '../services/settings/settings.dart';
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
    : preferredEngine = defaultEngine {
    _controller = LivePlaybackController(kernel, onEngineFallbackSources: _refreshEngineFallbackSources);

    // The app lifecycle is the source of truth the handle's lifecycle
    // state machine was always meant to consume: backgrounding auto-pauses
    // the live player, foregrounding re-arms it (without auto-play). The
    // driver resolves the current handle per event, so it survives engine
    // switches.
    _appLifecycle = AppLifecycleDriver(
      resolve: () => _controller.handle,
      // Backgrounding must also stand the live controller's watchdogs down,
      // or its unexpected-pause recovery quietly resumes playback in the
      // background.
      onBackgrounded: (_) => _controller.noteBackgrounded(),
    );

    _bindController();
  }

  /// The engine the app prefers for the next session.
  PlayerEngine preferredEngine;

  /// Called before the sweep switches to [nextEngine], when every line
  /// failed on the current engine.
  ///
  /// Signed live URLs are usually single-use — the first engine's attempt
  /// consumes them — so the app should refetch fresh play URLs here and
  /// return them. Return an empty list (or leave this null) to reuse the
  /// lines the request already carries. The sweep restarts from line 0
  /// with the refreshed URLs.
  Future<List<String>> Function(String nextEngine)? onEngineFallbackUrls;

  /// Headers the current request was built with, reused when the
  /// engine-fallback resolver hands over fresh URLs.
  Map<String, String> _lastHeaders = const <String, String>{};

  Future<List<PlayerSource>> _refreshEngineFallbackSources(String nextEngine, List<PlayerSource> currentSources) async {
    final resolver = onEngineFallbackUrls;

    if (resolver == null) {
      return const <PlayerSource>[];
    }

    final urls = await resolver(nextEngine);

    if (urls.isEmpty) {
      return const <PlayerSource>[];
    }

    return LiveSourceRequest.fromUrls(urls, headers: _lastHeaders).sources;
  }

  late final LivePlaybackController _controller;

  late final AppLifecycleDriver _appLifecycle;

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

  /// Whether the current surface has a picture to show.
  ///
  /// False whenever there is provably nothing on screen - no player yet, a
  /// source opening, an engine switch in progress, playback stopped - and
  /// true once the adapter reports a decoded frame (video size) or a
  /// playing state. The play page shows its loading overlay while this is
  /// false instead of staring at a black surface.
  final _pictureSubject = BehaviorSubject<bool>.seeded(false);

  /// Picture-availability stream. See [_pictureSubject].
  Stream<bool> get onPictureAvailable => _pictureSubject.stream;

  /// Whether the current surface has a picture right now.
  bool get hasPicture => _pictureSubject.value;

  void _setPictureAvailable(bool available) {
    if (_pictureSubject.value == available) return;
    _pictureSubject.add(available);
  }

  /// Audio-only playback mode, as the play page sees it.
  ///
  /// Seeded from the persisted setting so a room entered after a settings
  /// restore (backup / WebDAV / LAN sync) starts in the right mode.
  final _audioOnlySubject = BehaviorSubject<bool>.seeded(SettingsService.to.playerState.audioOnly);

  /// Audio-only playback mode stream.
  Stream<bool> get onAudioOnlyChanged => _audioOnlySubject.stream;

  StreamSubscription<PlayerFailure>? _errorSub;
  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<PlayerHandle>? _handleSub;
  StreamSubscription<PlayerAdapterEvent>? _adapterSub;
  StreamSubscription<PlayerBackendChange>? _backendChangeSub;

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

    // The controller swaps handles when an engine switch commits. The
    // videoKey bump at that moment replaces the mounted surface exactly
    // when the new engine already has a decoded frame, which is what
    // keeps the engine-switch black flash to a single frame.
    _handleSub = _controller.onHandleChanged.listen((_) {
      if (_disposed) return;
      _bindCurrentHandle();
      _bumpVideoKey();
      _setPictureAvailable(false);
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
    unawaited(_backendChangeSub?.cancel());

    _adapterBuffering = false;

    // The handle's stream, not the adapter instance's: recovery can swap
    // the adapter inside the handle, and a subscription taken from the
    // adapter would go silently dead at that moment — playing/size updates
    // would stop while the new engine played on.
    _adapterSub = handle.adapterEvents.listen(_onAdapterEvent, onError: (Object _) {});

    // A recovery engine swap must rebuild the video surface: the widget
    // tree still holds the previous adapter's texture.
    _backendChangeSub = handle.backendChanges.listen((_) => _bumpVideoKey());
  }

  void _onAdapterEvent(PlayerAdapterEvent event) {
    if (_disposed) return;

    if (event is PlayerAdapterPlaying) {
      _adapterBuffering = false;
      _playingSubject.add(true);
      _setPictureAvailable(true);
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
      _setPictureAvailable(false);
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

      // A video-size report means a frame was decoded and laid out: the
      // surface has a picture even if the playing event is still pending.
      _setPictureAvailable(true);
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

    // An opening declaration means the surface is about to show nothing:
    // a source is opening or a line/engine switch is in flight.
    if (state.playback == PlayerPlaybackState.opening) {
      _setPictureAvailable(false);
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

    _lastHeaders = effectiveHeaders;

    final request = LiveSourceRequest.fromUrls(urls, headers: effectiveHeaders, title: room?.title);

    // Remember the complete request before opening it.
    //
    // An engine switch can happen immediately after play() returns, so the
    // replay path must have the exact same source information available.
    _lastRequest = request;

    // Pin the engine the user chose: the explicit preference cannot lose a
    // tie-break. Close/play ordering is the controller queue's job now.
    await _controller.play(request, preferredBackend: _backendIdOf(preferredEngine));

    // The controller creates the handle during open(). Bind whatever is
    // current after the queued task settled.
    _bindCurrentHandle();

    // Apply the audio-only preference to the freshly bound adapter; the
    // controller remembers it and re-applies it across engine switches.
    await setAudioOnly(SettingsService.to.playerState.audioOnly);

    if (room != null) {
      await setVolume(1.0);
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
    await _controller.close();
    _boundHandle = null;
    _adapterBuffering = false;
    _playingSubject.add(false);
    await _adapterSub?.cancel();
    _adapterSub = null;
    await _backendChangeSub?.cancel();
    _backendChangeSub = null;
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
  /// [resumeCurrentSource] re-opens the remembered request; the settings
  /// page passes false so the last room does not restart behind the
  /// settings screen.
  ///
  /// Close and play are tasks on the controller's queue, so they run in
  /// order and nothing can interleave: no delayed replay, no stale-request
  /// race. A switch is simply two consecutive tasks.
  Future<void> switchEngine(PlayerEngine engine, {bool isManual = false, bool resumeCurrentSource = true}) async {
    if (_disposed) return;

    preferredEngine = engine;

    if (isManual) {
      _onPreferredEngineChanged?.call(engine);
    }

    var request = _lastRequest;

    // Unmount the surface first: the retired adapter's widget must leave
    // the tree before its texture is disposed.
    _bumpVideoKey();

    await close();

    if (_disposed || !resumeCurrentSource || request == null || request.sources.isEmpty) {
      return;
    }

    // Manual engine switch runs the same single-use-URL refresh as the
    // sweep's engine fallback: the lines in the remembered request were
    // consumed by the engine that just retired, so replaying them on the
    // new engine fails on an expired signature before playback even
    // starts. An empty or failed refresh keeps the existing lines.
    final refresh = onEngineFallbackUrls;

    if (refresh != null) {
      try {
        final fresh = await refresh(_backendIdOf(engine));

        if (fresh.isNotEmpty) {
          request = LiveSourceRequest.fromUrls(fresh, headers: _lastHeaders, title: request.title);
        }
      } catch (_) {
        // Keep the remembered request; the sweep reports the failure.
      }
    }

    await playRequest(request!);
  }

  /// Plays a previously built request as-is.
  Future<void> playRequest(LiveSourceRequest request) async {
    if (_disposed) return;

    _lastRequest = request;

    await _controller.play(request, preferredBackend: _backendIdOf(preferredEngine));

    _bindCurrentHandle();

    await setAudioOnly(SettingsService.to.playerState.audioOnly);

    _bindCurrentHandle();
  }

  /// The backend id [engine] is registered under.
  String _backendIdOf(PlayerEngine engine) {
    switch (engine) {
      case PlayerEngine.fijk:
        return BackendIds.fijk;
      case PlayerEngine.betterPlayer:
        return BackendIds.betterPlayer;
      default:
        return BackendIds.mediaKit;
    }
  }

  /// Returns the engine currently in use.
  PlayerEngine get currentEngine {
    switch (_controller.backendId) {
      case BackendIds.fijk:
        return PlayerEngine.fijk;
      case BackendIds.betterPlayer:
        return PlayerEngine.betterPlayer;
      default:
        return PlayerEngine.mediaKit;
    }
  }

  // ---------------------------------------------------------------------------
  // Request metadata
  // ---------------------------------------------------------------------------

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
  // ---------------------------------------------------------------------------
  // Dispose
  // ---------------------------------------------------------------------------

  /// Releases the facade.
  Future<void> dispose() async {
    if (_disposed) return;

    _disposed = true;

    await _stateSub?.cancel();
    await _errorSub?.cancel();
    await _handleSub?.cancel();
    await _adapterSub?.cancel();

    _stateSub = null;
    _errorSub = null;
    _handleSub = null;
    _adapterSub = null;

    _boundHandle = null;
    _adapterBuffering = false;

    await _backendChangeSub?.cancel();
    _backendChangeSub = null;

    _appLifecycle.dispose();

    await _controller.dispose();

    await _stateSubject.close();
    await _playingSubject.close();
    await _errorSubject.close();
    await _widthSubject.close();
    await _heightSubject.close();
    await isVerticalVideo.close();
    await _pictureSubject.close();
    await videoFitIndex.close();
    await videoKey.close();
    await _audioOnlySubject.close();
  }
}
