import 'dart:async';

import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/services/background_task/background_task_model.dart';
import 'package:pure_live/services/background_task/background_task_config_x.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:pure_live/services/settings/settings_value.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pure_live/services/background_task/background_task_settings_model.dart';

part 'background_task_controller.g.dart';

/// 后台任务的配置与运行状态。
///
/// 这一层只管「记」和「读」：任务的开关、间隔、上次执行结果都落在这里，
/// 真正决定「现在该不该跑」和「跑的时候调用谁」在 `BackgroundTaskService`。
/// 拆开的好处是设置界面不需要认识任何任务实现，调度器也不需要关心界面。
///
/// 对应 iTab 扩展：配置 + 运行时间戳落在 `chrome.storage.local`，
/// 调度逻辑落在 `background.js` 的 alarm 回调里 —— 这里同样一分为二。
@riverpod
class BackgroundTaskController extends _$BackgroundTaskController {
  static BackgroundTaskController get to => SettingsService.to.backgroundTask;

  final StreamController<BackgroundTaskRunReport> _reportStream =
      StreamController<BackgroundTaskRunReport>.broadcast();

  /// 每次任务执行完都会推一条，遥控端 / 设置页用它做实时反馈。
  Stream<BackgroundTaskRunReport> get reports => _reportStream.stream;

  /// 正在执行的任务，供调度器去重。
  final Set<BackgroundTaskKind> _running = <BackgroundTaskKind>{};

  /// 当前配置快照。
  ///
  /// 对外暴露只读视图而不是直接用 `state`：`state` 是 Riverpod 的受保护成员，
  /// 非 Notifier 子类（调度器、设置页）读它会触发 lint，也不该让外部改写。
  BackgroundTaskSettings get settings => state;

  bool get globalEnabled => state.enabled;

  SettingsValue<bool> get settingsEnabledValue =>
      SettingsValue(() => state.enabled, setEnabled);

  @override
  BackgroundTaskSettings build() {
    ref.onDispose(_reportStream.close);

    final configs = <BackgroundTaskConfig>[];
    for (final kind in BackgroundTaskKind.values) {
      final stored = BackgroundTaskStorage.readConfig(kind);
      final config = stored == null
          ? BackgroundTaskConfig.defaults(kind)
          : BackgroundTaskConfig.fromJsonMap(kind, stored);
      final runState = BackgroundTaskStorage.readState(kind);
      configs.add(config.copyWith(lastRunAt: runState.lastRunAt));
    }

    return BackgroundTaskSettings(
      enabled: BackgroundTaskStorage.globalEnabled,
      tasks: configs,
    );
  }

  // ---------------------------------------------------------------------------
  // 配置读写
  // ---------------------------------------------------------------------------

  Future<void> setEnabled(bool enabled) async {
    state = state.copyWith(enabled: enabled);
    await BackgroundTaskStorage.setGlobalEnabled(enabled);
  }

  Future<void> setTaskEnabled(BackgroundTaskKind kind, bool enabled) async {
    final config = configOf(kind).copyWith(enabled: enabled);
    await _replace(config);
  }

  Future<void> setTaskInterval(BackgroundTaskKind kind, int minutes) async {
    final config = configOf(kind).copyWith(intervalMinutes: kind.clampInterval(minutes));
    await _replace(config);
  }

  /// 还原成默认值（总开关不动）。
  Future<void> resetToDefaults() async {
    for (final kind in BackgroundTaskKind.values) {
      await _replace(BackgroundTaskConfig.defaults(kind));
    }
  }

  Future<void> _replace(BackgroundTaskConfig config) async {
    final tasks = state.tasks.where((item) => item.kind != config.kind).toList(growable: true)
      ..add(config);
    tasks.sort((a, b) => a.kind.index.compareTo(b.kind.index));
    state = state.copyWith(tasks: tasks);
    await BackgroundTaskStorage.writeConfig(config);
  }

  BackgroundTaskConfig configOf(BackgroundTaskKind kind) {
    return state.tasks.byKind(kind) ?? BackgroundTaskConfig.defaults(kind);
  }

  BackgroundTaskState stateOf(BackgroundTaskKind kind) => BackgroundTaskStorage.readState(kind);

  /// 把运行状态里的时间戳同步回配置，界面显示「下次运行」时不用再读一遍存储。
  void _refreshLastRun(BackgroundTaskKind kind, DateTime? lastRunAt) {
    final current = state.tasks.byKind(kind);
    if (current == null) return;
    if (current.lastRunAt == lastRunAt) return;
    final tasks = state.tasks
        .map((item) => item.kind == kind ? item.copyWith(lastRunAt: lastRunAt) : item)
        .toList(growable: false);
    state = state.copyWith(tasks: tasks);
  }

  // ---------------------------------------------------------------------------
  // 运行状态
  // ---------------------------------------------------------------------------

  bool isRunning(BackgroundTaskKind kind) => _running.contains(kind);

  void markRunning(BackgroundTaskKind kind) => _running.add(kind);

  /// 记录一次执行结果并广播。
  ///
  /// [success] 为 false 时累计连续失败次数，调度器据此退避；成功则清零。
  Future<void> recordResult(
    BackgroundTaskKind kind, {
    required bool success,
    String error = '',
    DateTime? finishedAt,
  }) async {
    _running.remove(kind);
    final at = finishedAt ?? DateTime.now();
    final previous = BackgroundTaskStorage.readState(kind);
    final next = BackgroundTaskState(
      lastRunAt: at,
      lastSuccess: success,
      consecutiveFailures: success ? 0 : previous.consecutiveFailures + 1,
      lastError: success ? '' : error,
      runCount: success ? previous.runCount + 1 : previous.runCount,
    );
    await BackgroundTaskStorage.writeState(kind, next);
    _refreshLastRun(kind, at);

    if (!_reportStream.isClosed) {
      _reportStream.add(
        BackgroundTaskRunReport(
          kind: kind,
          success: success,
          error: error,
          finishedAt: at,
          consecutiveFailures: next.consecutiveFailures,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // 备份 / 同步
  // ---------------------------------------------------------------------------

  Map<String, dynamic> toJson() => <String, dynamic>{
    'enabled': state.enabled,
    'tasks': state.tasks.map((item) => item.toJson()).toList(growable: false),
  };

  /// 导入备份里的后台任务分区。
  ///
  /// 只认已存在的任务类型：备份可能来自旧版本（少任务）或新版本（多任务），
  /// 多出来的条目按默认值补上，认不出的直接忽略。
  Future<void> importFromJson(Map<String, dynamic> json) async {
    final enabled = json['enabled'] is bool ? json['enabled'] as bool : true;
    final rawTasks = json['tasks'];
    final incoming = <BackgroundTaskKind, BackgroundTaskConfig>{};
    if (rawTasks is List) {
      for (final item in rawTasks) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        final id = (map['kind'] ?? '') as String;
        final kind = BackgroundTaskKind.values.where((value) => value.id == id).firstOrNull;
        if (kind == null) continue;
        incoming[kind] = BackgroundTaskConfig.fromJsonMap(kind, map);
      }
    }

    state = state.copyWith(enabled: enabled);
    await BackgroundTaskStorage.setGlobalEnabled(enabled);
    for (final kind in BackgroundTaskKind.values) {
      final config = incoming[kind] ?? BackgroundTaskConfig.defaults(kind);
      await _replace(config.copyWith(lastRunAt: stateOf(kind).lastRunAt));
    }
  }
}

/// 一次任务执行的结果，用于界面与日志。
class BackgroundTaskRunReport {
  const BackgroundTaskRunReport({
    required this.kind,
    required this.success,
    required this.finishedAt,
    this.error = '',
    this.consecutiveFailures = 0,
  });

  final BackgroundTaskKind kind;
  final bool success;
  final DateTime finishedAt;
  final String error;
  final int consecutiveFailures;
}
