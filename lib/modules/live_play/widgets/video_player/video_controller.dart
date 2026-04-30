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
import 'package:pure_live/player/models/player_exception.dart';
import 'package:pure_live/player/models/player_error_type.dart';
import 'package:pure_live/pkg/canvas_danmaku/danmaku_controller.dart';
import 'package:pure_live/modules/live_play/live_play_controller.dart';

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
  late StreamSubscription<PlayerException> _errorSub;

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
  final selectedShieldIndex = 0.obs;
  final ScrollController shieldScrollController = ScrollController();
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
    initPlayerListener();
    // 初始化名称定时器
    _initNameTimer();

    _startUnifiedServer();

    ever(selectedShieldIndex, (int index) {
      _scrollToIndex(index);
    });
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
    GlobalPlayerService.instance.playerManager.play(datasource, playUrls, headers);
  }

  void initPlayerListener() {
    final manager = GlobalPlayerService.instance.playerManager;
    _errorSub = manager.onError.listen((error) {
      _handlePlayerError(error);
    });
  }

  void _scrollToIndex(int index) {
    if (!shieldScrollController.hasClients) return;

    double itemHeight = 60.h;
    int itemsPerRow = 3;

    double targetOffset = (index / itemsPerRow).floor() * itemHeight;

    shieldScrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
  }

  void _handlePlayerError(PlayerException error) {
    log(error.toString(), name: 'PlayerError');
    switch (error.type) {
      // =====================
      // 网络错误
      // =====================
      case PlayerErrorType.network:
        ToastUtil.show('网络连接失败');
        break;
      // =====================
      // 播放源错误
      // =====================
      case PlayerErrorType.source:
        ToastUtil.show('播放源异常');
        break;
      // =====================
      // 解码错误
      // =====================
      case PlayerErrorType.codec:
        ToastUtil.show('当前播放器解码失败');
        break;
      // =====================
      // native 崩溃
      // =====================
      case PlayerErrorType.native:
        ToastUtil.show('播放器异常');
        break;
      // =====================
      // 初始化失败
      // =====================
      case PlayerErrorType.initialization:
        ToastUtil.show('播放器初始化失败');
        break;
      // =====================
      // texture 错误
      // =====================
      case PlayerErrorType.texture:
        ToastUtil.show('视频渲染失败');
        break;
      // =====================
      // 生命周期错误
      // =====================
      case PlayerErrorType.lifecycle:
        ToastUtil.show('播放器状态异常');
        break;
      // =====================
      // 未知错误
      // =====================
      case PlayerErrorType.unknown:
        ToastUtil.show('未知播放错误');

        break;
    }
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
    videoFit.value = settings.videofitArrary[index];
  }

  void showShieldSetting() {
    showQrCodePanel.value = true;
  }

  // 这里的 port 默认为 8888
  void _startUnifiedServer({int port = 8888}) async {
    try {
      final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
      // 增加安全判断，防止网络未连接时崩溃
      if (interfaces.isEmpty) {
        debugPrint("No network interfaces found");
        return;
      }
      final ip = interfaces.firstWhere((i) => !i.name.contains('lo')).addresses.first.address;

      // 尝试绑定端口
      _server = await HttpServer.bind(InternetAddress.anyIPv4, port);

      // 成功绑定后更新 URL
      fullServerUrl.value = "http://$ip:$port";
      debugPrint("Server started on: ${fullServerUrl.value}");

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
      // 如果是端口占用错误，递归尝试 port + 1
      if (e.toString().contains("Address already in use")) {
        debugPrint("Port $port is in use, trying ${port + 1}...");
        _startUnifiedServer(port: port + 1);
      } else {
        debugPrint("Server Error: $e");
      }
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
<html lang="zh-CN">
<head>
  <meta charset="UTF-8">
  <!-- shrink-to-fit=no 解决夸克等浏览器的缩放问题 -->
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, shrink-to-fit=no, viewport-fit=cover">
  <title>PureLive 远程同步</title>
  <style>
    :root { 
      --primary: #007AFF; 
      --danger: #ff3b30; 
      --bg: #f4f4f9; 
    }
    
    * { 
      box-sizing: border-box; 
      -webkit-tap-highlight-color: transparent; 
    }
    
    html, body {
      /* 核心修复：禁止浏览器自动调整文字大小，解决夸克显示过小问题 */
      -webkit-text-size-adjust: 100%;
      text-size-adjust: 100%;
    }

    body { 
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; 
      margin: 0; 
      padding: env(safe-area-inset-top) 15px env(safe-area-inset-bottom); 
      background: var(--bg); 
      color: #333; 
      /* 确保基础字号在小屏设备上清晰可见 */
      font-size: 16px; 
      line-height: 1.5;
    }

    .container { 
      max-width: 500px; 
      margin: 15px auto; 
    }

    .card { 
      background: white; 
      padding: 20px; 
      border-radius: 16px; 
      box-shadow: 0 8px 20px rgba(0,0,0,0.06); 
    }

    h2 { 
      margin: 0 0 12px; 
      font-size: 20px; 
      display: flex; 
      align-items: center; 
      justify-content: space-between; 
    }
    
    .status { font-size: 14px; color: #999; display: flex; align-items: center; }
    .status.online { color: #34c759; font-weight: bold; }
    .dot { width: 8px; height: 8px; background: currentColor; border-radius: 50%; margin-right: 6px; }

    .input-group { 
      display: flex; 
      gap: 8px; 
      margin: 20px 0; 
    }
    
    input { 
      flex: 1; 
      padding: 12px; 
      border: 2px solid #eee; 
      border-radius: 10px; 
      /* 强制设置最小字号，防止 iOS 输入时自动放大 */
      font-size: 16px; 
      outline: none; 
      transition: border-color 0.2s;
      -webkit-appearance: none;
    }
    input:focus { border-color: var(--primary); }
    
    button { 
      padding: 12px 20px; 
      background: var(--primary); 
      color: white; 
      border: none; 
      border-radius: 10px; 
      font-size: 16px; 
      font-weight: 600; 
      cursor: pointer; 
      white-space: nowrap;
    }
    button:active { opacity: 0.7; transform: scale(0.96); }

    #list { 
      display: flex; 
      flex-wrap: wrap; 
      gap: 10px; 
    }
    
    .tag { 
      background: #f2f2f7; 
      padding: 6px 14px; 
      border-radius: 20px; 
      font-size: 15px; 
      display: flex; 
      align-items: center; 
      color: #444; 
      border: 1px solid #e5e5ea;
      animation: pop 0.25s ease-out;
    }
    
    .tag b { 
      margin-left: 8px; 
      color: var(--danger); 
      cursor: pointer; 
      font-size: 18px; 
      line-height: 1;
      padding: 2px;
    }

    @keyframes pop {
      0% { transform: scale(0.8); opacity: 0; }
      100% { transform: scale(1); opacity: 1; }
    }
    
    @media (max-width: 380px) {
      h2 { font-size: 18px; }
      .input-group { flex-direction: column; }
      button { width: 100%; }
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="card">
      <h2>
        屏蔽词同步
        <div id="status" class="status"><span class="dot"></span><span id="stateText">未连接</span></div>
      </h2>
      <p style="color: #666; font-size: 14px; margin-bottom: 10px;">添加词条后，电视端将立即实时同步：</p>
      <div class="input-group">
        <input type="text" id="ipt" placeholder="输入屏蔽词..." autocomplete="off">
        <button onclick="send('add')">添加</button>
      </div>
      <div id="list"></div>
    </div>
  </div>

  <script>
    let ws;
    const statusDiv = document.getElementById('status');
    const stateText = document.getElementById('stateText');
    const listDiv = document.getElementById('list');
    const ipt = document.getElementById('ipt');

    function connect() {
      // 适配不同环境的 WebSocket 协议
      const protocol = location.protocol === 'https:' ? 'wss://' : 'ws://';
      ws = new WebSocket(protocol + location.host);
      
      ws.onopen = () => { statusDiv.className = 'status online'; stateText.innerText = '已连接'; };
      ws.onclose = () => { statusDiv.className = 'status'; stateText.innerText = '已断开'; setTimeout(connect, 2000); };
      ws.onmessage = (e) => {
        try {
          const msg = JSON.parse(e.data);
          if (msg.type === 'init' || msg.type === 'update') render(msg.data);
        } catch(err) { console.error("Data error", err); }
      };
    }

    function render(data) {
      if (!data) return;
      listDiv.innerHTML = data.map(i => `
        <div class="tag">
          \${i}
          <b onclick="send('delete', '\${i}')">×</b>
        </div>
      `).join('');
    }

    function send(action, val) {
      const value = val || ipt.value.trim();
      if(!value) return;
      if(ws && ws.readyState === WebSocket.OPEN) {
        ws.send(JSON.stringify({ action, value }));
        if(!val) ipt.value = '';
      } else {
        alert("连接已断开，请刷新页面");
      }
    }

    // 监听键盘回车
    ipt.addEventListener('keypress', (e) => { if(e.key === 'Enter') send('add'); });
    
    connect();
  </script>
</body>
</html>
  ''';
  }

  /// 播放/暂停切换
  void togglePlayPause() => GlobalPlayerService.instance.playerManager.togglePlayPause();

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
    GlobalPlayerService.instance.playerManager.close();
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
    stopServer();
    livePlayController.liveDanmaku.stop();
    // 重置播放状态
    livePlayController.success.value = false;

    // 取消订阅
    await _errorSub.cancel();
    // 停止播放器
    GlobalPlayerService.instance.playerManager.close();

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
