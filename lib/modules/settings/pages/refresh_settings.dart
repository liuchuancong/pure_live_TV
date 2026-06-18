import 'package:remixicon/remixicon.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/widgets/tv_scaffold.dart';
import 'package:pure_live/tv_dialog/tv_menu_dialog.dart';
import 'package:pure_live/services/settings/refresh_config_controller.dart';

class RefreshSettingsPage extends GetView<RefreshConfigController> {
  const RefreshSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final Map<int, String> intervals = {
      5: "5 ${i18n("minute")}",
      10: "10 ${i18n("minute")}",
      15: "15 ${i18n("minute")}",
      20: "20 ${i18n("minute")}",
      30: "30 ${i18n("minute")}",
      45: "45 ${i18n("minute")}",
      60: "1 ${i18n("hour")}",
      90: "1.5 ${i18n("hour")}",
      120: "2 ${i18n("hour")}",
      180: "3 ${i18n("hour")}",
      240: "4 ${i18n("hour")}",
      360: "6 ${i18n("hour")}",
    };

    final Map<int, String> concurrents = {for (int i = 1; i <= 20; i++) i: i.toString()};

    return TvScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
            child: Text(
              i18n("refresh_settings"),
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: DpadRegion(
              memoryKey: 'settings/refresh',
              horizontalEdge: DpadEdgeBehavior.stop,
              verticalEdge: DpadEdgeBehavior.stop,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                children: [
                  context.buildGroupTitle(i18n("auto_refresh_settings")),
                  context.buildModernCard([
                    context.buildSwitchTile(
                      icon: Remix.refresh_line,
                      title: i18n("auto_refresh_follow"),
                      subtitle: i18n("auto_refresh_follow_subtitle"),
                      value: controller.autoRefreshFavorite,
                    ),
                    Obx(() {
                      if (!controller.autoRefreshFavorite.value) {
                        return const SizedBox.shrink();
                      }
                      return context.buildMenuTile<int>(
                        icon: Remix.time_line,
                        title: i18n("auto_refresh_interval"),
                        value: controller.autoRefreshInterval.value,
                        valueMap: intervals,
                        onChanged: (val) => controller.autoRefreshInterval.value = val,
                        onTap: () async => showRefreshIntervalDialog(intervals),
                      );
                    }),
                    Obx(
                      () => context.buildMenuTile<int>(
                        icon: Remix.server_line,
                        title: i18n("max_concurrent_refresh"),
                        value: controller.maxConcurrentRefresh.value,
                        valueMap: concurrents,
                        onChanged: (val) => controller.maxConcurrentRefresh.value = val,
                        onTap: () async => showMaxConcurrentDialog(concurrents),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void showRefreshIntervalDialog(Map<int, String> intervals) async {
    final List<TvMenuItem<int>> menuItems = intervals.entries.map((e) {
      return TvMenuItem<int>(title: e.value, value: e.key);
    }).toList();

    final selected = await Get.dialog<int>(
      TvMenuDialog<int>(
        title: i18n("auto_refresh_interval"),
        items: menuItems,
        selectedValue: controller.autoRefreshInterval.value,
      ),
    );

    if (selected != null) {
      controller.autoRefreshInterval.value = selected;
    }
  }

  void showMaxConcurrentDialog(Map<int, String> concurrents) async {
    final List<TvMenuItem<int>> menuItems = concurrents.entries.map((e) {
      return TvMenuItem<int>(title: e.value, value: e.key);
    }).toList();

    final selected = await Get.dialog<int>(
      TvMenuDialog<int>(
        title: i18n("max_concurrent_refresh"),
        items: menuItems,
        selectedValue: controller.maxConcurrentRefresh.value,
      ),
    );

    if (selected != null) {
      controller.maxConcurrentRefresh.value = selected;
    }
  }
}
