import 'package:flame_barrage/flame_barrage.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/services/danmaku_settings/danmaku_settings_model.dart';

/// The danmaku settings the engine can render, as one [BarrageConfig]. Every
/// appearance setting the UI exposes must map here. Units: `baseSpeed` is
/// pixels per second, `bottomAreaDistance` a pixel inset.
BarrageConfig buildDanmakuConfig(
  DanmakuSettingsModel settings, {
  String? fontFamily,
  double? refreshRate,
}) {
  final double fontSize = settings.danmakuFontSize;
  return BarrageConfig(
    // 50ms admit interval plus a visible cap keeps layout and paint cost low.
    emitInterval: 0.05,
    fontFamily: fontFamily,
    fontSize: fontSize,
    area: settings.danmakuArea.clamp(DanmakuSettingsModel.minArea, DanmakuSettingsModel.maxArea),
    topAreaDistance: settings.danmakuTopArea.clamp(DanmakuSettingsModel.minDistance, DanmakuSettingsModel.maxDistance),
    bottomAreaDistance: settings.danmakuBottomArea.clamp(
      DanmakuSettingsModel.minDistance,
      DanmakuSettingsModel.maxDistance,
    ),
    baseSpeed: settings.danmakuSpeed.clamp(DanmakuSettingsModel.minSpeed, DanmakuSettingsModel.maxSpeed),
    opacity: settings.danmakuOpacity.clamp(0.05, 1.0),
    fontWeight: FontWeight(settings.danmakuFontWeight.clamp(100, 900)),
    strokeWidth: settings.danmakuFontBorder.clamp(0, 8),
    showStroke: settings.enableDanmakuStroke,
    noEmojiMode: settings.noEmojiMode,
    fps: resolveDanmakuFps(settings, refreshRate: refreshRate),
    maxVisibleCount: 48,
    trackHeight: (fontSize * 1.55).clamp(24.0, 64.0).toDouble(),
    emojiSize: (fontSize * 1.3).clamp(16.0, 48.0).toDouble(),
  );
}

/// The frame budget the engine dispatches against.
///
/// `danmakuAutoFps` means "follow the panel", so it reads the display's refresh rate
/// (60 on a 60Hz TV, 120 on a 120Hz one) instead of pinning everything to 60; the manual
/// setting is used as-is inside the engine's own bounds.
int resolveDanmakuFps(DanmakuSettingsModel settings, {double? refreshRate}) {
  if (!settings.danmakuAutoFps) return settings.danmakuFps.clamp(30, 240);

  final double? rate = refreshRate ?? _displayRefreshRate();
  if (rate == null || !rate.isFinite || rate <= 0) return 60;
  // Halo/VRR panels report odd values; snapping to the usual steps keeps the engine's
  // telemetry stable and never leaves it below 30 or above 240.
  return rate.round().clamp(30, 240);
}

double? _displayRefreshRate() {
  try {
    final views = WidgetsBinding.instance.platformDispatcher.views;
    if (views.isEmpty) return null;
    return views.first.display.refreshRate;
  } catch (_) {
    return null;
  }
}
