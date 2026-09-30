part of 'tv_scaffold.dart';

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
          BackgroundSource.networkImage => wallpaperBlurred(_ImageBackground(config: config), config.blurSigma),
          BackgroundSource.assetVideo ||
          BackgroundSource.localVideo ||
          // Not const on purpose: a const instance is identical across builds, so
          // Element.updateChild skips the rebuild and player/poster changes never
          // reach the screen (the layer keeps painting the old frame).
          BackgroundSource.networkVideo => wallpaperBlurred(_VideoBackground(), config.blurSigma),
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
    final bg = SettingsService.to.bg;

    // While a player (live or VOD) is running, the wallpaper decoder is released
    // and the layer paints the frame captured before playback: the background
    // stops competing for the decoder and the Surface.
    final poster = bg.posterFrame;
    if (poster != null) {
      return SizedBox.expand(child: Image.memory(poster, fit: BoxFit.cover, gaplessPlayback: true));
    }

    final controller = bg.videoController;
    // The player is lazy: right after switching to a video wallpaper the
    // controller may not exist yet, so paint black until it does.
    if (controller == null) return const SizedBox.expand(child: ColoredBox(color: Colors.black));

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
