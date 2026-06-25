import 'package:flutter/material.dart';
import 'package:pure_live/theme/tv_theme_x.dart';
import 'package:pure_live/widgets/tv_button.dart';
import 'package:pure_live/theme/styles/styles.dart';
import 'package:pure_live/theme/tv_theme_data.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:loading_indicator/loading_indicator.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

enum AppStatusType { loading, empty, error }

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

class _AppStatusViewState extends State<AppStatusView> with SingleTickerProviderStateMixin {
  late final AnimationController _rotateController;
  late String _currentLoadingStyle;

  @override
  void initState() {
    super.initState();
    _rotateController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _currentLoadingStyle = SettingsService.to.themeState.loadingStyle;
    if (_currentLoadingStyle == 'default') {
      _rotateController.repeat();
    }
  }

  @override
  void didUpdateWidget(AppStatusView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newStyle = SettingsService.to.themeState.loadingStyle;
    _currentLoadingStyle = newStyle;
    if (widget.type == AppStatusType.loading && newStyle == 'default') {
      if (!_rotateController.isAnimating) {
        _rotateController.repeat();
      }
    } else {
      if (_rotateController.isAnimating) {
        _rotateController.stop();
      }
    }
  }

  @override
  void dispose() {
    _rotateController.dispose();
    super.dispose();
  }

  Widget _buildLoadingWidget(BuildContext context) {
    final tvTheme = context.tvTheme;
    final setting = SettingsService.to;
    Color parsedColor;
    final hexColor = setting.themeState.loadingStyleColor;
    if (hexColor != null) {
      parsedColor = hexColor;
    } else {
      parsedColor = widget.iconColor ?? tvTheme.focusColor;
    }
    final double size = widget.isMini ? 24.sp : 50.sp;
    final String style = _currentLoadingStyle;
    if (style != 'default') {
      Widget spinKitWidget = _getSpinKit(style, parsedColor, size);
      if (spinKitWidget is! SizedBox) return spinKitWidget;

      Widget aniWidget = _getLoadingAnimation(style, parsedColor, size, tvTheme);
      if (aniWidget is! SizedBox) return aniWidget;

      Widget indicatorWidget = _getLoadingIndicator(style, parsedColor, size, tvTheme);
      if (indicatorWidget is! SizedBox || indicatorWidget.child != null) return indicatorWidget;
    }
    return RotationTransition(
      turns: _rotateController,
      child: ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (rect) => SweepGradient(
          startAngle: 0,
          endAngle: 2 * 3.14,
          colors: [parsedColor, parsedColor.withValues(alpha: 0.1)],
          stops: const [0.0, 0.85],
        ).createShader(rect),
        child: Container(
          width: widget.isMini ? 20.sp : 44.sp,
          height: widget.isMini ? 20.sp : 44.sp,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(width: widget.isMini ? 2.0.sp : 3.5.sp, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _getSpinKit(String style, Color color, double size) {
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
      _ => const SizedBox.shrink(),
    };
  }

  Widget _getLoadingAnimation(String style, Color color, double size, TvThemeData theme) {
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
      _ => const SizedBox.shrink(),
    };
  }

  Widget _getLoadingIndicator(String style, Color color, double size, TvThemeData theme) {
    Widget indicator = switch (style) {
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
      _ => const SizedBox.shrink(),
    };
    return SizedBox(width: size, height: size, child: indicator);
  }

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final effectiveIconColor = widget.iconColor ?? tvTheme.primaryTextColor;

    if (widget.type == AppStatusType.loading) {
      return Center(child: _buildLoadingWidget(context));
    }

    final String finalTitle = widget.title ?? (widget.type == AppStatusType.error ? "网络请求错误" : "暂无数据");
    final String finalSubtitle =
        widget.subtitle ?? (widget.type == AppStatusType.error ? "请检查您的网络连接或稍后再试" : "这里空空如也，什么都没有发现");
    final String finalButtonText = widget.buttonText ?? "重新加载";
    final Widget finalIcon = widget.buttonTextIcon ?? Icon(Icons.refresh_rounded, size: 24.sp);
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
