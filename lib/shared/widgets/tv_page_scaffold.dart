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
      final bool effectiveShowBackButton = widget.showBackButton ?? tvShowsBackButton(context);
      if (!effectiveShowBackButton) {
        _backNode = null;
        _ownsBackNode = false;
      } else if (widget.backFocusNode != null) {
        _backNode = widget.backFocusNode;
        _ownsBackNode = false;
      } else if (widget.appBar == null) {
        _backNode ??= FocusNode(debugLabel: 'tv_page_back');
        _ownsBackNode = true;
      } else {
        // A custom app bar builds its own button and node.
        _backNode = null;
        _ownsBackNode = false;
      }
      bar =
          widget.appBar ??
          TvAppBar(
            title: widget.title,
            titleWidget: widget.titleWidget,
            actions: widget.actions,
            beforeBack: widget.beforeBack,
            showBackButton: effectiveShowBackButton,
            backFocusNode: _backNode,
          );
    }

    return TvPageShell(topBar: bar, openingFocus: _backNode, child: widget.child);
  }
}
