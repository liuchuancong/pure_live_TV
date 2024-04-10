import 'dart:io';
import 'dart:async';
import 'dart:developer';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:fijkplayer/fijkplayer.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/plugins/barrage.dart';
import 'package:better_player/better_player.dart';
import 'package:pure_live/app/app_focus_node.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:pure_live/modules/live_play/live_play_controller.dart';
import 'package:media_kit_video/media_kit_video.dart' as media_kit_video;
import 'package:flutter_volume_controller/flutter_volume_controller.dart';
import 'package:pure_live/modules/live_play/widgets/video_player/danmaku_text.dart';

class VideoController with ChangeNotifier {
  final GlobalKey playerKey;

  final LiveRoom room;

  final String datasourceType;

  String datasource;

  final bool autoPlay;

  final Map<String, String> headers;

  final videoFit = BoxFit.contain.obs;

  final mediaPlayerControllerInitialized = false.obs;

  ScreenBrightness brightnessController = ScreenBrightness();

  BetterPlayerController? mobileController;

  bool isTryToHls = false;

  double initBrightness = 0.0;

  final hasError = false.obs;

  final isPlaying = false.obs;

  final isBuffering = false.obs;

  // Video player status
  // A [GlobalKey<VideoState>] is required to access the programmatic fullscreen interface.
  late final GlobalKey<media_kit_video.VideoState> key = GlobalKey<media_kit_video.VideoState>();

  // Create a [Player] to control playback.
  late Player player;
  // CeoController] to handle video output from [Player].
  late media_kit_video.VideoController mediaPlayerController;

  late FijkPlayer fijkPlayer;

  LivePlayController livePlayController = Get.find<LivePlayController>();

  final SettingsService settings = Get.find<SettingsService>();

  int videoPlayerIndex = 1;

  bool enableCodec = true;

  AppFocusNode focusNode = AppFocusNode();

  // Controller ui status
  ///State of navigator on widget created
  late NavigatorState navigatorState;

  ///Flag which determines if widget has initialized
  final initialized = false.obs;

  Timer? showControllerTimer;
  // Controller ui status
  final showController = true.obs;
  //  Settting ui status
  final showSettting = false.obs;

  final danmuKey = GlobalKey();

  Timer? _debounceTimer;
  // 五秒关闭控制器
  void enableController() {
    showControllerTimer?.cancel();
    showControllerTimer = Timer(const Duration(seconds: 5), () {
      showController.value = false;
    });
    showController.value = true;
  }

  // Danmaku player control
  BarrageWallController danmakuController = BarrageWallController();
  final hideDanmaku = false.obs;
  final danmakuArea = 1.0.obs;
  final danmakuSpeed = 8.0.obs;
  final danmakuFontSize = 16.0.obs;
  final danmakuFontBorder = 0.5.obs;
  final danmakuOpacity = 1.0.obs;
  final mergeDanmuRating = 0.0.obs;

  VideoController({
    required this.playerKey,
    required this.room,
    required this.datasourceType,
    required this.datasource,
    required this.headers,
    this.autoPlay = true,
    BoxFit fitMode = BoxFit.contain,
  }) {
    videoFit.value = settings.videofitArrary[settings.videoFitIndex.value];
    hideDanmaku.value = settings.hideDanmaku.value;
    danmakuArea.value = settings.danmakuArea.value;
    danmakuSpeed.value = settings.danmakuSpeed.value;
    danmakuFontSize.value = settings.danmakuFontSize.value;
    danmakuFontBorder.value = settings.danmakuFontBorder.value;
    danmakuOpacity.value = settings.danmakuOpacity.value;
    mergeDanmuRating.value = settings.mergeDanmuRating.value;
    initPagesConfig();
  }

  initPagesConfig() {
    initVideoController();
    initDanmaku();
  }

  void initVideoController() async {
    FlutterVolumeController.updateShowSystemUI(false);
    videoPlayerIndex = settings.videoPlayerIndex.value;
    enableCodec = settings.enableCodec.value;
    if (Platform.isWindows || Platform.isLinux) {
      player = Player();
      if (player.platform is NativePlayer) {
        await (player.platform as dynamic).setProperty('cache', 'no');
      }
      mediaPlayerController = media_kit_video.VideoController(player);
      setDataSource(datasource);
      mediaPlayerController.player.stream.playing.listen((bool playing) {
        if (playing) {
          isPlaying.value = true;
        } else {
          isPlaying.value = false;
        }
      });
      mediaPlayerController.player.stream.error.listen((event) {
        if (event.toString().contains('Failed to open')) {
          hasError.value = true;
          isPlaying.value = false;
          SmartDialog.showToast("无法播放视频");
        }
      });
      mediaPlayerControllerInitialized.value = true;
    } else if (Platform.isAndroid || Platform.isIOS) {
      if (videoPlayerIndex == 0) {
        mobileController = BetterPlayerController(
          BetterPlayerConfiguration(
            autoPlay: true,
            fit: videoFit.value,
            allowedScreenSleep: false,
            autoDetectFullscreenDeviceOrientation: true,
            autoDetectFullscreenAspectRatio: true,
            errorBuilder: (context, errorMessage) => Container(),
          ),
        );
        mobileController?.setControlsEnabled(false);
        setDataSource(datasource);
        mobileController?.addEventsListener(mobileStateListener);
      } else if (videoPlayerIndex == 1) {
        setDataSource(datasource);
      } else if (videoPlayerIndex == 2) {
        player = Player();
        mediaPlayerController = media_kit_video.VideoController(player,
            configuration: media_kit_video.VideoControllerConfiguration(
                androidAttachSurfaceAfterVideoParameters: false, enableHardwareAcceleration: enableCodec));
        setDataSource(datasource);
        mediaPlayerController.player.stream.playing.listen((bool playing) {
          if (playing) {
            isPlaying.value = true;
          } else {
            isPlaying.value = false;
          }
        });
        mediaPlayerController.player.stream.error.listen((event) {
          if (event.toString().contains('Failed to open')) {
            hasError.value = true;
            isPlaying.value = false;
          }
        });
        mediaPlayerControllerInitialized.value = true;
      }
    } else {
      throw UnimplementedError('Unsupported Platform');
    }
    debounce(hasError, (callback) {
      if (hasError.value) {
        // livePlayController.changePlayLine();
      }
    }, time: const Duration(seconds: 1));
  }

  void onKeyEvent(KeyEvent key) {
    if (key is KeyUpEvent) {
      return;
    }
    // 点击OK、Enter、Select键时显示/隐藏控制器
    if (key.logicalKey == LogicalKeyboardKey.select ||
        key.logicalKey == LogicalKeyboardKey.enter ||
        key.logicalKey == LogicalKeyboardKey.space) {
      if (!showController.value) {
        enableController();
        showController.value = true;
      } else {
        showControllerTimer?.cancel();
        showController.toggle();
      }
      return;
    }
  }

  void _playerValueChanged() {
    FijkValue value = fijkPlayer.value;
    bool playing = (value.state == FijkState.started);
    hasError.value = (value.state == FijkState.error);
    isPlaying.value = playing;
  }

  tryToHlsPlay() {
    isTryToHls = true;
    mobileController?.pause();
    mobileController?.setResolution(datasource, videoFormat: BetterPlayerVideoFormat.hls);
    mobileController?.play();
  }

  void debounceListen(Function? func, [int delay = 1000]) {
    if (_debounceTimer != null) {
      _debounceTimer?.cancel();
    }
    _debounceTimer = Timer(Duration(milliseconds: delay), () {
      try {
        func?.call();
      } catch (e) {
        log('${mobileController!.videoPlayerController!.value.errorDescription}');
      }

      _debounceTimer = null;
    });
  }

  dynamic mobileStateListener(BetterPlayerEvent state) {
    if (mobileController?.videoPlayerController != null) {
      if (state.betterPlayerEventType == BetterPlayerEventType.exception) {
        debounceListen(() {
          if (mobileController!.videoPlayerController!.value.errorDescription != null) {
            if (mobileController!.videoPlayerController!.value.errorDescription!.contains('Source error') &&
                !isTryToHls) {
              tryToHlsPlay();
            } else {
              hasError.value = mobileController?.videoPlayerController?.value.hasError ?? true;
            }
          }
        }, 1000);
      }
      isPlaying.value = mobileController?.isPlaying() ?? false;
      isBuffering.value = mobileController?.isBuffering() ?? false;
    }
  }

  void initDanmaku() {
    hideDanmaku.value = PrefUtil.getBool('hideDanmaku') ?? false;
    hideDanmaku.listen((data) {
      PrefUtil.setBool('hideDanmaku', data);
    });
    danmakuArea.value = PrefUtil.getDouble('danmakuArea') ?? 1.0;
    danmakuArea.listen((data) {
      PrefUtil.setDouble('danmakuArea', data);
    });
    danmakuSpeed.value = PrefUtil.getDouble('danmakuSpeed') ?? 8;
    danmakuSpeed.listen((data) {
      PrefUtil.setDouble('danmakuSpeed', data);
    });
    danmakuFontSize.value = PrefUtil.getDouble('danmakuFontSize') ?? 16;
    danmakuFontSize.listen((data) {
      PrefUtil.setDouble('danmakuFontSize', data);
    });
    danmakuFontBorder.value = PrefUtil.getDouble('danmakuFontBorder') ?? 0.5;
    danmakuFontBorder.listen((data) {
      PrefUtil.setDouble('danmakuFontBorder', data);
    });
    danmakuOpacity.value = PrefUtil.getDouble('danmakuOpacity') ?? 1.0;
    danmakuOpacity.listen((data) {
      PrefUtil.setDouble('danmakuOpacity', data);
    });
  }

  void sendDanmaku(LiveMessage msg) {
    if (hideDanmaku.value) return;

    danmakuController.send([
      Bullet(
        child: DanmakuText(
          msg.message,
          fontSize: danmakuFontSize.value,
          strokeWidth: danmakuFontBorder.value,
          color: Color.fromARGB(255, msg.color.r, msg.color.g, msg.color.b),
        ),
      ),
    ]);
  }

  @override
  void dispose() async {
    if (Platform.isAndroid || Platform.isIOS) {
      if (videoPlayerIndex == 0) {
        mobileController?.removeEventsListener(mobileStateListener);
        mobileController?.dispose();
        mobileController = null;
      } else if (videoPlayerIndex == 1) {
        fijkPlayer.removeListener(_playerValueChanged);
        fijkPlayer.release();
      } else if (videoPlayerIndex == 2) {
        if (key.currentState?.isFullscreen() ?? false) {
          key.currentState?.exitFullscreen();
        }
        mediaPlayerController.player.pause();
        player.dispose();
      }
      brightnessController.resetScreenBrightness();
    } else {
      if (key.currentState?.isFullscreen() ?? false) {
        key.currentState?.exitFullscreen();
      }
      mediaPlayerController.player.pause();
      player.dispose();
    }
    super.dispose();
  }

  void refresh() {
    if (Platform.isWindows || Platform.isLinux) {
      setDataSource(datasource);
    } else if (Platform.isAndroid || Platform.isIOS) {
      if (videoPlayerIndex == 0) {
        if (mobileController?.videoPlayerController != null) {
          mobileController?.retryDataSource();
        }
      } else if (videoPlayerIndex == 1) {
        setFijkPlayerDataSource(refresh: true);
      } else if (videoPlayerIndex == 2) {
        setDataSource(datasource);
      }
    }
  }

  void setDataSource(String url, {bool refresh = false}) async {
    datasource = url;
    // fix datasource empty error
    if (datasource.isEmpty) {
      hasError.value = true;
      return;
    } else {
      hasError.value = false;
    }
    if (Platform.isWindows || Platform.isLinux) {
      player.pause();
      player.open(Media(datasource, httpHeaders: headers));
    } else {
      if (videoPlayerIndex == 0) {
        if (refresh) {
          mobileController?.setResolution(url);
        } else {
          mobileController?.setupDataSource(BetterPlayerDataSource(
            BetterPlayerDataSourceType.network,
            url,
            liveStream: true,
            headers: headers,
          ));
          mobileController?.pause();
        }
      } else if (videoPlayerIndex == 1) {
        setFijkPlayerDataSource(refresh: refresh);
      } else if (videoPlayerIndex == 2) {
        player.pause();
        player.open(Media(datasource, httpHeaders: headers));
      }
    }
    notifyListeners();
  }

  setFijkPlayerDataSource({bool refresh = false}) async {
    fijkPlayer = FijkPlayer();
    fijkPlayer.addListener(_playerValueChanged);
    await setIjkplayer();
    await fijkPlayer.reset();
    await fijkPlayer.setDataSource(datasource, autoPlay: true);
    await fijkPlayer.prepareAsync();
  }

  Future setIjkplayer() async {
    var headersArr = [];
    headers.forEach((key, value) {
      headersArr.add('$key:$value');
    });
    fijkPlayer.setOption(FijkOption.formatCategory, "headers", headersArr.join('\r\n'));
    fijkPlayer.setOption(FijkOption.hostCategory, "request-screen-on", 1);
    fijkPlayer.setOption(FijkOption.hostCategory, "request-audio-focus", 1);
    fijkPlayer.setOption(FijkOption.playerCategory, "mediacodec-all-videos", 1);
    if (enableCodec) {
      fijkPlayer.setOption(FijkOption.codecCategory, "mediacodec", 1);
      fijkPlayer.setOption(FijkOption.codecCategory, "mediacodec-auto-rotate", 1);
      fijkPlayer.setOption(FijkOption.codecCategory, "mediacodec-handle-resolution-change", 1);
    }
  }

  void setVideoFit(BoxFit fit) {
    if (videoPlayerIndex == 0) {
      mobileController?.setOverriddenFit(videoFit.value);
      mobileController?.retryDataSource();
    } else if (videoPlayerIndex == 1) {
      //
    } else if (videoPlayerIndex == 2) {
      key.currentState?.update(fit: fit);
    }
  }

  void togglePlayPause() {
    if (videoPlayerIndex == 0) {
      isPlaying.value ? mobileController!.pause() : mobileController!.play();
    } else if (videoPlayerIndex == 1) {
      if (isPlaying.value) {
        fijkPlayer.pause();
      } else {
        fijkPlayer.start();
      }
    } else if (videoPlayerIndex == 2) {
      mediaPlayerController.player.playOrPause();
    }
  }

  Future<double> brightness() async {
    return await brightnessController.current;
  }

  void setBrightness(double value) async {
    await brightnessController.setScreenBrightness(value);
  }
}
