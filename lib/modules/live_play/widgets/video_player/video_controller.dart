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
import 'package:pure_live/modules/live_play/load_type.dart';
import 'package:pure_live/modules/live_play/live_play_controller.dart';
import 'package:media_kit_video/media_kit_video.dart' as media_kit_video;
import 'package:pure_live/modules/live_play/widgets/video_player/danmaku_text.dart';

class VideoController with ChangeNotifier {
  final GlobalKey playerKey;

  final LiveRoom room;

  final String datasourceType;

  final String qualiteName;

  final int currentLineIndex;

  final int currentQuality;

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

  int videoPlayerIndex = 0;

  bool enableCodec = true;

  AppFocusNode focusNode = AppFocusNode();

  // Controller ui status
  ///State of navigator on widget created
  late NavigatorState navigatorState;

  ///Flag which determines if widget has initialized
  final initialized = false.obs;

  Timer? showControllerTimer;
  // Controller ui status
  final showController = false.obs;
  //  Settting ui status
  final showSettting = false.obs;

  final danmuKey = GlobalKey();

  final playPauseFoucsNode = AppFocusNode();

  final refreshFoucsNode = AppFocusNode();

  final danmakuFoucsNode = AppFocusNode();

  final favoriteFoucsNode = AppFocusNode();

  final settingsFoucsNode = AppFocusNode();

  final qualiteNameNode = AppFocusNode();

  final currentLineNode = AppFocusNode();

  List<AppFocusNode> operateFoucsNodes = [];

  List<AppFocusNode> danmukuSettingFoucsNodes = [];
  // 底部控制按钮索引
  int currentNodeIndex = 0;
  // 弹幕控制按钮索引
  int danmukuNodeIndex = 0;

  Timer? _debounceTimer;

  Timer? _throttleTimer;

  bool _throttleFlag = true;

  // 五秒关闭控制器
  void enableController() {
    showControllerTimer?.cancel();
    showController.value = true;
    showControllerTimer = Timer(const Duration(seconds: 5), () {
      showController.value = false;
      cancleFocus();
      focusNode.requestFocus();
    });
    playPauseFoucsNode.requestFocus();
    currentNodeIndex = 0;
  }

  void disableController() {
    showControllerTimer?.cancel();
    showController.value = false;
    cancleFocus();
    cancledanmakuFocus();
    focusNode.requestFocus();
    currentNodeIndex = 0;
    danmukuNodeIndex = 0;
  }

  void cancleFocus() {
    playPauseFoucsNode.unfocus();
    refreshFoucsNode.unfocus();
    danmakuFoucsNode.unfocus();
    favoriteFoucsNode.unfocus();
    settingsFoucsNode.unfocus();
    qualiteNameNode.unfocus();
    currentLineNode.unfocus();
    currentNodeIndex = 0;
  }

  void cancledanmakuFocus() {
    danmakuAbleFoucsNode.unfocus();
    danmakuMergeFoucsNode.unfocus();
    danmakuSizeFoucsNode.unfocus();
    danmakuSpeedFoucsNode.unfocus();
    danmakuAreaFoucsNode.unfocus();
    danmakuStorkeFoucsNode.unfocus();
    danmukuNodeIndex = 0;
  }

  final danmakuAbleFoucsNode = AppFocusNode();
  final danmakuMergeFoucsNode = AppFocusNode();
  final danmakuSizeFoucsNode = AppFocusNode();
  final danmakuSpeedFoucsNode = AppFocusNode();
  final danmakuAreaFoucsNode = AppFocusNode();
  final danmakuOpacityFoucsNode = AppFocusNode();
  final danmakuStorkeFoucsNode = AppFocusNode();

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
    required this.qualiteName,
    required this.currentLineIndex,
    required this.currentQuality,
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
    videoPlayerIndex = settings.videoPlayerIndex.value;
    initPagesConfig();
  }

  initPagesConfig() {
    initVideoController();
    initDanmaku();
    initOperateFoucsNodes();
    initDanmukuSettingFoucsNodes();
    showSettting.listen((p0) {
      if (showSettting.value) {
        showControllerTimer?.cancel();
        showController.value = false;
        danmukuNodeIndex = 0;
        currentNodeIndex = 0;
        cancleFocus();
        danmakuAbleFoucsNode.requestFocus();
      } else {
        disableController();
      }
    });
  }

  void initOperateFoucsNodes() {
    operateFoucsNodes = [];
    operateFoucsNodes.add(playPauseFoucsNode);
    operateFoucsNodes.add(favoriteFoucsNode);
    operateFoucsNodes.add(refreshFoucsNode);
    operateFoucsNodes.add(danmakuFoucsNode);
    operateFoucsNodes.add(settingsFoucsNode);
    operateFoucsNodes.add(qualiteNameNode);
    operateFoucsNodes.add(currentLineNode);
    currentNodeIndex = 0;
  }

  void initDanmukuSettingFoucsNodes() {
    danmukuSettingFoucsNodes = [];
    danmukuSettingFoucsNodes.add(danmakuAbleFoucsNode);
    danmukuSettingFoucsNodes.add(danmakuMergeFoucsNode);
    danmukuSettingFoucsNodes.add(danmakuSizeFoucsNode);
    danmukuSettingFoucsNodes.add(danmakuSpeedFoucsNode);
    danmukuSettingFoucsNodes.add(danmakuAreaFoucsNode);
    danmukuSettingFoucsNodes.add(danmakuOpacityFoucsNode);
    danmukuSettingFoucsNodes.add(danmakuStorkeFoucsNode);
    danmukuNodeIndex = 0;
  }

  void initVideoController() async {
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
    debounce(hasError, (callback) {
      if (hasError.value) {
        changeLine();
      }
    }, time: const Duration(seconds: 1));
  }

  void onKeyEvent(KeyEvent key) {
    throttle(() {
      handleKeyEvent(key);
    }, 200);
  }

  handleKeyEvent(KeyEvent key) {
    // 点击Menu打开/关闭设置
    if (key.logicalKey == LogicalKeyboardKey.keyM || key.logicalKey == LogicalKeyboardKey.contextMenu) {
      showSettting.value = true;
      return;
    }
    // 如果没有显示控制面板
    if (!showController.value) {
      // 如果没有显示弹幕控制面板
      if (!showSettting.value) {
        // 点击OK、Enter、Select键时显示/隐藏控制器
        if (key.logicalKey == LogicalKeyboardKey.select ||
            key.logicalKey == LogicalKeyboardKey.enter ||
            key.logicalKey == LogicalKeyboardKey.space) {
          // 点击enter键显示控制器
          enableController();
          return;
        }
        // 点击上下键切换播放线路
        if (key.logicalKey == LogicalKeyboardKey.arrowUp) {
          lastPlayChannel();
        } else if (key.logicalKey == LogicalKeyboardKey.arrowDown) {
          nextPlayChannel();
        }
        // 点击左右键切换播放线路
        if (key.logicalKey == LogicalKeyboardKey.arrowLeft) {
          lastPlayChannel();
        } else if (key.logicalKey == LogicalKeyboardKey.arrowRight) {
          nextPlayChannel();
        }
        return;
      } else {
        //没有控制面板以及显示了设置面板

        if (key.logicalKey == LogicalKeyboardKey.arrowDown) {
          danmukuNodeIndex++;
          if (danmukuNodeIndex == danmukuSettingFoucsNodes.length) {
            danmukuNodeIndex = 0;
          }
          danmukuSettingFoucsNodes[danmukuNodeIndex].requestFocus();

          return;
        } else if (key.logicalKey == LogicalKeyboardKey.arrowUp) {
          if (danmukuNodeIndex == -1) {
            danmukuNodeIndex = danmukuSettingFoucsNodes.length - 1;
          }
          danmukuSettingFoucsNodes[danmukuNodeIndex].requestFocus();
          danmukuNodeIndex--;
          return;
        }
      }
    } else {
      // 显示了控制面板 点击时延长控制显示
      showControllerTimer?.cancel();
      showController.value = true;
      showControllerTimer = Timer(const Duration(seconds: 5), () {
        showController.value = false;
        cancleFocus();
        focusNode.requestFocus();
      });

      // 点击上下键切换播放线路
      // 默认是0
      if (key.logicalKey == LogicalKeyboardKey.arrowDown) {
        currentNodeIndex++;
        if (currentNodeIndex == operateFoucsNodes.length) {
          currentNodeIndex = 0;
        }
        operateFoucsNodes[currentNodeIndex].requestFocus();
        return;
      } else if (key.logicalKey == LogicalKeyboardKey.arrowUp) {
        currentNodeIndex--;
        if (currentNodeIndex == -1) {
          currentNodeIndex = operateFoucsNodes.length - 1;
        }
        operateFoucsNodes[currentNodeIndex].requestFocus();
        return;
      } else if (key.logicalKey == LogicalKeyboardKey.arrowRight) {
        currentNodeIndex++;
        if (currentNodeIndex == operateFoucsNodes.length) {
          currentNodeIndex = 0;
        }
        operateFoucsNodes[currentNodeIndex].requestFocus();
        return;
      } else if (key.logicalKey == LogicalKeyboardKey.arrowLeft) {
        currentNodeIndex--;
        if (currentNodeIndex == -1) {
          currentNodeIndex = operateFoucsNodes.length - 1;
        }
        operateFoucsNodes[currentNodeIndex].requestFocus();
        return;
      }
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

  void throttle(Function func, [int delay = 500]) {
    if (_throttleFlag) {
      func.call();
      _throttleFlag = false;
      return;
    }
    if (_throttleTimer != null) {
      return;
    }
    _throttleTimer = Timer(Duration(milliseconds: delay), () {
      func.call();
      _throttleTimer = null;
    });
  }

  void debounceListen(Function? func, [int delay = 1000]) {
    if (_debounceTimer != null) {
      _debounceTimer?.cancel();
    }
    _debounceTimer = Timer(Duration(milliseconds: delay), () {
      try {
        func?.call();
      } catch (e) {
        log('debounce error: $e');
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
      settings.hideDanmaku.value = data;
    });
    danmakuArea.value = PrefUtil.getDouble('danmakuArea') ?? 1.0;
    danmakuArea.listen((data) {
      PrefUtil.setDouble('danmakuArea', data);
      settings.danmakuArea.value = data;
    });
    danmakuSpeed.value = PrefUtil.getDouble('danmakuSpeed') ?? 8;
    danmakuSpeed.listen((data) {
      PrefUtil.setDouble('danmakuSpeed', data);
      settings.danmakuSpeed.value = data;
    });
    danmakuFontSize.value = PrefUtil.getDouble('danmakuFontSize') ?? 16;
    danmakuFontSize.listen((data) {
      PrefUtil.setDouble('danmakuFontSize', data);
      settings.danmakuFontSize.value = data;
    });
    danmakuFontBorder.value = PrefUtil.getDouble('danmakuFontBorder') ?? 0.5;
    danmakuFontBorder.listen((data) {
      PrefUtil.setDouble('danmakuFontBorder', data);
      settings.danmakuFontBorder.value = data;
    });
    danmakuOpacity.value = PrefUtil.getDouble('danmakuOpacity') ?? 1.0;
    danmakuOpacity.listen((data) {
      PrefUtil.setDouble('danmakuOpacity', data);
      settings.danmakuOpacity.value = data;
    });

    mergeDanmuRating.value = PrefUtil.getDouble('mergeDanmuRating') ?? 1.0;
    mergeDanmuRating.listen((data) {
      PrefUtil.setDouble('mergeDanmuRating', data);
      settings.mergeDanmuRating.value = data;
    });
  }

  void sendDanmaku(LiveMessage msg) {
    if (hideDanmaku.value || !livePlayController.success.value) return;
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
    destory();
    super.dispose();
  }

  destory() {
    cancleFocus();
    cancledanmakuFocus();
    if (videoPlayerIndex == 0) {
      mobileController?.removeEventsListener(mobileStateListener);
      mobileController?.dispose();
      mobileController = null;
    } else if (videoPlayerIndex == 1) {
      fijkPlayer.removeListener(_playerValueChanged);
      fijkPlayer.release();
    } else if (videoPlayerIndex == 2) {
      player.dispose();
    }
    danmakuController.dispose();
    isTryToHls = false;
    isPlaying.value = false;
    hasError.value = false;
    livePlayController.success.value = false;
  }

  void refresh() {
    destory();
    livePlayController.onInitPlayerState(reloadDataType: ReloadDataType.refreash);
  }

  void changeLine() {
    destory();
    livePlayController.onInitPlayerState(
        reloadDataType: ReloadDataType.changeLine, line: currentLineIndex, currentQuality: currentQuality);
  }

  void changeQuality() {
    destory();
    livePlayController.onInitPlayerState(
        reloadDataType: ReloadDataType.changeQuality, line: currentLineIndex, currentQuality: currentQuality);
  }

  void setDataSource(String url) async {
    datasource = url;
    // fix datasource empty error
    if (datasource.isEmpty) {
      hasError.value = true;
      return;
    } else {
      hasError.value = false;
    }
    if (videoPlayerIndex == 0) {
      mobileController?.setupDataSource(BetterPlayerDataSource(
        BetterPlayerDataSourceType.network,
        url,
        liveStream: true,
        headers: headers,
      ));
      mobileController?.pause();
    } else if (videoPlayerIndex == 1) {
      setFijkPlayerDataSource();
    } else if (videoPlayerIndex == 2) {
      player.pause();
      player.open(Media(datasource, httpHeaders: headers));
    }
  }

  setFijkPlayerDataSource() async {
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
      headersArr.add('$key: $value');
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
      print(fit.toString());
    } else if (videoPlayerIndex == 2) {
      key.currentState?.update(fit: fit);
    }
  }

  void togglePlayPause() {
    if (videoPlayerIndex == 0) {
      isPlaying.value ? mobileController!.pause() : mobileController!.play();
    } else if (videoPlayerIndex == 1) {
      isPlaying.value ? fijkPlayer.pause() : fijkPlayer.start();
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

  void lastPlayChannel() {}

  void nextPlayChannel() {}
}
