import 'dart:async';
import 'dart:developer';
import 'fijk_adapter.dart';
import 'package:get/get.dart';
import 'media_kit_adapter.dart';
import 'package:rxdart/rxdart.dart';
import 'unified_player_interface.dart';
import 'package:pure_live/common/index.dart';

enum PlayerEngine { mediaKit, fijk }

class SwitchableGlobalPlayer {
  static final SwitchableGlobalPlayer _instance = SwitchableGlobalPlayer._internal();
  factory SwitchableGlobalPlayer() => _instance;
  SwitchableGlobalPlayer._internal();

  // 状态管理
  final isInitialized = false.obs;
  final isVerticalVideo = false.obs;
  final isPlaying = false.obs;
  final isComplete = false.obs;
  final hasError = false.obs;
  final currentVolume = 1.0.obs;
  final isInPipMode = false.obs;
  bool playerHasInit = false;
  bool hasSetVolume = false;

  // 依赖
  final SettingsService settings = Get.find<SettingsService>();

  // 播放器相关
  UnifiedPlayer? _currentPlayer;
  PlayerEngine _currentEngine = PlayerEngine.mediaKit;
  ValueKey<String> videoKey = const ValueKey('video_0');

  // 订阅
  StreamSubscription<bool>? _orientationSubscription;
  StreamSubscription<bool>? _isPlayingSubscription;
  StreamSubscription<String?>? _errorSubscription;
  StreamSubscription<double?>? _volumeSubscription;
  StreamSubscription<bool>? _isCompleteSubscription;

  // Getter（安全访问）
  UnifiedPlayer? get currentPlayer => _currentPlayer;

  Stream<bool> get onLoading => _currentPlayer?.onLoading ?? Stream.value(false);
  Stream<bool> get onPlaying => _currentPlayer?.onPlaying ?? Stream.value(false);
  Stream<bool> get onComplete => _currentPlayer?.onComplete ?? Stream.value(false);
  Stream<String?> get onError => _currentPlayer?.onError ?? Stream.value(null);
  Stream<int?> get width => _currentPlayer?.width ?? Stream.value(null);
  Stream<int?> get height => _currentPlayer?.height ?? Stream.value(null);

  Future<void> init(PlayerEngine engine) async {
    if (_currentPlayer != null) return;
    _currentPlayer = _createPlayer(engine);
    _currentEngine = engine;
    _currentPlayer!.init();
    playerHasInit = true;
    hasSetVolume = false;
  }

  UnifiedPlayer _createPlayer(PlayerEngine engine) {
    switch (engine) {
      case PlayerEngine.mediaKit:
        return MediaKitPlayerAdapter();
      case PlayerEngine.fijk:
        return FijkPlayerAdapter();
    }
  }

  Future<void> switchEngine(PlayerEngine newEngine) async {
    if (newEngine == _currentEngine) return;
    _cleanup(); // 清理旧播放器和订阅
    _currentPlayer = _createPlayer(newEngine);
    _currentEngine = newEngine;
    videoKey = ValueKey('video_${DateTime.now().millisecondsSinceEpoch}');
    _currentPlayer!.init();
    playerHasInit = true;
  }

  Future<void> setDataSource(String url, List<String> playUrls, Map<String, String> headers) async {
    if (_currentPlayer != null || playerHasInit) {
      _currentPlayer!.stop();
      _cleanup();
    }
    await Future.delayed(const Duration(milliseconds: 100));
    _currentPlayer = _createPlayer(_currentEngine);
    playerHasInit = false;

    _cleanupSubscriptions();
    videoKey = ValueKey('video_${DateTime.now().millisecondsSinceEpoch}');

    unawaited(
      Future.microtask(() {
        isInitialized.value = false;
        isPlaying.value = true;
        hasError.value = false;
        hasSetVolume = false;
        isVerticalVideo.value = false;
      }),
    );

    try {
      await _currentPlayer!.init();
      await Future.delayed(const Duration(milliseconds: 100));
      await _currentPlayer!.setDataSource(url, playUrls, headers);

      unawaited(
        Future.microtask(() {
          isInitialized.value = true;
          _subscribeToPlayerEvents();
          playerHasInit = true;
          hasSetVolume = false;
        }),
      );
    } catch (e, st) {
      log('setDataSource failed: $e', error: e, stackTrace: st, name: 'SwitchableGlobalPlayer');
      hasError.value = true;
      hasSetVolume = false;
      isInitialized.value = false;
      _cleanup(); // 确保异常时也清理
    }
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

  Future<void> stop() async {
    _currentPlayer?.stop();
    dispose();
  }

  void changeVideoFit(int index) {
    settings.videoFitIndex.value = index;
    videoKey = ValueKey('video_${DateTime.now().millisecondsSinceEpoch}');
  }

  Widget getVideoWidget(Widget? child) {
    return Obx(() {
      if (!isInitialized.value) {
        return Material(
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              Container(color: Colors.black),
              Container(
                color: Colors.black,
                child: const Center(
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(strokeWidth: 4, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      }
      return KeyedSubtree(
        key: videoKey,
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

  void _subscribeToPlayerEvents() {
    _cleanupSubscriptions();

    final orientationStream = CombineLatestStream.combine2<int?, int?, bool>(
      width.where((w) => w != null && w > 0),
      height.where((h) => h != null && h > 0),
      (w, h) => h! >= w!,
    );

    _orientationSubscription = orientationStream.listen((isVertical) {
      isVerticalVideo.value = isVertical;
    });

    _isPlayingSubscription = onPlaying.listen((playing) {
      isPlaying.value = playing;
      if (!hasSetVolume && playing) {
        setVolume(1.0);
        hasSetVolume = true;
      }
    });
    _errorSubscription = onError.listen((error) {
      hasError.value = error != null;
      log('onError: $error', error: error, name: 'SwitchableGlobalPlayer');
    });

    _isCompleteSubscription = onComplete.listen((complete) {
      log('complete: $complete', name: 'SwitchableGlobalPlayer');
      isComplete.value = complete;
    });
  }

  void _cleanupSubscriptions() {
    _orientationSubscription?.cancel();
    _isPlayingSubscription?.cancel();
    _errorSubscription?.cancel();
    _volumeSubscription?.cancel();
    _isCompleteSubscription?.cancel();
  }

  void _cleanup() {
    _cleanupSubscriptions();
    _currentPlayer?.stop();
    _currentPlayer?.dispose();
    _currentPlayer = null;
    isInitialized.value = false;
    playerHasInit = false;
  }

  void dispose() {
    _cleanup();
  }

  PlayerEngine get currentEngine => _currentEngine;
}
