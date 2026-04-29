import 'dart:io';
import 'dart:async';
import 'dart:convert';
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
import 'package:network_info_plus/network_info_plus.dart';
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
  final RxBool showQrCodePanel = false.obs;
  final RxString serverIp = "".obs;
  NetworkInfo networkInfo = NetworkInfo();
  HttpServer? _server;
  final Set<WebSocket> _clients = {};
  final RxString fullServerUrl = "".obs;
  final shieldFocusNodes = <AppFocusNode>[].obs;
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

    _startUnifiedServer();

    ever(settings.shieldList, (_) => syncFocusNodes());
    syncFocusNodes(); // 初始同步焦点节点
  }

  void syncFocusNodes() {
    int dataLen = settings.shieldList.length;
    int nodeLen = shieldFocusNodes.length;

    if (nodeLen < dataLen) {
      // 补充缺少的 Node
      for (int i = 0; i < dataLen - nodeLen; i++) {
        shieldFocusNodes.add(AppFocusNode());
      }
    } else if (nodeLen > dataLen) {
      // 移除多余的 Node 并销毁
      for (int i = 0; i < nodeLen - dataLen; i++) {
        shieldFocusNodes.removeLast().dispose();
      }
    }
    if (shieldFocusNodes.isNotEmpty) {
      shieldFocusNodes.first.requestFocus();
    }
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

    showQrCodePanel.listen((show) {
      if (show) {
        hideAllPanelsExcept(PanelType.qrCode);
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
    _errorSub = globalPlayer.onError.listen((error) async {
      if (error == null || error.isEmpty) return;

      log('Player Error Caught: $error', name: 'VideoController');

      // 1. 处理硬件解码失败 (ExoPlayer 专属错误)
      if (error.contains("ExoPlaybackException") ||
          error.contains("NO_EXCEEDS_CAPABILITIES") ||
          error.contains("MediaCodecVideoRenderer")) {
        SmartDialog.showToast("硬件解码失败，正在尝试切换引擎...");
        // 延迟一小会儿执行，防止 UI 渲染冲突
        await destroy();
        await Future.delayed(const Duration(milliseconds: 500));
        await SwitchableGlobalPlayer().switchEngine(PlayerEngine.values[settings.useFallbackPlayer.value]);
        await Future.delayed(const Duration(milliseconds: 800));
        log('Player Error Caught: $error', name: 'refresh');
        refresh();
        return;
      }

      // 2. 处理无法打开资源 (通用错误)
      if (error.contains("Failed to open") || error.contains("IO_ERROR")) {
        SmartDialog.showToast("当前线路连接失败，请刷新后重试");
        return;
      }

      // 3. 其他未知错误
      log("Unhandled Player Error: $error");
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

  void showShieldSetting() {
    showQrCodePanel.value = true;
  }

  void _startUnifiedServer() async {
    try {
      final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
      final ip = interfaces.firstWhere((i) => !i.name.contains('lo')).addresses.first.address;

      _server = await HttpServer.bind(InternetAddress.anyIPv4, 8888);
      fullServerUrl.value = "http://$ip:8888";

      _server!.listen((HttpRequest request) async {
        // 1. Handle WebSocket Upgrade
        if (WebSocketTransformer.isUpgradeRequest(request)) {
          WebSocket socket = await WebSocketTransformer.upgrade(request);
          _clients.add(socket);
          // Send initial list to phone
          socket.add(jsonEncode({"type": "init", "data": settings.shieldList.value}));

          socket.listen((msg) => _handleWsMessage(msg), onDone: () => _clients.remove(socket));
          return;
        }

        // 2. Handle Web Remote (GET)
        if (request.method == 'GET') {
          request.response
            ..headers.contentType = ContentType.html
            ..write(_buildRemoteHtml())
            ..close();
        }
      });
    } catch (e) {
      debugPrint("Server Error: $e");
    }
  }

  void stopServer() async {
    try {
      // 1. Close all active WebSocket clients first
      for (var client in _clients) {
        await client.close(WebSocketStatus.goingAway, "Server shutting down");
      }
      _clients.clear();

      if (_server != null) {
        await _server!.close(force: true);
        _server = null;
        fullServerUrl.value = "";
        debugPrint("Server stopped successfully.");
      }
    } catch (e) {
      debugPrint("Error stopping server: $e");
    }
  }

  void removeShieldWord(String word) {
    settings.shieldList.remove(word);
    settings.shieldList.value = List.from(settings.shieldList); // 触发更新
    _broadcastList();
  }

  void _handleWsMessage(dynamic message) {
    final data = jsonDecode(message);
    final String action = data['action'];
    final String value = data['value'];

    if (action == 'add' && !settings.shieldList.contains(value)) {
      settings.shieldList.add(value);
    } else if (action == 'delete') {
      settings.shieldList.remove(value);
    }
    settings.shieldList.value = List.from(settings.shieldList); // 触发更新
    _broadcastList();
  }

  void _broadcastList() {
    final msg = jsonEncode({"type": "update", "data": settings.shieldList});
    for (var client in _clients) {
      client.add(msg);
    }
  }

  String _buildRemoteHtml() {
    return '''
  <!DOCTYPE html>
  <html>
  <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <title>PureLive 远程同步</title>
    <style>
      body { font-family: -apple-system, system-ui; padding: 20px; background: #f4f4f9; color: #333; }
      .card { background: white; padding: 20px; border-radius: 12px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); margin-bottom: 20px; }
      h2 { margin-top: 0; font-size: 20px; display: flex; align-items: center; justify-content: space-between; }
      
      /* 状态小点 */
      .status { font-size: 12px; font-weight: normal; color: #ff3b30; display: flex; align-items: center; }
      .status.online { color: #34c759; }
      .dot { width: 8px; height: 8px; background: currentColor; border-radius: 50%; margin-right: 5px; }

      .input-group { display: flex; gap: 10px; margin: 15px 0; }
      input { flex: 1; padding: 12px; border: 1px solid #ddd; border-radius: 8px; font-size: 16px; outline: none; }
      
      button { padding: 12px 20px; background: #007AFF; color: white; border: none; border-radius: 8px; font-size: 16px; font-weight: bold; cursor: pointer; }
      button:active { background: #0056b3; }

      /* 屏蔽词标签布局 */
      #list { display: flex; flex-wrap: wrap; gap: 8px; margin-top: 10px; }
      .tag { background: #f0f0f5; padding: 8px 12px; border-radius: 20px; font-size: 14px; display: flex; align-items: center; color: #555; border: 1px solid #e1e1e6; }
      .tag b { margin-left: 8px; color: #ff3b30; cursor: pointer; font-size: 18px; }
    </style>
  </head>
  <body>
    <div class="card">
      <h2>
        屏蔽词同步
        <div id="status" class="status"><span class="dot"></span><span id="stateText">未连接</span></div>
      </h2>
      <p style="color: #666; font-size: 14px;">在下方添加屏蔽词，电视端将实时同步：</p>
      <div class="input-group">
        <input type="text" id="ipt" placeholder="输入内容...">
        <button onclick="send('add')">添加</button>
      </div>
      <div id="list"></div>
    </div>

    <script>
      let ws;
      const statusDiv = document.getElementById('status');
      const stateText = document.getElementById('stateText');
      const listDiv = document.getElementById('list');

      function connect() {
        ws = new WebSocket('ws://' + location.host);
        
        ws.onopen = () => {
          statusDiv.className = 'status online';
          stateText.innerText = '已连接';
        };

        ws.onclose = () => {
          statusDiv.className = 'status';
          stateText.innerText = '已断开';
          setTimeout(connect, 2000); // 自动重连
        };

        ws.onmessage = (e) => {
          const msg = JSON.parse(e.data);
          if (msg.type === 'init' || msg.type === 'update') {
            render(msg.data);
          }
        };
      }

      function render(data) {
        listDiv.innerHTML = data.map(i => `
          <div class="tag">
            \${i}
            <b onclick="send('delete', '\${i}')">×</b>
          </div>
        `).join('');
      }

      function send(action, val) {
        const value = val || document.getElementById('ipt').value.trim();
        if(!value) return;
        ws.send(JSON.stringify({ action, value }));
        if(!val) document.getElementById('ipt').value = '';
      }

      connect();
    </script>
  </body>
  </html>
  ''';
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
    for (var node in shieldFocusNodes) {
      node.dispose();
    }
    stopServer();
    livePlayController.liveDanmaku.stop();
    // 重置播放状态
    livePlayController.success.value = false;

    // 取消订阅
    await _errorSub.cancel();
    // 停止播放器
    globalPlayer.stop();

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
