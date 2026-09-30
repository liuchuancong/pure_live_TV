import 'package:flutter/widgets.dart';
import 'package:pure_live/services/settings/settings.dart';

/// The user's font-scale preference — the single source of the multiplier.
///
/// Architecture (dual factors, one exit):
/// - **Screen factor**: flutter_screenutil_plus turns design `.sp` sizes into
///   panel-proportional sizes. It never knows about the user's preference.
/// - **User factor**: this class. Applied exactly once, inside the typography
///   resolver ([AppTextStyles] base styles), never by pages.
/// - **System factor**: the platform accessibility TextScaler, applied by
///   Flutter at paint time on top of everything. The app must not fold it in
///   or override it away.
///
/// So a text's painted size is `base × AppFontScale.user × screen(.sp) ×
/// system TextScaler`, and the multiplication of the user factor happens in
/// exactly one file.
///
/// Layout code that must *track* text (row heights, gaps) reads the final
/// painted factor via [paintedFactorOf] / the `.ts(context)` extension — that
/// is layout adaptation, explicitly not a second place to scale text.
class AppFontScale {
  const AppFontScale._();

  /// The user's multiplier, straight from the persisted font settings.
  ///
  /// Static on purpose: the resolver is a static, context-free style table,
  /// and the setting is app-global. Defaults to 1 before the settings
  /// provider is ready.
  static double get user {
    try {
      return SettingsService.to.fontState.textScaleFactor;
    } catch (_) {
      return 1.0;
    }
  }

  /// The factor the inherited TextScaler applies to any font size at this
  /// point in the tree — user × panel-correction × system accessibility.
  ///
  /// This is what a box that exists *because* of text (a row height, a gap,
  /// an icon) follows. See [TvTextScale.factorOf].
  static double paintedFactorOf(BuildContext context) => MediaQuery.textScalerOf(context).scale(1.0);
}

/// Text strategies for zones that must not follow the global user scale.
///
/// The player, the danmaku layer and the video subtitles are content, not
/// chrome: scaling them with the settings slider fights the video itself.
/// Such a zone declares [fixed] and calls the base styles through
/// [resolve] with the policy applied.
enum FontScalePolicy {
  /// Follow the user's scale (every chrome surface — the default).
  followGlobal,

  /// Keep the design size; only the system accessibility scaler still
  /// applies (Flutter enforces a floor for accessibility at paint time for
  /// widgets that opt in, and plain Text honors the ambient scaler).
  fixed,
}
