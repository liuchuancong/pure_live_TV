import 'dart:async';
import 'dart:developer';
import 'fijk_adapter.dart';
import 'media_kit_adapter.dart';
import 'unified_player_interface.dart';
import 'package:rxdart/rxdart.dart' as rx;
import 'package:pure_live/common/index.dart';
import 'package:pure_live/player/video_player_adapter.dart';
import 'package:get/get.dart' hide Rx; // Avoid conflict with RxDart

enum PlayerEngine { mediaKit, fijk, exo }

class SwitchableGlobalPlayer {
  static final SwitchableGlobalPlayer _instance = SwitchableGlobalPlayer._internal();
  factory SwitchableGlobalPlayer() => _instance;
  SwitchableGlobalPlayer._internal();

  // --- Observables ---
  final isInitialized = false.obs;
  final isVerticalVideo = false.obs;
  final isPlaying = false.obs;
  final isComplete = false.obs;
  final hasError = false.obs;
  final currentVolume = 1.0.obs;
  final isInPipMode = false.obs;

  // --- Internal State Management ---
  int _loadingToken = 0; // Prevents race conditions during fast switching
  bool _hasSetVolume = false;
  PlayerEngine _currentEngine = PlayerEngine.mediaKit;
  UnifiedPlayer? _currentPlayer;

  final _videoKey = ValueKey('player_${DateTime.now().millisecondsSinceEpoch}').obs;

  // --- Dependencies ---
  final SettingsService settings = Get.find<SettingsService>();

  // --- Subscriptions ---
  final rx.CompositeSubscription _subscriptions = rx.CompositeSubscription();

  // --- Getters ---
  UnifiedPlayer? get currentPlayer => _currentPlayer;
  PlayerEngine get currentEngine => _currentEngine;
  final _errorController = rx.BehaviorSubject<String?>.seeded(null);
  Stream<bool> get onLoading => _currentPlayer?.onLoading ?? Stream.value(false);
  Stream<bool> get onPlaying => _currentPlayer?.onPlaying ?? Stream.value(false);
  Stream<bool> get onComplete => _currentPlayer?.onComplete ?? Stream.value(false);
  Stream<String?> get onError => _errorController.stream;
  Stream<int?> get width => _currentPlayer?.width ?? Stream.value(null);
  Stream<int?> get height => _currentPlayer?.height ?? Stream.value(null);

  Future<void> init(PlayerEngine engine) async {
    if (_currentPlayer != null) return;
    _currentEngine = engine;
    _currentPlayer = _createPlayer(engine);
    await _currentPlayer!.init();
  }

  UnifiedPlayer _createPlayer(PlayerEngine engine) {
    switch (engine) {
      case PlayerEngine.mediaKit:
        return MediaKitPlayerAdapter();
      case PlayerEngine.fijk:
        return FijkPlayerAdapter();
      case PlayerEngine.exo:
        return VideoPlayerAdapter();
    }
  }

  Future<void> switchEngine(PlayerEngine newEngine) async {
    if (newEngine == _currentEngine) return;
    _loadingToken++; // Invalidate pending setDataSource calls
    await _cleanup();
    _currentEngine = newEngine;
    _currentPlayer = _createPlayer(newEngine);
    _updateVideoKey();
    await _currentPlayer!.init();
  }

  Future<void> setDataSource(String url, List<String> playUrls, Map<String, String> headers) async {
    final int currentToken = ++_loadingToken;
    log('setDataSource [$currentToken]: $url', name: 'SwitchableGlobalPlayer');

    try {
      // 1. Reset UI and stop current playback
      _subscriptions.clear();
      _resetStatus();
      await _currentPlayer?.stop();

      // Race condition check: Did a new request come in during 'stop'?
      if (currentToken != _loadingToken) return;

      // 2. Ensure player instance is ready (Shadowing to avoid null-checks)
      var player = _currentPlayer;
      if (player == null) {
        player = _createPlayer(_currentEngine);
        _currentPlayer = player;
        await player.init();
      }

      if (currentToken != _loadingToken) return;

      // 3. Load the source
      await player.setDataSource(url, playUrls, headers);

      // Final race condition check: Did the user switch channels while loading?
      if (currentToken != _loadingToken) return;

      _subscribeToPlayerEvents();
      isInitialized.value = true;
    } catch (e, st) {
      if (currentToken == _loadingToken) {
        log('setDataSource failed', error: e, stackTrace: st, name: 'SwitchableGlobalPlayer');
        hasError.value = true;
        isInitialized.value = false;
        await _cleanup();
      }
    }
  }

  void _resetStatus() {
    isInitialized.value = false;
    isPlaying.value = false;
    isComplete.value = false;
    hasError.value = false;
    isVerticalVideo.value = false;
    _hasSetVolume = false;
    _errorController.add(null);
  }

  void _updateVideoKey() {
    _videoKey.value = ValueKey('player_${DateTime.now().millisecondsSinceEpoch}');
  }

  void _subscribeToPlayerEvents() {
    _subscriptions.clear();

    // Combined stream for orientation with .distinct() to reduce rebuilds
    _subscriptions.add(
      rx.Rx.combineLatest2<int?, int?, bool>(
        width.where((w) => w != null && w > 0),
        height.where((h) => h != null && h > 0),
        (w, h) => h! > w!,
      ).distinct().listen((isVertical) {
        isVerticalVideo.value = isVertical;
      }),
    );

    _subscriptions.add(
      onPlaying.listen((playing) {
        isPlaying.value = playing;
        if (playing && !_hasSetVolume) {
          setVolume(currentVolume.value);
          _hasSetVolume = true;
        }
      }),
    );
    if (_currentPlayer != null) {
      _subscriptions.add(
        _currentPlayer!.onError.listen((error) {
          if (error != null) {
            hasError.value = true;
            _errorController.add(error); // 转发错误到外部
          } else {
            _errorController.add(null);
          }
        }),
      );
    }

    _subscriptions.add(onComplete.listen((complete) => isComplete.value = complete));
  }

  Future<void> setVolume(double volume) async {
    final clamped = volume.clamp(0.0, 1.0);
    currentVolume.value = clamped;
    await _currentPlayer?.setVolume(clamped);
  }

  Future<void> play() => _currentPlayer?.play() ?? Future.value();
  Future<void> pause() => _currentPlayer?.pause() ?? Future.value();

  Future<void> togglePlayPause() async {
    if (_currentPlayer?.isPlayingNow == true) {
      await pause();
    } else {
      await play();
    }
  }

  void changeVideoFit(int index) {
    settings.videoFitIndex.value = index;
  }

  Widget getVideoWidget(Widget? child) {
    return Obx(() {
      final engineKey = ValueKey("${_currentEngine.name}_${_videoKey.value}");

      if (!isInitialized.value) {
        return _buildPlaceholder();
      }
      return KeyedSubtree(
        key: engineKey,
        child: Material(
          key: ValueKey(settings.videoFitIndex.value),
          child: Scaffold(
            backgroundColor: Colors.black,
            body: Stack(
              fit: StackFit.passthrough,
              children: [
                Container(color: Colors.black),
                _currentPlayer?.getVideoWidget(settings.videoFitIndex.value, child) ?? const SizedBox(),
                child ?? const SizedBox(),
              ],
            ),
            resizeToAvoidBottomInset: true,
          ),
        ),
      );
    });
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.black,
      child: const Center(child: CircularProgressIndicator(strokeWidth: 4, color: Colors.white70)),
    );
  }

  Future<void> _cleanup() async {
    _subscriptions.clear();
    final player = _currentPlayer;
    _currentPlayer = null;

    try {
      await player?.stop();
      player?.dispose();
    } catch (_) {}

    _resetStatus();
  }

  Future<void> stop() async => await _cleanup();

  void dispose() => _cleanup();
}
