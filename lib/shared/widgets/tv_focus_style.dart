import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/shared/theme/tv_theme_data.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

/// The app's one focus language for every focusable TV widget.
///
/// A TV UI reads as polished when *every* control answers the remote the same
/// way: same duration, same curve, same ring, same glow. Before this file each
/// widget tuned its own numbers (100ms here, 120ms there, a 2.w blur on one
/// control and a 16 blur on another), so moving the highlight across a page
/// felt like hopping between apps.
///
/// The standard treatment, derived from the active palette:
///
/// * **Scale** — 1.05 lift (0.97 press) so the item visibly detaches.
/// * **Ring** — a 2.5sp border in the accent colour. This is the primary
///   indicator; it survives busy wallpapers better than any fill.
/// * **Glow** — dark palettes get a soft accent halo; light palettes get none
///   (a halo on white reads as a grey smear, not a glow).
/// * **Timing** — 120ms, `easeOutCubic`, everywhere.
///
/// Fills are left to each widget's custom effect because they differ by role
/// (a row tints, a button fills solid), but the ring/glow/scale come from here.
class TvFocusStyle {
  TvFocusStyle._();

  /// The one animation timing every focusable widget shares.
  static const Duration duration = Duration(milliseconds: 120);
  static const Curve curve = Curves.easeOutCubic;

  /// The standard effect stack for a focusable of the given shape.
  ///
  /// [radius] must match the widget's own corner radius, or the ring will be
  /// drawn at the wrong corners. Set [scale] below 1 for large surfaces (a
  /// full-width row scaling 1.05 overshoots the screen edge).
  static List<DpadEffect> effects(
    TvThemeData theme,
    BorderRadius radius, {
    double scale = 1.05,
    bool ring = true,
    bool glow = true,
  }) {
    return <DpadEffect>[
      DpadScaleEffect(
        scale: scale,
        pressedScale: 0.97,
        duration: duration,
        curve: curve,
      ),
      if (ring)
        DpadBorderEffect(
          color: theme.focusColor,
          width: 2.5.sp,
          borderRadius: radius,
          duration: duration,
        ),
      if (glow)
        DpadGlowEffect(
          // Same halo the room cards use (opacity .75, 18sp blur): the
          // highlight visibly *lights up* around the item. Light palettes
          // keep no blur — a halo on white reads as a grey smear.
          color: theme.focusColor,
          opacity: theme.isLight ? 1.0 : 0.75,
          blurRadius: theme.isLight ? 0 : 18.sp,
          spreadRadius: theme.isLight ? 2.sp : 1.5.sp,
          borderRadius: radius,
          duration: duration,
        ),
    ];
  }

  /// Focus foreground on a solid accent fill, chosen by contrast.
  ///
  /// Widgets keep calling [TvThemeData.onFocusColor] directly; this helper
  /// exists for the places that also need the idle/faded partners so the three
  /// states are always picked as a set.
  static (Color focused, Color faded, Color idle) foregrounds(TvThemeData theme) {
    return (theme.onFocusColor, theme.onFadedFocusColor, theme.primaryTextColor);
  }
}
