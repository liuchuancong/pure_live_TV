import 'package:pure_live/exports/package_export.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pure_live/shared/pagination/paging_core.dart';
import 'package:pure_live/shared/pagination/models/paging_param.dart';
import 'package:flutter_virtual_scroll/flutter_virtual_scroll.dart';
import 'package:pure_live/shared/widgets/index.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';

class BasePagedTvView<T> extends ConsumerStatefulWidget {
  final PagingParam<T> param;
  final PagingCore<T> Function() getNotifier;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final SliverGridDelegateWithFixedCrossAxisCount gridDelegate;
  final Widget Function(BuildContext context)? notLoginBuilder;
  final Widget Function(BuildContext context, String errorMsg, VoidCallback onRetry)? errorBuilder;
  final Widget Function(BuildContext context, VoidCallback onRefresh)? emptyBuilder;

  /// Business context for the built-in empty state (icon/copy/action); used
  /// when [emptyBuilder] is null.
  final EmptyScene emptyScene;

  /// Callbacks behind the scene's navigational action (go to search / browse hot).
  final VoidCallback? onEmptyGoSearch;
  final VoidCallback? onEmptyGoHot;

  /// Where the built-in login-required status sends the user (account
  /// settings). Null keeps the status buttonless: title and subtitle still
  /// explain what happened, and pages that can navigate pass this.
  final VoidCallback? onGoLogin;

  const BasePagedTvView({
    super.key,
    required this.param,
    required this.getNotifier,
    required this.itemBuilder,
    required this.gridDelegate,
    this.notLoginBuilder,
    this.errorBuilder,
    this.emptyBuilder,
    this.emptyScene = EmptyScene.generic,
    this.onEmptyGoSearch,
    this.onEmptyGoHot,
    this.onGoLogin,
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
        // The reference's login status view: the platform hid its data behind a
        // session, so the copy says so instead of reading as a network failure.
        return widget.notLoginBuilder != null
            ? widget.notLoginBuilder!(context)
            : AppStatusView(
                type: AppStatusType.notLogin,
                icon: Icons.account_circle_outlined,
                title: i18n('login_required_title'),
                subtitle: i18n('login_required_subtitle'),
                buttonText: i18n('go_to_login'),
                onTap: widget.onGoLogin,
              );
      }

      // Load failure
      if (state.controllerState.pageError) {
        final errMsg = state.controllerState.errorMsg.isNotEmpty
            ? state.controllerState.errorMsg
            : i18n('network_error_subtitle');
        return widget.errorBuilder != null
            ? widget.errorBuilder!(context, errMsg, _triggerRefresh)
            : AppStatusView(type: AppStatusType.error, subtitle: errMsg, onTap: _triggerRefresh);
      }

      // No results
      return widget.emptyBuilder != null
          ? widget.emptyBuilder!(context, _triggerRefresh)
          : sceneEmptyView(
              context,
              scene: widget.emptyScene,
              onRetry: _triggerRefresh,
              onGoSearch: widget.onEmptyGoSearch,
              onGoHot: widget.onEmptyGoHot,
            );
    }

    return Column(
      children: [
        Expanded(
          // No `DpadRegion` here on purpose. The callers already wrap this
          // view in a `TvTabView` region whose edges they choose; a region per
          // grid cell (plus one around the grid) replaced that region for every
          // cell with default `leave/leave` edges, silently discarding the
          // caller's `horizontalEdge: stop` and fragmenting the focus memory
          // that makes the grid return to the last watched card.
          //
          // The per-cell `onFocusChange` also animated the grid back to offset
          // 0 whenever a first-row card was focused, competing with the padded
          // auto-scroll `DpadFocusable` already performs.
          child: VirtualGridView(
            controller: _core.scrollController,
            gridDelegate: widget.gridDelegate,
            cacheExtent: 100.sp,
            padding: EdgeInsets.all(16.sp),
            physics: const ClampingScrollPhysics(),
            itemCount: state.items.length,
            itemBuilder: (context, index) => widget.itemBuilder(context, state.items[index], index),
          ),
        ),
        // Mounted only while loading: an always-mounted loader kept a repeating
        // AnimationController (or SpinKit) ticking at 60 fps even collapsed to
        // height 0, pinning the UI/raster threads awake on every paged page.
        if (state.controllerState.loading)
          AppStatusView(type: AppStatusType.loading, isMini: true)
              .animate()
              .fade(begin: 0.0, end: 1.0, duration: 250.ms)
              .move(begin: Offset(0, 15.sp), end: const Offset(0, 0), duration: 350.ms, curve: Curves.easeOutCubic),
      ],
    );
  }
}
