import 'dart:async';
import 'models/player_engine.dart';
import 'package:flutter/material.dart';
import 'adapters/flv_lzc_adapter.dart';
import '../shared/consts/app_consts.dart';
import 'package:rxdart/rxdart.dart' hide Rx;
import 'core/live_room_volume_manager.dart';
import 'core/playback_header_resolver.dart';
import '../services/settings/settings.dart';
import 'package:media_core/media_core.dart';
import 'adapters/better_player_adapter.dart';
import 'adapters/media_kit_core_adapter.dart';
import '../shared/models/live_room/live_room.dart';
import 'package:better_player_plus/better_player_plus.dart';

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
///                    └── view holders (FijkView / Video)
/// ```
final class LivePlayerFacade {
  /// Creates the facade.
  LivePlayerFacade(PlayerKernel kernel, {required PlayerEngine defaultEngine, this._onPreferredEngineChanged})
    : _controller = LivePlaybackController(kernel),
      preferredEngine = defaultEngine;

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

  final List<StreamSubscription<dynamic>> _subscriptions = <StreamSubscription<dynamic>>[];
  StreamSubscription<PlayerFailure>? _errorSub;
  StreamSubscription<PlayerState>? _stateSub;

  bool _disposed = false;

  /// The source last handed to [play], kept so an engine switch can reopen it.
  ///
  /// `LivePlaybackController.close()` releases the handle *and* clears its own
  /// current URL, which makes its `retry()` bail out immediately. A switch that
  /// closed the controller and then called `retry()` therefore tore the player
  /// down and never reopened the stream — a black surface with nothing playing.
  /// The resolved headers are kept too, so reopening does not repeat header
  /// resolution.
  String? _lastUrl;
  List<String> _lastLines = const <String>[];
  Map<String, String> _lastHeaders = const <String, String>{};
  LiveRoom? _lastRoom;

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
  // Binding
  // ---------------------------------------------------------------------------

  /// The handle whose adapter events are already bound.
  ///
  /// The controller creates its handle inside its first open(), which happens
  /// after play() returns. Binding only on the first call therefore never bound
  /// anything, and every adapter-driven signal - playing, buffering, the
  /// background-video suspension - stayed silent.
  PlayerHandle? _boundHandle;

  /// Whether the adapter last reported buffering.
  ///
  /// media_core declares buffering the moment open() returns, and that is not
  /// the adapter's opinion. For a live stream it can also be the last state
  /// change there ever is, which leaves the spinner on screen over a picture
  /// that is playing fine. Only the adapter's own report separates the two.
  bool _adapterBuffering = false;

  void _bind() {
    _stateSub ??= _controller.onStateChanged.listen(_onLiveStateChanged);
    _errorSub ??= _controller.onError.listen((failure) {
      if (_disposed) return;
      _errorSubject.add(failure);
    });

    final handle = _controller.handle;
    if (handle != null && !identical(handle, _boundHandle)) {
      _boundHandle = handle;
      _bindHandle(handle);
    }
  }

  void _bindHandle(PlayerHandle handle) {
    // A new handle means the previous one was released; its subscription goes
    // with it, and so does the buffering that handle last reported.
    for (final sub in List<StreamSubscription<dynamic>>.of(_subscriptions)) {
      unawaited(sub.cancel());
    }
    _subscriptions.clear();
    _adapterBuffering = false;
    _subscriptions.add(handle.adapter.events.listen(_onAdapterEvent, onError: (Object _) {}));
  }

  void _onAdapterEvent(PlayerAdapterEvent event) {
    if (_disposed) return;
    switch (event) {
      case PlayerAdapterPlaying():
        _adapterBuffering = false;
        _playingSubject.add(true);
        _syncBackgroundVideoSuspension(true);
      case PlayerAdapterPaused():
        _playingSubject.add(false);
        _syncBackgroundVideoSuspension(false);
      case PlayerAdapterStopped():
        _adapterBuffering = false;
        _playingSubject.add(false);
        _syncBackgroundVideoSuspension(false);
      case PlayerAdapterBuffering(buffering: final buffering):
        _adapterBuffering = buffering;
      case PlayerAdapterVideoSizeChanged(width: final w, height: final h):
        _widthSubject.add(w);
        _heightSubject.add(h);
        isVerticalVideo.add(h >= w);
      default:
        break;
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
    // buffering the adapter itself reported is real, and that has to come
    // from its events: the state it exposes is overwritten by whichever
    // event arrived last, and ExoPlayer re-buffers often enough that the
    // value read here is not evidence of anything.
    if (state.playback == PlayerPlaybackState.buffering && !_adapterBuffering) {
      // The controller's own state has to move with it: leaving it on
      // buffering makes a later real buffering collide with that dedupe
      // (`if (state == next) return`) and never reach the UI at all.
      _controller.state = state.copyWith(playback: PlayerPlaybackState.playing);
      return;
    }

    _stateSubject.add(state);
  }

  // ---------------------------------------------------------------------------
  // Playback (the legacy surface)
  // ---------------------------------------------------------------------------

  /// Starts playing [url] with [playUrls] as fallback lines.
  Future<void> play(String url, List<String> playUrls, Map<String, String> headers, {LiveRoom? room}) async {
    if (url.trim().isEmpty) {
      throw ArgumentError('Remote playback source is empty');
    }
    _bind();

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

    // Remember the request before it is opened: an engine switch later needs to
    // replay exactly this source, headers included.
    _lastUrl = url;
    _lastLines = playUrls;
    _lastHeaders = effectiveHeaders;
    _lastRoom = room;

    await _controller.play(
      LiveSourceRequest(
        urls: playUrls.isEmpty ? [url] : [url, ...playUrls.where((u) => u != url)],
        headers: effectiveHeaders,
        title: room?.title,
      ),
    );

    // Apply the audio-only preference to the freshly bound adapter.
    if (SettingsService.to.playerState.audioOnly) {
      await setAudioOnly(true);
    }

    if (room != null) {
      final volume = LiveRoomVolumeManager.getRoomVolume(room.platform, room.roomId).clamp(0.0, 1.0);
      await setVolume(volume);
    }
  }

  /// Replays the current source.
  Future<void> retry() => _controller.retry();

  /// Toggles play/pause.
  Future<void> togglePlayPause() => _controller.togglePlayPause();

  /// Pauses playback.
  Future<void> pause() => _controller.pause();

  /// Resumes playback.
  Future<void> resume() => _controller.resume();

  /// Stops playback and releases the player.
  Future<void> close() async {
    _syncBackgroundVideoSuspension(false);
    await _controller.close();
  }

  /// Sets the volume (0.0–1.0).
  Future<void> setVolume(double volume) => _controller.setVolume(volume);

  /// Applies audio-only to the active player.
  Future<void> setAudioOnly(bool audioOnly) async {
    final adapter = _controller.handle?.adapter;
    if (adapter is PureLiveMediaKitAdapter) {
      await adapter.setAudioOnly(audioOnly);
    } else if (adapter is FlvLzcPlayerAdapter) {
      await adapter.setAudioOnly(audioOnly);
    } else if (adapter is BetterPlayerAdapter) {
      await adapter.setAudioOnly(audioOnly);
    }
  }

  // ---------------------------------------------------------------------------
  // Engine switching (the legacy surface)
  // ---------------------------------------------------------------------------

  /// Switches the engine, disposing the player that runs now.
  ///
  /// [resumeCurrentSource] re-opens the remembered room; the
  /// settings page passes false so the last room does not restart
  /// behind the settings screen.
  ///
  /// The source is replayed through [play] rather than through
  /// `LivePlaybackController.retry()`, because closing the controller clears the
  /// URL that `retry()` needs and it then returns without doing anything — which
  /// is what made a switch leave a torn-down player behind. The replay also
  /// re-applies the audio-only preference and the room volume to the freshly
  /// created adapter.
  Future<void> switchEngine(PlayerEngine engine, {bool isManual = false, bool resumeCurrentSource = true}) async {
    if (_disposed) return;
    preferredEngine = engine;
    if (isManual) {
      _onPreferredEngineChanged?.call(engine);
    }

    final String? url = _lastUrl;
    final List<String> lines = _lastLines;
    final Map<String, String> headers = _lastHeaders;
    final LiveRoom? room = _lastRoom;

    // Unmount the surface first: bumping the key rebuilds [TvVideoSurface]
    // against a null handle so the retired `Video` widget leaves the tree
    // instead of rebuilding on the adapter this call is about to dispose.
    videoKey.add(ValueKey('video_${DateTime.now().millisecondsSinceEpoch}'));

    // Close the current player; the replay below creates the next one, and the
    // kernel's selector picks the engine this method just pushed to the top of
    // the registry.
    await _controller.close();

    if (resumeCurrentSource && url != null && url.isNotEmpty) {
      await play(url, lines, headers, room: room);
    }
  }

  /// The engine currently in use.
  PlayerEngine get currentEngine => switch (_controller.backendId) {
    'ijk' => PlayerEngine.fijk,
    'exo' => PlayerEngine.betterPlayer,
    _ => PlayerEngine.mediaKit,
  };

  // ---------------------------------------------------------------------------
  // Fit (the legacy surface)
  // ---------------------------------------------------------------------------

  /// Changes the viewport fit by index into the app fit list.
  void changeVideoFit(int index) {
    final fitList = AppConsts().videoFitList;
    if (index < 0 || index >= fitList.length) return;
    videoFitIndex.add(index);
    _applyVideoFit(fitList[index]);
  }

  void _applyVideoFit(BoxFit fit) {
    final adapter = _controller.handle?.adapter;
    if (adapter is PureLiveMediaKitAdapter) {
      adapter.setVideoFit(fit);
    } else if (adapter is FlvLzcPlayerAdapter) {
      adapter.setVideoFit(fit);
    } else if (adapter is BetterPlayerAdapter) {
      adapter.setVideoFit(fit);
    }
  }

  // ---------------------------------------------------------------------------
  // Video widget (the legacy surface)
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
          final boxFit = fitList[fitIndex.clamp(0, fitList.length - 1)];
          return KeyedSubtree(
            key: ValueKey('${videoKey.value}_${adapter.id}'),
            child: _buildAdapterView(adapter, boxFit),
          );
        },
      ),
    );
  }

  Widget _buildAdapterView(PlayerAdapter adapter, BoxFit fit) {
    if (adapter is PureLiveMediaKitAdapter) {
      adapter.setVideoFit(fit);
      final controller = adapter.videoController;
      if (controller == null) return const ColoredBox(color: Colors.black);
      return adapter.viewHolder.build(controller);
    }
    if (adapter is FlvLzcPlayerAdapter) {
      adapter.setVideoFit(fit);
      return adapter.viewHolder.build(adapter.fijkPlayer);
    }
    if (adapter is BetterPlayerAdapter) {
      adapter.setVideoFit(fit);
      return BetterPlayer(controller: adapter.controller);
    }
    return const ColoredBox(color: Colors.black);
  }

  // ---------------------------------------------------------------------------
  // Presentation visibility (watchdog hint)
  // ---------------------------------------------------------------------------

  /// Marks whether the current route owns the mounted video
  /// presentation; hidden presentations stop frame watchdogs.
  void setVideoPresentationVisible(bool visible) {
    _controller.setPresentationVisible(visible);
  }

  // ---------------------------------------------------------------------------
  // Dispose
  // ---------------------------------------------------------------------------

  /// Releases the facade.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;

    await _stateSub?.cancel();
    await _errorSub?.cancel();
    for (final sub in List<StreamSubscription<dynamic>>.of(_subscriptions)) {
      await sub.cancel();
    }
    _subscriptions.clear();

    await _controller.dispose();

    await _stateSubject.close();
    await _playingSubject.close();
    await _errorSubject.close();
    await _widthSubject.close();
    await _heightSubject.close();
    await isVerticalVideo.close();
    await videoFitIndex.close();
    await videoKey.close();
  }
}
