import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:pure_live/services/background_task/background_task_model.dart';

part 'background_task_settings_model.freezed.dart';
part 'background_task_settings_model.g.dart';

/// 后台任务模块的完整配置快照。
///
/// [enabled] 是模块总开关：关掉之后所有任务都不再被调度，但每个任务自己的开关
/// 会保留，重新打开时按原样恢复（对应扩展里 `permissions.contains` 挡住 alarm
/// 之后再放开的行为）。
@freezed
abstract class BackgroundTaskSettings with _$BackgroundTaskSettings {
  const factory BackgroundTaskSettings({
    @Default(true) bool enabled,
    @JsonKey(fromJson: _taskConfigsFromJson, toJson: _taskConfigsToJson)
    @Default(<BackgroundTaskConfig>[])
    List<BackgroundTaskConfig> tasks,
  }) = _BackgroundTaskSettings;

  factory BackgroundTaskSettings.fromJson(Map<String, dynamic> json) => _$BackgroundTaskSettingsFromJson(json);
}

/// 任务配置的 JSON 编解码。
///
/// 任务类型必须一起带出来才还原得出来，所以存成 `{kind, enabled, intervalMinutes}`，
/// 解析时按 [BackgroundTaskKindX.id] 反查类型；认不出的条目直接跳过 ——
/// 旧版本备份（少任务）和未来版本备份（多任务）都不会炸。
List<BackgroundTaskConfig> _taskConfigsFromJson(Object? raw) {
  if (raw is! List) return defaultBackgroundTaskConfigs();
  final configs = <BackgroundTaskConfig>[];
  for (final item in raw) {
    if (item is! Map) continue;
    final map = Map<String, dynamic>.from(item);
    final kind = _kindFromId((map['kind'] ?? '').toString());
    if (kind == null) continue;
    configs.add(BackgroundTaskConfig.fromJsonMap(kind, map));
  }
  return configs.isEmpty ? defaultBackgroundTaskConfigs() : configs;
}

List<Map<String, dynamic>> _taskConfigsToJson(List<BackgroundTaskConfig> configs) {
  return configs.map((config) => config.toJson()).toList(growable: false);
}

BackgroundTaskKind? _kindFromId(String id) {
  for (final kind in BackgroundTaskKind.values) {
    if (kind.id == id) return kind;
  }
  return null;
}

/// 按持久化 id 反查任务类型；认不出返回 null。
BackgroundTaskKind? backgroundTaskKindFromId(String id) => _kindFromId(id);

@visibleForTesting
List<BackgroundTaskConfig> defaultBackgroundTaskConfigs() {
  return BackgroundTaskKind.values
      .map((kind) => BackgroundTaskConfig.defaults(kind))
      .toList(growable: false);
}
