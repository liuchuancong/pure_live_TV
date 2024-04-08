import 'dart:developer';
import 'package:get/get.dart';
import 'package:pure_live/common/index.dart';
import 'widgets/video_player/video_controller.dart';
import 'package:pure_live/model/live_play_quality.dart';
import 'package:pure_live/core/interface/live_danmaku.dart';
import 'package:pure_live/modules/live_play/danmu_merge.dart';

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
  Future<bool> onBackPressed() async {
    if (videoController!.showSettting.value) {
      videoController?.showSettting.toggle();
      return await Future.value(false);
    }
    if (videoController!.isFullscreen.value) {
      videoController?.exitFullScreen();
      return await Future.value(false);
    }
    bool doubleExit = Get.find<SettingsService>().doubleExit.value;
    if (!doubleExit) {
      return Future.value(true);
    }
    int nowExitTime = DateTime.now().millisecondsSinceEpoch;
    if (nowExitTime - lastExitTime > 1000) {
      lastExitTime = nowExitTime;
      SmartDialog.showToast(S.current.double_click_to_exit);
      videoController?.isFullscreen.value = false;
      return await Future.value(false);
    }
    return await Future.value(true);
  }

  @override
  void onClose() {
    videoController?.dispose();
    liveDanmaku.stop();
    super.onClose();
  }

  @override
  void onInit() {
    super.onInit();
    try {
      currentSite.liveSite.getRoomDetail(roomId: room.roomId!).then((value) {
        detail.value = value;
        liveStatus.value = detail.value!.status! || detail.value!.isRecord!;
        if (liveStatus.value) {
          getPlayQualites();
        }
        // start danmaku server
        List<String> except = ['kuaishou', 'iptv', 'cc'];
        if (except.indexWhere((element) => element == detail.value?.platform!) == -1) {
          initDanmau();
          liveDanmaku.start(detail.value?.danmakuData);
        }
      }).then((value) => settings.addRoomToHistory(detail.value!));
    } catch (e) {
      log(e.toString(), name: 'LivePlayError');
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
          if (!DanmuMerge().isRepeat(msg.message)) {
            DanmuMerge().add(msg.message);
            messages.add(msg);
            videoController?.sendDanmaku(msg);
          }
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

  void setResolution(String quality, String index) {
    currentQuality.value = qualites.map((e) => e.quality).toList().indexWhere((e) => e == quality);
    currentLineIndex.value = int.tryParse(index) ?? 0;
    videoController?.isTryToHls = false;
    videoController?.isPlaying.value = false;
    videoController?.hasError.value = false;
    videoController?.setDataSource(playUrls.value[currentLineIndex.value], refresh: true);
    update();
  }

  /// 初始化播放器
  void getPlayQualites() async {
    qualites.value = [];
    currentQuality.value = 0;
    try {
      var playQualites = await currentSite.liveSite.getPlayQualites(detail: detail.value!);
      if (playQualites.isEmpty) {
        SmartDialog.showToast("无法读取播放清晰度");
        return;
      }
      qualites.value = playQualites;
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

      getPlayUrl();
    } catch (e) {
      SmartDialog.showToast("无法读取播放清晰度");
    }
  }

  void changePlayLine() {
    if (currentLineIndex.value == playUrls.length - 1) {
      liveStatus.value = false;
      success.value = false;

      if (videoController != null) {
        if (videoController!.isFullscreen.value) {
          videoController?.toggleFullScreen();
        }
        videoController?.hasError.value = true;
      }
      return;
    }
    currentLineIndex.value++;
    setResolution(qualites.map((e) => e.quality).toList()[currentQuality.value], currentLineIndex.value.toString());
  }

  void getPlayUrl() async {
    playUrls.value = [];
    currentLineIndex.value = 0;
    var playUrl =
        await currentSite.liveSite.getPlayUrls(detail: detail.value!, quality: qualites[currentQuality.value]);
    if (playUrl.isEmpty) {
      SmartDialog.showToast("无法读取播放地址");
      return;
    }
    playUrls.value = playUrl;
    currentLineIndex.value = 0;

    setPlayer();
  }

  void setPlayer() async {
    Map<String, String> headers = {};
    if (currentSite.id == 'bilibili') {
      headers = {
        "referer": "https://live.bilibili.com",
        "user-agent":
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36 Edg/115.0.1901.188"
      };
    } else if (currentSite.id == 'huya') {
      headers = {
        "Referer": "https://www.huya.com",
        "User-Agent":
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36 Edg/121.0.0.0"
      };
    }
    videoController = VideoController(
      playerKey: playerKey,
      room: detail.value!,
      datasourceType: 'network',
      datasource: playUrls.value[currentLineIndex.value],
      allowBackgroundPlay: settings.enableBackgroundPlay.value,
      allowScreenKeepOn: settings.enableScreenKeepOn.value,
      fullScreenByDefault: settings.enableFullScreenDefault.value,
      autoPlay: true,
      headers: headers,
    );
    success.value = true;
  }
}
