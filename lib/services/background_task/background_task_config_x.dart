import 'package:pure_live/services/background_task/background_task_model.dart';

/// 任务配置列表里按类型取一条。
extension BackgroundTaskConfigListX on List<BackgroundTaskConfig> {
  BackgroundTaskConfig? byKind(BackgroundTaskKind kind) {
    for (final config in this) {
      if (config.kind == kind) return config;
    }
    return null;
  }
}
