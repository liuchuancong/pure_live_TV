import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:pure_live/theme/tv_theme_x.dart';
import 'package:pure_live/widgets/tv_button.dart';
import 'package:pure_live/widgets/tv_icon_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/pagination/models/base_paged_state.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

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
  final ScrollController _scrollController = ScrollController();
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100.sp) {
      widget.notifier.loadNextPage();
    }
  }

  Future<void> _triggerRefresh() async {
    if (_isRefreshing) return;
    setState(() {
      _isRefreshing = true;
    });
    _rotationController.repeat();

    try {
      await widget.notifier.refreshData();
    } catch (_) {
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
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentTvTheme = context.tvTheme;
    final state = ref.watch(widget.provider);

    if (state.items.isEmpty && state.controllerState.pageLoading) {
      return Center(
        child: SizedBox(
          width: 48.sp,
          height: 48.sp,
          child: CircularProgressIndicator(
            strokeWidth: 4.sp,
            valueColor: AlwaysStoppedAnimation<Color>(currentTvTheme.focusColor),
          ),
        ),
      );
    }

    if (state.items.isEmpty) {
      if (state.controllerState.notLogin) {
        return widget.notLoginBuilder != null
            ? widget.notLoginBuilder!(context)
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.account_circle_outlined, size: 72.sp, color: currentTvTheme.secondaryTextColor),
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

      if (state.controllerState.pageError) {
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
                    TvButton(title: "重新加载", size: TvButtonSize.medium, autofocus: true, onTap: _triggerRefresh),
                  ],
                ),
              );
      }

      if (state.controllerState.pageEmpty) {
        return widget.emptyBuilder != null
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
              );
      }
    }

    return Column(
      children: [
        DpadRegion(
          child: Container(
            alignment: Alignment.centerRight,
            color: Colors.transparent,
            padding: EdgeInsets.only(right: 16.sp, bottom: 20.sp),
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
            child: GridView.builder(
              controller: _scrollController,
              gridDelegate: widget.gridDelegate,
              itemCount: state.items.length + (state.canLoadMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == state.items.length) {
                  return Focus(
                    canRequestFocus: false,
                    descendantsAreFocusable: false,
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
                  );
                }
                return widget.itemBuilder(context, state.items[index], index);
              },
            ),
          ),
        ),
      ],
    );
  }
}
