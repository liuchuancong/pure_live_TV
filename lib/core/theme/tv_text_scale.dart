import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/core/theme/typography/app_font_scale.dart';

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

  /// The text scale for a subtree: the inherited (system) scale times the
  /// panel correction.
  ///
  /// The user's own scale does NOT ride here anymore — it is applied exactly
  /// once, inside the typography resolver ([AppTextStyles] base styles), so
  /// that the resolver is the single exit for text sizing and special zones
  /// (danmaku, subtitles) can opt out of it. What remains here is the panel
  /// legibility correction times whatever the platform's accessibility
  /// setting demands — the system factor must never be flattened away.
  static TextScaler scalerFor(BuildContext context) {
    final inherited = MediaQuery.textScalerOf(context).scale(1.0);
    return TextScaler.linear(legibilityLift(context) * inherited);
  }

  /// The factor the inherited text scaler applies to any font size, i.e. the
  /// setting the whole app is currently rendering text at: the user scale
  /// (from [AppFontScale.user], via the resolver) times the panel correction
  /// times the system accessibility scale.
  ///
  /// Every box that exists *because* of text has to follow it. A line box, the
  /// gap between two lines, or the height of a button holding a label, derived
  /// from `.sp` alone stays put while the glyphs inside it grow — the label is
  /// then clipped, and the control stops looking like the peer of the text next
  /// to it. That is how the room/area cards and the home buttons broke. `.sp`
  /// covers the panel; this covers the text.
  ///
  /// `scale(1.0)` is the right value for a box: the scaler is linear in the
  /// sizes this app uses, so a design-pixel length becomes `length * factor`.
  static double factorOf(BuildContext context) => AppFontScale.user * MediaQuery.textScalerOf(context).scale(1.0);
}

/// Lengths that have to track the text around them.
///
/// `.sp` follows the panel; `.ts(context)` follows the font the user set. Read
/// `44.ts(context)` as "the 44 design pixels this label needs at the current
/// font scale".
extension TvTextScaledLength on num {
  double ts(BuildContext context) => toDouble().sp * TvTextScale.factorOf(context);
}

/// Grid delegates whose density follows the text.
///
/// A fixed `crossAxisCount` + `childAspectRatio` pair is drafted against the
/// 100% font: the card titles inside the cells grow with the setting while the
/// cells stay put, and past ~120% the labels wrap into ellipsis chains. The
/// fix is the grid's own two knobs:
///
/// - **Columns** shrink as the font grows (`count / scale`, rounded up), so
///   each cell gets wider. Rounding to whole columns can leave the cell short
///   of its full k-fold width.
/// - **Aspect ratio** hands that shortfall back as height: the cell's text
///   band ends up with at least its k-fold room at every scale, whatever the
///   column rounding did. At 100% both knobs are the drafted values, so the
///   grids look exactly as before.
class TvAdaptiveGrid {
  const TvAdaptiveGrid._();

  /// The parameter names match [SliverGridDelegateWithFixedCrossAxisCount]'s
  /// so a call site converts by swapping the constructor only — the spacing
  /// arguments keep whatever `.w`/`.sp` semantics the caller already had.
  ///
  /// [fontWeight] damps the response for grids whose cells are not mostly
  /// text: a media card's caption is a small band over a cover, and a cell
  /// that grows at the full font rate turns a four-column feed into two
  /// giant cards. `1.0` (the default) responds at the full rate; see [media].
  static SliverGridDelegateWithFixedCrossAxisCount fixed(
    BuildContext context, {
    required int crossAxisCount,
    required double childAspectRatio,
    double mainAxisSpacing = 0.0,
    double crossAxisSpacing = 0.0,
    double fontWeight = 1.0,
  }) {
    final double scale = _dampedFactor(context, fontWeight);
    final int columns = (crossAxisCount / scale).ceil().clamp(1, crossAxisCount * 2);
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: columns,
      childAspectRatio: childAspectRatio * crossAxisCount / (scale * columns),
      mainAxisSpacing: mainAxisSpacing * scale,
      crossAxisSpacing: crossAxisSpacing * scale,
    );
  }

  /// The damped variant for media-card grids (cover + a caption band): the
  /// cell follows the font at 40% of the rate, so a 150% font keeps the feed's
  /// column count instead of collapsing it, while titles still get room.
  static SliverGridDelegateWithFixedCrossAxisCount media(
    BuildContext context, {
    required int crossAxisCount,
    required double childAspectRatio,
    double mainAxisSpacing = 0.0,
    double crossAxisSpacing = 0.0,
  }) {
    return fixed(
      context,
      crossAxisCount: crossAxisCount,
      childAspectRatio: childAspectRatio,
      mainAxisSpacing: mainAxisSpacing,
      crossAxisSpacing: crossAxisSpacing,
      fontWeight: 0.4,
    );
  }

  /// The font factor damped by [weight]: `1.0` passes the factor through,
  /// `0.0` pins it at 1.0.
  static double _dampedFactor(BuildContext context, double weight) {
    final double factor = TvTextScale.factorOf(context);
    return 1.0 + (factor - 1.0) * weight;
  }

  /// The same language for a max-extent grid: cells are drafted at most
  /// `maxCrossAxisExtent` wide, so the extent grows with the text and the
  /// cells with it. The aspect is untouched — a wider cell is already a
  /// proportionally taller one.
  static SliverGridDelegateWithMaxCrossAxisExtent maxExtent(
    BuildContext context, {
    required double maxCrossAxisExtent,
    required double childAspectRatio,
    double mainAxisSpacing = 0.0,
    double crossAxisSpacing = 0.0,
  }) {
    final double scale = TvTextScale.factorOf(context);
    return SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: maxCrossAxisExtent * scale,
      childAspectRatio: childAspectRatio,
      mainAxisSpacing: mainAxisSpacing * scale,
      crossAxisSpacing: crossAxisSpacing * scale,
    );
  }
}
