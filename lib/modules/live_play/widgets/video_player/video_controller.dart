import 'dart:async';
import 'dart:developer';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/plugins/barrage.dart';
import 'package:pure_live/app/app_focus_node.dart';
import 'package:pure_live/modules/live_play/load_type.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
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

  double initBrightness = 0.0;

  bool hasDestory = false;

  final hasError = false.obs;

  final isPlaying = false.obs;

  final isBuffering = false.obs;

  LivePlayController livePlayController = Get.find<LivePlayController>();

  final SettingsService settings = Get.find<SettingsService>();

  final mediaPlayerControllerInitialized = false.obs;

  int videoPlayerIndex = 0;

  bool enableCodec = true;

  AppFocusNode focusNode = AppFocusNode();

  late ScrollController scrollController;
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

  final showPlayListPanel = false.obs;

  final danmuKey = GlobalKey();

  // 底部控制按钮索引
  var currentNodeIndex = 0.obs;
  // 弹幕控制按钮索引
  var danmukuNodeIndex = 0.obs;

  int _currentTimeStamp = 0;

  var showChangeNameFlag = true.obs;

  Timer? showChangeNameTimer;

  Timer? hasErrorTimer;

  var beforePlayNodeIndex = 0.obs;

  Timer? doubleClickTimer;

  int doubleClickTimeStamp = 0;

  // Video player control
  late GsyVideoPlayerController gsyVideoPlayerController;

  late ChewieController chewieController;

  var currentBottomClickType = BottomButtonClickType.favorite.obs;

  var currentDanmukuClickType = DanmakuSettingClickType.danmakuAble.obs;

  static const danmakuAbleKey = ValueKey(DanmakuSettingClickType.danmakuAble);

  // A [GlobalKey<VideoState>] is required to access the programmatic fullscreen interface.
  late final GlobalKey<media_kit_video.VideoState> key = GlobalKey<media_kit_video.VideoState>();
  // CeoController] to handle video output from [Player].
  late media_kit_video.VideoController mediaPlayerController;

  final GlobalKey vlcPlayerKey = GlobalKey();
  // Create a [Player] to control playback.
  late Player player;
  // 是否手动暂停
  var isActivePause = true.obs;

  late VlcPlayerController vlcPlayerController;

  Timer? hasActivePause;

  // 五秒关闭控制器
  void enableController() {
    showControllerTimer?.cancel();
    showController.value = true;
    showControllerTimer = Timer(const Duration(seconds: 5), () {
      showController.value = false;
      cancleFocus();
      focusNode.requestFocus();
    });
    currentNodeIndex.value = 0;
  }

  void disableController() {
    showControllerTimer?.cancel();
    showController.value = false;
    cancleFocus();
    cancledanmakuFocus();
    focusNode.requestFocus();
    currentNodeIndex.value = 0;
    danmukuNodeIndex.value = 0;
  }

  void cancleFocus() {
    currentNodeIndex.value = 0;
  }

  void cancledanmakuFocus() {
    danmukuNodeIndex.value = 0;
  }

  // Danmaku player control
  BarrageWallController danmakuController = BarrageWallController();
  final hideDanmaku = false.obs;
  final danmakuArea = 1.0.obs;
  final danmakuSpeed = 8.0.obs;
  final danmakuFontSize = 16.0.obs;
  final danmakuFontBorder = 2.0.obs;
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
    hasDestory = false;
    videoFit.value = settings.videofitArrary[settings.videoFitIndex.value];
    hideDanmaku.value = settings.hideDanmaku.value;
    danmakuArea.value = settings.danmakuArea.value;
    danmakuSpeed.value = settings.danmakuSpeed.value;
    danmakuFontSize.value = settings.danmakuFontSize.value;
    danmakuFontBorder.value = settings.danmakuFontBorder.value;
    danmakuOpacity.value = settings.danmakuOpacity.value;
    mergeDanmuRating.value = settings.mergeDanmuRating.value;
    videoPlayerIndex = settings.videoPlayerIndex.value;
    beforePlayNodeIndex.value = settings.currentPlayListNodeIndex.value;
    scrollController = ScrollController();
    scrollController.addListener(() {
      Future.delayed(Duration.zero, () {
        if (showPlayListPanel.value) {
          scrollController.animateTo(
            (100 * (beforePlayNodeIndex.value)).toDouble(),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    });
    initPagesConfig();
  }

  initPagesConfig() {
    initVideoController();
    initDanmaku();
    initOperateFocusNodes();
    initDanmukuSettingFocusNodes();
    showChangeNameTimer = Timer(const Duration(milliseconds: 2000), () {
      showChangeNameFlag.value = false;
      showChangeNameTimer?.cancel();
    });
    showController.listen((p0) {
      if (showController.value) {
        showChangeNameFlag.value = false;
        if (isPlaying.value) {
          // 取消手动暂停

          isActivePause.value = false;
        }
      }
      if (isPlaying.value) {
        hasActivePause?.cancel();
      }
    });

    hasError.listen((p0) {
      if (hasError.value && !livePlayController.isLastLine.value) {
        hasErrorTimer?.cancel();
        hasErrorTimer = Timer(const Duration(milliseconds: 2000), () {
          SmartDialog.showToast("当前视频播放出错,正在为您切换路线");
          changeLine();
          hasErrorTimer?.cancel();
        });
      }
    });
    showSettting.listen((p0) {
      if (showSettting.value) {
        showControllerTimer?.cancel();
        showController.value = false;
        showPlayListPanel.value = false;
        danmukuNodeIndex.value = 0;
        currentNodeIndex.value = 0;
        cancleFocus();
      } else {
        disableController();
      }
    });

    showPlayListPanel.listen((p0) {
      if (showPlayListPanel.value) {
        showControllerTimer?.cancel();
        showController.value = false;
        showSettting.value = false;
        danmukuNodeIndex.value = 0;
        currentNodeIndex.value = 0;
        scrollController.animateTo(
          (100 * (beforePlayNodeIndex.value)).toDouble(),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
        cancleFocus();
      } else {
        beforePlayNodeIndex.value = settings.currentPlayListNodeIndex.value;
        disableController();
      }
    });
    beforePlayNodeIndex.listen((p0) {
      if (showPlayListPanel.value) {
        scrollController.animateTo(
          (100 * (beforePlayNodeIndex.value)).toDouble(),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
    currentNodeIndex.listen((p0) {
      currentBottomClickType.value = BottomButtonClickType.values[currentNodeIndex.value];
    });
    danmukuNodeIndex.listen((p0) {
      currentDanmukuClickType.value = DanmakuSettingClickType.values[danmukuNodeIndex.value];
    });

    isPlaying.listen((p0) {
      // 代表手动暂停了
      if (!isPlaying.value) {
        if (showController.value) {
          isActivePause.value = true;
          hasActivePause?.cancel();
        } else {
          if (isActivePause.value) {
            hasActivePause = Timer(const Duration(seconds: 20), () {
              // 暂停了
              SmartDialog.showToast("系统监测视频已停止播放,正在为您刷新视频");
              isActivePause.value = false;
              refresh();
            });
          }
        }
      } else {
        hasActivePause?.cancel();
        isActivePause.value = false;
      }
    });
  }

  void initOperateFocusNodes() {
    currentNodeIndex.value = 0;
  }

  void initDanmukuSettingFocusNodes() {
    danmukuNodeIndex.value = 0;
  }

  void initVideoController() async {
    if (videoPlayerIndex == 5) {
      vlcPlayerController = VlcPlayerController.network(
        datasource,
        hwAcc: HwAcc.auto,
        autoPlay: true,
        allowBackgroundPlayback: false,
        options: headers['User-Agent'] != null
            ? VlcPlayerOptions(
                http: VlcHttpOptions([
                VlcHttpOptions.httpReconnect(true),
                VlcHttpOptions.httpUserAgent(headers['User-Agent']!),
                VlcHttpOptions.httpReferrer(headers['Referer']!),
              ]))
            : VlcPlayerOptions(),
      );

      mediaPlayerControllerInitialized.value = true;
      vlcPlayerController.addListener(() {
        isPlaying.value = vlcPlayerController.value.isPlaying;
        hasError.value = vlcPlayerController.value.hasError;
      });
    } else if (videoPlayerIndex == 4) {
      player = Player();
      mediaPlayerController = enableCodec
          ? media_kit_video.VideoController(player,
              configuration: media_kit_video.VideoControllerConfiguration(
                enableHardwareAcceleration: enableCodec,
                androidAttachSurfaceAfterVideoParameters: false,
                vo: 'mediacodec_embed',
                hwdec: 'mediacodec',
              ))
          : media_kit_video.VideoController(player,
              configuration: const media_kit_video.VideoControllerConfiguration(
                enableHardwareAcceleration: false,
                androidAttachSurfaceAfterVideoParameters: false,
              ));
      setDataSource(datasource);
      mediaPlayerController.player.stream.playing.listen((bool playing) {
        if (playing) {
          if (!mediaPlayerControllerInitialized.value) {
            mediaPlayerControllerInitialized.value = true;
          }
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
    } else {
      gsyVideoPlayerController =
          GsyVideoPlayerController(allowBackgroundPlayback: false, player: getVideoPlayerType(videoPlayerIndex));
      chewieController = ChewieController(
        videoPlayerController: gsyVideoPlayerController,
        autoPlay: false,
        looping: false,
        draggableProgressBar: false,
        showControls: false,
        useRootNavigator: true,
        showOptions: false,
      );
      gsyVideoPlayerController.setMediaCodec(enableCodec);
      gsyVideoPlayerController.setMediaCodecTexture(enableCodec);
      gsyVideoPlayerController.setNetWorkBuilder(datasource, mapHeadData: headers, cacheWithPlay: false);
      gsyVideoPlayerController.addEventsListener((VideoEventType event) {
        if (event == VideoEventType.onError) {
          hasError.value = true;
          isPlaying.value = false;
          log('video error ${gsyVideoPlayerController.value.what}', name: 'video_player');
        } else {
          mediaPlayerControllerInitialized.value = gsyVideoPlayerController.value.onVideoPlayerInitialized;
          if (mediaPlayerControllerInitialized.value) {
            isPlaying.value = gsyVideoPlayerController.value.isPlaying;
          }
        }
      });
    }
  }

  void setDataSource(String url) async {
    player.pause();
    player.open(Media(url, httpHeaders: headers));
  }

  void onKeyEvent(KeyEvent key) {
    if (key is KeyUpEvent) {
      return;
    }

    throttle(() {
      handleKeyEvent(key);
    }, 100);
  }

  handleDanmuKeyLeft(items, value) {
    if (items.keys.first == value) {
      return items.keys.last;
    }
    return items.keys.elementAt(items.keys.toList().indexOf(value) - 1);
  }

  handleDanmuKeyRight(items, value) {
    if (items.keys.last == value) {
      return items.keys.first;
    }
    return items.keys.elementAt(items.keys.toList().indexOf(value) + 1);
  }

  handleKeyEvent(KeyEvent key) {
    if (key is KeyUpEvent) {
      return;
    }
    // 点击Menu打开/关闭设置
    if (key.logicalKey == LogicalKeyboardKey.keyM || key.logicalKey == LogicalKeyboardKey.contextMenu) {
      showPlayListPanel.value = false;
      showController.value = false;
      showSettting.value = true;
    }
    // 如果没有显示控制面板
    if (!showController.value) {
      // 如果没有显示弹幕控制面板和关注列表
      if (!showSettting.value && !showPlayListPanel.value) {
        // 点击OK、Enter、Select键时显示/隐藏控制器
        if (key.logicalKey == LogicalKeyboardKey.select ||
            key.logicalKey == LogicalKeyboardKey.enter ||
            key.logicalKey == LogicalKeyboardKey.space ||
            key.logicalKey == LogicalKeyboardKey.controlRight ||
            key.logicalKey == LogicalKeyboardKey.controlLeft) {
          // 点击enter键显示控制器
          enableController();
          return;
        }
        // 点击上下键切换播放线路
        if (key.logicalKey == LogicalKeyboardKey.arrowUp) {
          prevPlayChannel();
        } else if (key.logicalKey == LogicalKeyboardKey.arrowDown) {
          nextPlayChannel();
        }
        // 点击左右键切换播放线路
        if (key.logicalKey == LogicalKeyboardKey.arrowLeft) {
          // 双击取消或关注
          if (doubleClickTimeStamp == 0) {
            settings.isFavorite(room) ? SmartDialog.showToast("双击取消关注") : SmartDialog.showToast("双击关注");
            doubleClickTimeStamp = DateTime.now().millisecondsSinceEpoch;
          } else {
            var now = DateTime.now().millisecondsSinceEpoch;
            if (now - doubleClickTimeStamp < 500) {
              if (settings.isFavorite(room)) {
                settings.removeRoom(room);
                SmartDialog.showToast("已取消关注");
              } else {
                settings.addRoom(room);
                SmartDialog.showToast("已关注");
              }
              doubleClickTimeStamp = 0;
              doubleClickTimer?.cancel();
            }
            doubleClickTimer?.cancel();
            doubleClickTimer = Timer(const Duration(milliseconds: 500), () {
              doubleClickTimeStamp = 0;
              doubleClickTimer?.cancel();
            });
          }
        } else if (key.logicalKey == LogicalKeyboardKey.arrowRight) {
          showPlayListPanel.value = true;
        }
      } else if (showPlayListPanel.value) {
        // 展示关注列表
        var playIndex = beforePlayNodeIndex.value;
        if (key.logicalKey == LogicalKeyboardKey.arrowDown) {
          playIndex++;
          if (playIndex == settings.currentPlayList.length) {
            playIndex = 0;
          }
        } else if (key.logicalKey == LogicalKeyboardKey.arrowUp) {
          if (playIndex == -1) {
            playIndex = settings.currentPlayList.length - 1;
          }
          playIndex--;
        }
        beforePlayNodeIndex.value = playIndex;

        if (key.logicalKey == LogicalKeyboardKey.arrowLeft) {
          var room = settings.currentPlayList[beforePlayNodeIndex.value];
          if (settings.isFavorite(room)) {
            settings.removeRoom(room);
            SmartDialog.showToast("已取消关注");
          } else {
            settings.addRoom(room);
            SmartDialog.showToast("已关注");
          }
        } else if (key.logicalKey == LogicalKeyboardKey.arrowRight) {
          var room = settings.currentPlayList[beforePlayNodeIndex.value];
          if (settings.isFavorite(room)) {
            settings.removeRoom(room);
            SmartDialog.showToast("已取消关注");
          } else {
            settings.addRoom(room);
            SmartDialog.showToast("已关注");
          }
        }

        if (key.logicalKey == LogicalKeyboardKey.select ||
            key.logicalKey == LogicalKeyboardKey.enter ||
            key.logicalKey == LogicalKeyboardKey.space ||
            key.logicalKey == LogicalKeyboardKey.controlRight ||
            key.logicalKey == LogicalKeyboardKey.controlLeft) {
          // 点击enter键显示控制器
          settings.currentPlayListNodeIndex.value = beforePlayNodeIndex.value;
          livePlayController.playFavoriteChannel();
        }
      } else {
        //没有控制面板以及关注列表显示了 设置面板
        var danmakuIndex = danmukuNodeIndex.value;
        if (key.logicalKey == LogicalKeyboardKey.arrowDown) {
          danmakuIndex++;
          if (danmakuIndex == DanmakuSettingClickType.values.length) {
            danmakuIndex = 0;
          }
        } else if (key.logicalKey == LogicalKeyboardKey.arrowUp) {
          if (danmakuIndex == -1) {
            danmakuIndex = DanmakuSettingClickType.values.length - 1;
          }
          danmakuIndex--;
        }
        danmukuNodeIndex.value = danmakuIndex;
        // 点击左右键切换播放线路
        if (key.logicalKey == LogicalKeyboardKey.arrowLeft) {
          handleDanmuKeyLeftEvent();
        } else if (key.logicalKey == LogicalKeyboardKey.arrowRight) {
          handleDanmuKeyRightEvent();
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
      var bottomActionIndex = currentNodeIndex.value;
      if (key.logicalKey == LogicalKeyboardKey.arrowDown) {
        bottomActionIndex++;
        if (bottomActionIndex == BottomButtonClickType.values.length) {
          bottomActionIndex = 0;
        }
      } else if (key.logicalKey == LogicalKeyboardKey.arrowUp) {
        bottomActionIndex--;
        if (bottomActionIndex == -1) {
          bottomActionIndex = BottomButtonClickType.values.length - 1;
        }
      } else if (key.logicalKey == LogicalKeyboardKey.arrowRight) {
        bottomActionIndex++;
        if (bottomActionIndex == BottomButtonClickType.values.length) {
          bottomActionIndex = 0;
        }
      } else if (key.logicalKey == LogicalKeyboardKey.arrowLeft) {
        bottomActionIndex--;
        if (bottomActionIndex == -1) {
          bottomActionIndex = BottomButtonClickType.values.length - 1;
        }
      }
      currentNodeIndex.value = bottomActionIndex;
      // 点击OK、Enter、Select键时显示/隐藏控制器
      if (key.logicalKey == LogicalKeyboardKey.select ||
          key.logicalKey == LogicalKeyboardKey.enter ||
          key.logicalKey == LogicalKeyboardKey.space ||
          key.logicalKey == LogicalKeyboardKey.controlRight ||
          key.logicalKey == LogicalKeyboardKey.controlLeft) {
        // 点击enter键显示控制器
        switch (currentBottomClickType.value) {
          case BottomButtonClickType.playPause:
            togglePlayPause();
            break;
          case BottomButtonClickType.favorite:
            if (settings.isFavorite(room)) {
              settings.removeRoom(room);
            } else {
              settings.addRoom(room);
            }
            break;
          case BottomButtonClickType.refresh:
            refresh();
            break;
          case BottomButtonClickType.danmaku:
            hideDanmaku.toggle();
            break;
          case BottomButtonClickType.settings:
            showSettting.value = true;
            break;
          case BottomButtonClickType.qualityName:
            changeQuality();
            break;
          case BottomButtonClickType.changeLine:
            changeLine(active: true);
            break;
          case BottomButtonClickType.boxFit:
            setVideoFit();
            break;
          default:
        }
      }
    }
  }

  void throttle(Function func, [int delay = 500]) {
    var now = DateTime.now().millisecondsSinceEpoch;
    if (now - _currentTimeStamp > delay) {
      _currentTimeStamp = now;
      func.call();
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
    danmakuFontBorder.value = PrefUtil.getDouble('danmakuFontBorder') ?? 2.0;
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

    videoFit.listen((p0) {
      if (p0 != settings.videofitArrary[settings.videoFitIndex.value]) {
        var index = settings.videofitArrary.indexWhere((element) => element == videoFit.value);
        settings.videoFitIndex.value = index;
      }
    });
  }

  void sendDanmaku(LiveMessage msg) {
    if (hideDanmaku.value || !livePlayController.success.value) return;
    if (!danmakuController.isEnabled) return;
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
    if (hasDestory == false) {
      await destory();
    }
    super.dispose();
  }

  destory() async {
    cancleFocus();
    cancledanmakuFocus();
    danmakuController.disable();
    await danmakuController.dispose();
    isPlaying.value = false;
    hasError.value = false;
    livePlayController.success.value = false;
    hasDestory = true;
    if (videoPlayerIndex == 5) {
      log('vlc dispose', name: 'video_player');
      await vlcPlayerController.stopRendererScanning();
      await vlcPlayerController.dispose();
    } else if (videoPlayerIndex == 4) {
      player.dispose();
    } else {
      chewieController.dispose();
      await gsyVideoPlayerController.dispose();
    }
  }

  void refresh() async {
    await destory();
    Timer(const Duration(seconds: 2), () {
      livePlayController.onInitPlayerState(reloadDataType: ReloadDataType.refreash);
    });
  }

  void changeLine({bool active = false}) async {
    // 播放错误 不一定是线路问题 先切换路线解决 后面尝试通知用户切换播放器
    await destory();
    Timer(const Duration(seconds: 2), () {
      livePlayController.onInitPlayerState(
        reloadDataType: ReloadDataType.changeLine,
        line: currentLineIndex,
        active: active,
      );
    });
  }

  void changeQuality() async {
    await destory();
    Timer(const Duration(seconds: 2), () {
      livePlayController.onInitPlayerState(
          reloadDataType: ReloadDataType.changeQuality, line: currentLineIndex, currentQuality: currentQuality);
    });
  }

  void setVideoFit() {
    var index = settings.videoFitIndex.value;
    index += 1;
    if (index >= settings.videofitArrary.length) {
      index = 0;
    }
    settings.videoFitIndex.value = index;
    var aspectRatio = "16:9";
    if (index == 0) {
      aspectRatio = "16:9";
    } else if (index == 1) {
      aspectRatio = "1:1";
    } else if (index == 2) {
      aspectRatio = "9:16";
    } else if (index == 3) {
      aspectRatio = "3:4";
    } else if (index == 4) {
      aspectRatio = "4:3";
    }

    if (videoPlayerIndex == 5) {
      vlcPlayerController.setVideoAspectRatio(aspectRatio);
    } else if (videoPlayerIndex == 4) {
      key.currentState?.update(fit: settings.videofitArrary[index]);
    } else {
      gsyVideoPlayerController.setBoxFit(settings.videofitArrary[index]);
    }
  }

  void togglePlayPause() {
    if (videoPlayerIndex == 5) {
      if (isPlaying.value) {
        vlcPlayerController.pause();
      } else {
        vlcPlayerController.play();
      }
    } else if (videoPlayerIndex == 4) {
      mediaPlayerController.player.playOrPause();
    } else {
      if (isPlaying.value) {
        gsyVideoPlayerController.pause();
      } else {
        gsyVideoPlayerController.resume();
      }
    }
  }

  void prevPlayChannel() {
    showChangeNameFlag.value = true;
    showChangeNameTimer?.cancel();
    showChangeNameTimer = Timer(const Duration(milliseconds: 2000), () {
      showChangeNameFlag.value = false;
      showChangeNameTimer?.cancel();
    });
    livePlayController.prevChannel();
  }

  void nextPlayChannel() {
    showChangeNameFlag.value = true;
    showChangeNameTimer?.cancel();
    showChangeNameTimer = Timer(const Duration(milliseconds: 2000), () {
      showChangeNameFlag.value = false;
      showChangeNameTimer?.cancel();
    });
    livePlayController.nextChannel();
  }

  void playFavoriteChannel() {
    showChangeNameFlag.value = true;
    showChangeNameTimer?.cancel();
    showChangeNameTimer = Timer(const Duration(milliseconds: 2000), () {
      showChangeNameFlag.value = false;
      showChangeNameTimer?.cancel();
    });
    livePlayController.playFavoriteChannel();
  }

  handleDanmuKeyRightEvent() {
    switch (currentDanmukuClickType.value) {
      case DanmakuSettingClickType.danmakuAble:
        Map<dynamic, String> items = {
          0: "关",
          1: "开",
        };
        hideDanmaku.value = handleDanmuKeyRight(items, hideDanmaku.value ? 0 : 1) == 0;
      case DanmakuSettingClickType.danmakuMerge:
        Map<dynamic, String> items = {
          0.0: "不合并",
          0.25: "相似度小于25%",
          0.5: "相似度小于50%",
          0.75: "相似度小于75%",
          1.0: "全部合并",
        };
        mergeDanmuRating.value = handleDanmuKeyRight(items, mergeDanmuRating.value);
        break;
      case DanmakuSettingClickType.danmakuSize:
        Map<dynamic, String> items = {
          10.0: "10",
          12.0: "12",
          14.0: "14",
          16.0: "16",
          18.0: "18",
          20.0: "20",
          22.0: "22",
          24.0: "24",
          26.0: "26",
          28.0: "28",
          32.0: "32",
          40.0: "40",
          48.0: "48",
          56.0: "56",
          64.0: "64",
          72.0: "72",
        };
        danmakuFontSize.value = handleDanmuKeyRight(items, danmakuFontSize.value);
        break;
      case DanmakuSettingClickType.danmakuSpeed:
        Map<dynamic, String> items = {
          18.0: "很慢",
          14.0: "较慢",
          12.0: "慢",
          10.0: "正常",
          8.0: "快",
          6.0: "较快",
          4.0: "很快",
        };
        danmakuSpeed.value = handleDanmuKeyRight(items, danmakuSpeed.value);
      case DanmakuSettingClickType.danmakuArea:
        Map<dynamic, String> items = {
          0.25: "1/4",
          0.5: "1/2",
          0.75: "3/4",
          1.0: "全屏",
        };
        danmakuArea.value = handleDanmuKeyRight(items, danmakuArea.value);
        break;
      case DanmakuSettingClickType.danmakuOpacity:
        Map<dynamic, String> items = {
          0.1: "10%",
          0.2: "20%",
          0.3: "30%",
          0.4: "40%",
          0.5: "50%",
          0.6: "60%",
          0.7: "70%",
          0.8: "80%",
          0.9: "90%",
          1.0: "100%",
        };
        danmakuOpacity.value = handleDanmuKeyRight(items, danmakuOpacity.value);
      case DanmakuSettingClickType.danmakuStorke:
        Map<dynamic, String> items = {
          2.0: "2",
          4.0: "4",
          6.0: "6",
          8.0: "8",
          10.0: "10",
          12.0: "12",
          14.0: "14",
          16.0: "16",
          18.0: "18",
          20.0: "20",
          22.0: "22",
          24.0: "24",
        };
        danmakuFontBorder.value = handleDanmuKeyRight(items, danmakuFontBorder.value);
        break;
      default:
    }
  }

  handleDanmuKeyLeftEvent() {
    switch (currentDanmukuClickType.value) {
      case DanmakuSettingClickType.danmakuAble:
        Map<dynamic, String> items = {
          0: "关",
          1: "开",
        };
        hideDanmaku.value = handleDanmuKeyLeft(items, hideDanmaku.value ? 0 : 1) == 0;
      case DanmakuSettingClickType.danmakuMerge:
        Map<dynamic, String> items = {
          0.0: "不合并",
          0.25: "相似度小于25%",
          0.5: "相似度小于50%",
          0.75: "相似度小于75%",
          1.0: "全部合并",
        };
        mergeDanmuRating.value = handleDanmuKeyLeft(items, mergeDanmuRating.value);
        break;
      case DanmakuSettingClickType.danmakuSize:
        Map<dynamic, String> items = {
          10.0: "10",
          12.0: "12",
          14.0: "14",
          16.0: "16",
          18.0: "18",
          20.0: "20",
          22.0: "22",
          24.0: "24",
          26.0: "26",
          28.0: "28",
          32.0: "32",
          40.0: "40",
          48.0: "48",
          56.0: "56",
          64.0: "64",
          72.0: "72",
        };
        danmakuFontSize.value = handleDanmuKeyLeft(items, danmakuFontSize.value);
        break;
      case DanmakuSettingClickType.danmakuSpeed:
        Map<dynamic, String> items = {
          18.0: "很慢",
          14.0: "较慢",
          12.0: "慢",
          10.0: "正常",
          8.0: "快",
          6.0: "较快",
          4.0: "很快",
        };
        danmakuSpeed.value = handleDanmuKeyLeft(items, danmakuSpeed.value);
      case DanmakuSettingClickType.danmakuArea:
        Map<dynamic, String> items = {
          0.2: "1/5",
          0.25: "1/4",
          0.5: "1/2",
          0.6: "3/5",
          0.75: "3/4",
          1.0: "全屏",
        };
        danmakuArea.value = handleDanmuKeyLeft(items, danmakuArea.value);
        break;
      case DanmakuSettingClickType.danmakuOpacity:
        Map<dynamic, String> items = {
          0.1: "10%",
          0.2: "20%",
          0.3: "30%",
          0.4: "40%",
          0.5: "50%",
          0.6: "60%",
          0.7: "70%",
          0.8: "80%",
          0.9: "90%",
          1.0: "100%",
        };
        danmakuOpacity.value = handleDanmuKeyLeft(items, danmakuOpacity.value);
      case DanmakuSettingClickType.danmakuStorke:
        Map<dynamic, String> items = {
          1.0: "2",
          2.0: "2",
          4.0: "4",
          6.0: "6",
          8.0: "8",
          10.0: "10",
          12.0: "12",
          14.0: "14",
          16.0: "16",
          18.0: "18",
          20.0: "20",
          22.0: "22",
          24.0: "24",
        };
        danmakuFontBorder.value = handleDanmuKeyLeft(items, danmakuFontBorder.value);
        break;
      default:
    }
  }
}

enum BottomButtonClickType { favorite, refresh, playPause, danmaku, settings, qualityName, changeLine, boxFit }

enum DanmakuSettingClickType {
  danmakuAble,
  danmakuMerge,
  danmakuSize,
  danmakuSpeed,
  danmakuArea,
  danmakuOpacity,
  danmakuStorke
}
