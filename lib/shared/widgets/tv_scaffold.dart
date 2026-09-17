import 'dart:ui' show ImageFilter;

import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pure_live/shared/widgets/tv_app_bar.dart';
import 'package:pure_live/shared/widgets/tv_focus_restorer.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:pure_live/services/index.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pure_live/shared/utils/cache_manager.dart';
import 'package:pure_live/shared/consts/back_ground_source.dart';
import 'package:pure_live/shared/theme/index.dart';

class TvScaffold extends StatefulWidget {
  final Widget child;
  final String? title;
  final TvAppBar? appBar;
  final bool showAppBar;
  final bool? showBackButton;
  final Future<bool> Function()? beforeBack;

  const TvScaffold({
    super.key,
    required this.child,
    this.title,
    this.appBar,
    this.showAppBar = true,
    this.showBackButton,
    this.beforeBack,
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
  /// the content region remembers, otherwise the first usable one.
  FocusNode? _contentFocusTarget() {
    final DpadRegionState? region = _contentRegionKey.currentState;
    if (region == null) return null;
    bool usable(FocusNode node) => node.parent != null && node.context?.mounted == true && node.canRequestFocus;
    final FocusNode? remembered = region.lastFocused;
    if (remembered != null && usable(remembered) && region.focusNodes.contains(remembered)) return remembered;
    return region.focusNodes.where(usable).firstOrNull;
  }

  /// Whether [node] is one of this page's rows, rather than its app bar.
  ///
  /// The nearest [DpadRegion] above the focused widget is the content region for a
  /// row and the outer region for the back button, which is exactly the
  /// distinction the focus claim needs.
  bool _contentOwnsFocus(FocusNode? node) {
    final BuildContext? nodeContext = node?.context;
    if (nodeContext == null) return false;
    return nodeContext.findAncestorStateOfType<DpadRegionState>() == _contentRegionKey.currentState;
  }

  /// Lands the keyboard on the first content row of a page that just came to the
  /// top.
  ///
  /// The back button carries `autofocus: true`, so without this pass every page
  /// opened with the highlight parked on 返回. It also settles the race with the
  /// d-pad layer's own restore: the node that held the keyboard dies when the page
  /// below is covered (its subtree stops being focusable), and the restore that
  /// follows can otherwise land on a node of that invisible page.
  ///
  /// The pass stands down as soon as a row of this page holds the keyboard, so it
  /// never fights a user who has already moved on, and it only ever runs once per
  /// page.
  void _claimFocus() {
    if (!mounted || _claimedFocus) return;
    final ModalRoute<void>? route = ModalRoute.of(context);
    // A dialog (or any other route) above owns the keyboard.
    if (route != null && !route.isCurrent) return;
    if (_contentOwnsFocus(FocusManager.instance.primaryFocus)) {
      _claimedFocus = true;
      return;
    }

    final DpadRegionState? region = _contentRegionKey.currentState;
    // Same usability rule the package's own DpadMarks uses, minus the unexported
    // helper: attached, mounted, and able to take focus.
    bool usable(FocusNode node) => node.parent != null && node.context?.mounted == true && node.canRequestFocus;

    final FocusNode? first = region?.focusNodes.where(usable).firstOrNull;
    if (first != null) {
      region!.noteFocus(first);
      first.requestFocus();
      if (_contentOwnsFocus(FocusManager.instance.primaryFocus)) {
        _claimedFocus = true;
        return;
      }
    }

    // No focusable row yet (rows that arrive a few frames late, async font lists
    // and friends): retry briefly, then settle for the back button so the page is
    // never left without a highlight.
    if (_focusClaimAttempts < _maxFocusClaimAttempts) {
      _focusClaimAttempts++;
      WidgetsBinding.instance.addPostFrameCallback((_) => _claimFocus());
      return;
    }
    _claimedFocus = true;
    final FocusNode? back = _backNode;
    if (back != null && usable(back)) {
      DpadRegion.ofNode(back)?.noteFocus(back);
      back.requestFocus();
    }
  }

  int _focusClaimAttempts = 0;
  static const int _maxFocusClaimAttempts = 6;

  /// Set once this page has claimed the keyboard (or given up on it).
  bool _claimedFocus = false;

  void _onContentEdge(TraversalDirection direction) {
    if (direction != TraversalDirection.up) return;
    final FocusNode? back = _backNode;
    final bool usable =
        back != null && back.parent != null && back.context?.mounted == true && back.canRequestFocus;
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
      finalAppBar = widget.appBar ??
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
      child: Stack(
        fit: StackFit.expand,
        children: [_BackgroundLayer(), _MaskLayer()],
      ),
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
        return ColoredBox(
          color: (lightSurface ? Colors.white : Colors.black).withValues(alpha: config.maskOpacity),
        );
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
        return CachedNetworkImageProvider(
          url,
          cacheManager: CustomImageCacheManager.instance,
        );
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
