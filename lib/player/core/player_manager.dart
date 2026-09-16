import 'dart:async';
import 'dart:developer';
import 'player_pool.dart';
import 'line_fallback_manager.dart';
import 'live_room_volume_manager.dart';
import 'playback_lifecycle_coordinator.dart';
import 'playback_source.dart';
import 'playback_source_transport.dart';
import 'playback_header_resolver.dart';
import '../models/player_state.dart';
import 'preload_player_manager.dart';
import '../models/player_engine.dart';
import 'engine_fallback_manager.dart';
import 'package:flutter/material.dart';
import '../models/player_exception.dart';
import '../models/player_error_type.dart';
import 'package:rxdart/rxdart.dart' hide Rx;
import '../interface/unified_player_interface.dart';
import 'package:pure_live/shared/widgets/app_status_view.dart';
import 'package:pure_live/player/utils/player_consts.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:pure_live/shared/consts/app_consts.dart';
import 'package:pure_live/shared/models/live_room/live_room.dart';

/// A single queued native error. It is bound to the source session that
/// raised it, so anything from a superseded session can be dropped.
class _PendingPlayerError {
  const _PendingPlayerError({required this.error, required this.sessionId});

  final PlayerException error;
  final int sessionId;
}

/// Playback orchestration core for the single global player.
///
/// - serialized player lifecycle queue with sessionId/intentRevision guards
/// - PlaybackSource + PlaybackSourceTransport (one input lease per player)
/// - error-code driven recovery pipeline: line switch, software decoding,
///   engine fallback, same-engine rebuild, bounded backoff, terminal state
/// - watchdogs: open deadline, buffer stall, unexpected pause, frame stall
/// - lifecycle pause/resume tokens and per-room volume restore
/// - platform header resolution when the caller passes no headers
class PlayerManager {
  final PlayerPool playerPool;

  final EngineFallbackManager fallbackManager;

  final PreloadPlayerManager preloadManager;

  final LineFallbackManager lineManager;

  final Duration sourceOpenTimeout;
  final Duration sourceReadyTimeout;
  final Duration unexpectedPauseGrace;
  final Duration unexpectedPauseFailureGrace;
  final Duration bufferingStallTimeout;
  final Duration videoFrameStallTimeout;
  final Duration recoveryBudgetResetDelay;
  final List<Duration> transientLiveRetryDelays;

  PlayerManager({
    required this.playerPool,
    required this.fallbackManager,
    required this.preloadManager,
    required this.lineManager,
    this.sourceOpenTimeout = const Duration(seconds: 18),
    this.sourceReadyTimeout = Duration.zero,
    this.unexpectedPauseGrace = const Duration(milliseconds: 350),
    this.unexpectedPauseFailureGrace = const Duration(seconds: 5),
    this.bufferingStallTimeout = const Duration(seconds: 12),
    this.videoFrameStallTimeout = const Duration(seconds: 10),
    this.recoveryBudgetResetDelay = const Duration(seconds: 30),
    this.transientLiveRetryDelays = const <Duration>[Duration(milliseconds: 750), Duration(seconds: 2)],
  }) {
    _lifecycleCoordinator = PlaybackLifecycleCoordinator(
      pauseForLifecycle: pauseForLifecycle,
      resumeFromLifecycle: resumeFromLifecycle,
    );
    _lifecycleCoordinator.start();
  }

  late final PlaybackLifecycleCoordinator _lifecycleCoordinator;

  // =========================
  // player
  // =========================

  UnifiedPlayer? _currentPlayer;

  PlayerEngine? _runtimeEngine;

  PlayerEngine? _defaultEngine;

  // =========================
  // session / intent
  // =========================

  Future<void> _playerLifecycleQueue = Future.value();
  int _sessionId = 0;
  int _playbackIntentRevision = 0;
  bool _playbackRequested = false;
  bool _isClosing = false;
  final Set<_PlaybackSuspensionReason> _playbackSuspensions = <_PlaybackSuspensionReason>{};

  bool _isSessionValid(int id) => !_disposed && !_isClosing && _sessionId == id;

  bool _isPlaybackCommandCurrent(int revision) =>
      !_disposed && !_isClosing && _playbackRequested && _playbackIntentRevision == revision;

  bool _isPlayerEventCurrent(UnifiedPlayer player, int sessionId) =>
      _isSessionValid(sessionId) && identical(player, _currentPlayer);

  // =========================
  // play info
  // =========================

  PlaybackSource? _currentSource;
  bool _sourceOpened = false;
  String? get _currentUrl => _currentSource?.url;
  List<String> _currentPlayUrls = [];
  Map<String, String> _currentHeaders = {};

  final Map<UnifiedPlayer, PlaybackSourceTransport> _sourceTransports = Map.identity();

  // =========================
  // rx state
  // =========================
  final isInitialized = BehaviorSubject<bool>.seeded(false);
  final hasError = BehaviorSubject<bool>.seeded(false);
  final isVerticalVideo = BehaviorSubject<bool>.seeded(false);
  final videoFitIndex = BehaviorSubject<int>.seeded(0);
  final videoKey = BehaviorSubject<ValueKey>.seeded(const ValueKey("video_0"));

  bool get initialized => isInitialized.value;

  void setInitialized(bool value) => isInitialized.add(value);

  void updateVideoKey() {
    videoKey.add(ValueKey("video_${DateTime.now().millisecondsSinceEpoch}"));
  }

  // =========================
  // stream state
  // =========================

  final _stateSubject = BehaviorSubject<PlayerState>.seeded(PlayerState.idle);

  final _playingSubject = BehaviorSubject<bool>.seeded(false);

  final _loadingSubject = BehaviorSubject<bool>.seeded(false);

  final _completeSubject = BehaviorSubject<bool>.seeded(false);

  final _errorSubject = PublishSubject<PlayerException>();

  final _widthSubject = BehaviorSubject<int?>.seeded(null);

  final _heightSubject = BehaviorSubject<int?>.seeded(null);

  // Native buffering is tracked separately from the loading state that the
  // recovery logic observes.
  bool _nativeLoading = false;
  int _bufferingRecoveryRevision = 0;
  int _playingRecoveryRevision = 0;

  // =========================
  // subscriptions
  // =========================

  final List<StreamSubscription> _subscriptions = [];

  // =========================
  // recovery state
  // =========================

  bool _disposed = false;

  bool _isSwitchingDueToFallback = false;
  bool _isHandlingError = false;
  _PendingPlayerError? _pendingPlayerError;
  int? _errorDedupeSession;
  final Set<String> _errorDedupeSignatures = <String>{};

  int _sameEngineRecoveryAttempts = 0;
  int _transientLiveRetryAttempts = 0;
  int _transientLiveRetryRevision = 0;
  Timer? _transientLiveRetryTimer;
  _PendingPlayerError? _transientLiveRetryOwner;

  Timer? _sourceReadyTimer;
  Timer? _continuityTimer;
  Timer? _bufferingStallTimer;
  Timer? _videoFrameStallTimer;
  final Stopwatch _videoFrameWatchdogClock = Stopwatch();
  Duration? _videoFrameDeadline;
  int _continuityRevision = 0;
  int _presentedFrameRevision = 0;
  bool _videoPresentationVisible = true;
  Timer? _recoveryBudgetResetTimer;

  LiveRoom? currentFloatRoom;

  // =========================
  // getter
  // =========================

  UnifiedPlayer? get currentPlayer => _currentPlayer;

  PlayerEngine get currentEngine => _runtimeEngine ?? _defaultEngine ?? PlayerEngine.mediaKit;

  Stream<PlayerState> get onStateChanged => _stateSubject.stream;

  Stream<bool> get onPlaying => _playingSubject.stream;

  Stream<bool> get onLoading => _loadingSubject.stream;

  Stream<bool> get onComplete => _completeSubject.stream;

  Stream<PlayerException> get onError => _errorSubject.stream;

  Stream<int?> get width => _widthSubject.stream;

  Stream<int?> get height => _heightSubject.stream;

  bool get isPlayingNow => _playingSubject.value;

  /// 仅播放音频 (settings row 仅播放音频) as the native players need it.
  ///
  /// The adapters keep the mode per native player and reset it from every
  /// `setDataSource`/`init` call, so both the pooled instance and the source
  /// open have to receive it. Reading the setting here keeps the settings page
  /// free of player-internal plumbing.
  bool get _audioOnlySetting => SettingsService.to.playerState.audioOnly;

  /// Applies 仅播放音频 to the active player and every pooled adapter.
  Future<void> setAudioOnly(bool audioOnly) async {
    if (_disposed) return;
    await playerPool.setAudioOnly(audioOnly);
  }

  double get currentVideoRatio {
    final w = _widthSubject.value?.toDouble() ?? 1920;

    final h = _heightSubject.value?.toDouble() ?? 1080;

    if (w <= 0 || h <= 0) {
      return 16 / 9;
    }

    return w / h;
  }

  // =========================
  // lifecycle queue
  // =========================

  Future<T> _enqueuePlayerLifecycle<T>(Future<T> Function() operation) {
    final previous = _playerLifecycleQueue;

    final current = previous.then((_) => operation());

    _playerLifecycleQueue = current.then<void>((_) {}, onError: (_, _) {});

    return current;
  }

  // =========================
  // suspension (lifecycle pause and resume)
  // =========================

  /// A lifecycle pause is an implementation detail, not a user playback
  /// intent. The token lets a later resume prove that neither the source nor
  /// the user's intent changed while the application was hidden.
  Future<PlaybackLifecyclePauseToken?> pauseForLifecycle() async {
    // There is no background playback on a TV: the playback page is the app, so
    // a lifecycle pause always suspends the stream.
    return _pauseForSuspension(_PlaybackSuspensionReason.lifecycle);
  }

  Future<bool> resumeFromLifecycle(PlaybackLifecyclePauseToken token) async {
    return _resumeFromSuspension(_PlaybackSuspensionReason.lifecycle, token);
  }

  Future<PlaybackLifecyclePauseToken?> _pauseForSuspension(_PlaybackSuspensionReason reason) async {
    final player = _currentPlayer;
    if (player == null || _disposed || _isClosing) return null;
    if (!_playbackRequested) {
      if (!isPlayingNow && !player.isPlayingNow) return null;
      // Compatibility for an already-active adapter supplied by an explicit
      // pre-warm/restore path. Once any public command establishes intent,
      // native state alone never overrides that user decision.
      _playbackRequested = true;
    }
    final token = (sessionId: _sessionId, intentRevision: _playbackIntentRevision);
    _playbackSuspensions.add(reason);
    _cancelContinuityRecovery();
    _cancelVideoFrameStallRecovery();
    _cancelTransientLiveRetry();
    if (isPlayingNow || player.isPlayingNow) await player.pause();
    if (_disposed || _isClosing || _sessionId != token.sessionId) {
      _playbackSuspensions.remove(reason);
      return null;
    }
    return token;
  }

  Future<bool> _resumeFromSuspension(_PlaybackSuspensionReason reason, PlaybackLifecyclePauseToken token) async {
    final player = _currentPlayer;
    if (player == null ||
        _disposed ||
        _isClosing ||
        _sessionId != token.sessionId ||
        _playbackIntentRevision != token.intentRevision ||
        !_playbackRequested ||
        !_playbackSuspensions.remove(reason)) {
      return false;
    }
    if (_playbackSuspensions.isNotEmpty || isPlayingNow || player.isPlayingNow) return true;
    await player.play();
    _armVideoFrameStallRecovery(player, token.sessionId);
    _scheduleRecoveryBudgetReset(player, token.sessionId);
    return !_disposed && !_isClosing && _sessionId == token.sessionId;
  }

  // =========================
  // initialize
  // =========================

  Future<void> initialize({PlayerEngine engine = PlayerEngine.mediaKit}) {
    return _enqueuePlayerLifecycle(
      () => _initializeInternal(engine: engine, sessionId: _sessionId, publishError: true),
    );
  }

  Future<void> _initializeInternal({
    required PlayerEngine engine,
    required int sessionId,
    required bool publishError,
  }) async {
    if (_disposed || _isClosing) return;

    _stateSubject.add(PlayerState.initializing);

    try {
      _defaultEngine = engine;
      _runtimeEngine = engine;

      final player = await playerPool.getPlayer(engine, audioOnly: _audioOnlySetting);

      if (!_isSessionValid(sessionId)) {
        await _safeDestroyPlayer(player);
        return;
      }

      _currentPlayer = player;

      await _bindPlayerStreams(player, sessionId: sessionId);

      if (!_isSessionValid(sessionId)) {
        await _safeDestroyPlayer(player);
        if (identical(_currentPlayer, player)) {
          _currentPlayer = null;
        }
        return;
      }

      isInitialized.value = true;
      _stateSubject.add(PlayerState.initialized);
    } catch (e, s) {
      if (!_isSessionValid(sessionId)) return;

      final exception = PlayerException(
        message: 'Initialize player failed',
        type: PlayerErrorType.initialization,
        error: e,
        stackTrace: s,
      );

      // Explicit pre-warm calls own their terminal error. A player allocated as
      // part of [play] is different: its initialization failure must remain
      // private until the orchestrator has tried the remaining engines.
      if (publishError) _publishTerminalPlayerError(exception);

      throw exception;
    }
  }

  // =========================
  // play
  // =========================

  Future<void> play(String url, List<String> playUrls, Map<String, String> headers, {LiveRoom? room}) {
    if (url.trim().isEmpty) {
      throw ArgumentError('Remote playback source is empty');
    }
    final requestedUrls = List<String>.unmodifiable(playUrls);
    final requestedHeaders = Map<String, String>.unmodifiable(headers);
    _playbackRequested = true;
    _playbackIntentRevision++;
    _cancelPendingSourceInputs();
    _playbackSuspensions.clear();
    _sameEngineRecoveryAttempts = 0;
    _transientLiveRetryAttempts = 0;
    _cancelTransientLiveRetry();
    _cancelContinuityRecovery();
    _cancelVideoFrameStallRecovery();
    final intentRevision = _playbackIntentRevision;
    return _enqueuePlayerLifecycle(() async {
      if (!_isPlaybackCommandCurrent(intentRevision)) return;
      await _playInternal(UrlPlaybackSource(url), requestedUrls, requestedHeaders, room: room);
    });
  }

  Future<void> _playInternal(
    PlaybackSource source,
    List<String> playUrls,
    Map<String, String> headers, {
    LiveRoom? room,
  }) async {
    if (_disposed || _isClosing) return;
    _cancelContinuityRecovery();
    _cancelVideoFrameStallRecovery();
    _sourceReadyTimer?.cancel();
    _sourceReadyTimer = null;
    if (_disposed || _isClosing) return;
    final mySessionId = ++_sessionId;
    final sourceIntentRevision = _playbackIntentRevision;
    _sourceOpened = false;

    final roomChanged = room != currentFloatRoom;
    if (roomChanged) {
      lineManager.reset();
      fallbackManager.resetAll();
      _sameEngineRecoveryAttempts = 0;
      _transientLiveRetryAttempts = 0;
      _cancelTransientLiveRetry();
    }

    // Recovery needs the complete request even when the preferred native
    // engine fails before a player exists. Previously these fields were set
    // only after initialization, so an initialization exception escaped the
    // line/engine recovery state machine and immediately surfaced as a decoder
    // error.
    _currentSource = source;
    _currentPlayUrls = List<String>.from(playUrls);
    currentFloatRoom = room;
    hasError.value = false;

    if (_currentPlayer == null || _runtimeEngine == null) {
      if (_defaultEngine == null) {
        final String savedKey = SettingsService.to.playerState.videoPlayerKey;
        final String validKey = PlayerConsts.engines.containsKey(savedKey) ? savedKey : PlayerConsts.defaultKey;
        _defaultEngine = PlayerConsts.engines[validKey]!;
      }

      final engine = _defaultEngine!;

      log('No current player, initializing with default engine: $engine', name: 'PlayerManager');

      try {
        await _initializeInternal(engine: engine, sessionId: mySessionId, publishError: false);
      } on PlayerException catch (error) {
        if (_isSessionValid(mySessionId) && _isPlaybackCommandCurrent(sourceIntentRevision)) {
          await _handleError(error, sessionId: mySessionId);
        }
        return;
      }
    } else if (_runtimeEngine != _defaultEngine && !_isSwitchingDueToFallback) {
      await _switchEngineInternal(_defaultEngine!, isManual: false, openCurrentSource: false);
    }

    if (!_isSessionValid(mySessionId) || !_isPlaybackCommandCurrent(sourceIntentRevision)) return;

    final player = _currentPlayer;

    if (player == null) {
      if (!_isSessionValid(mySessionId)) {
        return;
      }

      throw PlayerException(message: 'Current player is null', type: PlayerErrorType.lifecycle);
    }

    // Reset retained-adapter subjects before rebinding this source generation.
    // Without this handshake BehaviorSubjects replayed the previous URL's
    // dimensions and delayed errors into the new room/quality session.
    if (player is SourceTransitionAwarePlayer) {
      (player as SourceTransitionAwarePlayer).beginSourceTransition();
    }
    await _bindPlayerStreams(player, sessionId: mySessionId);
    if (!_isSessionValid(mySessionId) || !_isPlaybackCommandCurrent(sourceIntentRevision)) return;

    try {
      _stateSubject.add(PlayerState.preparing);
      // With no explicit headers, resolve them per platform.
      final effectiveHeaders =
          (headers.isEmpty && room != null && room.platform.isNotEmpty)
          ? await PlaybackHeaderResolver.resolve(
              platform: room.platform,
              roomId: room.roomId,
              roomHeaders: room.httpHeaders,
            )
          : headers;
      _currentHeaders = Map<String, String>.from(effectiveHeaders);
      await _openPlayerSource(player, source, _currentPlayUrls, effectiveHeaders, room: room);
      if (!_isSessionValid(mySessionId) || !_isPlaybackCommandCurrent(sourceIntentRevision)) return;
      _sourceOpened = true;
      _armSourceReadyDeadline(player, mySessionId);

      // Restore the remembered volume for this room. A corrupt preference must
      // never fail playback; fall back to the adapter volume.
      if (room != null) {
        try {
          await player.setVolume(
            LiveRoomVolumeManager.getRoomVolume(room.platform, room.roomId).clamp(0.0, 1.0),
          );
        } catch (error, stackTrace) {
          log('Restore room volume failed: $error', name: 'PlayerManager', error: error, stackTrace: stackTrace);
        }
      }
      if (!_isSessionValid(mySessionId) || !_isPlaybackCommandCurrent(sourceIntentRevision)) return;

      // Opening the source can finish before the native cache has refilled.
      // Keep that buffering episode authoritative for both UI and recovery.
      _stateSubject.add(_nativeLoading ? PlayerState.buffering : PlayerState.ready);
      videoKey.value = ValueKey("video_${DateTime.now().millisecondsSinceEpoch}");
    } on PlayerException catch (e) {
      if (_isSessionValid(mySessionId) && _isPlaybackCommandCurrent(sourceIntentRevision)) {
        await _handleError(e, sessionId: mySessionId);
      }
    } catch (e, s) {
      log(e.toString());
      if (_isSessionValid(mySessionId) && _isPlaybackCommandCurrent(sourceIntentRevision)) {
        final exception = PlayerException(
          message: 'Play failed',
          type: PlayerErrorType.unknown,
          error: e,
          stackTrace: s,
        );
        await _handleError(exception, sessionId: mySessionId);
      }
    } finally {
      _isSwitchingDueToFallback = false;
    }
  }

  // =========================
  // source transport
  // =========================

  Future<void> _openPlayerSource(
    UnifiedPlayer player,
    PlaybackSource source,
    List<String> playUrls,
    Map<String, String> headers, {
    required LiveRoom? room,
  }) async {
    final transport = _sourceTransports.putIfAbsent(player, () => PlaybackSourceTransport());

    Future<void> nativeOpen(String input, List<String> inputs, Map<String, String> inputHeaders, bool privateInput) {
      if (player is PrivateInputAwarePlayer) {
        (player as PrivateInputAwarePlayer).setPrivateInput(privateInput, sourceIdentity: source.identity);
      }
      return player.setDataSource(input, inputs, inputHeaders, room: room, audioOnly: _audioOnlySetting);
    }

    final sourceOpen = switch (source) {
      OwnedPlaybackSource() => transport.openOwned(createInput: source.createInput, nativeOpen: nativeOpen),
      UrlPlaybackSource() => transport.open(url: source.url, urls: playUrls, headers: headers, nativeOpen: nativeOpen),
    };
    try {
      if (sourceOpenTimeout <= Duration.zero) {
        await sourceOpen;
        return;
      }
      await sourceOpen.timeout(
        sourceOpenTimeout,
        onTimeout: () {
          throw PlayerException(
            message: 'Native player did not finish opening the source before the deadline',
            type: PlayerErrorType.initialization,
            code: 'source_open_timeout',
          );
        },
      );
    } catch (_) {
      await transport.cancelPending();
      rethrow;
    }
  }

  Future<void> _closeSourceTransport(UnifiedPlayer player) async {
    await _sourceTransports.remove(player)?.close();
  }

  void _cancelPendingSourceInputs() {
    for (final transport in _sourceTransports.values) {
      unawaited(
        transport.cancelPending().catchError((Object error, StackTrace stackTrace) {
          log('Pending source input cleanup failed', name: 'PlayerManager', error: error, stackTrace: stackTrace);
        }),
      );
    }
  }

  Future<void> _disposePlayerWithTransport(UnifiedPlayer player) async {
    try {
      await _closeSourceTransport(player);
    } finally {
      await player.hardDispose();
    }
  }

  Future<void> _safeDestroyPlayer(UnifiedPlayer player) async {
    try {
      await _disposePlayerWithTransport(player);
    } catch (e, s) {
      log("destroy player error: $e", stackTrace: s);
    }
  }

  // =========================
  // replay
  // =========================

  Future<void> replay() {
    _playbackRequested = true;
    _playbackIntentRevision++;
    _cancelPendingSourceInputs();
    _playbackSuspensions.clear();
    _sameEngineRecoveryAttempts = 0;
    _transientLiveRetryAttempts = 0;
    _cancelTransientLiveRetry();
    _cancelContinuityRecovery();
    final intentRevision = _playbackIntentRevision;
    return _enqueuePlayerLifecycle(() async {
      if (!_isPlaybackCommandCurrent(intentRevision) || _currentSource == null) return;

      await _playInternal(_currentSource!, _currentPlayUrls, _currentHeaders, room: currentFloatRoom);
    });
  }

  // =========================
  // switch engine
  // =========================

  Future<void> switchEngine(PlayerEngine engine, {bool isManual = false}) {
    return _enqueuePlayerLifecycle(() => _switchEngineInternal(engine, isManual: isManual));
  }

  Future<void> _switchEngineInternal(
    PlayerEngine engine, {
    bool isManual = false,
    bool openCurrentSource = true,
    bool forceRecreate = false,
    bool Function()? isStillRequired,
  }) async {
    if (_disposed || _isClosing) return;
    final sessionId = _sessionId;

    try {
      final oldPlayer = _currentPlayer;

      final oldEngine = _runtimeEngine;

      if (forceRecreate) {
        final candidate = await playerPool.getPlayer(engine, audioOnly: _audioOnlySetting);
        if (identical(candidate, oldPlayer)) {
          // Forced recreation must never alias the active instance.
          await _safeDestroyPlayer(candidate);
          await playerPool.removeFromCache(engine);
          throw StateError('Forced player recreation returned the active player instance');
        }
        if (isStillRequired?.call() == false || !_isSessionValid(sessionId)) {
          await _safeDestroyPlayer(candidate);
          return;
        }
        await _clearSubscriptions();
        _currentPlayer = candidate;
        _runtimeEngine = engine;
        await _bindPlayerStreams(candidate, sessionId: sessionId);
      } else {
        if (_runtimeEngine == engine && _currentPlayer != null) {
          return;
        }
        await _clearSubscriptions();

        final newPlayer = await playerPool.getPlayer(engine, audioOnly: _audioOnlySetting);

        if (isStillRequired?.call() == false || !_isSessionValid(sessionId)) {
          await _safeDestroyPlayer(newPlayer);
          return;
        }

        _currentPlayer = newPlayer;

        _runtimeEngine = engine;

        await _bindPlayerStreams(newPlayer, sessionId: sessionId);
      }

      if (isManual) {
        _defaultEngine = engine;
      }

      if (oldPlayer != null && oldEngine != null && !identical(oldPlayer, _currentPlayer)) {
        await _safeDestroyPlayer(oldPlayer);
      }

      videoKey.value = ValueKey("video_${DateTime.now().millisecondsSinceEpoch}");

      if (openCurrentSource && _currentSource != null && _isSessionValid(sessionId)) {
        await _playInternal(_currentSource!, _currentPlayUrls, _currentHeaders, room: currentFloatRoom);
      }
    } catch (e, s) {
      final exception = PlayerException(
        message: 'Switch engine failed',
        type: PlayerErrorType.lifecycle,
        error: e,
        stackTrace: s,
      );

      _errorSubject.add(exception);

      rethrow;
    }
  }

  // =========================
  // preload
  // =========================

  Future<void> preload(String url, List<String> playUrls, Map<String, String> headers) async {
    if (_disposed) return;

    if (_runtimeEngine == null) return;

    final standby = await playerPool.getPlayer(_runtimeEngine!, audioOnly: _audioOnlySetting);

    await preloadManager.preload(standby, url, playUrls, headers, audioOnly: _audioOnlySetting);
  }

  // =========================
  // seamless switch
  // =========================

  Future<void> seamlessSwitch() async {
    if (_disposed) return;

    await preloadManager.switchToStandby();

    final player = preloadManager.current;

    if (player == null) return;

    await _clearSubscriptions();

    _currentPlayer = player;

    await _bindPlayerStreams(player, sessionId: _sessionId);
  }

  // =========================
  // play control
  // =========================

  Future<void> togglePlayPause() async {
    if (_currentPlayer == null) return;

    if (isPlayingNow) {
      await pause();
    } else {
      await resume();
    }
  }

  Future<void> pause() async {
    final player = _currentPlayer;
    _playbackRequested = false;
    _playbackIntentRevision++;
    _cancelPendingSourceInputs();
    _playbackSuspensions.clear();
    _cancelContinuityRecovery();
    _cancelVideoFrameStallRecovery();
    _cancelTransientLiveRetry();
    await player?.pause();
  }

  Future<void> resume() async {
    // Pause can cancel source opening before a usable source exists. Resuming
    // an empty decoder is not a media open; recreate the retained source
    // through the same queue and cancellation transaction.
    if (_currentSource != null && !_sourceOpened) {
      await replay();
      return;
    }
    final player = _currentPlayer;
    if (player == null) return;
    _playbackRequested = true;
    _playbackIntentRevision++;
    _playbackSuspensions.clear();
    _cancelContinuityRecovery();
    await player.play();
    _armVideoFrameStallRecovery(player, _sessionId);
    _scheduleRecoveryBudgetReset(player, _sessionId);
  }

  Future<void> stop() async {
    await close();
  }

  // =========================
  // volume
  // =========================

  Future<void> setVolume(double volume) async {
    await _currentPlayer?.setVolume(volume.clamp(0.0, 1.0));
  }

  // =========================
  // fit
  // =========================

  void changeVideoFit(int index) {
    videoFitIndex.value = index;
    _applyVideoFit(_currentPlayer, index);
  }

  void _applyVideoFit(UnifiedPlayer? player, int fitIndex) {
    if (player is! VideoFitAwarePlayer) return;
    final fitList = _videoFitList();
    if (fitIndex < 0 || fitIndex >= fitList.length) return;
    (player as VideoFitAwarePlayer).setVideoFit(fitList[fitIndex]);
  }

  /// Fit options the stored `videoFitIndex` indexes into; the settings page
  /// renders the same list, so every index it can save is applicable here.
  List<BoxFit> _videoFitList() => AppConsts().videoFitList;

  Widget getVideoWidget(int fitIndex, {Widget? controls, required List<BoxFit> fitList}) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(0),
      child: StreamBuilder<bool>(
        stream: onPlaying,
        initialData: isPlayingNow,
        builder: (context, snapshot) {
          if (_currentPlayer == null) {
            return _buildPlaceholder();
          }
          final boxFit = fitList[fitIndex.clamp(0, fitList.length - 1)];
          return KeyedSubtree(
            key: videoKey.value,
            child: Container(
              color: Colors.black,
              width: double.infinity,
              height: double.infinity,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      color: Colors.black,
                      child: FittedBox(
                        fit: boxFit,
                        clipBehavior: Clip.hardEdge,
                        child: StreamBuilder<List<int?>>(
                          stream: CombineLatestStream.list([width, height]),
                          builder: (context, snapshot) {
                            // Follow the real video dimensions.
                            final vW = snapshot.data?[0]?.toDouble() ?? 1920.0;
                            final vH = snapshot.data?[1]?.toDouble() ?? 1080.0;
                            return SizedBox(width: vW, height: vH, child: _currentPlayer!.getVideoWidget(fit: boxFit));
                          },
                        ),
                      ),
                    ),
                  ),

                  if (controls != null) Positioned.fill(child: controls),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlaceholder() {
    return AppStatusView(type: AppStatusType.loading);
  }

  // =========================
  // close
  // =========================

  Future<void> close() {
    if (_disposed) return Future<void>.value();
    // Intent changes belong to dispatch, not native teardown. A pending source
    // open/recovery must lose ownership as soon as close is requested. Waiting
    // for the lifecycle queue used to let it become audible first, and a later
    // close callback could overwrite a newer play() already in the queue.
    _playbackRequested = false;
    _playbackIntentRevision++;
    _sessionId++;
    _cancelPendingSourceInputs();
    _playbackSuspensions.clear();
    _cancelContinuityRecovery();
    _cancelVideoFrameStallRecovery();
    _cancelTransientLiveRetry();
    return _enqueuePlayerLifecycle(_closeInternal);
  }

  Future<void> _closeInternal() async {
    if (_disposed) return;
    _sourceReadyTimer?.cancel();
    _sourceReadyTimer = null;
    _isClosing = true;
    _sourceOpened = false;
    try {
      if (SettingsService.to.playerState.useHardStopOnExit) {
        await _hardDisposeInternal();
      } else {
        await softStop();
      }
    } finally {
      _isClosing = false;
    }
  }

  Future<void> softStop() async {
    lineManager.reset();
    try {
      if (_stateSubject.value == PlayerState.error) {
        await _hardDisposeInternal();

        return;
      }

      final player = _currentPlayer;
      await player?.softStop();
      if (player != null) await _closeSourceTransport(player);
      _stateSubject.add(PlayerState.idle);

      _playingSubject.add(false);
    } catch (e) {
      await _hardDisposeInternal();
    }
  }

  Future<void> hardDispose() async {
    await _enqueuePlayerLifecycle(_hardDisposeInternal);
  }

  Future<void> _hardDisposeInternal() async {
    _cancelVideoFrameStallRecovery();
    _cancelTransientLiveRetry();
    _sourceReadyTimer?.cancel();
    _sourceReadyTimer = null;
    _sessionId++;
    lineManager.reset();
    await _clearSubscriptions();
    final player = _currentPlayer;

    if (player != null) {
      await _disposePlayerWithTransport(player);
    }
    _currentPlayer = null;
    _runtimeEngine = null;
    _currentSource = null;
    _sourceOpened = false;
    _sameEngineRecoveryAttempts = 0;
    isInitialized.value = false;
  }

  // =========================
  // retry
  // =========================

  Future<void> retry() {
    _playbackRequested = true;
    _playbackIntentRevision++;
    _cancelPendingSourceInputs();
    _playbackSuspensions.clear();
    _sameEngineRecoveryAttempts = 0;
    _transientLiveRetryAttempts = 0;
    _cancelTransientLiveRetry();
    _cancelContinuityRecovery();
    final intentRevision = _playbackIntentRevision;
    return _enqueuePlayerLifecycle(() async {
      if (!_isPlaybackCommandCurrent(intentRevision)) return;
      final source = _currentSource;
      if (source == null) return;
      await _playInternal(source, _currentPlayUrls, _currentHeaders, room: currentFloatRoom);
    });
  }

  // =========================
  // watchdogs
  // =========================

  bool get _isContinuousLiveSource {
    final room = currentFloatRoom;
    return room != null && room.isRecord != true && room.isCatchUp != true;
  }

  bool _shouldMaintainPlayback(UnifiedPlayer player, int sessionId) {
    return _shouldOwnContinuousPlayback(player, sessionId) && !_loadingSubject.value;
  }

  bool _shouldOwnContinuousPlayback(UnifiedPlayer player, int sessionId) {
    return _isPlayerEventCurrent(player, sessionId) &&
        _playbackRequested &&
        _playbackSuspensions.isEmpty &&
        _isContinuousLiveSource &&
        _currentSource != null &&
        !hasError.value;
  }

  bool _supportsVideoFrameProgress(UnifiedPlayer player) {
    return player is VideoFrameProgressAwarePlayer &&
        (player as VideoFrameProgressAwarePlayer).supportsVideoFrameProgress;
  }

  /// Marks whether the current route owns a mounted video presentation.
  void setVideoPresentationVisible(bool visible) {
    if (_videoPresentationVisible == visible) return;
    _videoPresentationVisible = visible;
    if (!visible) {
      _cancelVideoFrameStallRecovery();
      return;
    }
    final player = _currentPlayer;
    if (player != null) {
      _armVideoFrameStallRecovery(player, _sessionId);
    }
  }

  void _cancelContinuityRecovery() {
    _continuityRevision++;
    _continuityTimer?.cancel();
    _continuityTimer = null;
    _bufferingStallTimer?.cancel();
    _bufferingStallTimer = null;
  }

  void _cancelTransientLiveRetry() {
    _transientLiveRetryRevision++;
    _transientLiveRetryTimer?.cancel();
    _transientLiveRetryTimer = null;
    _transientLiveRetryOwner = null;
  }

  void _cancelVideoFrameStallRecovery() {
    _videoFrameStallTimer?.cancel();
    _videoFrameStallTimer = null;
    _videoFrameDeadline = null;
    _videoFrameWatchdogClock
      ..stop()
      ..reset();
  }

  void _armVideoFrameStallRecovery(UnifiedPlayer player, int sessionId) {
    if (videoFrameStallTimeout <= Duration.zero ||
        !_videoPresentationVisible ||
        !_supportsVideoFrameProgress(player) ||
        !_shouldOwnContinuousPlayback(player, sessionId) ||
        _loadingSubject.value ||
        (!player.isPlayingNow && !isPlayingNow)) {
      _cancelVideoFrameStallRecovery();
      return;
    }
    // Progress notifications move a monotonic deadline, not a Timer allocation.
    _videoFrameWatchdogClock.start();
    _videoFrameDeadline = _videoFrameWatchdogClock.elapsed + videoFrameStallTimeout;
    if (_videoFrameStallTimer != null) return;

    void checkDeadline() {
      _videoFrameStallTimer = null;
      if (!_videoPresentationVisible ||
          !_shouldOwnContinuousPlayback(player, sessionId) ||
          _loadingSubject.value ||
          (!player.isPlayingNow && !isPlayingNow)) {
        _cancelVideoFrameStallRecovery();
        return;
      }
      final deadline = _videoFrameDeadline;
      if (deadline == null) return;
      final remaining = deadline - _videoFrameWatchdogClock.elapsed;
      if (remaining > Duration.zero) {
        _videoFrameStallTimer = Timer(remaining, checkDeadline);
        return;
      }
      _cancelVideoFrameStallRecovery();
      final observedFrameRevision = _presentedFrameRevision;
      _schedulePlayerError(
        PlayerException(
          message: 'Live player remained active but presented no new video frame',
          type: PlayerErrorType.source,
          code: 'video_frame_stall_timeout',
        ),
        sessionId,
        isStillRelevant: () =>
            observedFrameRevision == _presentedFrameRevision &&
            _videoPresentationVisible &&
            !_loadingSubject.value &&
            (player.isPlayingNow || isPlayingNow),
      );
    }

    _videoFrameStallTimer = Timer(videoFrameStallTimeout, checkDeadline);
  }

  void _scheduleRecoveryBudgetReset(UnifiedPlayer player, int sessionId) {
    if (recoveryBudgetResetDelay <= Duration.zero ||
        (_sameEngineRecoveryAttempts == 0 && _transientLiveRetryAttempts == 0)) {
      return;
    }
    _recoveryBudgetResetTimer ??= Timer(recoveryBudgetResetDelay, () {
      _recoveryBudgetResetTimer = null;
      if (!_isPlayerEventCurrent(player, sessionId) ||
          !player.isPlayingNow ||
          _loadingSubject.value ||
          hasError.value ||
          _playbackSuspensions.isNotEmpty) {
        return;
      }
      _sameEngineRecoveryAttempts = 0;
      _transientLiveRetryAttempts = 0;
      lineManager.reset();
      fallbackManager.resetAll();
      log('Sustained playback restored live recovery budgets', name: 'PlayerManager');
    });
  }

  void _notePresentedFrameProgress(UnifiedPlayer player, int sessionId) {
    if (!_isPlayerEventCurrent(player, sessionId)) return;
    _presentedFrameRevision++;
    _retireTransientLiveRetryForProgress(videoFrame: true);
    _scheduleRecoveryBudgetReset(player, sessionId);
  }

  void _retireTransientLiveRetryForProgress({
    bool videoFrame = false,
    bool bufferingEnded = false,
    bool playingResumed = false,
  }) {
    final retry = _transientLiveRetryOwner;
    if (retry == null) return;
    // Use the same evidence contract as immediate recovery. Buffered tail
    // frames or late texture notifications never refute an explicit EOF or a
    // terminal native error. Only the matching inferred stall is retired.
    final refuted = switch (retry.error.code) {
      'video_frame_stall_timeout' => videoFrame,
      'buffering_stall_timeout' => bufferingEnded,
      'unexpected_pause_resume_failed' || 'unexpected_pause_timeout' || 'source_ready_timeout' => playingResumed,
      _ => false,
    };
    if (!refuted) return;
    _cancelTransientLiveRetry();
    _errorDedupeSignatures.remove('${retry.error.type.name}:${retry.error.code ?? '-'}:${retry.error.message}');
    final playing = _currentPlayer?.isPlayingNow == true;
    _playingSubject.add(playing);
    _loadingSubject.add(_nativeLoading);
    _stateSubject.add(_nativeLoading ? PlayerState.buffering : (playing ? PlayerState.playing : PlayerState.paused));
    hasError.value = false;
  }

  void _scheduleBufferingStallRecovery(UnifiedPlayer player, int sessionId) {
    if (bufferingStallTimeout <= Duration.zero ||
        !_loadingSubject.value ||
        !_shouldOwnContinuousPlayback(player, sessionId) ||
        _bufferingStallTimer != null) {
      return;
    }
    // Own one deadline per uninterrupted buffering episode.
    final revision = ++_continuityRevision;
    _bufferingStallTimer = Timer(bufferingStallTimeout, () {
      _bufferingStallTimer = null;
      if (revision != _continuityRevision ||
          !_loadingSubject.value ||
          !_shouldOwnContinuousPlayback(player, sessionId)) {
        return;
      }
      _schedulePlayerError(
        PlayerException(
          message: 'Live playback remained buffered without media progress',
          type: PlayerErrorType.source,
          code: 'buffering_stall_timeout',
        ),
        sessionId,
        isStillRelevant: () => revision == _continuityRevision && _loadingSubject.value,
      );
    });
  }

  void _scheduleContinuityRecovery(UnifiedPlayer player, int sessionId) {
    if (!_shouldMaintainPlayback(player, sessionId) || player.isPlayingNow || isPlayingNow) return;
    _continuityTimer?.cancel();
    final revision = ++_continuityRevision;
    _continuityTimer = Timer(unexpectedPauseGrace, () {
      _continuityTimer = null;
      unawaited(
        _enqueuePlayerLifecycle(() async {
          if (revision != _continuityRevision ||
              !_shouldMaintainPlayback(player, sessionId) ||
              player.isPlayingNow ||
              isPlayingNow) {
            return;
          }
          try {
            // Some native live players briefly publish `playing=false` after
            // an audio-focus hand-off or CDN discontinuity without raising an
            // error. Reassert the existing source once before escalating to
            // the normal line/engine recovery state machine.
            await player.play().timeout(unexpectedPauseFailureGrace);
          } catch (error, stackTrace) {
            _schedulePlayerError(
              PlayerException(
                message: 'Live playback did not resume after an unexpected pause',
                type: PlayerErrorType.source,
                code: 'unexpected_pause_resume_failed',
                error: error,
                stackTrace: stackTrace,
              ),
              sessionId,
              isStillRelevant: () =>
                  revision == _continuityRevision &&
                  _shouldMaintainPlayback(player, sessionId) &&
                  !player.isPlayingNow &&
                  !isPlayingNow,
            );
            return;
          }
          if (player.isPlayingNow || isPlayingNow || !_shouldMaintainPlayback(player, sessionId)) return;
          final confirmationRevision = ++_continuityRevision;
          _continuityTimer = Timer(unexpectedPauseFailureGrace, () {
            _continuityTimer = null;
            if (confirmationRevision != _continuityRevision ||
                !_shouldMaintainPlayback(player, sessionId) ||
                player.isPlayingNow ||
                isPlayingNow) {
              return;
            }
            _schedulePlayerError(
              PlayerException(
                message: 'Live playback remained paused after the continuity retry',
                type: PlayerErrorType.source,
                code: 'unexpected_pause_timeout',
              ),
              sessionId,
              isStillRelevant: () =>
                  confirmationRevision == _continuityRevision &&
                  _shouldMaintainPlayback(player, sessionId) &&
                  !player.isPlayingNow &&
                  !isPlayingNow,
            );
          });
        }).catchError((Object error, StackTrace stackTrace) {
          log('Unexpected-pause recovery failed: $error', name: 'PlayerManager', stackTrace: stackTrace);
        }),
      );
    });
  }

  void _armSourceReadyDeadline(UnifiedPlayer player, int sessionId) {
    _sourceReadyTimer?.cancel();
    _sourceReadyTimer = null;
    if (sourceReadyTimeout <= Duration.zero || player.isPlayingNow || !_isPlayerEventCurrent(player, sessionId)) {
      return;
    }
    _sourceReadyTimer = Timer(sourceReadyTimeout, () {
      _sourceReadyTimer = null;
      if (!_isPlayerEventCurrent(player, sessionId) || player.isPlayingNow || _playingSubject.value) return;
      _schedulePlayerError(
        PlayerException(
          message: 'Source opened but produced no playable frame before the readiness deadline',
          type: PlayerErrorType.source,
          code: 'source_ready_timeout',
        ),
        sessionId,
        isStillRelevant: () => !player.isPlayingNow && !_playingSubject.value,
      );
    });
  }

  void _schedulePlayerError(PlayerException error, int sessionId, {bool Function()? isStillRelevant}) {
    final expectedPlayer = _currentPlayer;
    final expectedIntentRevision = _playbackIntentRevision;
    unawaited(
      _enqueuePlayerLifecycle(() async {
        // Queueing preserves native ownership but can outlive the observation:
        // a token request may still be in flight while media recovers or the
        // user pauses. Revalidate before changing loading, timers or sources.
        if (!_isSessionValid(sessionId) ||
            !identical(expectedPlayer, _currentPlayer) ||
            expectedIntentRevision != _playbackIntentRevision ||
            !_playbackRequested ||
            _playbackSuspensions.isNotEmpty ||
            (isStillRelevant != null && !isStillRelevant())) {
          return;
        }
        await _handleError(error, sessionId: sessionId);
      }).catchError((Object failure, StackTrace stackTrace) {
        log(
          'Scheduled player recovery failed: $failure',
          name: 'PlayerManager',
          error: failure,
          stackTrace: stackTrace,
        );
      }),
    );
  }

  // =========================
  // error
  // =========================

  Future<void> _handleError(PlayerException error, {int? sessionId}) async {
    if (_disposed || _isClosing) return;
    final mySessionId = sessionId ?? _sessionId;
    if (!_isSessionValid(mySessionId)) return;
    final request = _PendingPlayerError(error: error, sessionId: mySessionId);
    // Reject duplicates before touching any watchdog or backoff owner. Native
    // layers can repeat the same failure after its first recovery was queued.
    if (!_registerPlayerError(request)) {
      log('skip duplicated source-generation error: ${error.message}', name: 'PlayerManager');
      return;
    }
    _cancelContinuityRecovery();
    _cancelVideoFrameStallRecovery();
    _cancelTransientLiveRetry();
    _sourceReadyTimer?.cancel();
    _sourceReadyTimer = null;

    if (_isHandlingError) {
      // A replacement line/engine can fail synchronously while the previous
      // recovery is still on the stack. Dropping that event left the second
      // source loading forever. Keep the newest source-generation failure and
      // drain it as soon as the current recovery step returns.
      _pendingPlayerError = request;
      return;
    }

    _isHandlingError = true;
    try {
      _PendingPlayerError? current = request;
      while (current != null && !_disposed && !_isClosing) {
        _pendingPlayerError = null;
        await _recoverOrPublishPlayerError(current);
        current = _pendingPlayerError;
      }
    } finally {
      _isHandlingError = false;
      final pending = _pendingPlayerError;
      _pendingPlayerError = null;
      if (pending != null && _isSessionValid(pending.sessionId)) {
        unawaited(_handleError(pending.error, sessionId: pending.sessionId));
      }
    }
  }

  bool _registerPlayerError(_PendingPlayerError request) {
    if (_errorDedupeSession != request.sessionId) {
      _errorDedupeSession = request.sessionId;
      _errorDedupeSignatures.clear();
    }
    return _errorDedupeSignatures.add(
      '${request.error.type.name}:${request.error.code ?? '-'}:${request.error.message}',
    );
  }

  Future<void> _recoverOrPublishPlayerError(_PendingPlayerError request) async {
    if (!_isSessionValid(request.sessionId)) return;
    final error = request.error;
    final activeAtStart = _currentPlayer;
    final intentAtStart = _playbackIntentRevision;
    final bufferRecoveryAtStart = _bufferingRecoveryRevision;
    final playingRecoveryAtStart = _playingRecoveryRevision;
    final frameAtStart = _presentedFrameRevision;
    final engineAttemptsAtStart = _sameEngineRecoveryAttempts;
    bool isStillRequired() {
      if (!_isSessionValid(request.sessionId) ||
          !identical(_currentPlayer, activeAtStart) ||
          _playbackIntentRevision != intentAtStart ||
          !_playbackRequested ||
          _playbackSuspensions.isNotEmpty) {
        return false;
      }
      // Only inferred stalls can be refuted by new progress. A real EOF or
      // native error still needs recovery even while buffered frames drain.
      return switch (error.code) {
        'buffering_stall_timeout' => bufferRecoveryAtStart == _bufferingRecoveryRevision,
        'video_frame_stall_timeout' => frameAtStart == _presentedFrameRevision && _videoPresentationVisible,
        'unexpected_pause_resume_failed' ||
        'unexpected_pause_timeout' ||
        'source_ready_timeout' => playingRecoveryAtStart == _playingRecoveryRevision,
        _ => true,
      };
    }

    if (!isStillRequired()) return;
    _loadingSubject.add(true);
    _stateSubject.add(PlayerState.buffering);

    try {
      final currentUrl = _currentUrl;
      if ((error.type == PlayerErrorType.network || error.type == PlayerErrorType.source) &&
          currentUrl != null &&
          _currentPlayUrls.length > 1) {
        lineManager.markFailed(currentUrl);
        if (lineManager.hasAvailable(_currentPlayUrls)) {
          final nextLine = lineManager.next(_currentPlayUrls);
          if (nextLine != currentUrl) {
            log('recover playback with next line', name: 'PlayerManager');
            await _playInternal(
              UrlPlaybackSource(nextLine),
              _currentPlayUrls,
              _currentHeaders,
              room: currentFloatRoom,
            );
            return;
          }
        }
      }

      // A presented-frame stall means the current transport is already no
      // longer producing visible content. With alternate CDNs available,
      // switching source on the existing engine is both faster and safer than
      // opening the same signed URL concurrently on a replacement engine.
      // The single-line case still gets the bounded same-engine recreation.
      if (error.code == 'video_frame_stall_timeout' &&
          await _tryRecreateCurrentEngineForStall(error, isStillRequired: isStillRequired)) {
        return;
      }
      if (!isStillRequired()) return;

      final activePlayer = _currentPlayer;
      final currentDecoderSource = _currentSource;
      if (error.type == PlayerErrorType.codec &&
          error.code?.startsWith('audio_') != true &&
          activePlayer is DecoderRecoveryAwarePlayer &&
          currentDecoderSource != null &&
          await (activePlayer as DecoderRecoveryAwarePlayer).prepareSoftwareDecoderFallback(error)) {
        if (!isStillRequired()) return;
        log('recover playback with software decoder on the current engine', name: 'PlayerManager');
        await _playInternal(
          currentDecoderSource,
          _currentPlayUrls,
          _currentHeaders,
          room: currentFloatRoom,
        );
        return;
      }
      if (!isStillRequired()) return;

      if (fallbackManager.shouldFallback(error)) {
        final activeEngine = _runtimeEngine;
        if (activeEngine != null) {
          var engineCursor = activeEngine;
          var engineError = error;
          while (true) {
            final nextEngine = await fallbackManager.fallback(engineCursor, engineError);
            if (!isStillRequired()) return;
            if (nextEngine == engineCursor) break;
            log('recover playback with engine: ${engineCursor.name} -> ${nextEngine.name}', name: 'PlayerManager');
            _isSwitchingDueToFallback = true;
            try {
              await _switchEngineInternal(
                nextEngine,
                isManual: false,
                isStillRequired: isStillRequired,
              );
            } catch (switchError, stackTrace) {
              // Initialization can fail before the replacement engine owns a
              // source. Continue through the remaining engines instead of
              // leaving the old engine marked as switching forever.
              _isSwitchingDueToFallback = false;
              if (!isStillRequired()) return;
              engineCursor = nextEngine;
              engineError = switchError is PlayerException
                  ? switchError
                  : PlayerException(
                      message: 'Switch engine failed: $switchError',
                      type: PlayerErrorType.initialization,
                      error: switchError,
                      stackTrace: stackTrace,
                    );
              continue;
            }
            return;
          }
        }
      }
      if (!isStillRequired()) return;
      if (_shouldRecreateCurrentEngine(error) &&
          await _tryRecreateCurrentEngineForStall(error, isStillRequired: isStillRequired)) {
        return;
      }
      if (!isStillRequired()) return;
      _isSwitchingDueToFallback = false;
      if (_scheduleTransientLiveRetry(error)) return;
      _publishTerminalPlayerError(error);
    } catch (fallbackError, stackTrace) {
      _isSwitchingDueToFallback = false;
      if (!isStillRequired()) return;
      log('player recovery exhausted: $fallbackError', name: 'PlayerManager', stackTrace: stackTrace);
      if (_scheduleTransientLiveRetry(error)) return;
      _publishTerminalPlayerError(fallbackError is PlayerException ? fallbackError : error);
    } finally {
      if (activeAtStart != null &&
          !hasError.value &&
          !isStillRequired() &&
          _isPlayerEventCurrent(activeAtStart, request.sessionId)) {
        // Retire only this obsolete diagnostic; a later independent stall in
        // the same source generation must not be swallowed by deduplication.
        _errorDedupeSignatures.remove('${error.type.name}:${error.code ?? '-'}:${error.message}');
        // An aborted transaction is not an exhausted repair attempt. Keep
        // earlier real failures, but refund this uncommitted transaction.
        _sameEngineRecoveryAttempts = engineAttemptsAtStart;
        fallbackManager.reset(activeAtStart.engine);
        _isSwitchingDueToFallback = false;
        final loading = _playbackRequested && _playbackSuspensions.isEmpty && _nativeLoading;
        final playing = activeAtStart.isPlayingNow;
        _loadingSubject.add(loading);
        _playingSubject.add(playing);
        _stateSubject.add(loading ? PlayerState.buffering : (playing ? PlayerState.playing : PlayerState.paused));
        if (loading) {
          _scheduleBufferingStallRecovery(activeAtStart, request.sessionId);
        } else {
          _armVideoFrameStallRecovery(activeAtStart, request.sessionId);
          _scheduleContinuityRecovery(activeAtStart, request.sessionId);
          _scheduleRecoveryBudgetReset(activeAtStart, request.sessionId);
        }
      }
    }
  }

  /// Keeps a continuous live session recoverable across a short network/TLS
  /// interruption without spinning through every source and decoder in the
  /// same failing millisecond. Immediate line/engine recovery above still runs
  /// first. Only after it is exhausted do we schedule the finite backoff rounds
  /// configured by [transientLiveRetryDelays].
  bool _scheduleTransientLiveRetry(PlayerException error) {
    if ((error.type != PlayerErrorType.network && error.type != PlayerErrorType.source) ||
        !_isContinuousLiveSource ||
        !_playbackRequested ||
        _playbackSuspensions.isNotEmpty ||
        _currentSource == null ||
        _transientLiveRetryAttempts >= transientLiveRetryDelays.length) {
      return false;
    }

    final delay = transientLiveRetryDelays[_transientLiveRetryAttempts++];
    final expectedSessionId = _sessionId;
    final expectedIntentRevision = _playbackIntentRevision;
    final expectedRoom = currentFloatRoom;
    final expectedPlayer = _currentPlayer;
    final revision = ++_transientLiveRetryRevision;
    _transientLiveRetryTimer?.cancel();
    _transientLiveRetryOwner = _PendingPlayerError(error: error, sessionId: expectedSessionId);
    hasError.value = false;
    _loadingSubject.add(true);
    _stateSubject.add(PlayerState.buffering);
    log('Immediate live recovery exhausted; retrying after ${delay.inMilliseconds} ms', name: 'PlayerManager');

    bool isStillRequired() =>
        revision == _transientLiveRetryRevision &&
        !_disposed &&
        !_isClosing &&
        _playbackRequested &&
        _playbackSuspensions.isEmpty &&
        _playbackIntentRevision == expectedIntentRevision &&
        _sessionId == expectedSessionId &&
        identical(_currentPlayer, expectedPlayer) &&
        currentFloatRoom == expectedRoom;

    _transientLiveRetryTimer = Timer(delay, () {
      _transientLiveRetryTimer = null;
      if (!isStillRequired()) {
        if (revision == _transientLiveRetryRevision) _transientLiveRetryOwner = null;
        return;
      }
      unawaited(
        _enqueuePlayerLifecycle(() async {
              if (!isStillRequired()) return;

              // A new recovery round receives fresh bounded line/engine budgets.
              // The delayed-round budget itself remains monotonic until sustained
              // playback proves the transport healthy again.
              _sameEngineRecoveryAttempts = 0;
              _transientLiveRetryAttempts = 0;
              lineManager.reset();
              fallbackManager.resetAll();

              final retrySource = _currentSource;
              if (retrySource == null) return;
              await _playInternal(
                retrySource,
                _currentPlayUrls,
                _currentHeaders,
                room: currentFloatRoom,
              );
            })
            .catchError((Object retryError, StackTrace stackTrace) {
              log(
                'Delayed live recovery failed: $retryError',
                name: 'PlayerManager',
                error: retryError,
                stackTrace: stackTrace,
              );
            })
            .whenComplete(() {
              if (revision == _transientLiveRetryRevision) _transientLiveRetryOwner = null;
            }),
      );
    });
    return true;
  }

  void _publishTerminalPlayerError(PlayerException error) {
    _cancelTransientLiveRetry();
    _playbackRequested = false;
    _playbackSuspensions.clear();
    _cancelContinuityRecovery();
    _cancelVideoFrameStallRecovery();
    _sourceReadyTimer?.cancel();
    _sourceReadyTimer = null;
    hasError.value = true;
    _loadingSubject.add(false);
    _errorSubject.add(error);
    _stateSubject.add(PlayerState.error);
  }

  bool _shouldRecreateCurrentEngine(PlayerException error) {
    if (error.type != PlayerErrorType.source) return false;
    return const <String>{
      'buffering_stall_timeout',
      'live_source_completed',
      'unexpected_pause_resume_failed',
      'unexpected_pause_timeout',
      'video_frame_stall_timeout',
    }.contains(error.code);
  }

  Future<bool> _tryRecreateCurrentEngineForStall(PlayerException error, {bool Function()? isStillRequired}) async {
    if (isStillRequired?.call() == false) return true;
    if (!_shouldRecreateCurrentEngine(error) || _sameEngineRecoveryAttempts >= 1) return false;
    final activeEngine = _runtimeEngine;
    final activePlayer = _currentPlayer;
    final currentSource = _currentSource;
    if (activeEngine == null || activePlayer == null || currentSource == null) return false;
    _sameEngineRecoveryAttempts++;
    log('recover runtime live stall with a bounded same-engine recreation', name: 'PlayerManager');
    try {
      await _switchEngineInternal(
        activeEngine,
        isManual: false,
        forceRecreate: true,
        isStillRequired: isStillRequired,
      );
      return true;
    } catch (recreateError, recreateStackTrace) {
      log(
        'same-engine recreation failed: $recreateError',
        name: 'PlayerManager',
        error: recreateError,
        stackTrace: recreateStackTrace,
      );
      return false;
    }
  }

  // =========================
  // bind
  // =========================

  bool _isPlayerEventCurrentBindGuard(UnifiedPlayer player, int sessionId) =>
      _isPlayerEventCurrent(player, sessionId);

  Future<void> _bindPlayerStreams(UnifiedPlayer player, {required int sessionId}) async {
    await _clearSubscriptions();
    _nativeLoading = false;
    if (_supportsVideoFrameProgress(player)) {
      final frameAwarePlayer = player as VideoFrameProgressAwarePlayer;
      _subscriptions.add(
        frameAwarePlayer.onVideoFrameProgress.listen((_) {
          if (!_isPlayerEventCurrentBindGuard(player, sessionId)) return;
          _notePresentedFrameProgress(player, sessionId);
          _armVideoFrameStallRecovery(player, sessionId);
        }),
      );
    }
    _subscriptions.add(
      player.onPlaying.distinct().listen((event) {
        if (!_isPlayerEventCurrentBindGuard(player, sessionId)) return;
        _playingSubject.add(event);
        if (event) {
          _playingRecoveryRevision++;
          _retireTransientLiveRetryForProgress(playingResumed: true);
          _sourceReadyTimer?.cancel();
          _sourceReadyTimer = null;
          hasError.value = false;
          if (_loadingSubject.value) {
            // libmpv may keep `playing=true` while the demuxer is starved.
            // Persistent buffering is the authoritative progress signal.
            _continuityTimer?.cancel();
            _continuityTimer = null;
            _stateSubject.add(PlayerState.buffering);
            _scheduleBufferingStallRecovery(player, sessionId);
          } else {
            _cancelContinuityRecovery();
            _stateSubject.add(PlayerState.playing);
            _armVideoFrameStallRecovery(player, sessionId);
          }
          final currentUrl = _currentUrl;
          if (currentUrl != null) lineManager.markSuccess(currentUrl);
          final runtimeEngine = _runtimeEngine;
          if (runtimeEngine != null) fallbackManager.reset(runtimeEngine);
          if (_isSwitchingDueToFallback) {
            _isSwitchingDueToFallback = false;
          }
          _scheduleRecoveryBudgetReset(player, sessionId);
        } else {
          _cancelVideoFrameStallRecovery();
          // A transient native `playing=false` is not a user pause while the
          // room still owns continuous playback.
          final transportOwnsPause = _shouldOwnContinuousPlayback(player, sessionId);
          if (!transportOwnsPause &&
              _stateSubject.value != PlayerState.preparing &&
              _stateSubject.value != PlayerState.buffering) {
            _stateSubject.add(PlayerState.paused);
          }
          // Native players commonly publish buffering=true before
          // playing=false. Schedule the watchdog again after false becomes the
          // authoritative state.
          if (_loadingSubject.value) {
            _scheduleBufferingStallRecovery(player, sessionId);
          } else {
            _scheduleContinuityRecovery(player, sessionId);
          }
        }
      }),
    );

    _subscriptions.add(
      player.onLoading.distinct().listen((event) {
        if (!_isPlayerEventCurrentBindGuard(player, sessionId)) return;
        if (!event && _nativeLoading) _bufferingRecoveryRevision++;
        _nativeLoading = event;
        if (!event) _retireTransientLiveRetryForProgress(bufferingEnded: true);
        _loadingSubject.add(event);
        if (event) {
          _cancelVideoFrameStallRecovery();
          _cancelContinuityRecovery();
          if (_stateSubject.value != PlayerState.buffering) {
            _stateSubject.add(PlayerState.buffering);
          }
          _scheduleBufferingStallRecovery(player, sessionId);
        } else {
          _cancelContinuityRecovery();
          if (player.isPlayingNow || isPlayingNow) {
            _stateSubject.add(PlayerState.playing);
            _armVideoFrameStallRecovery(player, sessionId);
          } else {
            _scheduleContinuityRecovery(player, sessionId);
          }
        }
      }),
    );

    _subscriptions.add(
      player.onComplete.distinct().listen((event) {
        if (!_isPlayerEventCurrentBindGuard(player, sessionId)) return;
        _completeSubject.add(event);
        if (event &&
            _playbackRequested &&
            _playbackSuspensions.isEmpty &&
            _isContinuousLiveSource &&
            _stateSubject.value != PlayerState.preparing) {
          _cancelContinuityRecovery();
          _schedulePlayerError(
            PlayerException(
              message: 'Live source ended unexpectedly',
              type: PlayerErrorType.source,
              code: 'live_source_completed',
            ),
            sessionId,
          );
        }
      }),
    );

    _subscriptions.add(
      player.onStateChanged.listen((event) {
        if (!_isPlayerEventCurrentBindGuard(player, sessionId)) return;
        // media_kit can publish PlayerState.paused after onLoading(true) or
        // after a transient onPlaying(false). For a live source whose owner
        // still requests playback this is transport state, not user intent.
        if (event == PlayerState.paused && _shouldOwnContinuousPlayback(player, sessionId)) {
          if (_loadingSubject.value) {
            if (_stateSubject.value != PlayerState.buffering) {
              _stateSubject.add(PlayerState.buffering);
            }
            _scheduleBufferingStallRecovery(player, sessionId);
          } else {
            _scheduleContinuityRecovery(player, sessionId);
          }
          return;
        }
        _stateSubject.add(event);
      }),
    );

    _subscriptions.add(
      player.onError.listen((error) {
        if (!_isPlayerEventCurrentBindGuard(player, sessionId)) return;
        _schedulePlayerError(error, sessionId);
      }),
    );

    _subscriptions.add(
      player.width.listen((event) {
        if (!_isPlayerEventCurrentBindGuard(player, sessionId)) return;
        _widthSubject.add(event);
      }),
    );

    _subscriptions.add(
      player.height.listen((event) {
        if (!_isPlayerEventCurrentBindGuard(player, sessionId)) return;
        _heightSubject.add(event);
      }),
    );

    _subscriptions.add(
      CombineLatestStream.combine2<int?, int?, bool>(
        width.where((w) => w != null && w > 0),
        height.where((h) => h != null && h > 0),
        (w, h) => h! >= w!,
      ).distinct().listen((event) {
        isVerticalVideo.value = event;
      }),
    );

    _armVideoFrameStallRecovery(player, sessionId);
  }

  // =========================
  // clear subscriptions
  // =========================

  Future<void> _clearSubscriptions() async {
    _cancelVideoFrameStallRecovery();
    if (_subscriptions.isEmpty) return;
    final subscriptions = List<StreamSubscription>.of(_subscriptions);
    // Detach ownership before awaiting cancellation so a synchronous source
    // callback cannot append into the list being drained.
    _subscriptions.clear();
    await Future.wait<void>(subscriptions.map((item) => item.cancel()));
  }

  // =========================
  // dispose
  // =========================

  Future<void> dispose() async {
    if (_disposed) return;

    _disposed = true;
    _currentSource = null;
    _sourceOpened = false;
    _cancelPendingSourceInputs();
    _playbackRequested = false;
    _playbackSuspensions.clear();
    _cancelContinuityRecovery();
    _cancelVideoFrameStallRecovery();
    _cancelTransientLiveRetry();
    _sessionId++;
    _pendingPlayerError = null;
    _errorDedupeSignatures.clear();
    _isClosing = true;
    _sourceReadyTimer?.cancel();
    _sourceReadyTimer = null;
    _recoveryBudgetResetTimer?.cancel();
    _recoveryBudgetResetTimer = null;
    await _clearSubscriptions();
    await _hardDisposeInternal();
    await Future.wait([
      _stateSubject.close(),
      _playingSubject.close(),
      _loadingSubject.close(),
      _completeSubject.close(),
      _errorSubject.close(),
      _widthSubject.close(),
      _heightSubject.close(),
      isInitialized.close(),
      hasError.close(),
      isVerticalVideo.close(),
      videoFitIndex.close(),
      videoKey.close(),
    ]);
    await _lifecycleCoordinator.dispose();
  }
}

enum _PlaybackSuspensionReason { lifecycle }
