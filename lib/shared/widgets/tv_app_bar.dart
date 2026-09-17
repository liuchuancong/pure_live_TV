import 'package:flutter/material.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/app/router/extensions.dart';
import 'package:pure_live/shared/widgets/tv_button.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/widgets/tv_focus_restorer.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

/// Whether the default app bar may show its back button here.
///
/// Three conditions, and all of them have to be re-read when the route stack
/// changes: there must be something to pop, this route has to be the one on screen,
/// and — for a page that lives inside a nested navigator (every settings section page
/// is) — the *outer* navigator counts too. Such a page can be the first page of its own
/// navigator while the settings shell above it can still be popped, and without that
/// check 返回 simply did not appear on it.
///
/// A page underneath a pushed route is rebuilt while the pop is still running — at
/// that moment `canPop()` is still true, so the page drew a back button and nothing
/// recomputed it afterwards. That is the stale "返回" the user saw on the home and
/// favorites pages until an unrelated rebuild fixed it.
bool tvShowsBackButton(BuildContext context) {
  final bool isCurrent = ModalRoute.of(context)?.isCurrent ?? true;
  if (!isCurrent) return false;
  if (Navigator.of(context).canPop()) return true;
  // `rootNavigator: true` throws when this context is not under a Navigator at all
  // (a widget test that mounts an app bar on its own).
  return Navigator.maybeOf(context, rootNavigator: true)?.canPop() ?? false;
}

class TvAppBar extends StatefulWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final bool showBackButton;
  final Future<bool> Function()? beforeBack;

  /// Focus node bound to the back button, so a page can steer focus onto it
  /// (e.g. when d-pad navigation hits the top edge of the content).
  final FocusNode? backFocusNode;

  const TvAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.showBackButton = true,
    this.beforeBack,
    this.backFocusNode,
  });

  @override
  State<TvAppBar> createState() => _TvAppBarState();
}

class _TvAppBarState extends State<TvAppBar> with RouteAware {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ModalRoute<void>? route = ModalRoute.of(context);
    if (route != null) tvRouteObserver.subscribe(this, route);
  }

  @override
  void dispose() {
    tvRouteObserver.unsubscribe(this);
    super.dispose();
  }

  // Rebuild on every route-stack change so [tvShowsBackButton] is recomputed:
  // `didPopNext` is the one that clears a stale back button after a pop.
  @override
  void didPopNext() => setState(() {});

  @override
  void didPop() => setState(() {});

  @override
  void didPush() => setState(() {});

  @override
  void didPushNext() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final bool hasBackButton = widget.showBackButton && tvShowsBackButton(context);
    final bool hasTitle = (widget.title != null && widget.title!.isNotEmpty) || widget.titleWidget != null;
    final bool hasActions = widget.actions != null && widget.actions!.isNotEmpty;

    if (!hasBackButton && !hasTitle && !hasActions) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      height: 66.sp,
      padding: EdgeInsets.symmetric(horizontal: 16.sp),
      alignment: Alignment.centerLeft,
      color: Colors.transparent,
      child: Row(
        children: [
          if (hasBackButton) ...[
            TvButton(
              title: i18n('ui_back'),
              size: TvButtonSize.mini,
              autofocus: false,
              focusNode: widget.backFocusNode,
              icon: Icon(Icons.arrow_back_ios_new_rounded, size: 24.sp),
              onTap: () async {
                if (widget.beforeBack != null) {
                  final shouldPop = await widget.beforeBack!();
                  if (!shouldPop) return;
                }
                if (context.mounted) {
                  context.back();
                }
              },
            ),
            SizedBox(width: 16.sp),
          ],
          Expanded(
            child:
                widget.titleWidget ??
                Text(
                  widget.title ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.t24W700.copyWith(color: tvTheme.primaryTextColor),
                ),
          ),
          if (widget.actions != null) ...[
            SizedBox(width: 16.sp),
            Row(mainAxisSize: MainAxisSize.min, children: widget.actions!),
          ],
        ],
      ),
    );
  }
}
