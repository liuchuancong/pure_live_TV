import 'dart:async';

import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/widgets/index.dart';
import 'package:pure_live/features/settings/tv_settings_option_tile.dart';
import 'package:pure_live/services/background_task/background_task_model.dart';
import 'package:pure_live/services/background_task/background_task_service.dart';
import 'package:pure_live/services/background_task/background_task_controller.dart';

/// 设置页里的「后台任务」分区。
///
/// 这一页存在的意义是让「应用在后台到底在干什么」可见可控：过去 IPTV 自动同步、
/// 换壁纸这些定时行为散落在各自的页面里，用户既看不到也关不掉。这里把
/// [BackgroundTaskService] 调度的全部任务列出来 —— 开关、间隔、上次执行结果、
/// 立即执行 —— 对应 iTab 扩展里由 `chrome.alarms` 托管的那几个定时行为。
class BackgroundTaskSectionPage extends ConsumerStatefulWidget {
  const BackgroundTaskSectionPage({super.key});

  @override
  ConsumerState<BackgroundTaskSectionPage> createState() => _BackgroundTaskSectionPageState();
}

class _BackgroundTaskSectionPageState extends ConsumerState<BackgroundTaskSectionPage> {
  /// 正在被「立即执行」触发的任务（比真正的 running 早一点点，用来即时反馈）。
  final Set<BackgroundTaskKind> _triggered = <BackgroundTaskKind>{};

  StreamSubscription<BackgroundTaskRunReport>? _reportSubscription;
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    // 任务在后台跑完时刷新「上次/下次」文案。
    _reportSubscription = ref
        .read(backgroundTaskControllerProvider.notifier)
        .reports
        .listen((_) {
          if (mounted) setState(() {});
        });
    // 「约 N 分钟后」是相对时间，不重绘就会一直停在进入页面那一刻。
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _reportSubscription?.cancel();
    _clockTimer?.cancel();
    super.dispose();
  }

  Future<void> _runNow(BackgroundTaskKind kind) async {
    setState(() => _triggered.add(kind));
    try {
      await BackgroundTaskService.instance.runNow(kind);
    } finally {
      if (mounted) setState(() => _triggered.remove(kind));
    }
  }

  /// 上次 / 下次执行的可读文案。
  String _scheduleSummary(BackgroundTaskConfig config, BackgroundTaskState state) {
    if (!config.enabled) return '已关闭';

    final last = state.lastRunAt;
    if (last == null) return '尚未执行 · 下次进入应用时执行';

    final lastText = _formatTime(last);
    final statusText = state.lastSuccess ? '成功' : '失败';
    final parts = <String>['上次 $lastText（$statusText）'];

    if (state.lastSuccess) {
      final next = last.add(config.interval);
      if (next.isAfter(DateTime.now())) {
        parts.add('下次 ${_formatTime(next)}');
      } else {
        parts.add('已到期，等待调度');
      }
    } else if (state.consecutiveFailures > 0) {
      parts.add('第 ${state.consecutiveFailures} 次失败，${state.retryDelay.inMinutes} 分钟后重试');
    }

    if (state.lastError.isNotEmpty) parts.add(state.lastError);
    return parts.join(' · ');
  }

  static String _formatTime(DateTime time) {
    String two(int value) => value.toString().padLeft(2, '0');
    final now = DateTime.now();
    final sameDay = now.year == time.year && now.month == time.month && now.day == time.day;
    final clock = '${two(time.hour)}:${two(time.minute)}';
    return sameDay ? clock : '${time.month}-${time.day} $clock';
  }

  String _buttonLabel(BackgroundTaskKind kind, bool running) {
    if (_triggered.contains(kind)) return '执行中…';
    if (running) return '调度中…';
    return '立即执行';
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(backgroundTaskControllerProvider);
    final controller = ref.read(backgroundTaskControllerProvider.notifier);
    final running = <BackgroundTaskKind>{
      for (final kind in BackgroundTaskKind.values)
        if (controller.isRunning(kind)) kind,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TvSettingsCard(
          children: [
            TvSettingsSwitchTile(
              title: '后台任务',
              subtitle: '关闭后所有定时任务停止调度（各任务自己的开关会保留）',
              icon: Icons.schedule_rounded,
              value: settings.enabled,
              onChanged: controller.setEnabled,
            ),
          ],
        ),
        SizedBox(height: 8.sp),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.sp, vertical: 4.sp),
          child: Text(
            i18nOr(
              'ui_background_task_hint',
              '任务在应用运行时按间隔执行；熄屏或退出期间错过的任务，会在下次进入应用时补跑。',
            ),
            style: TextStyle(fontSize: 12.sp, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
        SizedBox(height: 8.sp),
        for (final config in settings.tasks) ...[
          TvSettingsCard(
            children: [
              TvSettingsSwitchTile(
                title: config.kind.title,
                subtitle: config.kind.description,
                icon: _iconFor(config.kind),
                value: config.enabled,
                onChanged: (value) => controller.setTaskEnabled(config.kind, value),
              ),
              TvSettingsOptionTile(
                title: '执行间隔',
                subtitle: config.kind == BackgroundTaskKind.wallpaperRotate
                    ? '检查频率；实际换图间隔在「背景设置」里'
                    : null,
                icon: Icons.timer_outlined,
                options: config.kind.intervalOptions.map(config.kind.intervalLabel).toList(growable: false),
                index: config.kind.intervalOptions.indexOf(config.intervalMinutes),
                onChanged: (index) {
                  final options = config.kind.intervalOptions;
                  if (index < 0 || index >= options.length) return;
                  controller.setTaskInterval(config.kind, options[index]);
                },
              ),
              TvSettingsTile(
                title: '执行状态',
                subtitle: _scheduleSummary(config, controller.stateOf(config.kind)),
                icon: Icons.history_rounded,
                trailing: TvButton(
                  title: _buttonLabel(config.kind, running.contains(config.kind)),
                  size: TvButtonSize.small,
                  isSecondary: true,
                  onTap: () => _runNow(config.kind),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.sp),
        ],
        TvSettingsTile(
          title: '恢复默认',
          subtitle: '把所有任务和间隔还原成默认值',
          icon: Icons.restart_alt_rounded,
          onTap: controller.resetToDefaults,
        ),
      ],
    );
  }

  static IconData _iconFor(BackgroundTaskKind kind) => switch (kind) {
    BackgroundTaskKind.iptvAutoSync => Icons.playlist_play_rounded,
    BackgroundTaskKind.epgAutoSync => Icons.calendar_month_rounded,
    BackgroundTaskKind.iptvHotResource => Icons.local_fire_department_outlined,
    BackgroundTaskKind.epgDefaultResource => Icons.download_for_offline_outlined,
    BackgroundTaskKind.favoriteRefresh => Icons.favorite_border_rounded,
    BackgroundTaskKind.wallpaperRotate => Icons.wallpaper_rounded,
  };
}
