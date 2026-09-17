import 'package:flutter/material.dart';
import 'package:pure_live/shared/widgets/tv_focus_restorer.dart';

/// Keeps a page that is **covered by another page of the same scaffold** out of the
/// focus tree.
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
/// callbacks, and does that one job: exclude a covered page from focus. The opening
/// highlight is the scaffold's business (it lands on 返回 through
/// `TvScaffold.contentIdentity`), so this widget deliberately does not claim focus —
/// two claimants is what made the back button and a row hand focus back and forth
/// every frame.
class TvPageFocusScope extends StatefulWidget {
  const TvPageFocusScope({super.key, required this.child});

  final Widget child;

  @override
  State<TvPageFocusScope> createState() => _TvPageFocusScopeState();
}

class _TvPageFocusScopeState extends State<TvPageFocusScope> with RouteAware {
  bool _isCurrent = true;

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

  @override
  void didPush() => _setCurrent(true);

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

  @override
  Widget build(BuildContext context) {
    return ExcludeFocus(excluding: !_isCurrent, child: widget.child);
  }
}
