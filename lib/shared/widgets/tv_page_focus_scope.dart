import 'package:flutter/material.dart';
import 'package:pure_live/shared/widgets/tv_focus_restorer.dart';
/// Route-aware focus policy for a page that lives inside a **shared** scaffold.
///
/// The settings shell keeps one `TvScaffold` for every settings page and swaps the
/// page with a nested navigator, so the scaffold never sees those pushes: from its
/// point of view the route never changed, `didPushNext` never fires, and the page
/// that was just covered keeps its rows focusable — laid out at the same
/// coordinates as the new page, because both are settings pages of the same shape.
/// The d-pad layer then restores focus by geometry and the remote drives a screen
/// nobody is looking at, which is the "focus is stuck on 返回 / up and down do
/// nothing" failure on third- and fourth-level pages.
///
/// This wrapper sits *inside* the nested navigator, so it does get the route
/// callbacks, and it applies the same two rules `TvScaffold` applies to its own
/// route:
///
/// * a covered page [ExcludeFocus]es its subtree, so it offers no focus
///   candidates at all;
/// * a page that comes to the top claims the keyboard for its first focusable.
///
/// Restoring "the row the user acted on" when a page above pops is deliberately
/// *not* done here: a second `TvFocusRestorer` under the one `TvScaffold` already
/// installs made the back button and the first row hand focus back and forth every
/// frame (an endless frame loop, which is worse than the missing restore). The
/// region's own focus memory covers that case.
class TvPageFocusScope extends StatefulWidget {
  const TvPageFocusScope({super.key, required this.child});

  final Widget child;

  @override
  State<TvPageFocusScope> createState() => _TvPageFocusScopeState();
}

class _TvPageFocusScopeState extends State<TvPageFocusScope> with RouteAware {
  final FocusNode _root = FocusNode(debugLabel: 'tv-page-focus-scope', skipTraversal: true);

  bool _isCurrent = true;
  bool _claimedFocus = false;
  int _claimAttempts = 0;
  static const int _maxClaimAttempts = 6;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ModalRoute<void>? route = ModalRoute.of(context);
    if (route != null) tvRouteObserver.subscribe(this, route);
  }

  @override
  void dispose() {
    tvRouteObserver.unsubscribe(this);
    _root.dispose();
    super.dispose();
  }

  @override
  void didPush() {
    _setCurrent(true);
    _claimFocus();
  }

  @override
  void didPopNext() => _setCurrent(true);

  @override
  void didPushNext() => _setCurrent(false);

  @override
  void didPop() => _setCurrent(false);

  void _setCurrent(bool current) {
    if (_isCurrent == current || !mounted) return;
    setState(() => _isCurrent = current);
  }

  /// Whether the keyboard is inside this page.
  bool get _holdsKeyboard {
    for (FocusNode? node = FocusManager.instance.primaryFocus; node != null; node = node.parent) {
      if (identical(node, _root)) return true;
    }
    return false;
  }

  Iterable<FocusNode> get _candidates =>
      _root.descendants.where((node) => node.canRequestFocus && node.context?.mounted == true);

  /// Lands the keyboard on this page's first focusable.
  ///
  /// Retries briefly: a page's rows can arrive a few frames after the push (async
  /// lists, fonts), and the d-pad layer's own restore races this.
  void _claimFocus() {
    if (!mounted || _claimedFocus) return;
    if (_holdsKeyboard) {
      _claimedFocus = true;
      return;
    }
    final ModalRoute<dynamic>? route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return; // another page is on top
    final FocusNode? first = _candidates.firstOrNull;
    if (first != null) {
      first.requestFocus();
      if (_holdsKeyboard) {
        _claimedFocus = true;
        return;
      }
    }
    if (_claimAttempts < _maxClaimAttempts) {
      _claimAttempts++;
      WidgetsBinding.instance.addPostFrameCallback((_) => _claimFocus());
      return;
    }
    _claimedFocus = true;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _root,
      canRequestFocus: false,
      skipTraversal: true,
      child: ExcludeFocus(
        excluding: !_isCurrent,
        child: widget.child,
      ),
    );
  }
}
