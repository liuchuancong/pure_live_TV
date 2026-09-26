import 'dart:developer' as developer;

import 'package:dpad/dpad.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/features/history/history_page_provider.dart';
import 'package:pure_live/features/home/home_provider.dart';
import 'package:pure_live/services/history_settings/history_controller.dart';
import 'package:pure_live/services/refresh_config/refresh_config_controller.dart';
import 'package:pure_live/services/theme_settings/theme_settings_controller.dart';

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  /// One entry's lookup may not hold the whole pass hostage.
  static const Duration _roomRefreshTimeout = Duration(seconds: 12);

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
                    // OK on the tab already in force re-verifies every entry against
                    // its platform — the reference's history pull-to-refresh. The
                    // returned future holds the bar's progress line meanwhile.
                    onTabRefresh: (index) => _refreshHistoryRooms(),
                  ),
                  SizedBox(height: 16.sp),
                  Expanded(
                    child: TvTabView(
                      // Stable identity: the room count used to be part of the
                      // key, so clearing or adding one entry rebuilt the view
                      // and reset focus and scroll position.
                      memoryKey: "history_tv_view_${historyPageState.tabSiteIndex}",
                      // Left at the first column hands the remote to the home sidebar.
                      // Stopping here left the rail reachable only through the tab bar above,
                      // so a viewer browsing a grid had to go up first.
                      verticalEdge: DpadEdgeBehavior.leave,
                      horizontalEdge: DpadEdgeBehavior.leave,
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
                          index: index,
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

  /// Re-verifies every history entry against its platform.
  ///
  /// The reference's history pull-to-refresh: one bounded pass over the whole
  /// list — not only the platform tab on screen — asking each platform for the
  /// room's current status. An entry whose lookup failed keeps its stored
  /// snapshot ([HistoryController.applyRefreshedRooms] maps a null back onto the
  /// entry it came from), so a network hiccup cannot rewrite a room as offline.
  Future<void> _refreshHistoryRooms() async {
    final snapshot = List<LiveRoom>.from(ref.read(historyControllerProvider).historyRooms);
    if (snapshot.isEmpty) return;

    final refreshState = ref.read(refreshConfigControllerProvider);
    final concurrency = refreshState.maxConcurrentRefresh > 0 ? refreshState.maxConcurrentRefresh : 5;

    final refreshed = await boundedAsyncMap<LiveRoom, LiveRoom>(
      snapshot,
      maxConcurrent: concurrency,
      task: _refreshOneHistoryRoom,
      shouldCancel: () => !mounted,
    );
    if (!mounted) return;

    // The notifier is read after the await rather than held across it: the pass
    // outlives the frame that started it, and the grid re-slices from the
    // updated list on the rebuild this write triggers.
    ref.read(historyControllerProvider.notifier).applyRefreshedRooms(snapshot, refreshed);
  }

  /// One entry's verification pass; null keeps the stored snapshot.
  ///
  /// [fetchRoomDetailForRefresh] is the guarded path the favourite refresh uses
  /// for the same reason: the presentation-facing `LiveSite.getRoomDetail`
  /// answers a failure with an offline-looking fallback room, which would
  /// rewrite a still-live entry as offline.
  Future<LiveRoom?> _refreshOneHistoryRoom(LiveRoom room) async {
    if (room.platform.isEmpty || room.roomId.isEmpty) return null;
    try {
      final refreshed = await fetchRoomDetailForRefresh(
        site: Sites.of(room.platform).liveSite,
        roomId: room.roomId,
        platform: room.platform,
      ).timeout(_roomRefreshTimeout);
      // Some platforms answer with another canonical id: re-binding keeps the
      // identity the history list dedupes by.
      return preserveHistoryMetadata(refreshed.copyWith(roomId: room.roomId, platform: room.platform), room);
    } catch (e) {
      developer.log('History room refresh failed for ${room.identityKey}: $e');
      return null;
    }
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
