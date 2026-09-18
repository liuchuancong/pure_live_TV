import 'dart:ui' show ImageFilter;

import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/services/index.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:pure_live/shared/utils/cache_manager.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pure_live/shared/consts/back_ground_source.dart';
import 'package:pure_live/shared/widgets/tv_page_shell.dart';

/// A page shell **without chrome**: no app bar, no 返回 button, no title.
///
/// This widget used to build the app bar and own the back button for every page, which
/// is exactly what made focus unpredictable: the settings shell kept ONE of these for
/// all of its pages, so the 返回 button belonged to the shell rather than to the page it
/// was drawn on, survived every page change, and kept pulling the highlight back.
///
/// The app bar and the back button belong to the page now — see [TvPageScaffold], where
/// the page builds its own bar, owns its own node and decides what 返回 does. Pages that
/// need no bar (the home tabs, a fullscreen page) use this one and get only what is
/// genuinely shared: the transparent page background, "a covered page offers no focus",
/// and the opening highlight on the first row.
class TvScaffold extends StatelessWidget {
  const TvScaffold({super.key, required this.child, this.openingRegion, this.openingFocus});

  final Widget child;

  /// See [TvPageShell.openingRegion] — the region the opening highlight claims.
  final GlobalKey<DpadRegionState>? openingRegion;

  /// See [TvPageShell.openingFocus] — an exact node the opening highlight
  /// claims (the home page aims it at the selected side-menu entry).
  final FocusNode? openingFocus;

  @override
  Widget build(BuildContext context) =>
      TvPageShell(openingRegion: openingRegion, openingFocus: openingFocus, child: child);
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

/// Background taken from the active theme: its own colour, lifted towards
/// the accent so each palette reads as a distinct surface rather than a flat fill.
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
