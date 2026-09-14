import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:pure_live/services/background_task/background_task_model.dart';
import 'package:pure_live/services/background_task/background_task_controller.dart';

/// 任务执行体：跑成功返回 true。
typedef BackgroundTaskExecutor = Future<bool> Function();

/// 后台任务调度器。
///
/// 参考 iTab 扩展 `background.js` 的机制，把 Flutter 端缺的那一层补上：
///
/// | 扩展 | 这里 |
/// | --- | --- |
/// | `chrome.alarms.create` / `onAlarm` | 心跳 [tickInterval] + 每任务的到期判断 |
/// | alarm 触发时间存 `chrome.storage.local` | [BackgroundTaskStorage] 持久化时间戳 |
/// | `runtime.onMessage` 的指令分发 | [EventBus] 广播任务状态 + [runNow] 手动触发 |
/// | Service Worker 被回收后靠 alarm 补跑 | 应用回到前台时补跑错过的任务 |
/// | 任务在飞行中不重入 | [_inflight] 去重 + 控制器里的 running 集合 |
///
/// 关键差异：扩展的 alarm 由浏览器兜底，进程被杀了到点照样唤醒；Flutter 应用进程
/// 一旦被杀就没有任何回调机会。所以这里是**前台常驻调度 + 回前台补跑**，而不是
/// 系统级定时 —— 不假装能唤醒已经死掉的进程，开机后第一次进入应用会把过期的任务补上。
class BackgroundTaskService with WidgetsBindingObserver {
  BackgroundTaskService._internal();

  static final BackgroundTaskService instance = BackgroundTaskService._internal();

  /// 心跳间隔。
  ///
  /// 取 1 分钟是为了让最短的任务间隔（10 分钟）误差可控；单次 tick 只做时间比较，
  /// 真正的任务都在 [checkNow] 里按需启动，空转成本可以忽略。
  static const Duration tickInterval = Duration(minutes: 1);

  /// 任务名（[BackgroundTaskKindX.id]）前缀的事件名：`background_task.<id>.done`。
  static const String eventPrefix = 'background_task.';
  static const String eventSuffix = '.done';
  static const String eventTick = 'background_task.tick';

  final Map<BackgroundTaskKind, BackgroundTaskExecutor> _executors = <BackgroundTaskKind, BackgroundTaskExecutor>{};
  final Map<BackgroundTaskKind, Future<bool>> _inflight = <BackgroundTaskKind, Future<bool>>{};

  Timer? _timer;
  bool _started = false;
  bool _checking = false;

  bool get isStarted => _started;

  BackgroundTaskController get _controller {
    final container = SettingsService.to.container;
    if (container == null) throw StateError('SettingsService.init must run before the background task service');
    return container.read(backgroundTaskControllerProvider.notifier);
  }

  List<BackgroundTaskKind> get registeredKinds => _executors.keys.toList(growable: false);

  // ---------------------------------------------------------------------------
  // 生命周期
  // ---------------------------------------------------------------------------

  /// 注册任务执行体。
  ///
  /// 允许重复注册（后注册的覆盖先注册的），因为设置页的「立即执行」和真实调度
  /// 走的是同一个执行体，测试里也常用这一层替换实现。
  void register(BackgroundTaskKind kind, BackgroundTaskExecutor executor) {
    _executors[kind] = executor;
  }

  void registerAll(Map<BackgroundTaskKind, BackgroundTaskExecutor> executors) {
    _executors.addAll(executors);
  }

  /// 启动心跳并立即补跑一次过期的任务。
  Future<void> start() async {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(tickInterval, (_) => unawaited(checkNow()));
    // 冷启动补跑：上次运行到现在的间隔已经过去了，不必等到第一个 tick。
    unawaited(checkNow());
  }

  Future<void> stop() async {
    if (!_started) return;
    _started = false;
    _timer?.cancel();
    _timer = null;
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 熄屏 / 切后台期间定时器可能被系统节流甚至冻结，回前台先补一次。
    // 与扩展 Service Worker 被回收后靠 alarm 时间戳补跑是同一个道理。
    if (state == AppLifecycleState.resumed) unawaited(checkNow());
  }

  // ---------------------------------------------------------------------------
  // 调度
  // ---------------------------------------------------------------------------

  /// 扫一遍任务表，跑掉所有到期的任务。
  ///
  /// 串行执行：这些任务都会打网络，并发跑只会互相抢带宽（IPTV 同步本身已经是
  /// 分批并发）。一个任务失败不影响后面的任务。
  Future<void> checkNow() async {
    if (_checking) return;
    _checking = true;
    try {
      final controller = _controller;
      final settings = controller.settings;
      if (!settings.enabled) return;

      for (final kind in BackgroundTaskKind.values) {
        final executor = _executors[kind];
        if (executor == null) continue;
        if (!isDue(kind)) continue;
        await _run(kind, executor);
      }
    } catch (error, stackTrace) {
      Log.e('后台任务调度失败: $error', stackTrace);
    } finally {
      _checking = false;
      EventBus.instance.emit(eventTick, DateTime.now());
    }
  }

  /// 该任务现在是否到期。
  ///
  /// 判据与扩展一致：开关打开 + 不在运行中 + 距离上次执行已超过间隔；
  /// 额外加一层失败退避，避免一个坏掉的任务每分钟重试一次。
  bool isDue(BackgroundTaskKind kind) {
    final controller = _controller;
    if (!controller.globalEnabled) return false;

    final config = controller.configOf(kind);
    if (!config.enabled) return false;
    if (controller.isRunning(kind)) return false;
    if (_inflight.containsKey(kind)) return false;

    final state = controller.stateOf(kind);
    final lastRunAt = state.lastRunAt;
    if (lastRunAt == null) return true;

    final elapsed = DateTime.now().difference(lastRunAt);
    if (elapsed.isNegative) return true; // 系统时间被往回调过，按到期处理。

    // 最近一次是失败：先等退避时间，再等正常间隔里较早的那个。
    if (state.consecutiveFailures > 0 && !state.lastSuccess) {
      final retryAt = lastRunAt.add(state.retryDelay);
      return !DateTime.now().isBefore(retryAt);
    }

    return elapsed >= config.interval;
  }

  /// 手动触发一次任务（设置页的「立即执行」）。
  ///
  /// 与自动调度共用执行体和去重，不受开关和间隔限制 —— 用户点了就该跑。
  Future<bool> runNow(BackgroundTaskKind kind) {
    final executor = _executors[kind];
    if (executor == null) return Future<bool>.value(false);
    return _run(kind, executor);
  }

  Future<bool> _run(BackgroundTaskKind kind, BackgroundTaskExecutor executor) {
    final existing = _inflight[kind];
    if (existing != null) return existing;

    final controller = _controller;
    controller.markRunning(kind);

    late final Future<bool> tracked;
    tracked = Future<bool>.sync(executor)
        .then<bool>(
          (success) => success
              ? _complete(kind, success: true)
              : _complete(kind, success: false, error: '任务返回失败'),
          onError: (Object error, StackTrace stackTrace) {
            Log.e('后台任务 ${kind.id} 执行失败: $error', stackTrace);
            return _complete(kind, success: false, error: '$error');
          },
        )
        .whenComplete(() {
          if (identical(_inflight[kind], tracked)) _inflight.remove(kind);
        });

    _inflight[kind] = tracked;
    return tracked;
  }

  Future<bool> _complete(BackgroundTaskKind kind, {required bool success, String error = ''}) async {
    await _controller.recordResult(kind, success: success, error: error);
    EventBus.instance.emit('$eventPrefix${kind.id}$eventSuffix', success);
    return success;
  }

  /// 供测试与热重启清理。
  @visibleForTesting
  Future<void> reset() async {
    await stop();
    _inflight.clear();
  }
}
