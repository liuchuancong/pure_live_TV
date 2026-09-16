import 'dart:ui' show ImageFilter;

import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
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

class _TvScaffoldState extends State<TvScaffold> {
  /// The app bar back button, when [TvScaffold] builds the default app bar.
  /// The content region's top edge hands focus to this node, so "up" from the
  /// first content row always reaches the back button without relying on
  /// cross-region geometric search (which is fragile on devices with overscan
  /// / safe-area offsets).
  FocusNode? _backNode;

  @override
  void dispose() {
    _backNode?.dispose();
    super.dispose();
  }

  void _onContentEdge(TraversalDirection direction) {
    if (direction != TraversalDirection.up) return;
    final FocusNode? back = _backNode;
    final bool usable = back != null &&
        back.parent != null &&
        back.context?.mounted == true &&
        back.canRequestFocus;
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
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (finalAppBar != null) SafeArea(bottom: false, child: finalAppBar),
                  // Route-aware focus memory: when a pushed page (a settings
                  // sub-page, a dialog) pops away, focus returns to the item
                  // the user acted on instead of dying on the dpad root's
                  // top-left fallback.
                  Expanded(child: content),
                ],
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
