import 'dart:async';
import 'dart:developer';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/app/app_focus_node.dart';
import 'package:pure_live/core/site/huya_site.dart';
import 'package:pure_live/model/live_play_quality.dart';
import 'package:pure_live/core/interface/live_danmaku.dart';
import 'package:pure_live/modules/live_play/load_type.dart';
import 'package:pure_live/modules/live_play/widgets/index.dart';

class LivePlayController extends StateController {
  LivePlayController({
    required this.room,
    required this.site,
  });
  final String site;

  late final Site currentSite = Sites.of(site);

  late final LiveDanmaku liveDanmaku = Sites.of(site).liveSite.getDanmaku();

  final settings = Get.find<SettingsService>();

  final messages = <LiveMessage>[].obs;

  // 控制唯一子组件
  VideoController? videoController;

  final playerKey = GlobalKey();

  final danmakuViewKey = GlobalKey();

  final LiveRoom room;

  Rx<LiveRoom?> detail = Rx<LiveRoom?>(LiveRoom());

  final success = false.obs;

  var liveStatus = false.obs;

  Map<String, List<String>> liveStream = {};

  /// 清晰度数据
  RxList<LivePlayQuality> qualites = RxList<LivePlayQuality>();

  /// 当前清晰度
  final currentQuality = 0.obs;

  /// 线路数据
  RxList<String> playUrls = RxList<String>();

  /// 当前线路
  final currentLineIndex = 0.obs;

  int lastExitTime = 0;

  final FocusNode focusNode = AppFocusNode()..isFoucsed.value = true;

  /// 双击退出Flag
  bool doubleClickExit = false;

  /// 双击退出Timer
  Timer? doubleClickTimer;

  var isFirstLoad = true.obs;
  // 0 代表向上 1 代表向下
  int isNextOrPrev = 0;

  int _currentTimeStamp = 0;
  // 当前直播间信息 下一个频道或者上一个
  var currentPlayRoom = LiveRoom().obs;

  var getVideoSuccess = true.obs;

  var currentChannelIndex = 0.obs;

  var lastChannelIndex = 0.obs;

  Timer? channelTimer;

  Timer? loadRefreshRoomTimer;
  // 切换线路会添加到这个数组里面
  var isLastLine = false.obs;

  var hasError = false.obs;

  var loadTimeOut = true.obs;
  // 是否是手动切换线路
  var isActive = false.obs;

  @override
  void onClose() {
    videoController?.dispose();
    liveDanmaku.stop();
    super.onClose();
  }

  @override
  void onInit() {
    // 发现房间ID 会变化 使用静态列表ID 对比

    currentPlayRoom.value = room;
    onInitPlayerState();

    isFirstLoad.listen((p0) {
      if (isFirstLoad.value) {
        loadTimeOut.value = true;
        Timer(const Duration(seconds: 5), () {
          isFirstLoad.value = false;
          loadTimeOut.value = false;
          Timer(const Duration(seconds: 5), () {
            loadTimeOut.value = true;
          });
        });
      } else {
        // 防止闪屏
        Timer(const Duration(seconds: 2), () {
          loadTimeOut.value = false;
          Timer(const Duration(seconds: 5), () {
            loadTimeOut.value = true;
          });
        });
      }
    });

    isLastLine.listen((p0) {
      if (isLastLine.value && hasError.value && isActive.value == false) {
        // 刷新到了最后一路线 并且有错误
        SmartDialog.showToast("当前房间无法播放,正在为您每10秒刷新直播间信息...", displayTime: const Duration(seconds: 2));
        Timer(const Duration(seconds: 1), () {
          loadRefreshRoomTimer?.cancel();
          loadRefreshRoomTimer = Timer(const Duration(seconds: 10), () {
            isLastLine.value = false;
            isFirstLoad.value = true;
            restoryQualityAndLines();
            resetRoom(Sites.of(currentPlayRoom.value.platform!), currentPlayRoom.value.roomId!);
          });
        });
      } else {
        if (success.value) {
          isActive.value = false;
          loadRefreshRoomTimer?.cancel();
        }
      }
    });
    super.onInit();
  }

  Future<LiveRoom> onInitPlayerState({
    ReloadDataType reloadDataType = ReloadDataType.refreash,
    int line = 0,
    int currentQuality = 0,
    bool active = false,
  }) async {
    isActive.value = active;
    isFirstLoad.value = true;
    var liveRoom = await currentSite.liveSite.getRoomDetail(
      roomId: currentPlayRoom.value.roomId!,
      platform: currentPlayRoom.value.platform!,
      title: currentPlayRoom.value.title!,
      nick: currentPlayRoom.value.nick!,
    );
    isLastLine.value = calcIsLastLine(reloadDataType, line) && reloadDataType == ReloadDataType.changeLine;
    if (isLastLine.value) {
      hasError.value = true;
    } else {
      hasError.value = false;
    }
    // active 代表用户是否手动切换路线 只有不是手动自动切换才会显示路线错误信息

    if (isLastLine.value && hasError.value && active == false) {
      disPoserPlayer();
      restoryQualityAndLines();
      getVideoSuccess.value = false;
      isFirstLoad.value = false;
      return liveRoom;
    } else {
      handleCurrentLineAndQuality(reloadDataType: reloadDataType, line: line, quality: currentQuality);
      detail.value = liveRoom;
      resetGlobalListState();
      if (liveRoom.liveStatus == LiveStatus.unknown) {
        SmartDialog.showToast("获取直播间信息失败,请按确定建重新获取", displayTime: const Duration(seconds: 2));
        getVideoSuccess.value = false;
        isFirstLoad.value = false;
        return liveRoom;
      }

      liveStatus.value = liveRoom.status! || liveRoom.isRecord!;
      if (liveStatus.value) {
        getPlayQualites();
        getVideoSuccess.value = true;
        if (currentPlayRoom.value.platform == Sites.iptvSite) {
          settings.addRoomToHistory(currentPlayRoom.value);
        } else {
          settings.addRoomToHistory(liveRoom);
        }
        // start danmaku server
        List<String> except = ['kuaishou', 'iptv', 'cc'];
        if (except.indexWhere((element) => element == liveRoom.platform!) == -1) {
          liveDanmaku.stop();
          initDanmau();
          liveDanmaku.start(liveRoom.danmakuData);
        }
      } else {
        isFirstLoad.value = false;
        success.value = false;
        getVideoSuccess.value = true;
        SmartDialog.showToast("当前主播未开播或主播已下播", displayTime: const Duration(seconds: 2));
        restoryQualityAndLines();
      }

      return liveRoom;
    }
  }

  resetGlobalListState() {
    var index = settings.currentPlayList.indexWhere((element) =>
        element.roomId == currentPlayRoom.value.roomId && element.platform == currentPlayRoom.value.platform);
    currentChannelIndex.value = index > -1 ? index : 0;
    settings.currentPlayListNodeIndex.value = currentChannelIndex.value;
  }

  Future<LiveRoom> resetPlayerState({
    ReloadDataType reloadDataType = ReloadDataType.refreash,
    int line = 0,
    int currentQuality = 0,
  }) async {
    channelTimer?.cancel();
    handleCurrentLineAndQuality(reloadDataType: reloadDataType, line: line, quality: currentQuality);
    var liveRoom = await currentSite.liveSite.getRoomDetail(
      roomId: currentPlayRoom.value.roomId!,
      platform: currentPlayRoom.value.platform!,
      title: currentPlayRoom.value.title!,
      nick: currentPlayRoom.value.nick!,
    );
    detail.value = liveRoom;
    resetGlobalListState();
    if (liveRoom.liveStatus == LiveStatus.unknown) {
      SmartDialog.showToast("获取直播间信息失败,请按确定建重新获取", displayTime: const Duration(seconds: 2));
      getVideoSuccess.value = false;
      return liveRoom;
    }

    liveStatus.value = liveRoom.status! || liveRoom.isRecord!;
    if (liveStatus.value) {
      getPlayQualites();
      getVideoSuccess.value = true;
      if (currentPlayRoom.value.platform == Sites.iptvSite) {
        settings.addRoomToHistory(currentPlayRoom.value);
      } else {
        settings.addRoomToHistory(liveRoom);
      }
      // start danmaku server
      List<String> except = ['kuaishou', 'iptv', 'cc'];
      if (except.indexWhere((element) => element == liveRoom.platform!) == -1) {
        liveDanmaku.stop();
        initDanmau();
        liveDanmaku.start(liveRoom.danmakuData);
      }
    }

    return liveRoom;
  }

  bool calcIsLastLine(ReloadDataType reloadDataType, int line) {
    var lastLine = line + 1;
    if (playUrls.isEmpty) {
      return true;
    }
    if (playUrls.length == 1) {
      return true;
    }
    if (lastLine == playUrls.length - 1) {
      return true;
    }
    return false;
  }

  disPoserPlayer() {
    videoController?.dispose();
    videoController = null;
    liveDanmaku.stop();
    success.value = false;
    focusNode.requestFocus();
    liveDanmaku.stop();
  }

  handleCurrentLineAndQuality({
    ReloadDataType reloadDataType = ReloadDataType.refreash,
    int line = 0,
    int quality = 0,
  }) {
    disPoserPlayer();
    try {
      if (reloadDataType == ReloadDataType.refreash) {
        restoryQualityAndLines();
      } else if (reloadDataType == ReloadDataType.changeLine) {
        if (line == playUrls.length - 1) {
          currentLineIndex.value = 0;
        } else {
          currentLineIndex.value = currentLineIndex.value + 1;
        }
        isFirstLoad.value = false;
      } else if (reloadDataType == ReloadDataType.changeQuality) {
        if (quality == qualites.length - 1) {
          currentQuality.value = 0;
        } else {
          currentQuality.value = currentQuality.value + 1;
        }
        isFirstLoad.value = false;
      }
    } catch (e) {
      restoryQualityAndLines();
      if (reloadDataType == ReloadDataType.changeLine) {
        SmartDialog.showToast("切换线路失败", displayTime: const Duration(seconds: 2));
      } else if (reloadDataType == ReloadDataType.changeQuality) {
        SmartDialog.showToast("切换清晰度失败", displayTime: const Duration(seconds: 2));
      }
    }
  }

  /// 初始化弹幕接收事件
  void initDanmau() {
    if (detail.value!.isRecord!) {
      messages.add(
        LiveMessage(
          type: LiveMessageType.chat,
          userName: "系统消息",
          message: "当前主播未开播，正在轮播录像",
          color: LiveMessageColor.white,
        ),
      );
    }
    messages.add(
      LiveMessage(
        type: LiveMessageType.chat,
        userName: "系统消息",
        message: "开始连接弹幕服务器",
        color: LiveMessageColor.white,
      ),
    );
    liveDanmaku.onMessage = (msg) {
      if (msg.type == LiveMessageType.chat) {
        if (settings.shieldList.every((element) => !msg.message.contains(element))) {
          messages.add(msg);
          videoController?.sendDanmaku(msg);
        }
      }
    };
    liveDanmaku.onClose = (msg) {
      messages.add(
        LiveMessage(
          type: LiveMessageType.chat,
          userName: "系统消息",
          message: msg,
          color: LiveMessageColor.white,
        ),
      );
    };
    liveDanmaku.onReady = () {
      messages.add(
        LiveMessage(
          type: LiveMessageType.chat,
          userName: "系统消息",
          message: "弹幕服务器连接正常",
          color: LiveMessageColor.white,
        ),
      );
    };
  }

  Future<bool> onBackPressed() async {
    if (videoController!.showSettting.value) {
      videoController?.showSettting.value = false;
      videoController?.focusNode.requestFocus();
      return await Future.value(false);
    }
    if (videoController!.showPlayListPanel.value) {
      videoController?.showPlayListPanel.value = false;
      videoController?.focusNode.requestFocus();
      return await Future.value(false);
    }
    if (videoController!.showController.value) {
      videoController?.disableController();
      videoController?.focusNode.requestFocus();
      return await Future.value(false);
    }
    int nowExitTime = DateTime.now().millisecondsSinceEpoch;
    if (nowExitTime - lastExitTime > 1000) {
      lastExitTime = nowExitTime;
      SmartDialog.showToast(S.current.double_click_to_exit);
      return await Future.value(false);
    }
    if (videoController != null && videoController!.hasDestory == false) {
      videoController?.focusNode.requestFocus();
      videoController!.destory();
    }
    return await Future.value(true);
  }

  /// 初始化播放器
  void getPlayQualites() async {
    try {
      var playQualites = await currentSite.liveSite.getPlayQualites(detail: detail.value!);
      if (playQualites.isEmpty) {
        SmartDialog.showToast("无法读取视频信息,请按确定键重新获取", displayTime: const Duration(seconds: 2));
        getVideoSuccess.value = false;
        isFirstLoad.value = false;
        success.value = false;
        return;
      }
      qualites.value = playQualites;
      // 第一次加载 使用系统默认线路
      if (isFirstLoad.value) {
        int qualityLevel = settings.resolutionsList.indexOf(settings.preferResolution.value);
        if (qualityLevel == 0) {
          //最高
          currentQuality.value = 0;
        } else if (qualityLevel == settings.resolutionsList.length - 1) {
          //最低
          currentQuality.value = playQualites.length - 1;
        } else {
          //中间值
          int middle = (playQualites.length / 2).floor();
          currentQuality.value = middle;
        }
      }
      isFirstLoad.value = false;
      getPlayUrl();
    } catch (e) {
      SmartDialog.showToast("无法读取视频信息,请按确定键重新获取");
      getVideoSuccess.value = false;
      isFirstLoad.value = false;
      success.value = false;
    }
  }

  restoryQualityAndLines() {
    playUrls.value = [];
    currentLineIndex.value = 0;
    qualites.value = [];
    currentQuality.value = 0;
  }

  void getPlayUrl() async {
    var playUrl =
        await currentSite.liveSite.getPlayUrls(detail: detail.value!, quality: qualites[currentQuality.value]);
    if (playUrl.isEmpty) {
      SmartDialog.showToast("无法读取播放地址,请按确定键重新获取", displayTime: const Duration(seconds: 2));
      getVideoSuccess.value = false;
      isFirstLoad.value = false;
      success.value = false;
      return;
    }
    playUrls.value = playUrl;
    setPlayer();
  }

  void setPlayer() async {
    Map<String, String> headers = {};
    if (currentSite.id == 'bilibili') {
      headers = {
        "cookie": settings.bilibiliCookie.value,
        "authority": "api.bilibili.com",
        "accept":
            "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
        "accept-language": "zh-CN,zh;q=0.9",
        "cache-control": "no-cache",
        "dnt": "1",
        "pragma": "no-cache",
        "sec-ch-ua": '"Not A(Brand";v="99", "Google Chrome";v="121", "Chromium";v="121"',
        "sec-ch-ua-mobile": "?0",
        "sec-ch-ua-platform": '"macOS"',
        "sec-fetch-dest": "document",
        "sec-fetch-mode": "navigate",
        "sec-fetch-site": "none",
        "sec-fetch-user": "?1",
        "upgrade-insecure-requests": "1",
        "user-agent":
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36",
        "referer": "https://live.bilibili.com"
      };
    } else if (currentSite.id == 'huya') {
      var ua = await HuyaSite().getHuYaUA();
      headers = {
        "user-agent": ua,
        "origin": "https://www.huya.com",
        "cookie": settings.huyaCookie.value,
      };
    }
    videoController = VideoController(
      playerKey: playerKey,
      room: detail.value!,
      datasourceType: 'network',
      datasource: playUrls.value[currentLineIndex.value],
      autoPlay: true,
      headers: headers,
      qualiteName: qualites[currentQuality.value].quality,
      currentLineIndex: currentLineIndex.value,
      currentQuality: currentQuality.value,
    );

    success.value = true;
    isActive.value = false;
  }

  void nextChannel() {
    //读取正在直播的频道
    var liveChannels = settings.currentPlayList;
    log(liveChannels.length.toString());
    if (liveChannels.isEmpty) {
      SmartDialog.showToast("没有正在直播的频道", displayTime: const Duration(seconds: 2));
      return;
    }
    var index = settings.currentPlayListNodeIndex.value;
    index += 1;
    if (index >= liveChannels.length) {
      index = 0;
    }
    var nextChannel = liveChannels[index];
    settings.currentPlayListNodeIndex.value = index;
    currentChannelIndex.value = index;
    currentPlayRoom.value = nextChannel;
    isNextOrPrev = 1;
    channelTimer?.cancel();
    channelTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      lastChannelIndex.value = currentChannelIndex.value;
      resetRoom(Sites.of(nextChannel.platform!), nextChannel.roomId!);
    });
  }

  void prevChannel() {
    //读取正在直播的频道
    _currentTimeStamp = DateTime.now().millisecondsSinceEpoch;
    var liveChannels = settings.currentPlayList;
    log(liveChannels.length.toString());
    if (liveChannels.isEmpty) {
      SmartDialog.showToast("没有正在直播的频道", displayTime: const Duration(seconds: 2));
      return;
    }
    var index = settings.currentPlayListNodeIndex.value;
    index -= 1;
    if (index < 0) {
      index = liveChannels.length - 1;
    }
    settings.currentPlayListNodeIndex.value = index;
    currentChannelIndex.value = index;

    var nextChannel = liveChannels[index];
    currentPlayRoom.value = nextChannel;
    isNextOrPrev = 0;
    channelTimer?.cancel();
    channelTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      lastChannelIndex.value = currentChannelIndex.value;
      resetRoom(Sites.of(nextChannel.platform!), nextChannel.roomId!);
    });
  }

  playFavoriteChannel() {
    //读取正在直播的频道
    _currentTimeStamp = DateTime.now().millisecondsSinceEpoch;
    var liveChannels = settings.currentPlayList;
    log(liveChannels.length.toString());
    if (liveChannels.isEmpty) {
      SmartDialog.showToast("没有正在直播的频道", displayTime: const Duration(seconds: 2));
      return;
    }
    var index = settings.currentPlayListNodeIndex.value;
    currentChannelIndex.value = index;
    var nextChannel = liveChannels[index];
    currentPlayRoom.value = nextChannel;
    isNextOrPrev = 0;
    channelTimer?.cancel();
    channelTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      lastChannelIndex.value = currentChannelIndex.value;
      resetRoom(Sites.of(nextChannel.platform!), nextChannel.roomId!);
    });
  }

  void resetRoom(Site site, String roomId) async {
    success.value = false;
    hasError.value = false;
    if (videoController != null && videoController!.hasDestory == false) {
      await videoController?.destory();
      videoController = null;
    }
    isFirstLoad.value = true;
    getVideoSuccess.value = true;
    loadTimeOut.value = true;
    focusNode.requestFocus();
    Timer(const Duration(milliseconds: 200), () {
      if (lastChannelIndex.value == currentChannelIndex.value) {
        resetPlayerState();
      }
    });
  }

  void onKeyEvent(KeyEvent key) {
    if (key is KeyUpEvent) {
      return;
    }
    throttle(() {
      handleKeyEvent(key);
    }, 100);
  }

  handleKeyEvent(KeyEvent key) {
    // 点击上下键切换播放线路
    if (key.logicalKey == LogicalKeyboardKey.arrowUp) {
      prevChannel();
    } else if (key.logicalKey == LogicalKeyboardKey.arrowDown) {
      nextChannel();
    }
    // 点击左右键切换播放线路
    if (key.logicalKey == LogicalKeyboardKey.arrowLeft) {
      prevChannel();
    } else if (key.logicalKey == LogicalKeyboardKey.arrowRight) {
      nextChannel();
    }
    // 点击OK、Enter、Select键时刷新直播间
    if (key.logicalKey == LogicalKeyboardKey.select ||
        key.logicalKey == LogicalKeyboardKey.enter ||
        key.logicalKey == LogicalKeyboardKey.space ||
        key.logicalKey == LogicalKeyboardKey.controlRight ||
        key.logicalKey == LogicalKeyboardKey.controlLeft) {
      restoryQualityAndLines();
      resetRoom(Sites.of(currentPlayRoom.value.platform!), currentPlayRoom.value.roomId!);
      onInitPlayerState();
    }
  }

  void throttle(Function func, [int delay = 1000]) {
    var now = DateTime.now().millisecondsSinceEpoch;
    if (now - _currentTimeStamp > delay) {
      _currentTimeStamp = now;
      func.call();
    }
  }
}
