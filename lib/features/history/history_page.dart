import 'package:dpad/dpad.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/features/history/history_page_provider.dart';
import 'package:pure_live/features/home/home_provider.dart';
import 'package:pure_live/services/history_settings/history_controller.dart';
import 'package:pure_live/services/theme_settings/theme_settings_controller.dart';

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  @override
  Widget build(BuildContext context) {
    final historyPageState = ref.watch(historyPageProvider);
    final currentRooms = historyPageState.rooms;
    // column/row spacing are an offset from the 6.0 design default, so the untouched
    // default reproduces the original 32 design-pixel gap.
    final themeState = ref.watch(themeSettingsControllerProvider);
    final double crossSpacing = themeState.crossAxisSpacing;
    final double mainSpacing = themeState.mainAxisSpacing;

    final currentParam = PagingParam<LiveRoom>(
      mode: PagingMode.localReactive,
      pageSize: 12,
      keepAlive: false,
      fetchAll: () async {
        return ref.read(historyPageProvider).rooms;
      },
      localRefresh: () async {},
    );

    final availableSitesList = Sites().availableSites(containsAll: true);
    final List<TvTabItemData> siteTabs = availableSitesList.map(TvTabItemData.site).toList();

    return TvScaffold(
      child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HistoryToolbar(
                    onClear: () => _confirmClearHistory(context),
                    onEditLimit: () => _showLimitMenu(context),
                  ),
                  SizedBox(height: 12.sp),
                  TvTabBar(
                    tabs: siteTabs,
                    currentIndex: historyPageState.tabSiteIndex,
                    onTabChange: (index) {
                      ref.read(historyPageProvider.notifier).changeSiteTab(index);
                    },
                  ),
                  SizedBox(height: 16.sp),
                  Expanded(
                    child: TvTabView(
                      // Stable identity: the room count used to be part of the
                      // key, so clearing or adding one entry rebuilt the view
                      // and reset focus and scroll position.
                      memoryKey: "history_tv_view_${historyPageState.tabSiteIndex}",
                      verticalEdge: DpadEdgeBehavior.leave,
                      horizontalEdge: DpadEdgeBehavior.stop,
                      child: BasePagedTvView<LiveRoom>(
                        key: ValueKey('history_grid_${historyPageState.tabSiteIndex}'),
                        param: currentParam,
                        getNotifier: () => ref.read(pagingCoreProvider(currentParam).notifier),
                        emptyScene: EmptyScene.history,
                        onEmptyGoHot: () => ref.read(sideMenuIndexProvider.notifier).changeIndex(TvMenuType.hot.value),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: themeState.denseRoomLayout,
                          mainAxisSpacing: mainSpacing.w,
                          crossAxisSpacing: crossSpacing.w,
                          childAspectRatio: ThemeSettingsController.roomCardAspectRatio(themeState.denseRoomLayout),
                        ),
                        itemBuilder: (context, room, index) => TvRoomCard(
                          room: room,
                          playlist: currentRooms,
                          onLongPress: () {
                            FavOperateUtil.toggleHistoryDeleteDialog(context, room);
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
    );
  }

  /// Clears the whole history after confirming how many entries are removed.
  Future<void> _confirmClearHistory(BuildContext context) async {
    final count = ref.read(historyControllerProvider).historyRooms.length;
    if (count == 0) return;

    await TvDialogUtils.showConfirm(
      context: context,
      title: i18n('clear_history'),
      message: i18n('clear_history_confirm_named', args: {'count': '$count'}),
      confirmText: i18n('clear'),
      cancelText: i18n('cancel'),
      onConfirm: () => ref.read(historyControllerProvider.notifier).clearHistory(),
    );
  }

  /// Preset retention sizes, the custom value and "unlimited".
  Future<void> _showLimitMenu(BuildContext context) async {
    final controller = ref.read(historyControllerProvider.notifier);
    final current = ref.read(historyControllerProvider).historyLimit;
    const presets = [20, 50, 100, 200];

    final action = await TvDialogUtils.showSelect<int>(
      context: context,
      title: i18n('history_limit'),
      items: [
        for (final preset in presets)
          TvSelectItem(title: '$preset', value: preset, leading: const Icon(Icons.numbers_rounded)),
        TvSelectItem(
          title: i18n('history_unlimited'),
          value: unlimitedHistoryLimit,
          leading: const Icon(Icons.all_inclusive_rounded),
        ),
        TvSelectItem(
          title: i18n('history_limit_custom'),
          value: -1,
          leading: const Icon(Icons.edit_rounded),
        ),
      ],
      selectedValue: current,
    );
    if (action == null || !mounted) return;

    if (action != -1) {
      controller.setHistoryLimit(action);
      return;
    }

    if (!context.mounted) return;
    final input = await TvDialogUtils.showInput(
      context: context,
      title: i18n('history_limit_custom'),
      hintText: i18n('history_limit_custom_hint'),
      initialValue: current == unlimitedHistoryLimit ? '' : '$current',
    );
    if (input == null) return;
    final parsed = int.tryParse(input.trim());
    if (parsed == null) return;
    controller.setHistoryLimit(parsed);
  }
}

/// History page toolbar: clear everything and change the retention size.
class _HistoryToolbar extends ConsumerWidget {
  const _HistoryToolbar({required this.onClear, required this.onEditLimit});

  final VoidCallback onClear;
  final VoidCallback onEditLimit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final limit = ref.watch(historyControllerProvider).historyLimit;
    final limitLabel = limit == unlimitedHistoryLimit ? i18n('history_unlimited') : '$limit';

    return Row(
      children: [
        TvButton(
          title: i18n('clear_history'),
          icon: const Icon(Icons.delete_sweep_outlined),
          size: TvButtonSize.mini,
          isSecondary: true,
          onTap: onClear,
        ),
        SizedBox(width: 12.sp),
        TvButton(
          title: '${i18n('history_limit')}: $limitLabel',
          icon: const Icon(Icons.history_toggle_off_rounded),
          size: TvButtonSize.mini,
          isSecondary: true,
          onTap: onEditLimit,
        ),
      ],
    );
  }
}
