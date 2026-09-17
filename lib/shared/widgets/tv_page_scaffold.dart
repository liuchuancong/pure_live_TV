import 'package:flutter/material.dart';
import 'package:pure_live/shared/widgets/tv_app_bar.dart';
import 'package:pure_live/shared/widgets/tv_page_shell.dart';

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

class _TvPageScaffoldState extends State<TvPageScaffold> {
  /// This page's 返回 button node. External when the caller passed one, created here
  /// when this page builds the default app bar.
  FocusNode? _backNode;
  bool _ownsBackNode = false;

  @override
  void dispose() {
    if (_ownsBackNode) _backNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget? bar;

    if (widget.showAppBar) {
      final TvAppBar? custom = widget.appBar;
      final bool effectiveShowBackButton =
          widget.showBackButton ?? custom?.showBackButton ?? tvShowsBackButton(context);

      // A page can name its 返回 node either on the scaffold or inside the app bar it
      // built itself; both mean "this node is mine, create none".
      final FocusNode? externalNode = widget.backFocusNode ?? custom?.backFocusNode;
      if (!effectiveShowBackButton) {
        _backNode = null;
        _ownsBackNode = false;
      } else if (externalNode != null) {
        _backNode = externalNode;
        _ownsBackNode = false;
      } else {
        _backNode ??= FocusNode(debugLabel: 'tv_page_back');
        _ownsBackNode = true;
      }

      // One bar either way, so a page that passed its own `TvAppBar` keeps its title
      // and actions *and* gets the focus node the shell needs: without the node its
      // 返回 was drawn but unreachable — nothing handed focus Up to it, so the remote
      // could not select it and it never even showed the focused look the other
      // pages' 返回 buttons have. `/settings` was exactly that page.
      bar = TvAppBar(
        title: custom?.title ?? widget.title,
        titleWidget: custom?.titleWidget ?? widget.titleWidget,
        actions: custom?.actions ?? widget.actions,
        beforeBack: custom?.beforeBack ?? widget.beforeBack,
        showBackButton: effectiveShowBackButton,
        backFocusNode: _backNode,
      );
    }

    return TvPageShell(topBar: bar, openingFocus: _backNode, child: widget.child);
  }
}
