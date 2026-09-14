import 'dart:convert';

import 'package:pure_live/shared/utils/hive_pref_util.dart';

/// 后台任务类型。
///
/// 移植自 iTab 扩展 `background.js` 里 `chrome.alarms` 的用法：扩展把「番茄钟到点」
/// 「自动换壁纸」这类需要到点执行的事情注册成 alarm，由 Service Worker 统一调度。
/// Flutter 端没有 Service Worker，这里用同一套思路 —— 一张任务表 + 一个心跳，
/// 每个任务自己声明间隔，调度器负责「到点执行、去重、失败退避」。
enum BackgroundTaskKind {
  /// IPTV 播放列表自动同步（频道源过期后重新拉取）。
  iptvAutoSync,

  /// EPG 节目单自动同步。
  epgAutoSync,

  /// IPTV 热门资源（iptv-org 中国区播放列表）。
  iptvHotResource,

  /// 默认 EPG 源资源（epg.zsdc.eu.org）。
  epgDefaultResource,

  /// 关注列表在线状态刷新（只发事件，实际刷新由关注页通知器完成）。
  favoriteRefresh,

  /// 在线壁纸自动轮换。
  wallpaperRotate,
}

extension BackgroundTaskKindX on BackgroundTaskKind {
  /// 持久化键名。用显式字符串而不是 `name`，改名不会丢用户设置。
  String get id => switch (this) {
    BackgroundTaskKind.iptvAutoSync => 'iptv_auto_sync',
    BackgroundTaskKind.epgAutoSync => 'epg_auto_sync',
    BackgroundTaskKind.iptvHotResource => 'iptv_hot_resource',
    BackgroundTaskKind.epgDefaultResource => 'epg_default_resource',
    BackgroundTaskKind.favoriteRefresh => 'favorite_refresh',
    BackgroundTaskKind.wallpaperRotate => 'wallpaper_rotate',
  };

  /// 界面上的名字。
  String get title => switch (this) {
    BackgroundTaskKind.iptvAutoSync => 'IPTV 播放列表同步',
    BackgroundTaskKind.epgAutoSync => 'EPG 节目单同步',
    BackgroundTaskKind.iptvHotResource => '热门直播源（iptv-org）',
    BackgroundTaskKind.epgDefaultResource => '默认 EPG 源',
    BackgroundTaskKind.favoriteRefresh => '关注列表刷新',
    BackgroundTaskKind.wallpaperRotate => '自动更换壁纸',
  };

  String get description => switch (this) {
    BackgroundTaskKind.iptvAutoSync => '播放列表超过设定时长未更新时自动重新拉取',
    BackgroundTaskKind.epgAutoSync => '节目单缓存过期后自动重新下载',
    BackgroundTaskKind.iptvHotResource => '定时更新内置的 iptv-org 中国区频道列表',
    BackgroundTaskKind.epgDefaultResource => '定时更新内置的默认节目单源',
    BackgroundTaskKind.favoriteRefresh => '刷新关注房间的直播状态',
    BackgroundTaskKind.wallpaperRotate => '按「背景设置」里的间隔检查并更换在线壁纸',
  };

  /// 默认是否开启。
  ///
  /// 只被动跟随已有开关（IPTV 自动同步、自动换壁纸）的任务默认开启，
  /// 会主动发起外部下载的任务（热门源、默认 EPG）默认关闭 —— 不替用户决定流量。
  bool get defaultEnabled => switch (this) {
    BackgroundTaskKind.iptvAutoSync ||
    BackgroundTaskKind.epgAutoSync ||
    BackgroundTaskKind.favoriteRefresh ||
    BackgroundTaskKind.wallpaperRotate => true,
    BackgroundTaskKind.iptvHotResource || BackgroundTaskKind.epgDefaultResource => false,
  };

  /// 默认间隔（分钟）。
  int get defaultIntervalMinutes => switch (this) {
    BackgroundTaskKind.iptvAutoSync => 24 * 60,
    BackgroundTaskKind.epgAutoSync => 12 * 60,
    BackgroundTaskKind.iptvHotResource => 7 * 24 * 60,
    BackgroundTaskKind.epgDefaultResource => 7 * 24 * 60,
    BackgroundTaskKind.favoriteRefresh => 30,
    BackgroundTaskKind.wallpaperRotate => 60,
  };

  /// 允许用户选择的间隔档位（分钟）。
  List<int> get intervalOptions => switch (this) {
    BackgroundTaskKind.iptvAutoSync => const <int>[2 * 60, 6 * 60, 12 * 60, 24 * 60, 48 * 60, 72 * 60],
    BackgroundTaskKind.epgAutoSync => const <int>[60, 3 * 60, 6 * 60, 12 * 60, 24 * 60, 48 * 60],
    BackgroundTaskKind.favoriteRefresh => const <int>[10, 15, 30, 60, 120, 240],
    // 壁纸这一项是「多久检查一次该不该换」，真正的轮换频率在背景设置页
    //（`autoSwitchIntervalHours`）；所以这里只给到小时级，不跟着 24 小时走。
    BackgroundTaskKind.wallpaperRotate => const <int>[30, 60, 120, 180, 360],
    BackgroundTaskKind.iptvHotResource ||
    BackgroundTaskKind.epgDefaultResource => const <int>[24 * 60, 3 * 24 * 60, 7 * 24 * 60, 14 * 24 * 60, 30 * 24 * 60],
  };

  /// 间隔的可读文案。
  String intervalLabel(int minutes) {
    if (minutes % 1440 == 0) return '${minutes ~/ 1440} 天';
    if (minutes % 60 == 0) return '${minutes ~/ 60} 小时';
    return '$minutes 分钟';
  }

  int clampInterval(int minutes) {
    final options = intervalOptions;
    if (options.isEmpty) return defaultIntervalMinutes;
    if (minutes <= options.first) return options.first;
    if (minutes >= options.last) return options.last;
    // 落在两档之间时取最近的一档，保证界面下标总能对上。
    var best = options.first;
    for (final option in options) {
      if ((option - minutes).abs() < (best - minutes).abs()) best = option;
    }
    return best;
  }
}

/// 单个任务的运行状态（跨启动保留）。
///
/// 对应扩展里 `chrome.storage.local` 存的 alarm 触发时间：判断「该不该跑」必须
/// 依赖持久化的时间戳，否则每次冷启动都会把全部任务重跑一遍。
class BackgroundTaskState {
  const BackgroundTaskState({
    this.lastRunAt,
    this.lastSuccess = false,
    this.consecutiveFailures = 0,
    this.lastError = '',
    this.runCount = 0,
  });

  /// 上一次尝试执行的时间（无论成败）。
  final DateTime? lastRunAt;

  /// 上一次执行是否成功。
  final bool lastSuccess;

  /// 连续失败次数，成功后清零。
  final int consecutiveFailures;

  /// 最近一次错误摘要。
  final String lastError;

  /// 累计执行成功次数。
  final int runCount;

  BackgroundTaskState copyWith({
    DateTime? lastRunAt,
    bool? lastSuccess,
    int? consecutiveFailures,
    String? lastError,
    int? runCount,
  }) {
    return BackgroundTaskState(
      lastRunAt: lastRunAt ?? this.lastRunAt,
      lastSuccess: lastSuccess ?? this.lastSuccess,
      consecutiveFailures: consecutiveFailures ?? this.consecutiveFailures,
      lastError: lastError ?? this.lastError,
      runCount: runCount ?? this.runCount,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'lastRunAt': lastRunAt?.millisecondsSinceEpoch,
    'lastSuccess': lastSuccess,
    'consecutiveFailures': consecutiveFailures,
    'lastError': lastError,
    'runCount': runCount,
  };

  factory BackgroundTaskState.fromJsonMap(Map<String, dynamic> json) {
    final rawLastRun = json['lastRunAt'];
    return BackgroundTaskState(
      lastRunAt: rawLastRun is int && rawLastRun > 0
          ? DateTime.fromMillisecondsSinceEpoch(rawLastRun)
          : null,
      lastSuccess: json['lastSuccess'] == true,
      consecutiveFailures: json['consecutiveFailures'] is int ? json['consecutiveFailures'] as int : 0,
      lastError: (json['lastError'] ?? '') as String,
      runCount: json['runCount'] is int ? json['runCount'] as int : 0,
    );
  }

  /// 失败退避：连续失败越多次，下一次尝试越晚。
  ///
  /// 与扩展不同（扩展只在 alarm 到点时跑一次），这里的任务是长期周期任务，
  /// 失败后立刻等一整个周期会错过一整轮，所以用独立的短退避，并在成功时清零。
  static const List<int> retryBackoffMinutes = <int>[5, 15, 30, 60];

  Duration get retryDelay {
    if (consecutiveFailures <= 0) return Duration.zero;
    final index = (consecutiveFailures - 1).clamp(0, retryBackoffMinutes.length - 1);
    return Duration(minutes: retryBackoffMinutes[index]);
  }
}

/// 单个任务的用户配置。
class BackgroundTaskConfig {
  const BackgroundTaskConfig({
    required this.kind,
    required this.enabled,
    required this.intervalMinutes,
    this.lastRunAt,
  });

  final BackgroundTaskKind kind;
  final bool enabled;
  final int intervalMinutes;

  /// 最近一次成功执行的时间，界面用来显示「下次运行」。
  final DateTime? lastRunAt;

  factory BackgroundTaskConfig.defaults(BackgroundTaskKind kind, {BackgroundTaskState? state}) {
    return BackgroundTaskConfig(
      kind: kind,
      enabled: kind.defaultEnabled,
      intervalMinutes: kind.defaultIntervalMinutes,
      lastRunAt: state?.lastRunAt,
    );
  }

  BackgroundTaskConfig copyWith({bool? enabled, int? intervalMinutes, DateTime? lastRunAt}) {
    return BackgroundTaskConfig(
      kind: kind,
      enabled: enabled ?? this.enabled,
      intervalMinutes: intervalMinutes ?? this.intervalMinutes,
      lastRunAt: lastRunAt ?? this.lastRunAt,
    );
  }

  Duration get interval => Duration(minutes: intervalMinutes);

  /// 下一次到期时间；从未运行过时返回 null（调度器会立刻跑一次）。
  DateTime? get nextRunAt {
    final last = lastRunAt;
    if (last == null || !enabled) return null;
    return last.add(interval);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'kind': kind.id,
    'enabled': enabled,
    'intervalMinutes': intervalMinutes,
  };

  /// 从备份 / 偏好里还原；缺失字段回落到该任务的默认值。
  factory BackgroundTaskConfig.fromJsonMap(BackgroundTaskKind kind, Map<String, dynamic> json) {
    final rawEnabled = json['enabled'];
    final rawInterval = json['intervalMinutes'];
    return BackgroundTaskConfig(
      kind: kind,
      enabled: rawEnabled is bool ? rawEnabled : kind.defaultEnabled,
      intervalMinutes: rawInterval is int ? kind.clampInterval(rawInterval) : kind.defaultIntervalMinutes,
    );
  }
}

/// 后台任务模块的存放位置。
///
/// 配置和运行状态分开放：配置进备份（换设备后用户的选择跟着走），运行状态
/// （上次执行时间、失败次数）是本机行为，进了备份反而会让新设备误判「刚跑过」。
class BackgroundTaskStorage {
  BackgroundTaskStorage._();

  static const String globalEnabledKey = 'backgroundTaskEnabled';
  static const String configPrefix = 'backgroundTask.config.';
  static const String statePrefix = 'backgroundTask.state.';

  static bool get globalEnabled => HivePrefUtil.getBool(globalEnabledKey) ?? true;

  static Future<void> setGlobalEnabled(bool value) => HivePrefUtil.setBool(globalEnabledKey, value);

  static Map<String, dynamic>? readConfig(BackgroundTaskKind kind) {
    final raw = HivePrefUtil.getString('$configPrefix${kind.id}');
    return _decodeMap(raw);
  }

  static Future<void> writeConfig(BackgroundTaskConfig config) {
    return HivePrefUtil.setString('$configPrefix${config.kind.id}', jsonEncode(config.toJson()));
  }

  static BackgroundTaskState readState(BackgroundTaskKind kind) {
    final raw = _decodeMap(HivePrefUtil.getString('$statePrefix${kind.id}'));
    return raw == null ? const BackgroundTaskState() : BackgroundTaskState.fromJsonMap(raw);
  }

  static Future<void> writeState(BackgroundTaskKind kind, BackgroundTaskState state) {
    return HivePrefUtil.setString('$statePrefix${kind.id}', jsonEncode(state.toJson()));
  }

  static Map<String, dynamic>? _decodeMap(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {
      // 旧版本或手改坏了的条目当作不存在，回落默认值即可。
    }
    return null;
  }
}
