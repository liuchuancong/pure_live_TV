import 'package:dpad/dpad.dart';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pure_live/services/index.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:pure_live/shared/widgets/tv_app_bar.dart';
import 'package:pure_live/shared/utils/cache_manager.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pure_live/shared/widgets/tv_focus_restorer.dart';
import 'package:pure_live/shared/consts/back_ground_source.dart';

class TvScaffold extends StatefulWidget {
  final Widget child;
  final String? title;
  final TvAppBar? appBar;
  final bool showAppBar;
  final bool? showBackButton;
  final Future<bool> Function()? beforeBack;

  /// Identity of the page inside this scaffold, when the scaffold is shared.
  ///
  /// The settings shell keeps ONE [TvScaffold] for every settings page and swaps
  /// the page with a nested navigator, so pushing 排序 inside 导航与显示设置 fires no
  /// route callback here: from this scaffold's point of view nothing was pushed.
  /// A changed value therefore means "the content is a different page now, open it
  /// like a page" (from 返回).
  final Object? contentIdentity;

  const TvScaffold({
    super.key,
    required this.child,
    this.title,
    this.appBar,
    this.showAppBar = true,
    this.showBackButton,
    this.beforeBack,
    this.contentIdentity,
  });

  @override
  State<TvScaffold> createState() => _TvScaffoldState();
}

class _TvScaffoldState extends State<TvScaffold> with RouteAware {
  /// The app bar back button, when [TvScaffold] builds the default app bar.
  /// The content region's top edge hands focus to this node, so "up" from the
  /// first content row always reaches the back button without relying on
  /// cross-region geometric search (which is fragile on devices with overscan
  /// / safe-area offsets).
  FocusNode? _backNode;

  /// Lets the initial-focus pass reach the content region's nodes.
  final GlobalKey<DpadRegionState> _contentRegionKey = GlobalKey<DpadRegionState>();

  /// Whether this page is the route on top.
  ///
  /// A covered page keeps its widgets laid out (the navigator maintains state), so
  /// its rows still have screen rectangles — exactly the rectangles of the page
  /// now on screen, because a settings page pushing another settings page draws the
  /// same shape twice. Leaving them focusable is what let the remote drive the
  /// invisible page below: the d-pad layer restores focus itself when the node it
  /// held dies, and picks the geometrically nearest node, invisible or not.
  bool _isCurrent = true;

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
    _backNode?.dispose();
    super.dispose();
  }

  @override
  void didPush() => _setCurrent(true);

  @override
  void didUpdateWidget(covariant TvScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The page inside a shared scaffold changed (see [TvScaffold.contentIdentity]):
    // open the new page the same way a pushed route opens.
    if (oldWidget.contentIdentity == widget.contentIdentity) return;
    _claimedFocus = false;
    _focusClaimAttempts = 0;
    WidgetsBinding.instance.addPostFrameCallback((_) => _claimFocus());
  }

  @override
  void didPopNext() => _setCurrent(true);

  @override
  void didPushNext() => _setCurrent(false);

  @override
  void didPop() => _setCurrent(false);

  void _setCurrent(bool current) {
    if (_isCurrent == current) return;
    if (!mounted) return;
    setState(() => _isCurrent = current);
    // Coming back to the top: [TvFocusRestorer] hands focus back to the item the
    // user acted on, which beats picking the first row here.
    if (current) return;
  }

  /// Down on the app bar hands the keyboard to the page's rows explicitly.
  ///
  /// Up already works — the content region's top edge calls [_onContentEdge] — but
  /// the other direction was left to the d-pad policy's cross-region search: from
  /// the back button it looks for the nearest focusable below, and with a shared
  /// scaffold that search can settle on a row of the page *inside* that is no longer
  /// the visible one (the inner navigator keeps the pages below it alive and laid
  /// out, at the same coordinates). Naming the target here makes the round trip
  /// deterministic instead of geometric.
  KeyEventResult _onAppBarKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    if (event.logicalKey != LogicalKeyboardKey.arrowDown) return KeyEventResult.ignored;
    final FocusNode? target = _contentFocusTarget();
    if (target == null) return KeyEventResult.ignored;
    DpadRegion.ofNode(target)?.noteFocus(target);
    target.requestFocus();
    return KeyEventResult.handled;
  }

  /// The row the remote should land on when it comes down from the app bar: the one
  /// the content region remembers, otherwise the visually first one.
  FocusNode? _contentFocusTarget() {
    final DpadRegionState? region = _contentRegionKey.currentState;
    if (region == null) return null;
    bool usable(FocusNode node) => node.parent != null && node.context?.mounted == true && node.canRequestFocus;
    final FocusNode? remembered = region.lastFocused;
    if (remembered != null && usable(remembered) && region.focusNodes.contains(remembered)) return remembered;
    return _topLeftMost(region.focusNodes.where(usable));
  }

  /// Lands the opening highlight on the page's first content row, or on 返回
  /// when there is nothing to focus yet (the rows load late) or the page has
  /// no rows at all.
  ///
  /// Opening on the first row is what a remote user expects: the page is
  /// immediately walkable with Down and OK, and 返回 stays one Up away
  /// ([_onContentEdge]). Opening on 返回 instead cost an extra key press
  /// before anything could be selected.
  ///
  /// Left to itself the d-pad layer picks the node nearest the *previously* focused
  /// one, so a page could open on any row of the list — 通用设置 on one device, a
  /// different row elsewhere — which looks random and makes the remote feel
  /// unreliable. Naming the target here makes it the same every time.
  ///
  /// It also settles the race with the d-pad layer's restore: the node that held the
  /// keyboard dies when the page below is covered (its subtree stops being
  /// focusable), and that restore can otherwise land on a node of the invisible page.
  ///
  /// Runs once per page (and once per content change in a shared scaffold), retrying
  /// for a while as the app bar and the rows are being built — lazy pages
  /// (paged grids, async lists) take more than a couple of frames to offer any
  /// focusable node, and a claim that gave up left the keyboard dead: the first
  /// Down then went to 返回 via the d-pad fallback instead of into the list.
  void _claimFocus() {
    if (!mounted || _claimedFocus) return;
    final ModalRoute<void>? route = ModalRoute.of(context);
    // A dialog (or any other route) above owns the keyboard.
    if (route != null && !route.isCurrent) return;

    // Same usability rule the package's own DpadMarks uses, minus the unexported
    // helper: attached, mounted, and able to take focus.
    bool usable(FocusNode node) => node.parent != null && node.context?.mounted == true && node.canRequestFocus;

    final DpadRegionState? region = _contentRegionKey.currentState;

    // 1. The top-left-most content row, which is the first one visually instead
    //    of whatever order the focus tree reports.
    final FocusNode? first = _topLeftMost(region?.focusNodes.where(usable) ?? const <FocusNode>[]);
    if (first != null) {
      final FocusNode? primary = FocusManager.instance.primaryFocus;
      // Steer only when the keyboard is genuinely elsewhere *for this page*:
      // either nobody holds it, or the holder is dead (the node of the page
      // below, unmounted or excluded from focus once covered), or it is one of
      // this page's own nodes. A dead foreign node must not be mistaken for
      // "the user moved" — that left the opening highlight to the d-pad
      // fallback, which picks the row nearest the *previous* page's focus
      // (a mid-list row like 通用) instead of the first one.
      final bool foreignDead = primary != null && !(primary.context?.mounted == true && primary.canRequestFocus);
      final bool steering =
          primary == null || primary == _backNode || foreignDead || (region != null && _insideRegion(primary, region));
      if (steering) {
        region!.noteFocus(first);
        first.requestFocus();
        _keepOpeningFocus(first, region);
      }
      _claimedFocus = true;
      return;
    }

    // 2. No row yet (or a page that has none): 返回 holds the keyboard for now.
    //    Not claimed yet — a lazy page's rows can still appear, and the opening
    //    highlight then moves onto the first one (step 1 on a later attempt).
    final FocusNode? back = _backNode;
    if (back != null && usable(back)) {
      if (!identical(FocusManager.instance.primaryFocus, back)) {
        DpadRegion.ofNode(back)?.noteFocus(back);
        back.requestFocus();
      }
      if (_focusClaimAttempts < _maxFocusClaimAttempts) {
        _focusClaimAttempts++;
        WidgetsBinding.instance.addPostFrameCallback((_) => _claimFocus());
        return;
      }
      _claimedFocus = true;
      return;
    }

    // 3. Nothing to focus yet (rows that arrive a few frames late, async font
    //    lists and friends): keep retrying, then leave the highlight where it is
    //    rather than parking it somewhere arbitrary.
    if (_focusClaimAttempts < _maxFocusClaimAttempts) {
      _focusClaimAttempts++;
      WidgetsBinding.instance.addPostFrameCallback((_) => _claimFocus());
    }
  }

  /// Whether [node] is (or sits inside) one of the content region's rows.
  bool _insideRegion(FocusNode node, DpadRegionState region) {
    for (FocusNode? walk = node; walk != null; walk = walk.parent) {
      if (region.focusNodes.contains(walk)) return true;
    }
    return false;
  }

  /// Re-asserts the opening highlight for a short window after the page opens.
  ///
  /// The d-pad layer answers a dead foreign node (the page below losing focus)
  /// with its own restore, which runs a post-frame callback plus a microtask
  /// after this scaffold claimed the first row — and wins the race, moving the
  /// highlight to the row nearest the *previous* page's focus instead. Holding
  /// the opening target for a few more frames lets this claim outlast that
  /// fallback without ever fighting the user: the moment the keyboard is on any
  /// other live node of this page (another row, or 返回), the guard stands down.
  void _keepOpeningFocus(FocusNode node, DpadRegionState region) {
    int attempts = 0;
    void attempt() {
      if (!mounted || attempts >= 12) return;
      attempts++;
      final FocusNode? primary = FocusManager.instance.primaryFocus;
      final bool userMoved = primary != null && primary != node && _insideRegion(primary, region);
      if (primary == _backNode || userMoved) return;
      if (primary != node) {
        region.noteFocus(node);
        node.requestFocus();
      }
      WidgetsBinding.instance.addPostFrameCallback((_) => attempt());
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => attempt());
  }

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

  int _focusClaimAttempts = 0;
  static const int _maxFocusClaimAttempts = 15;

  /// Set once this page has claimed the keyboard (or given up on it).
  bool _claimedFocus = false;

  void _onContentEdge(TraversalDirection direction) {
    if (direction != TraversalDirection.up) return;
    final FocusNode? back = _backNode;
    final bool usable = back != null && back.parent != null && back.context?.mounted == true && back.canRequestFocus;
    if (!usable) return;
    DpadRegion.ofNode(back)?.noteFocus(back);
    back.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    Widget? finalAppBar;

    if (widget.showAppBar) {
      // Same rule the app bar applies itself, so the top-edge focus handoff is
      // only installed for a back button that is really on screen.
      final bool effectiveShowBackButton = widget.showBackButton ?? tvShowsBackButton(context);
      _backNode = (widget.appBar == null && effectiveShowBackButton)
          ? (_backNode ?? FocusNode(debugLabel: 'tv_scaffold_back'))
          : null;
      finalAppBar =
          widget.appBar ??
          TvAppBar(
            title: widget.title,
            beforeBack: widget.beforeBack,
            showBackButton: effectiveShowBackButton,
            backFocusNode: _backNode,
          );
    }

    // The content gets its own region with a stopped top edge: pressing up on
    // the first row deterministically focuses the back button above. Down at
    // the bottom edge simply stays put, as there is nothing below.
    final Widget content = _backNode != null
        ? DpadRegion(
            key: _contentRegionKey,
            verticalEdge: DpadEdgeBehavior.stop,
            onEdge: _onContentEdge,
            child: TvFocusRestorer(child: widget.child),
          )
        : TvFocusRestorer(child: widget.child);

    return Scaffold(
      // Transparent on purpose: the background is painted once for the whole app
      // (see [TvAppBackground]) instead of per page.
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          DpadRegion(
            // A covered page offers no focus candidates at all: its rows and its
            // back button sit at the coordinates of the page on screen, and the
            // d-pad layer's restore picks by geometry (see [_isCurrent]).
            child: ExcludeFocus(
              excluding: !_isCurrent,
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (finalAppBar != null)
                      SafeArea(
                        bottom: false,
                        // Passive node: it never takes focus itself, it only sees the
                        // keys the app bar's buttons leave unhandled (a Down on 返回).
                        child: Focus(
                          canRequestFocus: false,
                          skipTraversal: true,
                          onKeyEvent: _onAppBarKey,
                          child: finalAppBar,
                        ),
                      ),
                    // Route-aware focus memory: when a pushed page (a settings
                    // sub-page, a dialog) pops away, focus returns to the item
                    // the user acted on instead of dying on the dpad root's
                    // top-left fallback.
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

/// The background for the entire app: one instance, mounted below the Navigator.
///
/// It used to be built inside every [TvScaffold], so each push and pop
/// re-mounted the layer — a new image layer, a new `Video` widget over the same
/// controller — which is what made navigation flicker. Now the pages are
/// transparent and this single widget owns the background pixels for all of
/// them, so it never rebuilds on navigation and its image/video work is done
/// once.
class TvAppBackground extends StatelessWidget {
  const TvAppBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: Stack(fit: StackFit.expand, children: [_BackgroundLayer(), _MaskLayer()]),
    );
  }
}

class _BackgroundLayer extends StatelessWidget {
  const _BackgroundLayer();

  @override
  Widget build(BuildContext context) {
    // Mountable before bootstrap and in widget tests, where the settings
    // container does not exist yet: the theme supplies the background then.
    if (!SettingsService.to.isInitialized) {
      return _ThemeBackground(theme: context.tvTheme);
    }

    return StreamBuilder<BackgroundConfigModel>(
      stream: SettingsService.to.bg.configChanges,
      initialData: SettingsService.to.bgState,
      builder: (context, snapshot) {
        final config = snapshot.data!;

        // No background configured: the active theme supplies it. Without this
        // every page painted the same opaque `solidColor` (a fixed dark navy),
        // so switching themes only changed the accent and each palette looked
        // identical.
        if (config.source == BackgroundSource.none) {
          return _ThemeBackground(theme: context.tvTheme);
        }

        return switch (config.source) {
          BackgroundSource.none || BackgroundSource.color => _SolidBackground(config: config),
          BackgroundSource.gradient => _GradientBackground(config: config),
          BackgroundSource.localImage ||
          BackgroundSource.assetImage ||
          BackgroundSource.networkImage => _ImageBackground(config: config),
          BackgroundSource.assetVideo ||
          BackgroundSource.localVideo ||
          BackgroundSource.networkVideo => const _VideoBackground(),
        };
      },
    );
  }
}

/// Background taken from the active theme: its own colour, lifted towards the
/// accent so each palette reads as a distinct surface rather than a flat fill.
class _ThemeBackground extends StatelessWidget {
  const _ThemeBackground({required this.theme});

  final TvThemeData theme;

  @override
  Widget build(BuildContext context) {
    final Color base = theme.backgroundColor;
    final Color lift = Color.lerp(base, theme.focusColor, 0.10) ?? base;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[base, lift, base],
        ),
      ),
    );
  }
}

class _MaskLayer extends StatelessWidget {
  const _MaskLayer();

  @override
  Widget build(BuildContext context) {
    if (!SettingsService.to.isInitialized) return const SizedBox.shrink();

    return StreamBuilder<BackgroundConfigModel>(
      stream: SettingsService.to.bg.configChanges,
      initialData: SettingsService.to.bgState,
      builder: (context, snapshot) {
        final config = snapshot.data!;

        // The mask exists to keep text readable over a photo or video. A theme
        // background is already contrast-checked, so masking it only muddies the
        // palette (and would wash out a light theme).
        if (config.source == BackgroundSource.none) {
          return const SizedBox.shrink();
        }

        // A light palette needs a light wash over artwork: darkening it would
        // leave the dark text unreadable.
        final bool lightSurface = context.tvTheme.backgroundColor.computeLuminance() > 0.5;
        return ColoredBox(color: (lightSurface ? Colors.white : Colors.black).withValues(alpha: config.maskOpacity));
      },
    );
  }
}

class _SolidBackground extends StatelessWidget {
  final BackgroundConfigModel config;

  const _SolidBackground({required this.config});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(color: config.solidColor);
  }
}

class _GradientBackground extends StatelessWidget {
  final BackgroundConfigModel config;

  const _GradientBackground({required this.config});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: LinearGradient(colors: config.gradientColors)),
    );
  }
}

class _ImageBackground extends StatelessWidget {
  final BackgroundConfigModel config;

  const _ImageBackground({required this.config});

  @override
  Widget build(BuildContext context) {
    final image = _resolveImage();
    // Fits that can letterbox a differently-shaped picture previously showed
    // the flat gradient beside it — visibly "the background does not fill the
    // screen". A blurred, cover-filled copy of the same picture fills those
    // bars instead; cover/fill never letterbox so they skip the extra layer.
    final bool needsBackdrop = image != null && _fitCanLetterbox(config.boxFit);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Always the bottom layer: it also covers the decode window of a fresh
        // image, so a cold start shows the palette instead of a black frame.
        DecoratedBox(
          decoration: BoxDecoration(gradient: LinearGradient(colors: config.gradientColors)),
        ),
        if (needsBackdrop)
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 32, sigmaY: 32, tileMode: TileMode.clamp),
            child: DecoratedBox(
              decoration: BoxDecoration(
                image: DecorationImage(image: image, fit: BoxFit.cover),
              ),
            ),
          ),
        if (image != null)
          DecoratedBox(
            decoration: BoxDecoration(
              image: DecorationImage(image: image, fit: config.boxFit),
            ),
          ),
      ],
    );
  }

  static bool _fitCanLetterbox(BoxFit fit) =>
      fit == BoxFit.contain ||
      fit == BoxFit.fitWidth ||
      fit == BoxFit.fitHeight ||
      fit == BoxFit.none ||
      fit == BoxFit.scaleDown;

  /// Remote backgrounds come from two exclusive slots (the setters guarantee
  /// only one is filled): embedded bytes for downloaded random-API pictures
  /// whose URL would return a different image next time, otherwise the stored
  /// stable URL through [CachedNetworkImageProvider] with the on-disk cache.
  ImageProvider? _resolveImage() {
    if (config.source == BackgroundSource.networkImage) {
      final base64 = config.currentBoxImageBase64;
      if (base64.isNotEmpty) {
        return SettingsService.to.bg.cachedBackgroundImage;
      }
      final url = config.networkImageUrl;
      if (url != null && url.isNotEmpty) {
        return CachedNetworkImageProvider(url, cacheManager: CustomImageCacheManager.instance);
      }
      return null;
    }
    return SettingsService.to.bg.cachedBackgroundImage;
  }
}

class _VideoBackground extends StatelessWidget {
  const _VideoBackground();

  @override
  Widget build(BuildContext context) {
    final controller = SettingsService.to.bg.videoController;

    return SizedBox.expand(
      child: Video(
        controller: controller,
        fit: BoxFit.cover,
        // The wallpaper layer is pixels, not a player: media_kit's adaptive
        // controls would paint a scrub bar over every page, and a background
        // must not hold a wakelock of its own.
        controls: (state) => const SizedBox.shrink(),
        wakelock: false,
      ),
    );
  }
}
