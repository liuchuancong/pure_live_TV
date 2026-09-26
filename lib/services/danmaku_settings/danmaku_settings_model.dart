import 'package:freezed_annotation/freezed_annotation.dart';

part 'danmaku_settings_model.freezed.dart';
part 'danmaku_settings_model.g.dart';

/// Danmaku settings model.
///
/// The factory defaults below are frozen by the generated `.freezed.dart`/`.g.dart`, so
/// they stay as they were written; [minSpeed]/[maxSpeed]/[defaultSpeed] and the other
/// bounds are what the controller clamps **every** stored, imported and defaulted value
/// into, and they follow the engine's own units:
///
/// * `danmakuSpeed` — **pixels per second** (`BarrageConfig.baseSpeed`); the engine
///   compares it with a distance to get a duration, so a "level" like 8 is a frozen
///   danmaku rather than a slow one.
/// * `danmakuTopArea` / `danmakuBottomArea` — **pixel insets** from the top/bottom edge
///   (`topAreaDistance` / `bottomAreaDistance`), not ratios. `danmakuArea` *is* a ratio.
///
/// Tap/long-press interaction and the picture-in-picture fields have no TV UI; they are
/// kept so backup export/import stays compatible with the mobile app, and the controller
/// still re-registers the PiP font family if a backup names one.
@freezed
abstract class DanmakuSettingsModel with _$DanmakuSettingsModel {
  /// `DanmakuSettingsModel.danmakuSpeed` bounds, in px/s (the mobile app's own bounds).
  static const double minSpeed = 20;
  static const double maxSpeed = 400;
  static const double defaultSpeed = 120;

  /// Top/bottom inset bounds, in logical pixels (the engine's distance fields).
  static const double minDistance = 0;
  static const double maxDistance = 300;

  /// Display-area ratio bounds for `danmakuArea`.
  static const double minArea = 0.1;
  static const double maxArea = 1.0;

  /// Clamps a stored/imported speed into px/s.
  ///
  /// Anything below [minSpeed] is not a slow setting, it is the legacy "speed level"
  /// scale (4-32) that predates the unit: a level of 8 would freeze every danmaku on
  /// screen, so those values are mapped to [defaultSpeed] instead.
  static double normalizeSpeed(double? value) {
    if (value == null || !value.isFinite) return defaultSpeed;
    if (value < minSpeed) return defaultSpeed;
    return value.clamp(minSpeed, maxSpeed);
  }

  /// Clamps a stored/imported top/bottom inset into logical pixels.
  ///
  /// A value between 0 and 1 came from the old ratio slider, where 0.5 meant half the
  /// screen and the engine now reads it as half a pixel: that is "no inset", not 0.5px.
  static double normalizeDistance(double? value) {
    if (value == null || !value.isFinite) return 0;
    if (value > 0 && value < 1) return 0;
    return value.clamp(minDistance, maxDistance);
  }

  /// Snaps a font weight to the hundreds the engine's variable fonts expose.
  static int normalizeFontWeight(int? value) => ((value ?? 500).clamp(100, 900) ~/ 100) * 100;

  const factory DanmakuSettingsModel({
    @Default(false) bool hideDanmaku,
    @Default(false) bool noEmojiMode,
    @Default(0.0) double danmakuTopArea,
    @Default(1.0) double danmakuArea,
    @Default(0.5) double danmakuBottomArea,
    @Default(8.0) double danmakuSpeed,
    @Default(16.0) double danmakuFontSize,
    @Default(500) int danmakuFontWeight,
    @Default(4.0) double danmakuFontBorder,
    @Default(1.0) double danmakuOpacity,
    @Default(true) bool enableDanmakuDisplay,
    @Default(true) bool enableDanmakuStroke,
    @Default(60) int danmakuFps,
    /// Auto frame rate (follow the display) defaults off: a 120Hz panel doubles
    /// the danmaku compositing budget on boxes whose video decode is already
    /// tight. When off, [danmakuFps] applies (60 by default).
    @Default(false) bool danmakuAutoFps,
    @Default(true) bool enableDanmakuTapInteraction,
    @Default(true) bool enableDanmakuLongPressInteraction,
    @Default(false) bool collapseRepeatedDanmaku,
    @Default(5) int repeatedDanmakuWindowSeconds,
    @Default(0) int danmakuInteractionMigration,
    @Default('') String savedDanmakuTemplate,
    @Default('Default') String danmakuFontFamilyName,
    // Picture-in-picture danmaku. Synced but never consumed on TV.
    @Default(true) bool enablePipDanmaku,
    @Default(true) bool pipDanmakuAutoScale,
    @Default(false) bool pipDanmakuNoEmojiMode,
    @Default(true) bool pipDanmakuUseOriginalColor,
    @Default(0xFFFFFFFF) int pipDanmakuColor,
    @Default(12.0) double pipDanmakuFontSize,
    @Default(500) int pipDanmakuFontWeight,
    @Default(90.0) double pipDanmakuSpeed,
    @Default(0.9) double pipDanmakuOpacity,
    @Default(0.5) double pipDanmakuArea,
    @Default(6) int pipDanmakuMaxVisibleCount,
    @Default(0.35) double pipDanmakuEmitInterval,
    @Default(30) int pipDanmakuFps,
    @Default(true) bool pipDanmakuAutoFps,
    // Message filtering
    // Douyu's bot filter is part of its decoder now (only chat carrying the
    // `if=1` fan flag is kept), so this no longer has a switch; the field stays
    // for backups and for the site adapter's constructor.
    @Default(true) bool filterDouyuSuspectedAutomatedMessages,
    @Default(false) bool enableDanmakuSimilarityFilter,
    @Default(85) int danmakuSimilarityThreshold,
    @Default(3) int danmakuSimilarityCacheDuration,
    @Default(100) int danmakuSimilarityMaxCacheSize,
  }) = _DanmakuSettingsModel;

  factory DanmakuSettingsModel.fromJson(Map<String, dynamic> json) => _$DanmakuSettingsModelFromJson(json);
}
