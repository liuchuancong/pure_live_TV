import 'package:flutter/material.dart';
import 'package:pure_live/routes/router.dart';
import 'package:pure_live/widgets/index.dart';
import 'package:pure_live/theme/tv_theme_x.dart';
import 'package:pure_live/core/sites/sites.dart';
import 'package:pure_live/routes/web_router.dart';
import 'package:pure_live/widgets/tv_input_field.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:native_textfield_tv/native_textfield_tv.dart';
import 'package:pure_live/modules/search/tv_search_provider.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/core/utils/remote_receiver/tv_remote_receiver.dart';

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
  late final NativeTextFieldController _searchController;

  dynamic _remoteReceiverNotifier;
  bool _isInputFieldFocused = false;

  @override
  void initState() {
    super.initState();
    final sites = Sites().availableSites(containsAll: false);
    _siteTabs = sites.map((site) => TvTabItemData(title: site.name)).toList();
    _typeTabs = [TvTabItemData(title: '主播'), TvTabItemData(title: '直播间')];
    _searchController = NativeTextFieldController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _remoteReceiverNotifier = ref.read(tvRemoteReceiverProvider.notifier);
      _remoteReceiverNotifier.startServer();
      _bindRemoteCallbacks();
    });
  }

  void _bindRemoteCallbacks() {
    if (_remoteReceiverNotifier == null) return;
    _remoteReceiverNotifier.onStreamerSearch = (searchText) {
      _searchController.text = searchText;
      _onSearchSubmit(searchText);
    };
    _remoteReceiverNotifier.onRoomPush = (searchText) {
      _searchController.text = searchText;
      _onSearchSubmit(searchText);
    };
  }

  @override
  void dispose() {
    if (_remoteReceiverNotifier != null) {
      _remoteReceiverNotifier.onStreamerSearch = null;
      _remoteReceiverNotifier.onRoomPush = null;
    }
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onSearchSubmit(String keyword) async {
    if (keyword.trim().isEmpty) return;

    final searchState = ref.read(tvSearchNotifierProvider);
    final currentSite = _siteTabs[searchState.tabSiteIndex].title;
    final currentType = _typeTabs[searchState.searchTypeIndex].title;

    await context.push(
      AppRoutes.kSearchResult,
      extra: SearchResultArgs(keyword: keyword.trim(), site: currentSite, searchType: currentType),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final searchState = ref.watch(tvSearchNotifierProvider);
    final remoteState = ref.watch(tvRemoteReceiverProvider);
    final themeColor = tvTheme.focusColor;

    String qrCodeAddress = '正在启动服务...';
    String hintText = '正在初始化遥控连接...';

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
                  useNativeTextField: false,
                  controller: _searchController,
                  hint: "输入主播/直播间名称搜索",
                  height: 72.sp,
                  maxLines: 1,
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
          ],
        ),
      ),
    );
  }
}
