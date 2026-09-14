import 'dart:async';
import 'dart:developer';

import 'package:flame_barrage/flame_barrage.dart';
import 'package:flutter/painting.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:pure_live/exports/common_export.dart';
import 'package:pure_live/player/index.dart';
import 'package:pure_live/features/live_play/controllers/danmaku_filters.dart';
import 'package:pure_live/features/live_play/models/live_play_args.dart';
import 'package:pure_live/features/live_play/services/live_play_repository.dart';
import 'package:pure_live/features/live_play/states/live_play_state.dart';
import 'package:pure_live/services/settings/settings.dart';

part 'live_play_controller.g.dart';

/// 画面比例选项（与 PlayerManager.changeVideoFit 的索引语义对齐）。
const List<BoxFit> kLivePlayFitList = [BoxFit.contain, BoxFit.cover, BoxFit.fill, BoxFit.fitHeight, BoxFit.fitWidth];

const List<String> kLivePlayFitLabels = ['包含', '裁剪', '拉伸', '适配高', '适配宽'];

/// Drives one live room: room detail, quality list and stream URLs feed
/// [PlayerManager], while player streams are projected into UI state.
///
/// Responsibilities:
/// - enter a room and start playback through PlayerManager
/// - mirror buffering/playing/paused/error states into the page state
/// - quality and line switching, retry, pause, volume, video fit
/// - danmaku sessions live in [DanmakuSessionController]
@riverpod
class LivePlayController extends _$LivePlayController {
  static const LivePlayRepository _repository = LivePlayRepository();

  PlayerManager? _playerManager;
  final List<StreamSubscription<dynamic>> _subscriptions = <StreamSubscription<dynamic>>[];

  /// 异步引导代际：重试/重建后丢弃过期的异步回调。
  int _generation = 0;

  @override
  LivePlayState build(LivePlayArgs args) {
    ref.onDispose(_teardown);
    // 向站点层注册当前房间查询（房间详情的观众数/错误回退需要）
    Sites.currentRoomLookup = (platform, roomId) {
      final room = state.room;
      return (room != null && room.platform == platform && room.roomId == roomId) ? room : null;
    };
    unawaited(_bootstrap());
    return const LivePlayState(status: LivePlayStatus.loadingDetail);
  }

  // =========================
  // bootstrap / teardown
  // =========================

  Future<void> _bootstrap() async {
    final generation = ++_generation;
    state = state.copyWith(status: LivePlayStatus.loadingDetail, clearDetailError: true, clearErrorMessage: true);

    try {
      await GlobalPlayerService.instance.initialize();
    } catch (e, s) {
      log('GlobalPlayerService initialize failed: $e', name: 'LivePlayController', error: e, stackTrace: s);
    }
    if (!_isCurrent(generation)) return;

    _playerManager = GlobalPlayerService.instance.playerManager;
    _bindPlayerStreams();

    // 房间详情：入口携带的 LiveRoom 仅作为平台/房间号提示，结果以站点详情为准。
    LiveRoom detail;
    try {
      detail = await _repository.fetchRoomDetail(hintRoom: args.room ?? _hintRoom());
    } catch (e) {
      if (!_isCurrent(generation)) return;
      state = state.copyWith(
        status: LivePlayStatus.error,
        detailError: '获取房间信息失败: $e',
        errorMessage: '获取房间信息失败',
      );
      return;
    }
    if (!_isCurrent(generation)) return;

    state = state.copyWith(room: detail, clearDetailError: true);
    // 展示层音量与房间记忆音量对齐（PlayerManager 起播时会恢复同一值）。
    state = state.copyWith(volume: detail.getSavedVolume().clamp(0.0, 1.0).toDouble());
    unawaited(ref.read(danmakuSessionControllerProvider(args).notifier).connectRoom(detail));

    await loadQualitiesAndPlay(detail, generation);
  }

  LiveRoom _hintRoom() => LiveRoom(roomId: args.roomId, platform: args.platform);

  bool _isCurrent(int generation) => ref.mounted && generation == _generation;

  void _bindPlayerStreams() {
    final manager = _playerManager;
    if (manager == null) return;
    _cancelSubscriptions();
    _subscriptions.addAll(<StreamSubscription<dynamic>>[
      manager.onStateChanged.listen(_onPlayerStateChanged),
      manager.onError.listen(_onPlayerError),
      manager.videoFitIndex.stream.listen((index) {
        if (index != state.fitIndex) state = state.copyWith(fitIndex: index);
      }),
    ]);
  }

  void _onPlayerStateChanged(PlayerState playerState) {
    if (!ref.mounted) return;
    switch (playerState) {
      case PlayerState.ready:
      case PlayerState.playing:
        state = state.copyWith(status: LivePlayStatus.playing, clearErrorMessage: true);
        break;
      case PlayerState.buffering:
      case PlayerState.preparing:
      case PlayerState.initializing:
        if (state.status != LivePlayStatus.error) {
          state = state.copyWith(status: LivePlayStatus.buffering);
        }
        break;
      case PlayerState.paused:
        if (state.status != LivePlayStatus.error) {
          state = state.copyWith(status: LivePlayStatus.paused);
        }
        break;
      case PlayerState.error:
        // 终态错误由 onError 带出，这里仅兜底。
        state = state.copyWith(status: LivePlayStatus.error, errorMessage: '播放失败');
        break;
      case PlayerState.idle:
      case PlayerState.initialized:
      case PlayerState.completed:
      case PlayerState.stopped:
      case PlayerState.disposed:
        break;
    }
  }

  void _onPlayerError(PlayerException error) {
    if (!ref.mounted) return;
    state = state.copyWith(status: LivePlayStatus.error, errorMessage: error.message);
  }

  void _teardown() {
    _generation++;
    _cancelSubscriptions();
    final manager = _playerManager;
    _playerManager = null;
    if (manager != null) {
      // PlayerManager 是全局单例：离开房间时停止本次播放会话。
      unawaited(manager.close().catchError((Object e, StackTrace s) {}));
    }
  }

  void _cancelSubscriptions() {
    if (_subscriptions.isEmpty) return;
    final list = List<StreamSubscription<dynamic>>.of(_subscriptions);
    _subscriptions.clear();
    for (final sub in list) {
      unawaited(sub.cancel().catchError((Object e, StackTrace s) {}));
    }
  }

  // =========================
  // stream loading
  // =========================

  Future<void> loadQualitiesAndPlay(LiveRoom detail, int generation) async {
    state = state.copyWith(status: LivePlayStatus.preparing);
    final qualities = await _repository.fetchPlayQualities(detail);
    if (!_isCurrent(generation)) return;

    if (qualities.isEmpty) {
      state = state.copyWith(
        qualities: const <LivePlayQuality>[],
        qualityIndex: 0,
        status: LivePlayStatus.error,
        errorMessage: '该房间暂无可用清晰度',
      );
      return;
    }

    final preferredIndex = _resolvePreferredQualityIndex(qualities);
    state = state.copyWith(qualities: qualities, qualityIndex: preferredIndex);
    await _openStream(qualities[preferredIndex], generation);
  }

  int _resolvePreferredQualityIndex(List<LivePlayQuality> qualities) {
    // Prefer the preferred resolution label; otherwise fall back to the highest bitrate.
    final prefer = SettingsService.to.playerState.preferResolution;
    if (prefer.isNotEmpty) {
      final index = qualities.indexWhere((q) => q.quality.contains(prefer));
      if (index != -1) return index;
    }
    var best = 0;
    for (var i = 1; i < qualities.length; i++) {
      if (qualities[i].sort > qualities[best].sort) best = i;
    }
    return best;
  }

  Future<void> _openStream(LivePlayQuality quality, int generation) async {
    final detail = state.room;
    final manager = _playerManager;
    if (detail == null || manager == null) return;

    state = state.copyWith(status: LivePlayStatus.preparing, clearErrorMessage: true);
    List<String> urls;
    try {
      urls = await _repository.fetchPlayUrls(detail, quality);
    } catch (e) {
      if (!_isCurrent(generation)) return;
      state = state.copyWith(status: LivePlayStatus.error, errorMessage: '获取播放地址失败: $e');
      return;
    }
    if (!_isCurrent(generation)) return;

    urls = urls.where((u) => u.trim().isNotEmpty).toList(growable: false);
    if (urls.isEmpty) {
      state = state.copyWith(status: LivePlayStatus.error, errorMessage: '该清晰度下没有可用的播放线路');
      return;
    }

    state = state.copyWith(playUrls: urls, lineIndex: 0);
    try {
      await manager.play(urls.first, urls, const <String, String>{}, room: detail);
    } on ArgumentError catch (e) {
      if (!_isCurrent(generation)) return;
      state = state.copyWith(status: LivePlayStatus.error, errorMessage: e.message ?? '起播参数错误');
    } catch (e) {
      if (!_isCurrent(generation)) return;
      state = state.copyWith(status: LivePlayStatus.error, errorMessage: '起播失败: $e');
    }
  }

  // =========================
  // user commands
  // =========================

  Future<void> changeQuality(int index) async {
    if (index < 0 || index >= state.qualities.length || index == state.qualityIndex) return;
    final generation = ++_generation;
    state = state.copyWith(qualityIndex: index);
    await _openStream(state.qualities[index], generation);
  }

  Future<void> changeLine(int index) async {
    if (index < 0 || index >= state.playUrls.length || index == state.lineIndex) return;
    final manager = _playerManager;
    if (manager == null) return;
    final urls = state.playUrls;
    state = state.copyWith(lineIndex: index, status: LivePlayStatus.preparing, clearErrorMessage: true);
    try {
      await manager.play(urls[index], urls, const <String, String>{}, room: state.room);
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(status: LivePlayStatus.error, errorMessage: '切换线路失败: $e');
    }
  }

  Future<void> togglePlayPause() async {
    final manager = _playerManager;
    if (manager == null) return;
    await manager.togglePlayPause();
  }

  Future<void> retry() async {
    final manager = _playerManager;
    if (manager == null || !manager.initialized) {
      await _bootstrap();
      return;
    }
    state = state.copyWith(status: LivePlayStatus.preparing, clearErrorMessage: true);
    try {
      await manager.retry();
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(status: LivePlayStatus.error, errorMessage: '重试失败: $e');
    }
  }

  /// 重新拉取房间详情与线路并起播（用于长时间离线后的完整刷新）。
  Future<void> refreshRoom() async {
    _generation++;
    _cancelSubscriptions();
    await _bootstrap();
  }

  void cycleFit() {
    final next = (state.fitIndex + 1) % kLivePlayFitList.length;
    state = state.copyWith(fitIndex: next);
    _playerManager?.changeVideoFit(next);
  }

  Future<void> setVolume(double volume) async {
    final clamped = volume.clamp(0.0, 1.0).toDouble();
    state = state.copyWith(volume: clamped);
    await _playerManager?.setVolume(clamped);
    final room = state.room;
    if (room != null) {
      unawaited(room.saveCurrentVolume(clamped).catchError((Object e, StackTrace s) {}));
    }
  }

  Future<void> volumeUp() => setVolume(state.volume + 0.1);

  Future<void> volumeDown() => setVolume(state.volume - 0.1);

  // =========================
  // controls visibility (TV auto-hide)
  // =========================

  Timer? _controlsHideTimer;

  void showControls() {
    state = state.copyWith(showControls: true);
    _armControlsHide();
  }

  void toggleControls() {
    if (state.showControls) {
      _dismissControls();
    } else {
      showControls();
    }
  }

  void keepControlsAlive() => _armControlsHide();

  void toggleSidePanel() {
    state = state.copyWith(showSidePanel: !state.showSidePanel);
  }

  void _armControlsHide() {
    _controlsHideTimer?.cancel();
    _controlsHideTimer = Timer(const Duration(seconds: 5), _dismissControls);
  }

  void _dismissControls() {
    _controlsHideTimer?.cancel();
    _controlsHideTimer = null;
    if (ref.mounted) {
      state = state.copyWith(showControls: false);
    }
  }
}

/// Danmaku session for one room: owns the transport connection, message
/// gating and duplicate filtering, and fans messages out to the overlay and
/// the list view. Filter thresholds come from the global danmaku settings.
@riverpod
class DanmakuSessionController extends _$DanmakuSessionController {
  final DanmakuMessageGate _messageGate = DanmakuMessageGate();
  final RepeatedDanmakuFilter _repeatedFilter = RepeatedDanmakuFilter();
  final DanmakuSimilarityFilter _similarityFilter = DanmakuSimilarityFilter();

  LiveDanmaku? _engine;
  int _sessionToken = 0;

  @override
  DanmakuSessionState build(LivePlayArgs args) {
    ref.onDispose(_teardown);
    return DanmakuSessionState(barrageController: BarrageController());
  }

  Future<void> connectRoom(LiveRoom room) async {
    final token = ++_sessionToken;
    final controller = state.barrageController;

    // 断开旧会话并清空渲染层，避免旧房间包串台。
    final oldEngine = _engine;
    _engine = null;
    if (oldEngine != null) {
      oldEngine.onMessage = null;
      oldEngine.onClose = null;
      unawaited(oldEngine.stop().catchError((Object e, StackTrace s) {}));
    }
    _messageGate.clear();
    _repeatedFilter.clear();
    _similarityFilter.clear();
    controller.clear();
    state = state.copyWith(messages: const <LiveMessage>[], connected: false, statusText: '连接弹幕服务器...');

    LiveDanmaku engine;
    try {
      engine = _repository.createDanmaku(room);
    } catch (e) {
      if (token == _sessionToken && ref.mounted) {
        state = state.copyWith(statusText: '弹幕不可用');
      }
      return;
    }

    _engine = engine;
    engine.onMessage = (msg) => _acceptMessage(msg, token);
    engine.onClose = (msg) {
      if (token == _sessionToken && ref.mounted) {
        state = state.copyWith(connected: false, statusText: '弹幕连接已断开');
      }
    };

    try {
      await engine.start(room.danmakuData).timeout(const Duration(seconds: 20));
    } on TimeoutException {
      if (token == _sessionToken && ref.mounted) {
        state = state.copyWith(connected: false, statusText: '弹幕连接超时');
      }
      return;
    } catch (e) {
      if (token == _sessionToken && ref.mounted) {
        state = state.copyWith(connected: false, statusText: '弹幕连接失败');
      }
      return;
    }

    if (token == _sessionToken && ref.mounted) {
      state = state.copyWith(connected: engine.isConnected, statusText: null);
    }
  }

  static const LivePlayRepository _repository = LivePlayRepository();

  void _acceptMessage(LiveMessage message, int token) {
    if (token != _sessionToken || !ref.mounted) return;
    // 弹幕层只关心聊天消息；礼物/进场等消息仅进列表视图。
    if (message.type != LiveMessageType.chat) return;
    if (!_messageGate.accepts(message)) return;

    final danmakuSettings = SettingsService.to.danmakuState;
    if (!_repeatedFilter.accepts(
      message,
      enabled: danmakuSettings.collapseRepeatedDanmaku,
      window: Duration(seconds: danmakuSettings.repeatedDanmakuWindowSeconds.clamp(1, 30)),
    )) {
      return;
    }
    if (danmakuSettings.enableDanmakuSimilarityFilter && !_similarityFilter.shouldDisplay(message.message)) {
      return;
    }

    // flame_barrage 渲染（仅当弹幕显示开启时发送到画面层）。
    if (danmakuSettings.enableDanmakuDisplay && !danmakuSettings.hideDanmaku) {
      state.barrageController.send(_toBarrageItem(message));
    }

    // 列表视图保存最近 200 条。
    final messages = List<LiveMessage>.of(state.messages)..add(message);
    if (messages.length > 200) {
      messages.removeRange(0, messages.length - 200);
    }
    state = state.copyWith(messages: messages);
  }

  BarrageItem _toBarrageItem(LiveMessage msg) {
    final style = msg.style;
    final color = Color.fromARGB(255, msg.color.r, msg.color.g, msg.color.b);
    return BarrageItem(
      content: msg.message,
      type: switch (style?.placement) {
        LiveMessagePlacement.top => BarrageType.topFixed,
        LiveMessagePlacement.bottom => BarrageType.bottomFixed,
        _ => BarrageType.scroll,
      },
      userId: msg.userId,
      userName: msg.userName,
      textColor: color,
      fontSize: style?.fontSize,
      fontWeight: style == null ? null : FontWeight(style.fontWeight),
      fontFamily: style?.fontFamily,
      showStroke: style?.showStroke,
      strokeColor: style == null ? null : Color(style.strokeColor),
      strokeWidth: style?.strokeWidth,
      baseSpeed: style?.baseSpeed,
    );
  }

  void clearMessages() {
    _messageGate.clear();
    _repeatedFilter.clear();
    _similarityFilter.clear();
    state.barrageController.clear();
    state = state.copyWith(messages: const <LiveMessage>[]);
  }

  void _teardown() {
    _sessionToken++;
    final engine = _engine;
    _engine = null;
    engine?.onMessage = null;
    engine?.onClose = null;
    if (engine != null) {
      unawaited(engine.stop().catchError((Object e, StackTrace s) {}));
    }
  }
}

class DanmakuSessionState {
  const DanmakuSessionState({
    required this.barrageController,
    this.messages = const <LiveMessage>[],
    this.connected = false,
    this.statusText = '弹幕未连接',
  });

  final BarrageController barrageController;
  final List<LiveMessage> messages;
  final bool connected;
  final String? statusText;

  DanmakuSessionState copyWith({
    List<LiveMessage>? messages,
    bool? connected,
    String? statusText,
    bool clearStatusText = false,
  }) {
    return DanmakuSessionState(
      barrageController: barrageController,
      messages: messages ?? this.messages,
      connected: connected ?? this.connected,
      statusText: clearStatusText ? null : (statusText ?? this.statusText),
    );
  }
}
