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
  bool _isInputFieldFocused = false;

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
    final remoteState = ref.watch(tvRemoteReceiverProvider);
    final history = ref.watch(searchHistoryControllerProvider);
    final themeColor = tvTheme.focusColor;

    String qrCodeAddress = i18n('ui_starting_service');
    String hintText = i18n('ui_initializing_remote_control_connection');

    if (remoteState is AsyncData) {
      final serverState = remoteState.value!;
      if (serverState.isRunning) {
        qrCodeAddress = '${serverState.serverUrl}${WebRemoteRouter.search}';
        hintText = '${serverState.serverUrl}${WebRemoteRouter.search}';
      } else if (serverState.error != null) {
        qrCodeAddress = serverState.error!;
        hintText = serverState.error!;
      }
    }

    return TvScaffold(
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
            SizedBox(
              width: _centerWidgetWidth.sp,
              child: TvQrCodeCard(qrData: qrCodeAddress, urlText: hintText),
            ),
            SizedBox(height: _itemGap.sp),
            SizedBox(height: 12.sp),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.sp),
              child: TvTabBar(
                tabs: _siteTabs,
                currentIndex: searchState.tabSiteIndex,
                onTabChange: (index) {
                  ref.read(tvSearchNotifierProvider.notifier).changeSiteTab(index);
                },
              ),
            ),
            SizedBox(height: _itemGap.sp),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.sp),
              child: TvTabBar(
                tabs: _typeTabs,
                currentIndex: searchState.searchTypeIndex,
                onTabChange: (index) {
                  ref.read(tvSearchNotifierProvider.notifier).changeSearchType(index);
                },
              ),
            ),
            SizedBox(height: 20.sp),
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
                  builder: (content) {
                    return Focus(
                      onFocusChange: (hasFocus) {
                        setState(() {
                          _isInputFieldFocused = hasFocus;
                        });
                      },
                      child: AnimatedScale(
                        scale: _isInputFieldFocused ? 1.04 : 1.0,
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
                            border: Border.all(color: themeColor, width: _isInputFieldFocused ? 2.5.sp : 1.5.sp),
                            boxShadow: [
                              BoxShadow(
                                color: themeColor.withValues(alpha: _isInputFieldFocused ? 0.5 : 0.35),
                                blurRadius: 12.sp,
                              ),
                            ],
                          ),
                          child: content,
                        ),
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
