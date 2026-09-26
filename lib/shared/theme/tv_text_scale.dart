import 'package:flutter/widgets.dart';

/// Text sizing for TV panels.
///
/// The UI is drafted against a 1920x1080 panel and `flutter_screenutil`
/// multiplies every `.sp` size by `screenWidth / 1920`. That keeps the layout
/// proportional to the screen, which is what the design wants — but it also
/// makes text proportional, so a 720p panel renders a 12-16.sp label at 8-11 px
/// and it cannot be read from a couch. The same label on a 1080p TV is fine, and
/// that is the difference users report as "small TVs have small fonts".
///
/// [legibilityLift] therefore treats text differently from the layout: on a
/// panel below 1080p it scales text back up towards its drafted size, while
/// boxes and spacing keep scaling with the screen. The lift is a correction, not
/// a preference — the user's own font scale still applies on top of it.
class TvTextScale {
  const TvTextScale._();

  /// The panel the UI and every `.sp` size are drafted against.
  ///
  /// Pass this to `ScreenUtilPlusInit` so the draft is declared once.
  static const Size designSize = Size(1920, 1080);

  /// Physical height of the panel the design is drawn for.
  static const double designHeight = 1080;

  /// Upper bound for [legibilityLift].
  ///
  /// 1.5 is what a 720p panel needs; the headroom covers a panel that reports
  /// slightly less. Beyond it text would outgrow the boxes around it, which is
  /// worse than a slightly small label.
  static const double maxLegibilityLift = 1.6;

  /// Physical height of the current panel, in pixels.
  ///
  /// A panel's class is its *physical* resolution, not the logical one the
  /// framework reports: a certified 1080p Android TV reports 960x540 logical at
  /// a device pixel ratio of 2, and a box that drives its 720p UI natively
  /// reports 1280x720 at 1. Both are 1080 or 720 physical lines.
  static double panelHeight(BuildContext context) {
    final media = MediaQuery.of(context);
    final height = media.size.height * media.devicePixelRatio;
    return height.isFinite && height > 0 ? height : designHeight;
  }

  /// Correction that keeps text readable on a panel smaller than the draft.
  ///
  /// `1` — no correction — on a 1080p panel or larger, so the reference TVs are
  /// untouched; on a 720p panel it is `1080 / 720`, capped at
  /// [maxLegibilityLift].
  static double legibilityLift(BuildContext context) {
    return (designHeight / panelHeight(context)).clamp(1.0, maxLegibilityLift);
  }

  /// The text scale for a subtree: the caller's own scale times the correction.
  ///
  /// Use this instead of `TextScaler.linear` so a subtree that replaces the
  /// inherited text scale — the room switcher does, to size its own rows — keeps
  /// the correction.
  static TextScaler scalerFor(BuildContext context, {double userScale = 1}) =>
      TextScaler.linear(userScale * legibilityLift(context));
}
