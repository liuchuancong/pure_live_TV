import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pure_live/shared/widgets/tv_focus_restorer.dart';

/// The shared plumbing under [TvScaffold] and `TvPageScaffold`.
///
/// It owns the transparent `Scaffold`, keeps a **covered** page out of the focus tree,
/// hands Up at the content's top edge to a node the page names, turns Down on the
/// page's own top bar into "enter the content", and claims the opening highlight.
///
/// It deliberately knows nothing about app bars or back buttons: what a page puts in
/// [topBar] is the page's own business (its own app bar, its own 返回 button, its own
/// `onTap`), and the node the highlight should open on is passed in as
/// [openingFocus].
class TvPageShell extends StatefulWidget {
  const TvPageShell({super.key, required this.child, this.topBar, this.openingFocus});

  /// The page's content.
  final Widget child;

  /// The page's own top bar, if it built one.
  final Widget? topBar;

  /// The page's own 返回 button node, when it has one. Up at the content's top edge
  /// lands on it and the highlight opens on it; without it the keyboard opens on the
  /// first content row and Up leaves the region.
  final FocusNode? openingFocus;

  @override
  State<TvPageShell> createState() => _TvPageShellState();
}

class _TvPageShellState extends State<TvPageShell> with RouteAware {
  /// Lets the focus passes reach the content region's nodes.
  final GlobalKey<DpadRegionState> _contentRegionKey = GlobalKey<DpadRegionState>();

  /// Whether this page is the route on top. A covered page keeps its widgets laid out,
  /// at the coordinates of the page now on screen, so leaving it focusable lets the
  /// remote drive an invisible page — the d-pad layer restores focus by geometry when
  /// the node it held dies.
  bool _isCurrent = true;

  bool _claimedFocus = false;
  int _focusClaimAttempts = 0;
  static const int _maxFocusClaimAttempts = 15;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _claimFocus());
  }

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
  void didPush() {
    _setCurrent(true);
    _reclaim();
  }

  @override
  void didPopNext() {
    _setCurrent(true);
    _reclaim();
  }

  @override
  void didPushNext() => _setCurrent(false);

  @override
  void didPop() => _setCurrent(false);

  void _setCurrent(bool current) {
    if (_isCurrent == current || !mounted) return;
    setState(() => _isCurrent = current);
  }

  /// Rearms the opening-focus claim and schedules it for the next frame.
  void _reclaim() {
    _claimedFocus = false;
    _focusClaimAttempts = 0;
    WidgetsBinding.instance.addPostFrameCallback((_) => _claimFocus());
  }

  /// Down on the page's top bar hands the keyboard to its content explicitly.
  ///
  /// Up already works — the content region's top edge calls [_onContentEdge] — but the
  /// other direction was left to the d-pad policy's cross-region search, which can
  /// settle on a row of a page that is no longer visible. Naming the target makes the
  /// round trip deterministic instead of geometric.
  KeyEventResult _onTopBarKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    if (event.logicalKey != LogicalKeyboardKey.arrowDown) return KeyEventResult.ignored;
    final FocusNode? target = _contentFocusTarget();
    if (target == null) return KeyEventResult.ignored;
    DpadRegion.ofNode(target)?.noteFocus(target);
    target.requestFocus();
    return KeyEventResult.handled;
  }

  /// The row the remote should land on when it comes down from the top bar.
  FocusNode? _contentFocusTarget() {
    final DpadRegionState? region = _contentRegionKey.currentState;
    if (region == null) return null;
    final FocusNode? remembered = region.lastFocused;
    if (remembered != null && _usable(remembered) && region.focusNodes.contains(remembered)) return remembered;
    return _topLeftMost(region.focusNodes.where(_usable));
  }

  /// Up at the content's top edge: hand focus to whatever the page put above it.
  void _onContentEdge(TraversalDirection direction) {
    if (direction != TraversalDirection.up) return;
    final FocusNode? above = widget.openingFocus;
    if (above == null || !_usable(above)) return;
    DpadRegion.ofNode(above)?.noteFocus(above);
    above.requestFocus();
  }

  /// Puts the opening highlight on the page's own 返回 button when it has one, and on
  /// the first content row otherwise.
  ///
  /// Left to itself the d-pad layer picks the node nearest the *previously* focused
  /// one, so a page could open on any row of its list. This runs once per page (and
  /// again whenever the page comes back to the top), retrying a few frames while the
  /// bar and the rows are being built.
  void _claimFocus() {
    if (!mounted || _claimedFocus) return;
    final ModalRoute<void>? route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) {
      if (_focusClaimAttempts < _maxFocusClaimAttempts) {
        _focusClaimAttempts++;
        WidgetsBinding.instance.addPostFrameCallback((_) => _claimFocus());
      }
      return;
    }

    // 1. The page's own 返回 button, when it has one.
    final FocusNode? back = widget.openingFocus;
    if (back != null && _usable(back)) {
      if (!identical(FocusManager.instance.primaryFocus, back)) {
        DpadRegion.ofNode(back)?.noteFocus(back);
        back.requestFocus();
      }
      _claimedFocus = true;
      return;
    }

    // 2. No bar: the top-left-most row, which is the first one visually.
    final DpadRegionState? region = _contentRegionKey.currentState;
    final FocusNode? first = _topLeftMost(region?.focusNodes.where(_usable) ?? const <FocusNode>[]);
    if (first != null) {
      region!.noteFocus(first);
      first.requestFocus();
      _claimedFocus = true;
      return;
    }

    // 3. Nothing to focus yet: retry briefly.
    if (_focusClaimAttempts < _maxFocusClaimAttempts) {
      _focusClaimAttempts++;
      WidgetsBinding.instance.addPostFrameCallback((_) => _claimFocus());
    }
  }

  /// Attached, mounted and able to take focus — the rule the d-pad package's own
  /// `DpadMarks` uses, minus its unexported helper.
  static bool _usable(FocusNode node) =>
      node.parent != null && node.context?.mounted == true && node.canRequestFocus;

  /// The visually first node: topmost, then leftmost.
  FocusNode? _topLeftMost(Iterable<FocusNode> nodes) {
    FocusNode? best;
    Rect? bestRect;
    for (final FocusNode node in nodes) {
      final Rect? rect = _rectOf(node);
      if (rect == null) continue;
      final bool better =
          bestRect == null ||
          rect.top < bestRect.top - 1 ||
          (rect.top <= bestRect.top + 1 && rect.left < bestRect.left);
      if (better) {
        best = node;
        bestRect = rect;
      }
    }
    return best;
  }

  Rect? _rectOf(FocusNode node) {
    final RenderObject? object = node.context?.findRenderObject();
    if (object is! RenderBox || !object.attached || !object.hasSize) return null;
    return object.localToGlobal(Offset.zero) & object.size;
  }

  @override
  Widget build(BuildContext context) {
    final bool hasBar = widget.topBar != null;
    // Content region: its top edge hands focus to the page's bar when there is one;
    // otherwise the d-pad is left to search across regions.
    final Widget content = DpadRegion(
      key: _contentRegionKey,
      verticalEdge: hasBar ? DpadEdgeBehavior.stop : DpadEdgeBehavior.leave,
      onEdge: hasBar ? _onContentEdge : null,
      child: TvFocusRestorer(child: widget.child),
    );

    return Scaffold(
      // Transparent on purpose: the background is painted once for the whole app
      // (see [TvAppBackground]) instead of per page.
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          DpadRegion(
            child: ExcludeFocus(
              excluding: !_isCurrent,
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.topBar != null)
                      SafeArea(
                        bottom: false,
                        // Passive node: it never takes focus itself, it only sees the
                        // keys the bar's buttons leave unhandled (a Down on 返回).
                        child: Focus(
                          canRequestFocus: false,
                          skipTraversal: true,
                          onKeyEvent: _onTopBarKey,
                          child: widget.topBar!,
                        ),
                      ),
                    Expanded(child: content),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
