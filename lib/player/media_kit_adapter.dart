import 'dart:io';
import 'dart:developer';
import 'package:get/get.dart';
import 'package:rxdart/rxdart.dart';
import 'unified_player_interface.dart';
import 'package:media_kit/media_kit.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/player/player_consts.dart';
import 'package:media_kit_video/media_kit_video.dart';

class MediaKitPlayerAdapter implements UnifiedPlayer {
  late Player _player;
  late VideoController _controller;
  final SettingsService settings = Get.find<SettingsService>();

  // 👇 使用 BehaviorSubject 缓存状态（与 FijkPlayerAdapter 一致）
  final _playingSubject = BehaviorSubject<bool>.seeded(false);
  final _errorSubject = BehaviorSubject<String?>.seeded(null);
  final _loadingSubject = BehaviorSubject<bool>.seeded(false);
  final _widthSubject = BehaviorSubject<int?>.seeded(null);
  final _heightSubject = BehaviorSubject<int?>.seeded(null);
  final _completeSubject = BehaviorSubject<bool>.seeded(false);

  bool _isPlaying = false;
  bool isInitialized = false;

  @override
  Future<void> init() async {
    _isPlaying = false;
    isInitialized = false;

    _player = Player();

    var pp = _player.platform as NativePlayer;
    if (Platform.isAndroid) {
      await pp.setProperty('force-seekable', 'yes');
    }

    _controller = settings.playerCompatMode.value
        ? VideoController(
            _player,
            configuration: VideoControllerConfiguration(vo: 'mediacodec_embed', hwdec: 'mediacodec'),
          )
        : VideoController(
            _player,
            configuration: VideoControllerConfiguration(
              enableHardwareAcceleration: settings.enableCodec.value,
              androidAttachSurfaceAfterVideoParameters: false,
            ),
          );

    // 👇 监听 media_kit 原生流，并同步到 BehaviorSubject
    _player.stream.playing.listen((playing) {
      _isPlaying = playing;
      if (_playingSubject.value != playing) {
        _playingSubject.add(playing);
      }

      if (!isInitialized) {
        isInitialized = true;
        _player.setVolume(100);
      }
    });

    _player.stream.error.listen((error) {
      final msg = 'MediaKitPlayer error: $error';
      SmartDialog.showToast(msg);
      _errorSubject.add(msg);
    });

    _player.stream.completed.listen((isComplete) {
      if (isComplete) {
        log('MediakitPlayer: The Video is completed');
        _completeSubject.add(true);
      }
    });

    _player.stream.buffering.listen((buffering) {
      if (_loadingSubject.value != buffering) {
        _loadingSubject.add(buffering);
      }
    });

    _player.stream.width.listen((w) {
      if (_widthSubject.value != w) {
        _widthSubject.add(w);
      }
    });

    _player.stream.height.listen((h) {
      if (_heightSubject.value != h) {
        _heightSubject.add(h);
      }
    });
    _player.stream.error.listen((error) {
      SmartDialog.showToast("MediaKit error: $error", displayTime: Duration(seconds: 5));
    });
  }

  @override
  Future<void> setDataSource(String url, Map<String, String> headers) async {
    await _player.pause();
    await _player.open(Media(url, httpHeaders: headers));
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Widget getVideoWidget(int index, Widget? controls) {
    return Video(
      key: UniqueKey(),
      controller: _controller,
      pauseUponEnteringBackgroundMode: !settings.enableBackgroundPlay.value,
      resumeUponEnteringForegroundMode: !settings.enableBackgroundPlay.value,
      fit: PlayerConsts.videofitList[index],
      controls: NoVideoControls,
    );
  }

  @override
  void dispose() {
    // 👇 先关闭所有 subject
    _playingSubject.close();
    _errorSubject.close();
    _loadingSubject.close();
    _widthSubject.close();
    _heightSubject.close();
    _completeSubject.close();

    try {
      _player.dispose();
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  // 👇 统一返回缓存流
  @override
  Stream<bool> get onPlaying => _playingSubject.stream;

  @override
  Stream<String?> get onError => _errorSubject.stream;

  @override
  Stream<bool> get onLoading => _loadingSubject.stream;

  @override
  bool get isPlayingNow => _isPlaying;

  @override
  Stream<int?> get width => _widthSubject.stream;

  @override
  Stream<int?> get height => _heightSubject.stream;

  @override
  Stream<bool> get onComplete => _completeSubject.stream;

  @override
  Future<void> setVolume(double value) async {
    await _player.setVolume(value * 100);
  }

  @override
  void stop() {
    _player.stop();
  }

  @override
  void release() {
    _player.dispose();
  }
}
