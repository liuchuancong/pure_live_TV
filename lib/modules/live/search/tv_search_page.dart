import 'package:dpad/dpad.dart';
import 'package:pure_live/exports/exports.dart';
import 'package:pure_live/domains/device/tv_remote_receiver.dart';
import 'package:pure_live/modules/live/search/tv_search_provider.dart';
import 'package:pure_live/modules/live/search/search_history_controller.dart';

class TvSearchPage extends ConsumerStatefulWidget {
  const TvSearchPage({super.key});

  @override
  ConsumerState<TvSearchPage> createState() => _TvSearchPageState();
}

class _TvSearchPageState extends ConsumerState<TvSearchPage> {
  static const double _pagePadding = 32;
  static const double _centerWidgetWidth = 520;
  static const double _itemGap = 36;

  late final List<TvTabItemData> _siteTabs;
  late final List<TvTabItemData> _typeTabs;
  late final TextEditingController _searchController;

  TvRemoteReceiver? _remoteReceiverNotifier;

  @override
  void initState() {
    super.initState();
    final sites = Sites().availableSites(containsAll: false);
    _siteTabs = sites.map(TvTabItemData.site).toList();
    _typeTabs = [TvTabItemData(title: i18n('ui_streamer')), TvTabItemData(title: i18n('ui_live_room'))];
    _searchController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _remoteReceiverNotifier = ref.read(tvRemoteReceiverProvider.notifier);
      _remoteReceiverNotifier?.startServer();
      _bindRemoteCallbacks();
    });
  }

  void _bindRemoteCallbacks() {
    final receiver = _remoteReceiverNotifier;
    if (receiver == null) return;
    receiver.onStreamerSearch = (searchText) {
      _searchController.text = searchText;
      _onSearchSubmit(searchText);
    };
    receiver.onRoomPush = (searchText) {
      _searchController.text = searchText;
      _onSearchSubmit(searchText);
    };
  }

  @override
  void dispose() {
    final receiver = _remoteReceiverNotifier;
    if (receiver != null) {
      receiver.onStreamerSearch = null;
      receiver.onRoomPush = null;
    }
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onSearchSubmit(String keyword) async {
    final trimmed = keyword.trim();
    if (trimmed.isEmpty) return;

    ref.read(searchHistoryControllerProvider.notifier).add(trimmed);

    final searchState = ref.read(tvSearchNotifierProvider);
    final currentSite = _siteTabs[searchState.tabSiteIndex].title;
    final currentType = searchState.searchTypeIndex == 0 ? kSearchTypeStreamer : kSearchTypeRoom;

    await SearchResultRoute(
      SearchResultArgs(keyword: trimmed, site: currentSite, searchType: currentType),
    ).push(context);
  }

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final searchState = ref.watch(tvSearchNotifierProvider);
    final history = ref.watch(searchHistoryControllerProvider);
    final themeColor = tvTheme.focusColor;

    return TvPageScaffold(
      showAppBar: false,
      showBackButton: false,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: _pagePadding.ts(context), vertical: (_pagePadding * 1.2).sp),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: _centerWidgetWidth.ts(context),
              child: const RemoteSyncQrCard(width: 240, route: WebRemoteRouter.search),
            ),
            SizedBox(height: (_itemGap * 0.7).sp),
            _buildTypeSegmented(themeColor, searchState.searchTypeIndex),
            SizedBox(height: (_itemGap * 0.6).sp),
            TvTabBar(
              tabs: _siteTabs,
              currentIndex: searchState.tabSiteIndex,
              onTabChange: (index) {
                ref.read(tvSearchNotifierProvider.notifier).changeSiteTab(index);
              },
            ),
            SizedBox(height: _itemGap.ts(context)),
            // A long ellipse: wider than the rest of the column, fully
            // pill-rounded (radius = half the height) and quiet — card fill,
            // a hairline neutral border that turns into the accent ring only
            // while focused. No glow, no scale.
            SizedBox(
              width: (_centerWidgetWidth + 260).sp,
              child: TvInputField(
                controller: _searchController,
                hint: i18n('search_room_hint'),
                height: 76.ts(context),
                maxLines: 1,
                onChanged: (text) => ref.read(tvSearchNotifierProvider.notifier).updateKeyword(text),
                onSubmitted: _onSearchSubmit,
                postFixWidget: GestureDetector(
                  onTap: () => _onSearchSubmit(_searchController.text),
                  child: Padding(
                    padding: EdgeInsets.only(right: 16.sp),
                    child: Icon(Icons.search_rounded, color: tvTheme.secondaryTextColor, size: 28.ts(context)),
                  ),
                ),
                builder: (content, isFocused) {
                  final double scale = TvTextScale.factorOf(context);
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeOutCubic,
                    height: 76.ts(context) * scale,
                    padding: EdgeInsets.symmetric(horizontal: 28.ts(context) * scale),
                    decoration: BoxDecoration(
                      color: tvTheme.cardColor,
                      borderRadius: BorderRadius.circular(38.ts(context) * scale),
                      border: Border.all(
                        color: isFocused ? tvTheme.focusColor : tvTheme.secondaryTextColor.withValues(alpha: 0.25),
                        width: isFocused ? 2.ts(context) : 1.5.ts(context),
                      ),
                    ),
                    child: content,
                  );
                },
              ),
            ),
            if (history.isNotEmpty) ...[SizedBox(height: 24.ts(context)), _buildHistorySection(history, themeColor)],
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSegmented(Color themeColor, int currentIndex) {
    final tvTheme = context.tvTheme;
    // The segment pills hold t20 labels, so the strip grows with the text.
    return Container(
      height: 56.ts(context),
      padding: EdgeInsets.all(5.ts(context)),
      decoration: BoxDecoration(
        color: tvTheme.cardColor.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(28.ts(context)),
        border: Border.all(color: themeColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < _typeTabs.length; i++) ...[
            if (i > 0) SizedBox(width: 6.ts(context)),
            _SegmentedOption(
              icon: i == 0 ? Icons.person_rounded : Icons.live_tv_rounded,
              label: _typeTabs[i].title,
              selected: currentIndex == i,
              onTap: () => ref.read(tvSearchNotifierProvider.notifier).changeSearchType(i),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHistorySection(List<String> history, Color themeColor) {
    return SizedBox(
      width: (_centerWidgetWidth + 240).sp,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 8.sp, bottom: 10.sp),
            child: Text(
              '${i18n('search_history')}（${i18n('history_long_press_delete')}）',
              style: AppTextStyles.t20.copyWith(color: themeColor),
            ),
          ),
          SizedBox(
            // The chip row's viewport: the chips are pill buttons whose height
            // follows the font, so the band must too or they clip.
            height: 56.ts(context),
            child: DpadRegion(
              horizontalEdge: DpadEdgeBehavior.leave,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 8.ts(context)),
                itemCount: history.length + 1,
                separatorBuilder: (_, _) => SizedBox(width: 10.ts(context)),
                itemBuilder: (context, index) {
                  if (index == history.length) {
                    return _buildHistoryChip(
                      key: 'search_history_clear',
                      icon: Icons.delete_outline_rounded,
                      label: i18n('clear_search_history'),
                      themeColor: themeColor,
                      onTap: () => ref.read(searchHistoryControllerProvider.notifier).clear(),
                    );
                  }
                  final keyword = history[index];
                  return _buildHistoryChip(
                    key: 'search_history_$keyword',
                    label: keyword,
                    themeColor: themeColor,
                    onTap: () {
                      _searchController.text = keyword;
                      _onSearchSubmit(keyword);
                    },
                    onLongPress: () => ref.read(searchHistoryControllerProvider.notifier).remove(keyword),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryChip({
    required String key,
    required String label,
    required Color themeColor,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
    IconData? icon,
  }) {
    final tvTheme = context.tvTheme;
    // The pill's every dimension follows its t20 label (same language as
    // TvButton): a fixed 44.ts(context) pill clipped the enlarged text.
    return TvFocusable(
      key: Key(key),
      onTap: onTap,
      onLongPress: onLongPress,
      builder: (context, focused, child) {
        return AnimatedScale(
          scale: focused ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOutCubic,
            height: 44.ts(context),
            padding: EdgeInsets.symmetric(horizontal: 22.ts(context)),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: focused ? themeColor : tvTheme.cardColor,
              borderRadius: BorderRadius.circular(22.ts(context)),
              border: Border.all(color: themeColor, width: focused ? 2.5.ts(context) : 1.5.ts(context)),
              boxShadow: [
                BoxShadow(
                  color: themeColor.withValues(alpha: focused ? 0.55 : 0.0),
                  blurRadius: focused ? 16.ts(context) : 0,
                  spreadRadius: focused ? 2.ts(context) : 0,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 24.ts(context), color: focused ? Colors.white : themeColor),
                  SizedBox(width: 8.ts(context)),
                ],
                Text(
                  label,
                  style: AppTextStyles.t20.copyWith(color: focused ? Colors.white : tvTheme.primaryTextColor),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SegmentedOption extends StatelessWidget {
  const _SegmentedOption({required this.icon, required this.label, required this.selected, required this.onTap});

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final accent = tvTheme.focusColor;
    // The pill tracks its t20 label, like the history chips.

    return TvFocusable(
      onTap: onTap,
      builder: (context, focused, child) {
        final Color fill = selected ? accent : (focused ? accent.withValues(alpha: 0.35) : Colors.transparent);
        final Color ink = selected ? Colors.white : (focused ? Colors.white : tvTheme.secondaryTextColor);
        final Duration animDuration = focused ? const Duration(milliseconds: 120) : Duration.zero;

        return AnimatedScale(
          scale: focused && !selected ? 1.04 : 1.0,
          duration: animDuration,
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: animDuration,
            curve: Curves.easeOutCubic,
            height: 46.ts(context),
            padding: EdgeInsets.symmetric(horizontal: 26.ts(context)),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(23.ts(context)),
              border: Border.all(color: focused ? accent : Colors.transparent, width: 2.ts(context)),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: focused ? 0.5 : 0.0),
                  blurRadius: focused ? 14.ts(context) : 0,
                  spreadRadius: focused ? 2.ts(context) : 0,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 22.ts(context), color: ink),
                SizedBox(width: 8.ts(context)),
                Text(
                  label,
                  style: AppTextStyles.t20.copyWith(
                    color: ink,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
