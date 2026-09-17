import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/shared/widgets/tv_app_bar.dart';
import 'package:pure_live/shared/widgets/tv_page_shell.dart';
import 'package:pure_live/shared/widgets/tv_focus_restorer.dart';

/// A page that owns its chrome: **its own app bar and its own 返回 button**, plus the
/// focus wiring between them (the highlight opens on 返回, Down walks into the page,
/// Up comes back).
///
/// This is the page-level half of what `TvScaffold` used to do for the whole app. A
/// shared scaffold could not belong to a page: the settings shell swapped pages inside
/// one scaffold, so its 返回 button outlived the page it was drawn for and kept taking
/// the highlight. Here the page builds the bar, owns the node and decides what 返回
/// does.
///
/// Pages that need no bar use `TvScaffold`; pages that want a different bar can ignore
/// this widget entirely and pass their own into `TvPageShell`.
class TvPageScaffold extends StatefulWidget {
  final Widget child;
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final TvAppBar? appBar;
  final bool showAppBar;
  final bool? showBackButton;
  final Future<bool> Function()? beforeBack;

  /// The page's own 返回 button node, when it wants to steer focus onto it itself.
  final FocusNode? backFocusNode;

  const TvPageScaffold({
    super.key,
    required this.child,
    this.title,
    this.titleWidget,
    this.actions,
    this.appBar,
    this.showAppBar = true,
    this.showBackButton,
    this.beforeBack,
    this.backFocusNode,
  });

  @override
  State<TvPageScaffold> createState() => _TvPageScaffoldState();
}

class _TvPageScaffoldState extends State<TvPageScaffold> with RouteAware {
  /// This page's 返回 button node. External when the caller passed one, created here
  /// when this page builds the default app bar.
  FocusNode? _backNode;
  bool _ownsBackNode = false;

  @override
  void dispose() {
    tvRouteObserver.unsubscribe(this);
    if (_ownsBackNode) _backNode?.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ModalRoute<void>? route = ModalRoute.of(context);
    if (route != null) tvRouteObserver.subscribe(this, route);
  }

  /// A pushed page popped back to this one. The child's focus node died with it,
  /// so the keyboard is left on a dead node and the page stops responding to the
  /// remote. Hand the opening focus back to 返回, exactly like the first entry.
  @override
  void didPopNext() {
    int attempts = 0;
    void attempt() {
      if (!mounted || attempts >= 8) return;
      attempts++;
      final FocusNode? node = _backNode;
      if (node == null) return;
      if (node.parent == null || node.context?.mounted != true || !node.canRequestFocus) {
        WidgetsBinding.instance.addPostFrameCallback((_) => attempt());
        return;
      }
      final FocusNode? primary = FocusManager.instance.primaryFocus;
      if (primary != null && primary != node && primary.context?.mounted == true && primary.canRequestFocus) {
        return;
      }
      DpadRegion.ofNode(node)?.noteFocus(node);
      node.requestFocus();
      WidgetsBinding.instance.addPostFrameCallback((_) => attempt());
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => attempt());
  }

  bool _canPopAnyNavigator(BuildContext context) {
    if (Navigator.of(context).canPop()) return true;
    return Navigator.maybeOf(context, rootNavigator: true)?.canPop() ?? false;
  }

  @override
  Widget build(BuildContext context) {
    Widget? bar;

    if (widget.showAppBar) {
      final TvAppBar? custom = widget.appBar;
      final bool wantsBack = widget.showBackButton ?? custom?.showBackButton ?? _canPopAnyNavigator(context);

      final FocusNode? externalNode = widget.backFocusNode ?? custom?.backFocusNode;
      if (!wantsBack) {
        _backNode = null;
        _ownsBackNode = false;
      } else if (externalNode != null) {
        _backNode = externalNode;
        _ownsBackNode = false;
      } else {
        _backNode ??= FocusNode(debugLabel: 'tv_page_back');
        _ownsBackNode = true;
      }

      bar = TvAppBar(
        title: custom?.title ?? widget.title,
        titleWidget: custom?.titleWidget ?? widget.titleWidget,
        actions: custom?.actions ?? widget.actions,
        beforeBack: custom?.beforeBack ?? widget.beforeBack,
        showBackButton: wantsBack,
        backFocusNode: _backNode,
      );
    }

    return TvPageShell(topBar: bar, openingFocus: _backNode, child: widget.child);
  }
}
