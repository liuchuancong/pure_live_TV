import 'package:flutter/material.dart';
import 'package:pure_live/shared/widgets/index.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:pure_live/shared/consts/app_consts.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';

enum AppStatusType { loading, empty, error, notLogin }

/// The animation for one style, or null when the key is unknown.
///
/// [AppStatusView] and the loading-style picker share this, so the preview list
/// shows the very animation the app will use — SpinKit first, then
/// `LoadingAnimationWidget`, then `LoadingIndicator`. Every branch returns a
/// *live* animation: a null means "not handled by this library", never
/// "handled by a still frame".
Widget? tvLoadingStyleWidget({
  required String style,
  required Color color,
  required double size,
  required TvThemeData theme,
}) {
  if (style == AppConsts.defaultLoadingStyleKey) {
    return TvDefaultLoadingRing(color: color, size: size);
  }
  return _getSpinKit(style, color, size) ??
      _getLoadingAnimation(style, color, size, theme) ??
      _getLoadingIndicator(style, color, size, theme);
}

/// One animation in a fixed square, for the picker and the settings row.
///
/// The scale-down matters: several styles paint wider than the `size` they are
/// given (SpinKit's `threeInOut` needs about 1.5x), which overflowed their tile.
/// The mobile picker wraps its previews in the same `FittedBox`.
class TvLoadingStylePreview extends StatelessWidget {
  const TvLoadingStylePreview({
    super.key,
    required this.style,
    required this.color,
    required this.size,
    required this.theme,
  });

  final String style;
  final Color color;
  final double size;
  final TvThemeData theme;

  @override
  Widget build(BuildContext context) {
    final Widget? animation = tvLoadingStyleWidget(style: style, color: color, size: size, theme: theme);
    return SizedBox(
      width: size,
      height: size,
      child: animation == null ? null : FittedBox(fit: BoxFit.contain, child: animation),
    );
  }
}

/// The app's built-in loading ring: a rotating gradient-bordered circle.
///
/// This is the `default` style. It used to be drawn as a frozen arc in the
/// picker, which made the first entry look broken next to the animated ones.
class TvDefaultLoadingRing extends StatefulWidget {
  const TvDefaultLoadingRing({super.key, required this.color, required this.size});

  final Color color;
  final double size;

  @override
  State<TvDefaultLoadingRing> createState() => _TvDefaultLoadingRingState();
}

class _TvDefaultLoadingRingState extends State<TvDefaultLoadingRing> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (rect) => SweepGradient(
          startAngle: 0,
          endAngle: 2 * 3.14,
          colors: [widget.color, widget.color.withValues(alpha: 0.1)],
          stops: const [0.0, 0.85],
        ).createShader(rect),
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(width: widget.size * 0.08, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

Widget? _getSpinKit(String style, Color color, double size) {
  return switch (style) {
    'rotatingPlain' => SpinKitRotatingPlain(color: color, size: size),
    'doubleBounce' => SpinKitDoubleBounce(color: color, size: size),
    'wave' => SpinKitWave(color: color, size: size),
    'wanderingCubes' => SpinKitWanderingCubes(color: color, size: size),
    'fadingFour' => SpinKitFadingFour(color: color, size: size),
    'fadingCube' => SpinKitFadingCube(color: color, size: size),
    'pulse' => SpinKitPulse(color: color, size: size),
    'chasingDots' => SpinKitChasingDots(color: color, size: size),
    'threeBounce' => SpinKitThreeBounce(color: color, size: size),
    'circle' => SpinKitCircle(color: color, size: size),
    'cubeGrid' => SpinKitCubeGrid(color: color, size: size),
    'fadingCircle' => SpinKitFadingCircle(color: color, size: size),
    'rotatingCircle' => SpinKitRotatingCircle(color: color, size: size),
    'foldingCube' => SpinKitFoldingCube(color: color, size: size),
    'pumpingHeart' => SpinKitPumpingHeart(color: color, size: size),
    'hourGlass' => SpinKitHourGlass(color: color, size: size),
    'pouringHourGlass' => SpinKitPouringHourGlass(color: color, size: size),
    'pouringHourGlassRefined' => SpinKitPouringHourGlassRefined(color: color, size: size),
    'fadingGrid' => SpinKitFadingGrid(color: color, size: size),
    'ring' => SpinKitRing(color: color, size: size),
    'ripple' => SpinKitRipple(color: color, size: size),
    'spinningCircle' => SpinKitSpinningCircle(color: color, size: size),
    'spinningLines' => SpinKitSpinningLines(color: color, size: size),
    'squareCircle' => SpinKitSquareCircle(color: color, size: size),
    'dualRing' => SpinKitDualRing(color: color, size: size),
    'pianoWave' => SpinKitPianoWave(color: color, size: size),
    'dancingSquare' => SpinKitDancingSquare(color: color, size: size),
    'threeInOut' => SpinKitThreeInOut(color: color, size: size),
    'waveSpinner' => SpinKitWaveSpinner(color: color, size: size),
    'pulsingGrid' => SpinKitPulsingGrid(color: color, size: size),
    _ => null,
  };
}

Widget? _getLoadingAnimation(String style, Color color, double size, TvThemeData theme) {
  return switch (style) {
    'waveDots' => LoadingAnimationWidget.waveDots(color: color, size: size),
    'inkDrop' => LoadingAnimationWidget.inkDrop(color: color, size: size),
    'twistingDots' => LoadingAnimationWidget.twistingDots(
      leftDotColor: color,
      rightDotColor: theme.secondaryTextColor,
      size: size,
    ),
    'threeRotatingDots' => LoadingAnimationWidget.threeRotatingDots(color: color, size: size),
    'staggeredDotsWave' => LoadingAnimationWidget.staggeredDotsWave(color: color, size: size),
    'fourRotatingDots' => LoadingAnimationWidget.fourRotatingDots(color: color, size: size),
    'fallingDot' => LoadingAnimationWidget.fallingDot(color: color, size: size),
    'progressiveDots' => LoadingAnimationWidget.progressiveDots(color: color, size: size),
    'discreteCircular' => LoadingAnimationWidget.discreteCircle(color: color, size: size),
    'threeArchedCircle' => LoadingAnimationWidget.threeArchedCircle(color: color, size: size),
    'bouncingBall' => LoadingAnimationWidget.bouncingBall(color: color, size: size),
    'flickr' => LoadingAnimationWidget.flickr(
      leftDotColor: color,
      rightDotColor: theme.secondaryTextColor,
      size: size,
    ),
    'hexagonDots' => LoadingAnimationWidget.hexagonDots(color: color, size: size),
    'beat' => LoadingAnimationWidget.beat(color: color, size: size),
    'twoRotatingArc' => LoadingAnimationWidget.twoRotatingArc(color: color, size: size),
    'horizontalRotatingDots' => LoadingAnimationWidget.horizontalRotatingDots(color: color, size: size),
    'newtonCradle' => LoadingAnimationWidget.newtonCradle(color: color, size: size),
    'stretchedDots' => LoadingAnimationWidget.stretchedDots(color: color, size: size),
    'halfTriangleDot' => LoadingAnimationWidget.halfTriangleDot(color: color, size: size),
    'dotsTriangle' => LoadingAnimationWidget.dotsTriangle(color: color, size: size),
    _ => null,
  };
}

Widget? _getLoadingIndicator(String style, Color color, double size, TvThemeData theme) {
  final Widget? indicator = switch (style) {
    'ballPulse' => LoadingIndicator(indicatorType: Indicator.ballPulse, colors: [color]),
    'ballGridPulse' => LoadingIndicator(indicatorType: Indicator.ballGridPulse, colors: [color]),
    'ballClipRotate' => LoadingIndicator(indicatorType: Indicator.ballClipRotate, colors: [color]),
    'ballClipRotatePulse' => LoadingIndicator(indicatorType: Indicator.ballClipRotatePulse, colors: [color]),
    'squareSpin' => LoadingIndicator(indicatorType: Indicator.squareSpin, colors: [color]),
    'ballClipRotateMultiple' => LoadingIndicator(indicatorType: Indicator.ballClipRotateMultiple, colors: [color]),
    'ballPulseRise' => LoadingIndicator(indicatorType: Indicator.ballPulseRise, colors: [color]),
    'ballRotate' => LoadingIndicator(indicatorType: Indicator.ballRotate, colors: [color]),
    'cubeTransition' => LoadingIndicator(indicatorType: Indicator.cubeTransition, colors: [color]),
    'ballZigZag' => LoadingIndicator(indicatorType: Indicator.ballZigZag, colors: [color]),
    'ballZigZagDeflect' => LoadingIndicator(indicatorType: Indicator.ballZigZagDeflect, colors: [color]),
    'ballTrianglePath' => LoadingIndicator(indicatorType: Indicator.ballTrianglePath, colors: [color]),
    'ballTrianglePathColored' => LoadingIndicator(
      indicatorType: Indicator.ballTrianglePathColored,
      colors: [color, theme.secondaryTextColor, theme.primaryTextColor],
    ),
    'ballTrianglePathColoredFilled' => LoadingIndicator(
      indicatorType: Indicator.ballTrianglePathColoredFilled,
      colors: [color, theme.secondaryTextColor, theme.primaryTextColor],
    ),
    'ballScale' => LoadingIndicator(indicatorType: Indicator.ballScale, colors: [color]),
    'lineScale' => LoadingIndicator(indicatorType: Indicator.lineScale, colors: [color]),
    'lineScaleParty' => LoadingIndicator(indicatorType: Indicator.lineScaleParty, colors: [color]),
    'ballScaleMultiple' => LoadingIndicator(indicatorType: Indicator.ballScaleMultiple, colors: [color]),
    'ballPulseSync' => LoadingIndicator(indicatorType: Indicator.ballPulseSync, colors: [color]),
    'ballBeat' => LoadingIndicator(indicatorType: Indicator.ballBeat, colors: [color]),
    'lineScalePulseOut' => LoadingIndicator(indicatorType: Indicator.lineScalePulseOut, colors: [color]),
    'lineScalePulseOutRapid' => LoadingIndicator(indicatorType: Indicator.lineScalePulseOutRapid, colors: [color]),
    'ballScaleRipple' => LoadingIndicator(indicatorType: Indicator.ballScaleRipple, colors: [color]),
    'ballScaleRippleMultiple' => LoadingIndicator(indicatorType: Indicator.ballScaleRippleMultiple, colors: [color]),
    'ballSpinFadeLoader' => LoadingIndicator(indicatorType: Indicator.ballSpinFadeLoader, colors: [color]),
    'lineSpinFadeLoader' => LoadingIndicator(indicatorType: Indicator.lineSpinFadeLoader, colors: [color]),
    'triangleSkewSpin' => LoadingIndicator(indicatorType: Indicator.triangleSkewSpin, colors: [color]),
    'pacman' => LoadingIndicator(indicatorType: Indicator.pacman, colors: [color]),
    'ballGridBeat' => LoadingIndicator(indicatorType: Indicator.ballGridBeat, colors: [color]),
    'semiCircleSpin' => LoadingIndicator(indicatorType: Indicator.semiCircleSpin, colors: [color]),
    'ballRotateChase' => LoadingIndicator(indicatorType: Indicator.ballRotateChase, colors: [color]),
    'orbit' => LoadingIndicator(indicatorType: Indicator.orbit, colors: [color]),
    'audioEqualizer' => LoadingIndicator(indicatorType: Indicator.audioEqualizer, colors: [color]),
    'circleStrokeSpin' => LoadingIndicator(indicatorType: Indicator.circleStrokeSpin, colors: [color]),
    _ => null,
  };
  if (indicator == null) return null;
  return SizedBox(width: size, height: size, child: indicator);
}

class AppStatusView extends StatefulWidget {
  final AppStatusType type;
  final String? title;
  final String? subtitle;
  final IconData? icon;
  final String? buttonText;
  final Widget? buttonTextIcon;
  final VoidCallback? onTap;
  final bool isMini;
  final Color? iconColor;
  final Color? titleColor;
  final Color? subtitleColor;

  const AppStatusView({
    super.key,
    required this.type,
    this.title,
    this.subtitle,
    this.icon,
    this.buttonText,
    this.onTap,
    this.isMini = false,
    this.iconColor,
    this.titleColor,
    this.subtitleColor,
    this.buttonTextIcon,
  });

  @override
  State<AppStatusView> createState() => _AppStatusViewState();
}

class _AppStatusViewState extends State<AppStatusView> {
  /// The animation for the active style, falling back to the built-in ring.
  ///
  /// The style and its colour are read from settings at build time, so a choice
  /// made in the animation picker shows up as soon as the page rebuilds.
  Widget _buildLoadingWidget(BuildContext context) {
    final tvTheme = context.tvTheme;
    final setting = SettingsService.to;
    final Color parsedColor = setting.themeState.loadingStyleColor ?? widget.iconColor ?? tvTheme.focusColor;
    final double size = widget.isMini ? 24.sp : 50.sp;
    final String style = setting.themeState.loadingStyle;
    if (style != 'default') {
      final Widget? animation = tvLoadingStyleWidget(style: style, color: parsedColor, size: size, theme: tvTheme);
      if (animation != null) return animation;
    }
    return TvDefaultLoadingRing(color: parsedColor, size: widget.isMini ? 20.sp : 44.sp);
  }


  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final effectiveIconColor = widget.iconColor ?? tvTheme.primaryTextColor;

    if (widget.type == AppStatusType.loading) {
      return Center(child: _buildLoadingWidget(context));
    }

    final String finalTitle = widget.title ?? (widget.type == AppStatusType.error ? i18n('network_error_title') : i18n('status_empty_title'));
    final String finalSubtitle =
        widget.subtitle ?? (widget.type == AppStatusType.error ? i18n('network_error_subtitle') : i18n('status_empty_subtitle'));
    final String finalButtonText = widget.buttonText ?? i18n('status_retry_button');
    final Widget finalIcon =
        widget.buttonTextIcon ??
        Icon(widget.type == AppStatusType.notLogin ? Remix.login_box_fill : Icons.refresh_rounded, size: 24.sp);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(widget.isMini ? 8.sp : 22.sp),
            decoration: BoxDecoration(
              color: tvTheme.cardColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: effectiveIconColor.withValues(alpha: 0.05), width: 1.sp),
            ),
            child: Icon(
              widget.icon ?? (widget.type == AppStatusType.error ? Icons.wifi_off_rounded : Icons.live_tv_rounded),
              size: widget.isMini ? 36.sp : 64.sp,
              color: widget.iconColor ?? tvTheme.primaryTextColor.withValues(alpha: 0.6),
            ),
          ).animate().scaleXY(begin: 0, end: 1, duration: 1000.ms, curve: Curves.elasticOut),

          if (!widget.isMini || finalTitle.isNotEmpty) ...[
            Text(
              finalTitle,
              style: AppTextStyles.t28.copyWith(
                fontWeight: FontWeight.w600,
                color: widget.titleColor ?? tvTheme.primaryTextColor,
              ),
            ),
          ],
          if (!widget.isMini || finalSubtitle.isNotEmpty) ...[
            SizedBox(height: 6.sp),
            Text(
              finalSubtitle,
              style: AppTextStyles.t28.copyWith(color: widget.subtitleColor ?? tvTheme.secondaryTextColor),
            ),
          ],
          if (!widget.isMini && widget.onTap != null) ...[
            SizedBox(height: 24.sp),
            TvButton(
              title: finalButtonText,
              icon: finalIcon,
              autofocus: true,
              iconPosition: TvIconPosition.left,
              size: TvButtonSize.small,
              onTap: widget.onTap,
            ),
          ],
        ],
      ),
    );
  }
}
