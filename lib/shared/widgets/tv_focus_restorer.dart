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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ModalRoute<void>? route = ModalRoute.of(context);
    if (route != null) {
      tvRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    tvRouteObserver.unsubscribe(this);
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
