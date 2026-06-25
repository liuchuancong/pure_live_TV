import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/widgets/tv_app_bar.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:pure_live/consts/back_ground_source.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:pure_live/services/background_config/background_config_model.dart';

class TvScaffold extends StatelessWidget {
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
  Widget build(BuildContext context) {
    Widget? finalAppBar;

    if (showAppBar) {
      final bool canPop = Navigator.of(context).canPop();
      final bool effectiveShowBackButton = showBackButton ?? canPop;
      finalAppBar = appBar ?? TvAppBar(title: title, beforeBack: beforeBack, showBackButton: effectiveShowBackButton);
    }

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const IgnorePointer(child: _BackgroundLayer()),
          const IgnorePointer(child: _MaskLayer()),
          DpadRegion(
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (finalAppBar != null) SafeArea(bottom: false, child: finalAppBar),
                  Expanded(child: child),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundLayer extends StatelessWidget {
  const _BackgroundLayer();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<BackgroundConfigModel>(
      stream: SettingsService.to.bg.configChanges,
      initialData: SettingsService.to.bgState,
      builder: (context, snapshot) {
        final config = snapshot.data!;

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

class _MaskLayer extends StatelessWidget {
  const _MaskLayer();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<BackgroundConfigModel>(
      stream: SettingsService.to.bg.configChanges,
      initialData: SettingsService.to.bgState,
      builder: (context, snapshot) {
        final config = snapshot.data!;

        return ColoredBox(color: Colors.black.withValues(alpha: config.maskOpacity));
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
    final image = SettingsService.to.bg.cachedBackgroundImage;

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(gradient: LinearGradient(colors: config.gradientColors)),
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
}

class _VideoBackground extends StatelessWidget {
  const _VideoBackground();

  @override
  Widget build(BuildContext context) {
    final controller = SettingsService.to.bg.videoController;

    return SizedBox.expand(
      child: Video(fit: BoxFit.cover, controller: controller),
    );
  }
}
