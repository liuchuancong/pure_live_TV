import 'dart:async';
import 'player_pool.dart';
import 'package:rxdart/rxdart.dart';
import 'line_fallback_manager.dart';
import '../models/player_state.dart';
import 'preload_player_manager.dart';
import '../models/player_engine.dart';
import 'engine_fallback_manager.dart';
import 'player_error_dispatcher.dart';
import '../models/player_exception.dart';
import '../models/player_error_type.dart';
import 'package:pure_live/common/index.dart';
import '../interface/unified_player_interface.dart';

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

  UnifiedPlayer? _currentPlayer;

  /// 当前运行播放器
  PlayerEngine? _runtimeEngine;

  /// 用户默认播放器
  PlayerEngine? _defaultEngine;

  String? _currentUrl;

  List<String> _currentPlayUrls = [];

  Map<String, String> _currentHeaders = {};

  final _stateSubject = BehaviorSubject<PlayerState>.seeded(PlayerState.idle);

  final _playingSubject = BehaviorSubject<bool>.seeded(false);

  final _loadingSubject = BehaviorSubject<bool>.seeded(false);

  final _completeSubject = BehaviorSubject<bool>.seeded(false);

  final _errorSubject = PublishSubject<PlayerException>();

  final _widthSubject = BehaviorSubject<int?>.seeded(null);

  final _heightSubject = BehaviorSubject<int?>.seeded(null);

  final List<StreamSubscription> _subscriptions = [];

  bool _disposed = false;

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

      _bindPlayerStreams(_currentPlayer!);

      _stateSubject.add(PlayerState.initialized);
    } catch (e, s) {
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

  Future<void> play(String url, List<String> playUrls, Map<String, String> headers) async {
    if (_disposed) return;
    if (_runtimeEngine != _defaultEngine) {
      await switchEngine(_defaultEngine!);
    }
    final player = _currentPlayer;

    if (player == null) {
      throw PlayerException(message: 'Current player is null', type: PlayerErrorType.lifecycle);
    }

    _currentUrl = url;

    _currentPlayUrls = playUrls;

    _currentHeaders = headers;

    try {
      _stateSubject.add(PlayerState.preparing);

      await player.setDataSource(url, playUrls, headers);

      _stateSubject.add(PlayerState.ready);
    } on PlayerException catch (e) {
      await _handleError(e);
    } catch (e, s) {
      final exception = PlayerException(message: 'Play failed', type: PlayerErrorType.unknown, error: e, stackTrace: s);

      await _handleError(exception);
    }
  }

  // =========================
  // replay
  // =========================

  Future<void> replay() async {
    if (_currentUrl == null) return;

    await play(_currentUrl!, _currentPlayUrls, _currentHeaders);
  }

  // =========================
  // switch engine
  // =========================

  Future<void> switchEngine(PlayerEngine engine) async {
    if (_disposed) return;

    if (_runtimeEngine == engine && _currentPlayer != null) {
      return;
    }

    try {
      final oldPlayer = _currentPlayer;

      await _clearSubscriptions();

      await oldPlayer?.pause();

      final newPlayer = await playerPool.getPlayer(engine);

      _currentPlayer = newPlayer;

      _runtimeEngine = engine;

      _bindPlayerStreams(newPlayer);
    } catch (e, s) {
      final exception = PlayerException(
        message: 'Switch engine failed',
        type: PlayerErrorType.lifecycle,
        error: e,
        stackTrace: s,
      );

      _errorSubject.add(exception);

      throw exception;
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

    _bindPlayerStreams(player);
  }

  Future<void> togglePlayPause() async {
    if (_currentPlayer == null) return;

    try {
      if (isPlayingNow) {
        await pause();
      } else {
        await resume();
      }
    } catch (e, s) {
      final exception = PlayerException(
        message: 'Toggle play pause failed',
        type: PlayerErrorType.lifecycle,
        error: e,
        stackTrace: s,
      );

      _errorSubject.add(exception);

      rethrow;
    }
  }

  // =========================
  // pause
  // =========================

  Future<void> pause() async {
    await _currentPlayer?.pause();
  }

  // =========================
  // resume
  // =========================

  Future<void> resume() async {
    await _currentPlayer?.play();
  }

  // =========================
  // stop
  // =========================

  Future<void> stop() async {
    await _currentPlayer?.stop();
  }

  // =========================
  // UI Rendering
  // =========================

  /// Returns the reactive video widget.
  /// Uses [Obx] to ensure that when [seamlessSwitch] or [switchEngine] happens, the UI updates.
  Widget getVideoWidget(int fitIndex, {Widget? controls, required List<BoxFit> fitList}) {
    return StreamBuilder<PlayerState>(
      stream: onStateChanged,
      builder: (context, snapshot) {
        if (_currentPlayer == null || snapshot.data == PlayerState.initializing) {
          return _buildPlaceholder();
        }

        final boxFit = fitList[fitIndex];
        // final engineKey = ValueKey("${_runtimeEngine!.name}_$_currentUrl");

        return KeyedSubtree(
          child: Container(
            color: Colors.black,
            width: double.infinity,
            height: double.infinity,
            child: Stack(
              children: [
                Positioned.fill(
                  child: FittedBox(
                    fit: boxFit,
                    clipBehavior: Clip.hardEdge,
                    child: StreamBuilder<List<int?>>(
                      stream: CombineLatestStream.list([width, height]),
                      builder: (context, sizeSnapshot) {
                        final w = sizeSnapshot.data?[0]?.toDouble() ?? 1920.0;
                        final h = sizeSnapshot.data?[1]?.toDouble() ?? 1080.0;
                        return SizedBox(width: w, height: h, child: _currentPlayer!.getVideoWidget());
                      },
                    ),
                  ),
                ),
                if (controls != null) Positioned.fill(child: controls),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.black,
      child: const Center(child: CircularProgressIndicator(strokeWidth: 4, color: Colors.white70)),
    );
  }

  // =========================
  // soft stop
  // =========================
  Future<void> softStop() async {
    await _currentPlayer?.softStop();
  }

  // =========================
  // volume
  // =========================

  Future<void> setVolume(double volume) async {
    await _currentPlayer?.setVolume(volume.clamp(0.0, 1.0));
  }

  // =========================
  // retry
  // =========================

  Future<void> retry() async {
    await replay();
  }

  // =========================
  // handle error
  // =========================

  Future<void> _handleError(PlayerException error) async {
    _errorSubject.add(error);

    PlayerErrorDispatcher.instance.dispatch(error);

    _stateSubject.add(PlayerState.error);

    // ======================
    // line fallback
    // ======================

    if (error.type == PlayerErrorType.network || error.type == PlayerErrorType.source) {
      if (_currentPlayUrls.isEmpty) {
        throw error;
      }

      final nextLine = lineManager.next(_currentPlayUrls);

      await play(nextLine, _currentPlayUrls, _currentHeaders);

      return;
    }

    // ======================
    // engine fallback
    // ======================

    if (fallbackManager.shouldFallback(error)) {
      final nextEngine = await fallbackManager.fallback(_runtimeEngine!, error);

      await switchEngine(nextEngine);

      await replay();

      return;
    }

    throw error;
  }

  // =========================
  // bind streams
  // =========================

  void _bindPlayerStreams(UnifiedPlayer player) {
    _subscriptions.add(
      player.onPlaying.listen((event) {
        _playingSubject.add(event);

        if (event) {
          _stateSubject.add(PlayerState.playing);
        } else {
          _stateSubject.add(PlayerState.paused);
        }
      }),
    );

    _subscriptions.add(
      player.onLoading.listen((event) {
        _loadingSubject.add(event);

        if (event) {
          _stateSubject.add(PlayerState.buffering);
        }
      }),
    );

    _subscriptions.add(player.onComplete.listen(_completeSubject.add));

    _subscriptions.add(player.onStateChanged.listen(_stateSubject.add));

    _subscriptions.add(
      player.onError.listen((error) {
        unawaited(_handleError(error));
      }),
    );

    _subscriptions.add(player.width.listen(_widthSubject.add));

    _subscriptions.add(player.height.listen(_heightSubject.add));
  }

  // =========================
  // clear subscriptions
  // =========================

  Future<void> _clearSubscriptions() async {
    for (final item in _subscriptions) {
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
