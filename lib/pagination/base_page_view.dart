import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:pure_live/theme/tv_theme_x.dart';
import 'package:pure_live/widgets/tv_button.dart';
import 'package:pure_live/widgets/tv_icon_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/pagination/models/base_paged_state.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

class BasePagedTvView<T> extends ConsumerStatefulWidget {
  final ProviderBase<BasePagedState<T>> provider;
  final dynamic notifier;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final SliverGridDelegateWithFixedCrossAxisCount gridDelegate;
  final Widget Function(BuildContext context)? notLoginBuilder;
  final Widget Function(BuildContext context, String errorMsg, VoidCallback onRetry)? errorBuilder;
  final Widget Function(BuildContext context, VoidCallback onRefresh)? emptyBuilder;

  const BasePagedTvView({
    super.key,
    required this.provider,
    required this.notifier,
    required this.itemBuilder,
    required this.gridDelegate,
    this.notLoginBuilder,
    this.errorBuilder,
    this.emptyBuilder,
  });

  @override
  ConsumerState<BasePagedTvView<T>> createState() => _BasePagedTvViewState<T>();
}

class _BasePagedTvViewState<T> extends ConsumerState<BasePagedTvView<T>> with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(vsync: this, duration: const Duration(seconds: 1));
  }

  Future<void> _triggerRefresh() async {
    if (_isRefreshing) return;
    setState(() {
      _isRefreshing = true;
    });
    _rotationController.repeat();

    try {
      await widget.notifier.refreshData();
    } finally {
      if (mounted) {
        _rotationController.stop();
        _rotationController.reset();
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentTvTheme = context.tvTheme;
    final state = ref.watch(widget.provider);

    final mappedIspState = PagingState<int, T>(
      pages: [state.items],
      keys: [state.currentPage],
      hasNextPage: state.canLoadMore,
      isLoading: state.controllerState.pageLoading || state.controllerState.loading,
      error: state.controllerState.pageError ? state.controllerState.errorMsg : null,
    );

    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: EdgeInsets.only(right: 16.sp, bottom: 8.sp),
            child: TvIconButton(
              icon: RotationTransition(turns: _rotationController, child: const Icon(Icons.refresh_rounded)),
              size: TvIconButtonSize.medium,
              isSecondary: true,
              onTap: _triggerRefresh,
            ),
          ),
        ),
        Expanded(
          child: DpadRegion(
            child: PagedGridView<int, T>(
              scrollController: widget.notifier.scrollController,
              state: mappedIspState,
              fetchNextPage: () {
                widget.notifier.loadNextPage();
              },
              gridDelegate: widget.gridDelegate,
              builderDelegate: PagedChildBuilderDelegate<T>(
                itemBuilder: widget.itemBuilder,
                firstPageProgressIndicatorBuilder: (_) => Center(
                  child: SizedBox(
                    width: 48.sp,
                    height: 48.sp,
                    child: CircularProgressIndicator(
                      strokeWidth: 4.sp,
                      valueColor: AlwaysStoppedAnimation<Color>(currentTvTheme.focusColor),
                    ),
                  ),
                ),
                newPageProgressIndicatorBuilder: (_) => Focus(
                  canRequestFocus: false,
                  descendantsAreFocusable: false,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.sp),
                    child: Center(
                      child: SizedBox(
                        width: 36.sp,
                        height: 36.sp,
                        child: CircularProgressIndicator(
                          strokeWidth: 3.5.sp,
                          valueColor: AlwaysStoppedAnimation<Color>(currentTvTheme.focusColor),
                        ),
                      ),
                    ),
                  ),
                ),
                firstPageErrorIndicatorBuilder: (_) {
                  if (state.controllerState.notLogin) {
                    return widget.notLoginBuilder != null
                        ? widget.notLoginBuilder!(context)
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.account_circle_outlined,
                                  size: 72.sp,
                                  color: currentTvTheme.secondaryTextColor,
                                ),
                                SizedBox(height: 16.sp),
                                Text(
                                  "需要登录后访问",
                                  style: TextStyle(fontSize: 24.sp, color: currentTvTheme.primaryTextColor),
                                ),
                                SizedBox(height: 24.sp),
                                TvButton(title: "去登录", size: TvButtonSize.medium, autofocus: true, onTap: () {}),
                              ],
                            ),
                          );
                  }

                  return widget.errorBuilder != null
                      ? widget.errorBuilder!(context, state.controllerState.errorMsg, _triggerRefresh)
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.wifi_off_rounded, size: 72.sp, color: currentTvTheme.secondaryTextColor),
                              SizedBox(height: 16.sp),
                              Text(
                                state.controllerState.errorMsg.isEmpty ? "网络加载失败，请重试" : state.controllerState.errorMsg,
                                style: TextStyle(fontSize: 22.sp, color: currentTvTheme.secondaryTextColor),
                              ),
                              SizedBox(height: 24.sp),
                              TvButton(
                                title: "重新加载",
                                size: TvButtonSize.medium,
                                autofocus: true,
                                onTap: _triggerRefresh,
                              ),
                            ],
                          ),
                        );
                },
                newPageErrorIndicatorBuilder: (_) => Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.sp),
                  child: Center(
                    child: TvButton(
                      title: "加载更多失败，点击重试",
                      size: TvButtonSize.small,
                      onTap: () {
                        widget.notifier.loadNextPage();
                      },
                    ),
                  ),
                ),
                noItemsFoundIndicatorBuilder: (_) => widget.emptyBuilder != null
                    ? widget.emptyBuilder!(context, _triggerRefresh)
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox_rounded, size: 72.sp, color: currentTvTheme.secondaryTextColor),
                            SizedBox(height: 16.sp),
                            Text(
                              "暂无直播间内容",
                              style: TextStyle(fontSize: 22.sp, color: currentTvTheme.secondaryTextColor),
                            ),
                            SizedBox(height: 24.sp),
                            TvButton(title: "刷新页面", size: TvButtonSize.medium, autofocus: true, onTap: _triggerRefresh),
                          ],
                        ),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
