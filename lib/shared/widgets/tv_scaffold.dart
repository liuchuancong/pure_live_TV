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
  final FocusNode? backFocusNode;

  const TvScaffold({
    super.key,
    required this.child,
    this.title,
    this.appBar,
    this.showAppBar = true,
    this.showBackButton,
    this.beforeBack,
    this.backFocusNode,
  });

  @override
  State<TvScaffold> createState() => _TvScaffoldState();
}

class _TvScaffoldState extends State<TvScaffold> with RouteAware {
  /// The app bar back button node. Its ownership is decided in [build]:
  /// external when the caller passes [TvScaffold.backFocusNode], otherwise
  /// created here when the default [TvAppBar] is used.
  FocusNode? _backNode;
  bool _ownsBackNode = false;

  /// Lets the initial-focus pass reach the content region's nodes.
  final GlobalKey<DpadRegionState> _contentRegionKey = GlobalKey<DpadRegionState>();

  /// Whether this page is the route on top. A covered page excludes focus so
  /// its widgets cannot be reached while another page is on screen.
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
    if (_ownsBackNode) _backNode?.dispose();
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
    if (_isCurrent == current) return;
    if (!mounted) return;
    setState(() => _isCurrent = current);
  }

  /// Rearms the opening-focus claim and schedules it for the next frame.
  void _reclaim() {
    _claimedFocus = false;
    _focusClaimAttempts = 0;
    WidgetsBinding.instance.addPostFrameCallback((_) => _claimFocus());
  }

  /// Down on the app bar hands the keyboard to the page's rows explicitly.
  KeyEventResult _onAppBarKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    if (event.logicalKey != LogicalKeyboardKey.arrowDown) return KeyEventResult.ignored;
    final FocusNode? target = _contentFocusTarget();
    if (target == null) return KeyEventResult.ignored;
    DpadRegion.ofNode(target)?.noteFocus(target);
    target.requestFocus();
    return KeyEventResult.handled;
  }

  /// The row the remote should land on when it comes down from the app bar.
  FocusNode? _contentFocusTarget() {
    final DpadRegionState? region = _contentRegionKey.currentState;
    if (region == null) return null;
    bool usable(FocusNode node) => node.parent != null && node.context?.mounted == true && node.canRequestFocus;
    final FocusNode? remembered = region.lastFocused;
    if (remembered != null && usable(remembered) && region.focusNodes.contains(remembered)) return remembered;
    return _topLeftMost(region.focusNodes.where(usable));
  }

  /// Puts the opening highlight on the back button, or on the first content
  /// row when the page has no back button (the menu itself, the home page, a
  /// fullscreen page).
  ///
  /// Runs once per page (and once per content change in a shared scaffold),
  /// retrying a few frames while the app bar and the rows are being built.
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

    bool usable(FocusNode node) => node.parent != null && node.context?.mounted == true && node.canRequestFocus;

    // 1. 返回按钮优先。
    final FocusNode? back = _backNode;
    if (back != null && usable(back)) {
      if (!identical(FocusManager.instance.primaryFocus, back)) {
        DpadRegion.ofNode(back)?.noteFocus(back);
        back.requestFocus();
      }
      _claimedFocus = true;
      return;
    }

    // 2. 没有返回按钮：落内容第一项。
    final DpadRegionState? region = _contentRegionKey.currentState;
    final FocusNode? first = _topLeftMost(region?.focusNodes.where(usable) ?? const <FocusNode>[]);
    if (first != null) {
      region!.noteFocus(first);
      first.requestFocus();
      _claimedFocus = true;
      return;
    }

    // 3. 都还没准备好：重试几帧。
    if (_focusClaimAttempts < _maxFocusClaimAttempts) {
      _focusClaimAttempts++;
      WidgetsBinding.instance.addPostFrameCallback((_) => _claimFocus());
    }
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
      final bool effectiveShowBackButton = widget.showBackButton ?? tvShowsBackButton(context);
      if (!effectiveShowBackButton) {
        _backNode = null;
        _ownsBackNode = false;
      } else if (widget.backFocusNode != null) {
        _backNode = widget.backFocusNode;
        _ownsBackNode = false;
      } else if (widget.appBar == null) {
        _backNode ??= FocusNode(debugLabel: 'tv_scaffold_back');
        _ownsBackNode = true;
      } else {
        _backNode = null;
        _ownsBackNode = false;
      }
      finalAppBar =
          widget.appBar ??
          TvAppBar(
            title: widget.title,
            beforeBack: widget.beforeBack,
            showBackButton: effectiveShowBackButton,
            backFocusNode: _backNode,
          );
    }

    // Content region: top edge hands focus to the back button when there is
    // one; without a back button the dpad is left to search across regions.
    final Widget content = DpadRegion(
      key: _contentRegionKey,
      verticalEdge: _backNode != null ? DpadEdgeBehavior.stop : DpadEdgeBehavior.leave,
      onEdge: _backNode != null ? _onContentEdge : null,
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
    if (!SettingsService.to.isInitialized) {
      return _ThemeBackground(theme: context.tvTheme);
    }

    return StreamBuilder<BackgroundConfigModel>(
      stream: SettingsService.to.bg.configChanges,
      initialData: SettingsService.to.bgState,
      builder: (context, snapshot) {
        final config = snapshot.data!;

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

        if (config.source == BackgroundSource.none) {
          return const SizedBox.shrink();
        }

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
    final bool needsBackdrop = image != null && _fitCanLetterbox(config.boxFit);

    return Stack(
      fit: StackFit.expand,
      children: [
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
        controls: (state) => const SizedBox.shrink(),
        wakelock: false,
      ),
    );
  }
}
