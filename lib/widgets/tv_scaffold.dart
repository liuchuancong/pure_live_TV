import 'package:pure_live/common/index.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:pure_live/services/background/back_ground_source.dart';

class TvScaffold extends StatelessWidget {
  final Widget child;
  const TvScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        final bgCtrl = SettingsService.to.bg;
        Widget bgWidget = switch (bgCtrl.source) {
          BackgroundSource.none => const _NoneBackground(),
          BackgroundSource.color => const _ColorBackground(),
          BackgroundSource.gradient => const _GradientBackground(),
          BackgroundSource.localImage ||
          BackgroundSource.assetImage ||
          BackgroundSource.networkImage => const _ImageBackground(),
          BackgroundSource.assetVideo ||
          BackgroundSource.localVideo ||
          BackgroundSource.networkVideo => const _VideoBackground(),
        };

        return Stack(
          children: [
            bgWidget,
            Obx(() => Container(color: Colors.black.withValues(alpha: bgCtrl.maskOpacity.value))),
            DpadRegion(child: child),
          ],
        );
      }),
    );
  }
}

class _NoneBackground extends StatelessWidget {
  const _NoneBackground();

  @override
  Widget build(BuildContext context) {
    final bg = SettingsService.to.bg;
    return Container(color: bg.solidColor);
  }
}

class _ColorBackground extends StatelessWidget {
  const _ColorBackground();

  @override
  Widget build(BuildContext context) {
    final bg = SettingsService.to.bg;
    return Obx(() => Container(color: bg.solidColor));
  }
}

class _GradientBackground extends StatelessWidget {
  const _GradientBackground();

  @override
  Widget build(BuildContext context) {
    final bg = SettingsService.to.bg;
    return Obx(
      () => Container(
        decoration: BoxDecoration(gradient: LinearGradient(colors: bg.gradientColors)),
      ),
    );
  }
}

class _ImageBackground extends StatelessWidget {
  const _ImageBackground();

  @override
  Widget build(BuildContext context) {
    final bg = SettingsService.to.bg;
    return Stack(
      children: [
        Obx(
          () => Container(
            decoration: BoxDecoration(gradient: LinearGradient(colors: bg.gradientColors)),
          ),
        ),
        if (bg.cachedBackgroundImage != null)
          Positioned.fill(
            child: Obx(
              () => DecoratedBox(
                decoration: BoxDecoration(
                  image: DecorationImage(image: bg.cachedBackgroundImage!, fit: bg.boxFit),
                ),
              ),
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
    final bg = SettingsService.to.bg;
    return Positioned.fill(child: Video(controller: bg.videoController));
  }
}
