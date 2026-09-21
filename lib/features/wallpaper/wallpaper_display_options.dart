import 'package:flutter/material.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';

/// Fill modes offered by the display-settings row and cycled by the preview's
/// fill action, in the order the desktop app numbered them.
const List<BoxFit> kWallpaperFitModes = <BoxFit>[
  BoxFit.fill,
  BoxFit.contain,
  BoxFit.cover,
  BoxFit.fitWidth,
  BoxFit.fitHeight,
  BoxFit.none,
  BoxFit.scaleDown,
];

/// Mask presets. A remote steps through fixed values instead of dragging a
/// slider, which is far easier to operate from a couch.
const List<double> kWallpaperMaskSteps = <double>[
  0,
  0.05,
  0.1,
  0.15,
  0.2,
  0.25,
  0.3,
  0.35,
  0.4,
  0.45,
  0.5,
  0.55,
  0.6,
  0.65,
  0.7,
  0.75,
  0.8,
  0.85,
  0.9,
  0.95,
  1,
];

/// Blur presets (sigma). A remote steps through fixed values instead of
/// dragging a slider; 0 is "off" so the row always has a way back.
const List<double> kWallpaperBlurSteps = <double>[0, 2, 4, 6, 8, 12, 16, 24, 32, 48];

/// Localised label of one blur preset.
String wallpaperBlurLabel(double sigma) =>
    sigma <= 0 ? i18nOr('wallpaper_blur_off', 'Off') : '${sigma.round()}';

/// Index of the preset closest to [value].
int wallpaperBlurIndex(double value) {
  var best = 0;
  var bestDelta = double.infinity;
  for (var i = 0; i < kWallpaperBlurSteps.length; i++) {
    final delta = (kWallpaperBlurSteps[i] - value).abs();
    if (delta < bestDelta) {
      bestDelta = delta;
      best = i;
    }
  }
  return best;
}

/// Localised label of one fill mode.
String wallpaperFitLabel(BoxFit fit) => switch (fit) {
  BoxFit.fill => i18nOr('wallpaper_fit_fill', 'Stretch'),
  BoxFit.contain => i18nOr('wallpaper_fit_contain', 'Fit'),
  BoxFit.cover => i18nOr('wallpaper_fit_cover', 'Cover'),
  BoxFit.fitWidth => i18nOr('wallpaper_fit_fit_width', 'Fit width'),
  BoxFit.fitHeight => i18nOr('wallpaper_fit_fit_height', 'Fit height'),
  BoxFit.none => i18nOr('wallpaper_fit_none', 'Original'),
  BoxFit.scaleDown => i18nOr('wallpaper_fit_scale_down', 'Scale down'),
};

/// Localised label of one mask preset.
String wallpaperMaskLabel(double step) => '${(step * 100).round()}%';

/// Index of the preset closest to [value], so a stored opacity that is not
/// exactly one of the presets still highlights a sensible row.
int wallpaperMaskIndex(double value) {
  var best = 0;
  var bestDelta = double.infinity;
  for (var i = 0; i < kWallpaperMaskSteps.length; i++) {
    final delta = (kWallpaperMaskSteps[i] - value).abs();
    if (delta < bestDelta) {
      bestDelta = delta;
      best = i;
    }
  }
  return best;
}
