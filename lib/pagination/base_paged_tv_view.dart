import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/widgets/index.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pure_live/pagination/paging_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/pagination/models/paging_param.dart';
import 'package:flutter_virtual_scroll/flutter_virtual_scroll.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

class BasePagedTvView<T> extends ConsumerStatefulWidget {
  final PagingParam<T> param;
  final PagingCore<T> Function() getNotifier;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final SliverGridDelegateWithFixedCrossAxisCount gridDelegate;
  final Widget Function(BuildContext context)? notLoginBuilder;
  final Widget Function(BuildContext context, String errorMsg, VoidCallback onRetry)? errorBuilder;
  final Widget Function(BuildContext context, VoidCallback onRefresh)? emptyBuilder;

  const BasePagedTvView({
    super.key,
    required this.param,
    required this.getNotifier,
    required this.itemBuilder,
    required this.gridDelegate,
    this.notLoginBuilder,
    this.errorBuilder,
    this.emptyBuilder,
  });

  @override
  ConsumerState<BasePagedTvView<T>> createState() => _BasePagedTvViewState<T>();
}

class _BasePagedTvViewState<T> extends ConsumerState<BasePagedTvView<T>> {
  late PagingCore<T> _core;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _core = widget.getNotifier();
    _core.scrollController.addListener(_scrollListener);
  }

  @override
  void didUpdateWidget(covariant BasePagedTvView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newCore = widget.getNotifier();
    if (_core != newCore) {
      _core.scrollController.removeListener(_scrollListener);
      _core = newCore;
      _core.scrollController.addListener(_scrollListener);
    }
  }

  void _scrollListener() {
    final scroll = _core.scrollController;
    if (!scroll.hasClients) return;

    final threshold = 400.sp;
    if (scroll.position.pixels >= scroll.position.maxScrollExtent - threshold) {
      final currentState = ref.read(pagingCoreProvider(widget.param));
      if (currentState.canLoadMore && !currentState.controllerState.loading) {
        _core.loadNextPage();
      }
    }
  }

  Future<void> _triggerRefresh() async {
    if (_isRefreshing) return;
    if (!mounted) return;
    setState(() => _isRefreshing = true);
    try {
      await _core.refresh();
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  void dispose() {
    _core.scrollController.removeListener(_scrollListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pagingCoreProvider(widget.param));

    if (state.items.isEmpty && (state.controllerState.pageLoading || _isRefreshing)) {
      return const AppStatusView(type: AppStatusType.loading);
    }

    if (state.items.isEmpty) {
      if (state.controllerState.notLogin) {
        return widget.notLoginBuilder != null
            ? widget.notLoginBuilder!(context)
            : AppStatusView(
                type: AppStatusType.empty,
                icon: Icons.account_circle_outlined,
                title: "需要登录后访问",
                buttonText: "去登录",
                onTap: () {},
              );
      }

      // 加载错误
      if (state.controllerState.pageError) {
        final errMsg = state.controllerState.errorMsg.isNotEmpty ? state.controllerState.errorMsg : "网络加载失败，请重试";
        return widget.errorBuilder != null
            ? widget.errorBuilder!(context, errMsg, _triggerRefresh)
            : AppStatusView(type: AppStatusType.error, subtitle: errMsg, onTap: _triggerRefresh);
      }

      // 空数据
      return widget.emptyBuilder != null
          ? widget.emptyBuilder!(context, _triggerRefresh)
          : AppStatusView(type: AppStatusType.empty, title: "暂无直播间内容", onTap: _triggerRefresh);
    }

    return Column(
      children: [
        Expanded(
          child: DpadRegion(
            child: VirtualGridView(
              controller: _core.scrollController,
              gridDelegate: widget.gridDelegate,
              cacheExtent: 100.sp,
              padding: EdgeInsets.all(16.sp),
              physics: const ClampingScrollPhysics(),
              itemCount: state.items.length,
              itemBuilder: (context, index) {
                return DpadRegion(
                  onFocusChange: (hasFocus) {
                    if (hasFocus && index < widget.gridDelegate.crossAxisCount) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        final scroll = _core.scrollController;
                        if (scroll.hasClients && scroll.position.pixels != 0) {
                          scroll.animateTo(0, duration: const Duration(milliseconds: 50), curve: Curves.easeOutCubic);
                        }
                      });
                    }
                  },
                  child: widget.itemBuilder(context, state.items[index], index),
                );
              },
            ),
          ),
        ),
        AppStatusView(type: AppStatusType.loading, isMini: true)
            .animate(target: state.controllerState.loading ? 1.0 : 0.0)
            .custom(
              duration: 350.ms,
              curve: Curves.fastOutSlowIn,
              builder: (context, value, child) {
                return SizedBox(height: value * 64.sp, child: child);
              },
            )
            .fade(begin: 0.0, end: 1.0, duration: 250.ms)
            .move(begin: Offset(0, 15.sp), end: const Offset(0, 0), duration: 350.ms, curve: Curves.easeOutCubic),
      ],
    );
  }
}
