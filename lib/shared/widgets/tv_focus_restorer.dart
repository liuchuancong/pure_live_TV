import 'dart:async';
import 'package:flutter/material.dart';

/// Shared with the app's [GoRouter]-based navigator so every page using
/// [TvFocusRestorer] gets route-visibility events. Without a registered
/// observer the [RouteAware] callbacks below never fire.
final RouteObserver<ModalRoute<void>> tvRouteObserver = RouteObserver<ModalRoute<void>>();

/// Restores focus to the item the user acted on when a route pushed above
/// this subtree pops away (a settings sub-page, a dialog, ...).
///
/// The dpad root's fallback restore runs during the pop transition and picks
/// the top-left-most node of the whole tree — usually the outgoing page's own
/// back button. When that page disposes, the focus dies and the returned-to
/// page is left with a highlight that no longer reacts to the remote. Here we
/// remember the focused item at push time and hand focus back to it after the
/// pop, which is what a TV user expects.
class TvFocusRestorer extends StatefulWidget {
  final Widget child;

  const TvFocusRestorer({super.key, required this.child});

  @override
  State<TvFocusRestorer> createState() => _TvFocusRestorerState();
}

class _TvFocusRestorerState extends State<TvFocusRestorer> with RouteAware {
  /// How many frames the page-local restore keeps asserting itself. Enough to
  /// outlast the dpad root's fallback, short enough never to fight the user.
  static const int _maxRestoreAttempts = 3;

  FocusNode? _focusWhenCovered;

  /// The last node of *this route* that held the keyboard while the route was
  /// current, so a focus death after the bounded restore can still be corrected.
  FocusNode? _lastInsideRoute;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ModalRoute<void>? route = ModalRoute.of(context);
    if (route != null) {
      tvRouteObserver.subscribe(this, route);
    }
    // didChangeDependencies can run again on dependency changes; remove first
    // so the listener never accumulates.
    FocusManager.instance.removeListener(_handleFocusChange);
    FocusManager.instance.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    tvRouteObserver.unsubscribe(this);
    FocusManager.instance.removeListener(_handleFocusChange);
    super.dispose();
  }

  @override
  void didPushNext() {
    // Another route is covering this page. The dpad layer has not moved focus
    // yet, so whatever holds focus now is the item the user acted on.
    final FocusNode? primary = FocusManager.instance.primaryFocus;
    if (primary != null && primary is! FocusScopeNode) {
      _focusWhenCovered = primary;
    }
  }

  @override
  void didPopNext() {
    final FocusNode? node = _focusWhenCovered;
    _focusWhenCovered = null;
    if (node == null) return;
    _restore(node);
  }

  /// Watches for focus deaths while this route is on top.
  ///
  /// A dialog's focus tree disposes only when its *exit transition* ends —
  /// about 300ms after the pop started, long after the frame-bounded
  /// [restore] above has finished. When those nodes die the d-pad layer
  /// answers the death itself and lands on the top-most focusable it finds,
  /// which is the app bar's back button instead of the row the user acted on.
  /// Re-asserting the last known in-route node covers exactly that window; a
  /// focus that moved to another node of this route is left alone (the user is
  /// navigating).
  ///
  /// The decision is deferred by one frame, because a focus that *moves* into
  /// another route's scope also reports a bare [FocusScopeNode] for an instant.
  /// Restoring on that instant is what pulled the highlight back to back on every
  /// up/down round trip: the settings shell keeps one scaffold and swaps the page
  /// inside it with a nested navigator, so the keyboard crossing between the app
  /// bar and a page of that nested navigator always passes through such a scope —
  /// which is why only third- and deeper-level pages were affected. One frame
  /// later the focus is either on something real (nothing to do) or genuinely
  /// gone (restore).
  void _handleFocusChange() {
    if (!mounted) return;
    final ModalRoute<dynamic>? route = ModalRoute.of(context);
    if (route == null || !route.isCurrent) return;

    final FocusNode? primary = FocusManager.instance.primaryFocus;
    if (primary != null && _isInsideRoute(primary, route)) {
      if (primary is! FocusScopeNode) _lastInsideRoute = primary;
      return;
    }

    if (_restoreScheduled) return;
    _restoreScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restoreScheduled = false;
      if (!mounted) return;
      final FocusNode? settled = FocusManager.instance.primaryFocus;
      // Something real has the keyboard: the focus moved, it did not die.
      if (settled != null && settled is! FocusScopeNode) return;
      final FocusNode? node = _lastInsideRoute;
      if (node == null) return;
      _restore(node);
    });
  }

  bool _restoreScheduled = false;

  bool _isInsideRoute(FocusNode node, ModalRoute<dynamic> route) {
    final BuildContext? context = node.context;
    if (context == null || !context.mounted) return false;
    return identical(ModalRoute.of(context), route);
  }

  /// Hands focus back to [node], and keeps asserting it for a few frames.
  ///
  /// The dpad root runs its own fallback restore in a post-frame callback plus
  /// a microtask. Both restores therefore race, and when the root wins it picks
  /// the top-left-most node of the whole tree — which can be a node of a route
  /// further down the stack, leaving the page the user is looking at with no
  /// usable focus (the remote then appears dead and the title bar is
  /// unreachable). Re-asserting for a couple of frames makes the page-local
  /// restore win without fighting the user beyond that.
  void _restore(FocusNode node) {
    int attempts = 0;
    void attempt() {
      if (!mounted || attempts >= _maxRestoreAttempts) return;
      attempts++;

      if (FocusManager.instance.primaryFocus == node) return; // Settled.
      final bool usable = node.parent != null && node.context?.mounted == true && node.canRequestFocus;
      if (!usable) return;
      node.requestFocus();

      WidgetsBinding.instance.addPostFrameCallback((_) => scheduleMicrotask(attempt));
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => scheduleMicrotask(attempt));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
