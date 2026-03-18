import 'dart:async';
import 'dart:developer';
import 'package:get/get.dart';
import 'models/video_enums.dart';
import 'controller/video_panel.dart';
import 'controller/video_danmaku.dart';
import 'controller/video_constants.dart';
import 'controller/video_key_handler.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/app/app_focus_node.dart';
import 'package:pure_live/model/live_play_quality.dart';
import 'package:pure_live/modules/live_play/load_type.dart';
import 'package:pure_live/player/switchable_global_player.dart';
import 'package:pure_live/pkg/canvas_danmaku/danmaku_controller.dart';
import 'package:pure_live/modules/live_play/live_play_controller.dart';

// 导入所需文件（无需显式导入扩展）

// 项目依赖

/// 视频播放核心控制器
class VideoController with ChangeNotifier {
  // ==================== 构造参数 ====================
  final GlobalKey playerKey;
  final LiveRoom room;
  final List<String> playUrls;
  final String datasourceType;
  final String qualiteName;
  final int currentLineIndex;
  final int currentQuality;
  String datasource;
  final bool autoPlay;
  final Map<String, String> headers;
  final List<LivePlayQuality> qualites;

  // ==================== 依赖服务 ====================
  final LivePlayController livePlayController = Get.find<LivePlayController>();
  final SettingsService settings = Get.find<SettingsService>();
  final SwitchableGlobalPlayer globalPlayer = SwitchableGlobalPlayer();

  // ==================== UI状态（响应式） ====================
  final videoFit = BoxFit.contain.obs;
  final showController = false.obs;
  final showSettting = false.obs;
  final showQualityPanel = false.obs;
  final showPlayListPanel = false.obs;
  final currentNodeIndex = 0.obs;
  final danmukuNodeIndex = 0.obs;
  final showChangeNameFlag = true.obs;
  final beforePlayNodeIndex = 0.obs;
  final currentBottomClickType = BottomButtonClickType.favorite.obs;
  final currentDanmakuClickType = DanmakuSettingClickType.danmakuAble.obs;
  final isLoading = false.obs;
  final qualityCurrentIndex = 0.obs;
  final lineCurrentIndex = 0.obs;

  // ==================== 弹幕配置 ====================
  late DanmakuController danmakuController;
  final hideDanmaku = false.obs;
  final danmakuArea = 1.0.obs;
  final danmakuTopArea = 0.0.obs;
  final danmakuBottomArea = 0.0.obs;
  final danmakuSpeed = 8.0.obs;
  final danmakuFontSize = 16.0.obs;
  final danmakuFontBorder = 4.0.obs;
  final danmakuOpacity = 1.0.obs;

  // ==================== 控制器/定时器 ====================
  Timer? showControllerTimer;
  Timer? showChangeNameTimer;
  Timer? doubleClickTimer;
  late ScrollController scrollController;
  late StreamSubscription<String?> _errorSub;

  // ==================== 焦点管理 ====================
  final AppFocusNode focusNode = AppFocusNode();
  final AppFocusNode danmukuFocusNode = AppFocusNode();
  final GlobalKey danmuKey = GlobalKey();

  // ==================== 临时变量 ====================
  double initBrightness = 0.0;
  bool enableCodec = true;
  int _currentTimeStamp = 0;
  int doubleClickTimeStamp = 0;
  static const danmakuAbleKey = ValueKey(DanmakuSettingClickType.danmakuAble);
  // 线路面板显示控制
  final RxBool showLinePanel = false.obs;

  // ==================== 构造函数 ====================
  VideoController({
    required this.playerKey,
    required this.room,
    required this.datasourceType,
    required this.datasource,
    required this.headers,
    required this.qualiteName,
    required this.currentLineIndex,
    required this.currentQuality,
    required this.playUrls,
    this.autoPlay = true,
    BoxFit fitMode = BoxFit.contain,
    required this.qualites,
  }) {
    _init();
  }

  // ==================== 初始化 ====================
  void _init() {
    // 初始化弹幕控制器
    _initDanmaku();
    // 初始化基础配置
    _initBaseConfig();
    // 初始化滚动控制器
    _initScroll();
    // 初始化事件监听
    _initListeners();
    // 初始化播放器
    _initPlayer();
    // 初始化订阅
    _initSubscriptions();
    // 初始化名称定时器
    _initNameTimer();
  }

  /// 初始化弹幕控制器（核心修复：直接调用扩展方法）
  void _initDanmaku() {
    danmakuController = DanmakuController(
      onAddDanmaku: (item) {},
      onUpdateOption: (option) {},
      onPause: () {},
      onResume: () {},
      onClear: () {},
    );
    // 直接调用扩展方法（扩展方法已添加到 VideoController 类）
    initDanmakuPersistence();
  }

  /// 初始化基础配置
  void _initBaseConfig() {
    videoFit.value = settings.videofitArrary[settings.videoFitIndex.value];
    qualityCurrentIndex.value = currentQuality;
    lineCurrentIndex.value = currentLineIndex;
    beforePlayNodeIndex.value = settings.currentPlayListNodeIndex.value;
  }

  void changeLineIndex(int index) {
    changeLine(index);
  }

  /// 初始化滚动控制器
  void _initScroll() {
    scrollController = ScrollController();
    scrollController.addListener(() {
      if (showPlayListPanel.value) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          scrollToIndex(beforePlayNodeIndex.value);
        });
      }
    });
  }

  /// 初始化事件监听
  void _initListeners() {
    // 控制器显示状态监听
    showController.listen((show) {
      if (show) showChangeNameFlag.value = false;
    });

    // 画质面板监听
    showQualityPanel.listen((show) {
      if (show) {
        // 直接调用扩展方法
        hideAllPanelsExcept(PanelType.quality);
      } else {
        disableController();
      }
    });
    showLinePanel.listen((show) {
      if (show) {
        // 直接调用扩展方法
        hideAllPanelsExcept(PanelType.lines);
      } else {
        disableController();
      }
    });

    // 设置面板监听
    showSettting.listen((show) {
      if (show) {
        // 直接调用扩展方法
        hideAllPanelsExcept(PanelType.settings);
      } else {
        disableController();
      }
    });

    // 播放列表面板监听
    showPlayListPanel.listen((show) {
      if (show) {
        // 直接调用扩展方法
        hideAllPanelsExcept(PanelType.playlist);
        scrollToIndex(beforePlayNodeIndex.value);
      } else {
        beforePlayNodeIndex.value = settings.currentPlayListNodeIndex.value;
        disableController();
      }
    });

    // 播放列表索引监听
    beforePlayNodeIndex.listen((index) {
      if (showPlayListPanel.value) scrollToIndex(index);
    });

    // 底部按钮索引监听
    currentNodeIndex.listen((index) {
      currentBottomClickType.value = BottomButtonClickType.values[index];
      log("currentBottomClickType: ${currentBottomClickType.value.toString()}");
    });

    // 弹幕设置索引监听
    danmukuNodeIndex.listen((index) {
      currentDanmakuClickType.value = DanmakuSettingClickType.values[index];
    });
  }

  /// 初始化播放器
  void _initPlayer() {
    globalPlayer.setDataSource(datasource, playUrls, headers);
  }

  /// 初始化订阅
  void _initSubscriptions() {
    // 播放器错误监听
    _errorSub = globalPlayer.onError.listen((error) {
      if (error != null && error.contains("Failed to open")) {
        SmartDialog.showToast("当前视频播放出错,请刷新后重试");
      }
    });
  }

  /// 初始化名称显示定时器
  void _initNameTimer() {
    showChangeNameTimer = Timer(VideoConstants.showNameDuration, () {
      showChangeNameFlag.value = false;
      showChangeNameTimer?.cancel();
    });
  }

  // ==================== 核心业务方法 ====================
  /// 刷新播放
  Future<void> refresh() async {
    _handlePlayerReload(() => livePlayController.onInitPlayerState(reloadDataType: ReloadDataType.refreash));
  }

  /// 切换播放线路
  Future<void> changeLine(int index) async {
    _handlePlayerReload(
      () => livePlayController.onInitPlayerState(reloadDataType: ReloadDataType.changeLine, line: index),
    );
    showLinePanel.value = false;
  }

  /// 切换画质
  Future<void> changeQuality(int qualityIndex) async {
    _handlePlayerReload(
      () => livePlayController.onInitPlayerState(
        reloadDataType: ReloadDataType.changeQuality,
        line: currentLineIndex,
        currentQuality: qualityIndex,
        isReCalculate: false,
      ),
    );
    showQualityPanel.value = false;
  }

  /// 设置视频适配模式
  void setVideoFit() {
    int index = settings.videoFitIndex.value;
    index = (index + 1) % settings.videofitArrary.length;
    settings.videoFitIndex.value = index;
    globalPlayer.changeVideoFit(index);
    videoFit.value = settings.videofitArrary[index];
  }

  /// 播放/暂停切换
  void togglePlayPause() => globalPlayer.togglePlayPause();

  /// 上一个频道
  void prevPlayChannel() => _switchChannel(livePlayController.prevChannel);

  /// 下一个频道
  void nextPlayChannel() => _switchChannel(livePlayController.nextChannel);

  /// 播放收藏频道
  void playFavoriteChannel() {
    _resetNameTimer();
    livePlayController.playFavoriteChannel();
  }

  /// 节流函数
  void throttle(Function() func, [int delay = 100]) {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _currentTimeStamp > delay) {
      _currentTimeStamp = now;
      func.call();
    }
  }

  // ==================== 私有工具方法 ====================
  /// 处理播放器重载
  Future<void> _handlePlayerReload(VoidCallback reloadAction) async {
    isLoading.value = true;
    await destroy();
    reloadAction();
  }

  /// 切换频道通用逻辑
  void _switchChannel(VoidCallback switchAction) {
    globalPlayer.pause();
    isLoading.value = true;
    _resetNameTimer();
    switchAction();
  }

  /// 重置名称定时器
  void _resetNameTimer() {
    showChangeNameFlag.value = true;
    showChangeNameTimer?.cancel();
    showChangeNameTimer = Timer(VideoConstants.showNameDuration, () {
      showChangeNameFlag.value = false;
      showChangeNameTimer?.cancel();
    });
  }

  // ==================== 对外暴露的通用方法（直接调用扩展方法） ====================
  /// 滚动到指定索引
  void scrollToIndex(int index) {
    scrollToIndexInternal(index);
  }

  /// 显示控制器
  void enableController() {
    enableControllerInternal();
  }

  /// 隐藏控制器
  void disableController() {
    disableControllerInternal();
  }

  /// 取消底部按钮焦点
  void cancelFocus() {
    cancelFocusInternal();
  }

  /// 取消弹幕焦点
  void cancelDanmakuFocus() {
    cancelDanmakuFocusInternal();
  }

  /// 处理键盘事件（对外入口）
  void onKeyEvent(KeyEvent key) {
    handleKeyEventExternal(key);
  }

  /// 设置弹幕控制器
  void setDanmukuController(DanmakuController controller) {
    danmakuController = controller;
  }

  // ==================== 资源释放 ====================
  /// 销毁控制器资源
  Future<void> destroy() async {
    // 取消焦点
    cancelFocus();
    cancelDanmakuFocus();

    // 重置播放状态
    livePlayController.success.value = false;

    // 停止播放器
    globalPlayer.stop();

    // 取消订阅
    await _errorSub.cancel();

    // 取消所有定时器
    showControllerTimer?.cancel();
    showChangeNameTimer?.cancel();
    doubleClickTimer?.cancel();

    // 释放滚动控制器
    scrollController.dispose();
  }

  /// 生命周期释放
  @override
  void dispose() async {
    await destroy();
    super.dispose();
  }
}
