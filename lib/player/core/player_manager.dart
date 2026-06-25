import 'dart:async';
import 'dart:developer';
import 'player_pool.dart';
import 'line_fallback_manager.dart';
import '../models/player_state.dart';
import 'preload_player_manager.dart';
import '../models/player_engine.dart';
import 'engine_fallback_manager.dart';
import 'package:flutter/material.dart';
import '../models/player_exception.dart';
import '../models/player_error_type.dart';
import 'package:rxdart/rxdart.dart' hide Rx;
import '../interface/unified_player_interface.dart';
import 'package:pure_live/widgets/app_status_view.dart';
import 'package:pure_live/player/utils/player_consts.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:pure_live/core/models/live_room/live_room.dart';

class PlayerManager {
  final PlayerPool playerPool;

  final EngineFallbackManager fallbackManager;

  final PreloadPlayerManager preloadManager;

  final LineFallbackManager lineManager;
  PlayerManager({
    required this.playerPool,
    required this.fallbackManager,
    required this.preloadManager,
    required this.lineManager,
  });

  // =========================
  // player
  // =========================

  UnifiedPlayer? _currentPlayer;

  PlayerEngine? _runtimeEngine;

  PlayerEngine? _defaultEngine;

  // =========================
  // play info
  // =========================

  String? _currentUrl;

  List<String> _currentPlayUrls = [];

  Map<String, String> _currentHeaders = {};

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

  // =========================
  // subscriptions
  // =========================

  final List<StreamSubscription> _subscriptions = [];

  // =========================
  // misc
  // =========================

  bool _disposed = false;

  bool _isSwitchingDueToFallback = false;
  bool _isHandlingError = false;

  Timer? _hideTimer;

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

  double get currentVideoRatio {
    final w = _widthSubject.value?.toDouble() ?? 1920;

    final h = _heightSubject.value?.toDouble() ?? 1080;

    if (w <= 0 || h <= 0) {
      return 16 / 9;
    }

    return w / h;
  }

  // =========================
  // initialize
  // =========================

  Future<void> initialize({PlayerEngine engine = PlayerEngine.mediaKit}) async {
    if (_disposed) return;

    _stateSubject.add(PlayerState.initializing);

    try {
      _defaultEngine = engine;

      _runtimeEngine = engine;

      _currentPlayer = await playerPool.getPlayer(engine);

      await _bindPlayerStreams(_currentPlayer!);
      isInitialized.value = true;
      _stateSubject.add(PlayerState.initialized);
    } catch (e, s) {
      hasError.value = true;

      final exception = PlayerException(
        message: 'Initialize player failed',
        type: PlayerErrorType.initialization,
        error: e,
        stackTrace: s,
      );

      _errorSubject.add(exception);

      _stateSubject.add(PlayerState.error);

      throw exception;
    }
  }

  // =========================
  // play
  // =========================

  Future<void> play(String url, List<String> playUrls, Map<String, String> headers, {LiveRoom? room}) async {
    if (_disposed) return;
    if (room?.roomId != currentFloatRoom?.roomId) {
      lineManager.reset();
    }
    if (_currentPlayer == null || _runtimeEngine == null) {
      final String savedKey = SettingsService.to.playerState.videoPlayerKey;
      final String validKey = PlayerConsts.engines.containsKey(savedKey) ? savedKey : PlayerConsts.defaultKey;
      _defaultEngine = PlayerConsts.engines[validKey]!;
      _runtimeEngine = _defaultEngine;
      log('No current player, initializing with default engine: _defaultEngine', name: 'PlayerManager');
      await initialize(engine: _defaultEngine!);
    } else if (_runtimeEngine != _defaultEngine && !_isSwitchingDueToFallback) {
      await switchEngine(_defaultEngine!, isManual: false);
    }

    final player = _currentPlayer;

    if (player == null) {
      throw PlayerException(message: 'Current player is null', type: PlayerErrorType.lifecycle);
    }

    _currentUrl = url;

    _currentPlayUrls = playUrls;

    _currentHeaders = headers;

    currentFloatRoom = room;

    hasError.value = false;

    try {
      _stateSubject.add(PlayerState.preparing);
      await player.setDataSource(url, playUrls, headers, room: room);

      videoKey.value = ValueKey("video_${DateTime.now().millisecondsSinceEpoch}");

      _stateSubject.add(PlayerState.ready);
    } on PlayerException catch (e) {
      if (!_isHandlingError) {
        await _handleError(e);
      }
    } catch (e, s) {
      log(e.toString());
      final exception = PlayerException(message: 'Play failed', type: PlayerErrorType.unknown, error: e, stackTrace: s);

      if (!_isHandlingError) {
        await _handleError(exception);
      }
    } finally {
      _isSwitchingDueToFallback = false;
    }
  }

  // =========================
  // replay
  // =========================

  Future<void> replay() async {
    if (_currentUrl == null) return;
    await play(_currentUrl!, _currentPlayUrls, _currentHeaders, room: currentFloatRoom);
  }

  // =========================
  // switch engine
  // =========================

  Future<void> switchEngine(PlayerEngine engine, {bool isManual = false}) async {
    if (_disposed) return;

    if (_runtimeEngine == engine && _currentPlayer != null) {
      return;
    }

    try {
      final oldPlayer = _currentPlayer;

      final oldEngine = _runtimeEngine;

      await _clearSubscriptions();

      final newPlayer = await playerPool.getPlayer(engine);

      _currentPlayer = newPlayer;

      _runtimeEngine = engine;

      if (isManual) {
        _defaultEngine = engine;
      }

      await _bindPlayerStreams(newPlayer);
      if (oldPlayer != null && oldEngine != null) {
        await _safeDestroyPlayer(oldPlayer, oldEngine);
      }

      videoKey.value = ValueKey("video_${DateTime.now().millisecondsSinceEpoch}");
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

  Future<void> _safeDestroyPlayer(UnifiedPlayer player, PlayerEngine engine) async {
    try {
      await player.hardDispose();

      await playerPool.removeFromCache(engine);
    } catch (e, s) {
      log("destroy player error: $e", stackTrace: s);
    }
  }

  // =========================
  // preload
  // =========================

  Future<void> preload(String url, List<String> playUrls, Map<String, String> headers) async {
    if (_disposed) return;

    final standby = await playerPool.getPlayer(_runtimeEngine!);

    await preloadManager.preload(standby, url, playUrls, headers);
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

    await _bindPlayerStreams(player);
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
    await _currentPlayer?.pause();
  }

  Future<void> resume() async {
    await _currentPlayer?.play();
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
  }

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
          final boxFit = fitList[fitIndex];
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
                            // 动态使用视频的真实宽高
                            final vW = snapshot.data?[0]?.toDouble() ?? 1920.0;
                            final vH = snapshot.data?[1]?.toDouble() ?? 1080.0;
                            return SizedBox(width: vW, height: vH, child: _currentPlayer!.getVideoWidget());
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

  Future<void> close() async {
    SettingsService.to.playerState.useHardStopOnExit ? await hardDispose() : await softStop();
  }

  Future<void> softStop() async {
    lineManager.reset();
    try {
      if (_stateSubject.value == PlayerState.error) {
        await hardDispose();

        return;
      }

      await _currentPlayer?.softStop();

      _stateSubject.add(PlayerState.idle);

      _playingSubject.add(false);
    } catch (e) {
      await hardDispose();
    }
  }

  Future<void> hardDispose() async {
    lineManager.reset();
    await _clearSubscriptions();
    if (_runtimeEngine != null) {
      await playerPool.removeFromCache(_runtimeEngine!);
    }
    _currentPlayer = null;
    _runtimeEngine = null;
    isInitialized.value = false;
  }

  // =========================
  // retry
  // =========================

  Future<void> retry() async {
    await replay();
  }

  // =========================
  // error
  // =========================
  Future<void> _handleError(PlayerException error) async {
    if (_disposed) return;
    if (_isHandlingError) {
      log("skip duplicated error handling: ${error.message}");
      return;
    }
    _isHandlingError = true;

    try {
      hasError.value = true;
      _errorSubject.add(error);
      _stateSubject.add(PlayerState.error);

      bool lineSwitched = false;

      if ((error.type == PlayerErrorType.network || error.type == PlayerErrorType.source) &&
          _currentPlayUrls.length > 1) {
        lineManager.markFailed(_currentUrl!);

        if (!lineManager.hasAvailable(_currentPlayUrls)) {
          log("no available lines, fallback engine");
        } else {
          final nextLine = lineManager.next(_currentPlayUrls);

          if (nextLine != _currentUrl) {
            lineSwitched = true;

            log("switch line => $nextLine");

            await Future.delayed(const Duration(seconds: 2));

            await play(nextLine, _currentPlayUrls, _currentHeaders, room: currentFloatRoom);

            return;
          }
        }
      }
      log(error.type.toString());
      // =========================
      // 2. 再尝试切播放器
      // =========================

      if (!lineSwitched && fallbackManager.shouldFallback(error)) {
        final nextEngine = await fallbackManager.fallback(_runtimeEngine!, error);

        // 防止重复切换
        if (nextEngine == _runtimeEngine) {
          log("skip fallback: nextEngine(${nextEngine.name}) == currentEngine(${_runtimeEngine?.name})");
          return;
        }

        log(
          "fallback engine: "
          "${_runtimeEngine?.name} -> ${nextEngine.name}",
        );
        _isSwitchingDueToFallback = true;

        // 给底层播放器一点释放时间
        await Future.delayed(const Duration(milliseconds: 1200));

        await switchEngine(nextEngine, isManual: false);

        await Future.delayed(const Duration(milliseconds: 500));

        await replay();

        return;
      }
    } catch (e, s) {
      log("_handleError failed: $e", stackTrace: s);
    } finally {
      _isHandlingError = false;
    }
  }
  // =========================
  // bind
  // =========================

  Future<void> _bindPlayerStreams(UnifiedPlayer player) async {
    await _clearSubscriptions();
    _subscriptions.add(
      player.onPlaying.listen((event) async {
        _playingSubject.add(event);
        if (event) {
          hasError.value = false;
          _stateSubject.add(PlayerState.playing);
          if (_isSwitchingDueToFallback) {
            _isSwitchingDueToFallback = false;
          }
        } else {
          _stateSubject.add(PlayerState.paused);
        }
      }),
    );

    _subscriptions.add(
      player.onLoading.listen((event) {
        _loadingSubject.add(event);
        if (event && _stateSubject.value != PlayerState.buffering) {
          _stateSubject.add(PlayerState.buffering);
        }
      }),
    );

    _subscriptions.add(
      player.onComplete.listen((event) {
        _completeSubject.add(event);
      }),
    );

    _subscriptions.add(
      player.onStateChanged.listen((event) {
        _stateSubject.add(event);
      }),
    );

    _subscriptions.add(
      player.onError.listen((error) {
        if (!_isHandlingError) {
          _handleError(error);
        }
      }),
    );

    _subscriptions.add(
      player.width.listen((event) {
        _widthSubject.add(event);
      }),
    );

    _subscriptions.add(
      player.height.listen((event) {
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
  }

  // =========================
  // clear subscriptions
  // =========================

  Future<void> _clearSubscriptions() async {
    if (_subscriptions.isEmpty) return;
    for (final item in _subscriptions.toList()) {
      await item.cancel();
    }
    _subscriptions.clear();
  }

  // =========================
  // dispose
  // =========================

  Future<void> dispose() async {
    if (_disposed) return;

    _disposed = true;

    _hideTimer?.cancel();

    await _clearSubscriptions();

    await playerPool.disposeAll();

    await Future.wait([
      _stateSubject.close(),
      _playingSubject.close(),
      _loadingSubject.close(),
      _completeSubject.close(),
      _errorSubject.close(),
      _widthSubject.close(),
      _heightSubject.close(),
    ]);
  }
}
