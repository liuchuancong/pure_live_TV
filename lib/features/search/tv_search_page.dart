import 'package:dpad/dpad.dart';
import 'package:pure_live/exports/exports.dart';

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

    await context.push(
      AppRoutes.kSearchResult,
      extra: SearchResultArgs(keyword: trimmed, site: currentSite, searchType: currentType),
    );
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
        padding: EdgeInsets.symmetric(horizontal: _pagePadding.sp, vertical: (_pagePadding * 1.2).sp),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // The native sync QR: the phone app scans it (or types the address
            // below it) once, then every channel — search text included — is live.
            SizedBox(width: _centerWidgetWidth.sp, child: const RemoteSyncQrCard(width: 320)),
            SizedBox(height: (_itemGap * 0.8).sp),
            // 搜索类型: one joined segmented control instead of two loose
            // stadium tabs — a two-item tab bar stretched across the screen was
            // the ragged "button row" this page used to show.
            _buildTypeSegmented(themeColor, searchState.searchTypeIndex),
            SizedBox(height: (_itemGap * 0.7).sp),
            // 平台: centered chips instead of a full-width scrolling tab bar;
            // with ~6 platforms the bar never needed to scroll, it only spread
            // the chips from the left edge and looked misaligned under the QR.
            _buildSiteChips(themeColor, searchState.tabSiteIndex),
            SizedBox(height: _itemGap.sp),
            SizedBox(
              width: _centerWidgetWidth.sp,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.sp),
                  boxShadow: [
                    BoxShadow(
                      color: themeColor.withValues(alpha: 0.3),
                      blurRadius: 28.sp,
                      spreadRadius: 3.sp,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TvInputField(
                  controller: _searchController,
                  hint: i18n('search_room_hint'),
                  height: 72.sp,
                  maxLines: 1,
                  onChanged: (text) => ref.read(tvSearchNotifierProvider.notifier).updateKeyword(text),
                  onSubmitted: _onSearchSubmit,
                  postFixWidget: GestureDetector(
                    onTap: () => _onSearchSubmit(_searchController.text),
                    child: Padding(
                      padding: EdgeInsets.only(right: 6.sp),
                      child: Icon(Icons.search_rounded, color: themeColor, size: 32.sp),
                    ),
                  ),
                  builder: (content, isFocused) {
                    // The focus state comes from the field itself; wrapping the
                    // content in a bare Focus here made that wrapper the d-pad
                    // focus target and OK could never reach the TextField.
                    return AnimatedScale(
                      scale: isFocused ? 1.04 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        height: 80.sp,
                        padding: EdgeInsets.symmetric(horizontal: 18.sp, vertical: 12.sp),
                        decoration: BoxDecoration(
                          color: tvTheme.backgroundColor,
                          borderRadius: BorderRadius.circular(32.sp),
                          border: Border.all(color: themeColor, width: isFocused ? 2.5.sp : 1.5.sp),
                          boxShadow: [
                            BoxShadow(
                              color: themeColor.withValues(alpha: isFocused ? 0.5 : 0.35),
                              blurRadius: 12.sp,
                            ),
                          ],
                        ),
                        child: content,
                      ),
                    );
                  },
                ),
              ),
            ),
            if (history.isNotEmpty) ...[
              SizedBox(height: 24.sp),
              _buildHistorySection(history, themeColor),
            ],
          ],
        ),
      ),
    );
  }

  /// 主播 / 直播间 as one joined control: two halves sharing an outline, the
  /// active half filled with the accent. Reads as a single switch rather than
  /// two floating buttons.
  Widget _buildTypeSegmented(Color themeColor, int currentIndex) {
    final tvTheme = context.tvTheme;
    return Container(
      height: 56.sp,
      padding: EdgeInsets.all(5.sp),
      decoration: BoxDecoration(
        color: tvTheme.cardColor.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(28.sp),
        border: Border.all(color: themeColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < _typeTabs.length; i++) ...[
            if (i > 0) SizedBox(width: 6.sp),
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

  /// Platform chips laid out from the centre. Selection fills the chip with the
  /// accent; focus gets the shared ring/scale language via [TvFocusable].
  Widget _buildSiteChips(Color themeColor, int currentIndex) {
    final tvTheme = context.tvTheme;
    return SizedBox(
      width: (_centerWidgetWidth + 320).sp,
      child: Wrap(
        alignment: WrapAlignment.center,
        runAlignment: WrapAlignment.center,
        spacing: 12.sp,
        runSpacing: 12.sp,
        children: [
          for (int i = 0; i < _siteTabs.length; i++)
            TvFocusable(
              key: Key('search_site_${_siteTabs[i].tabId}'),
              onSelect: () => ref.read(tvSearchNotifierProvider.notifier).changeSiteTab(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                height: 48.sp,
                padding: EdgeInsets.symmetric(horizontal: 22.sp),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: currentIndex == i ? themeColor : tvTheme.cardColor,
                  borderRadius: BorderRadius.circular(24.sp),
                  border: Border.all(
                    color: currentIndex == i ? themeColor : themeColor.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_siteTabs[i].icon != null) ...[_siteTabs[i].icon!, SizedBox(width: 8.sp)],
                    Text(
                      _siteTabs[i].title,
                      style: AppTextStyles.t20.copyWith(
                        color: currentIndex == i ? Colors.white : tvTheme.primaryTextColor,
                        fontWeight: currentIndex == i ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
            height: 56.sp,
            child: DpadRegion(
              horizontalEdge: DpadEdgeBehavior.leave,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 8.sp),
                itemCount: history.length + 1,
                separatorBuilder: (_, _) => SizedBox(width: 10.sp),
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
    return TvFocusable(
      key: Key(key),
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        height: 44.sp,
        padding: EdgeInsets.symmetric(horizontal: 22.sp),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: tvTheme.cardColor,
          borderRadius: BorderRadius.circular(22.sp),
          border: Border.all(color: themeColor.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 24.sp, color: themeColor), SizedBox(width: 8.sp)],
            Text(label, style: AppTextStyles.t20.copyWith(color: tvTheme.primaryTextColor)),
          ],
        ),
      ),
    );
  }
}

/// One half of the joined 搜索类型 switch. The active half carries the accent
/// fill; the inactive half stays quiet until focused.
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

    return TvFocusable(
      onSelect: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        height: 46.sp,
        padding: EdgeInsets.symmetric(horizontal: 26.sp),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? accent : Colors.transparent,
          borderRadius: BorderRadius.circular(23.sp),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22.sp, color: selected ? Colors.white : tvTheme.secondaryTextColor),
            SizedBox(width: 8.sp),
            Text(
              label,
              style: AppTextStyles.t20.copyWith(
                color: selected ? Colors.white : tvTheme.secondaryTextColor,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}