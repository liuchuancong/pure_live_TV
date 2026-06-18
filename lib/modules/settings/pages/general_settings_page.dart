import 'package:remixicon/remixicon.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/widgets/tv_scaffold.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';
import 'package:pure_live/tv_dialog/tv_input_dialog.dart';
import 'package:pure_live/tv_dialog/tv_select_dialog.dart';

class GeneralSettingsPage extends GetView<SettingsService> {
  const GeneralSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TvScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
            child: Text(i18n("general"), style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: DpadRegion(
              memoryKey: 'settings/general',
              horizontalEdge: DpadEdgeBehavior.stop,
              verticalEdge: DpadEdgeBehavior.stop,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                children: [
                  context.buildGroupTitle(i18n("general")),
                  context.buildModernCard([
                    context.buildSwitchTile(
                      title: i18n('splash_animation'),
                      subtitle: i18n("splash_animation_subtitle"),
                      value: SettingsService.to.app.showSplashPage,
                      icon: Remix.rocket_2_line,
                    ),
                    context.buildSwitchTile(
                      title: i18n('enable_auto_check_update'),
                      subtitle: "",
                      value: SettingsService.to.app.enableAutoCheckUpdate,
                      icon: Remix.refresh_line,
                    ),
                    context.buildSwitchTile(
                      title: i18n('enable_countdown_close'),
                      subtitle: i18n('enable_countdown_close_subtitle'),
                      value: SettingsService.to.exit.enableAutoShutDownTime,
                      icon: Remix.timer_line,
                    ),
                    Obx(() {
                      final bool isEnabled = SettingsService.to.exit.enableAutoShutDownTime.v;
                      final int configMinutes = SettingsService.to.exit.autoShutDownTime.v;

                      return StreamBuilder<int>(
                        key: ValueKey('${isEnabled}_$configMinutes'),
                        stream: SettingsService.to.exit.stopWatchTimer.rawTime,
                        builder: (context, snapshot) {
                          final int value = snapshot.data ?? 0;
                          String subtitleText = "";

                          if (!isEnabled || value == 0) {
                            subtitleText = "$configMinutes ${i18n('minutes')}";
                          } else {
                            final displayTime = StopWatchTimer.getDisplayTime(value, hours: false, milliSecond: false);
                            subtitleText = "${i18n('remaining_time')}: $displayTime";
                          }

                          return context.buildTile(
                            title: i18n('countdown_duration'),
                            subtitle: subtitleText,
                            icon: Remix.history_line,
                            onTap: () async => _showCountdownDurationDialog(context),
                          );
                        },
                      );
                    }),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCountdownDurationDialog(BuildContext context) async {
    final List<int> minutesOptions = [15, 30, 45, 60, 90, 120, 180];
    final int currentValue = SettingsService.to.exit.autoShutDownTime.v;

    final List<TvSelectItem<int>> items = minutesOptions.map((minutes) {
      return TvSelectItem<int>(title: "$minutes ${i18n('minutes')}", value: minutes);
    }).toList();

    items.add(TvSelectItem<int>(title: i18n('custom_duration'), value: -1, leading: const Icon(Remix.edit_line)));

    final selected = await Get.dialog<int>(
      TvSelectDialog<int>(
        title: i18n('select_countdown_duration'),
        items: items,
        selectedValue: minutesOptions.contains(currentValue) ? currentValue : -1,
      ),
    );

    if (selected != null) {
      if (selected == -1) {
        final customString = await Get.dialog<String>(
          TvInputDialog(
            title: i18n('custom_duration'),
            hintText: i18n('custom_duration'),
            maxLength: 3,
            initialValue: minutesOptions.contains(currentValue) ? "" : currentValue.toString(),
          ),
        );
        if (customString != null && customString.isNotEmpty) {
          final int? parsedValue = int.tryParse(customString);
          if (parsedValue != null && parsedValue > 0) {
            SettingsService.to.exit.updateShutDownTime(parsedValue);
          }
        }
      } else {
        SettingsService.to.exit.updateShutDownTime(selected);
      }
    }
  }
}

class AnimatedTimerIcon extends StatelessWidget {
  final bool enabled;
  final int remainingMs;
  final int totalMinutes;

  const AnimatedTimerIcon({super.key, required this.enabled, required this.remainingMs, required this.totalMinutes});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = theme.colorScheme.primary;

    double turns = 0.0;
    if (enabled && totalMinutes > 0 && remainingMs > 0) {
      final double totalMs = totalMinutes * 60 * 1000;
      final double passedMs = totalMs - remainingMs;
      turns = (passedMs / (60 * 1000)) * 60.0;
    }

    return SizedBox(
      width: 22,
      height: 22,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: iconColor, width: 2),
            ),
          ),
          RotationTransition(
            turns: AlwaysStoppedAnimation(turns),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 2,
                  height: 7,
                  decoration: BoxDecoration(color: iconColor, borderRadius: BorderRadius.circular(1)),
                ),
                const SizedBox(height: 7),
              ],
            ),
          ),
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(color: iconColor, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }
}
