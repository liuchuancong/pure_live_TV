import 'package:flame_barrage/flame_barrage.dart';
import 'package:pure_live/player/global_player_service.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/services/danmaku_settings/danmaku_settings_model.dart';

/// The danmaku settings the engine can render, as one [BarrageConfig]. Every
/// appearance setting the UI exposes must map here. Units: `baseSpeed` is
/// pixels per second, `bottomAreaDistance` a pixel inset.
///
/// The performance knobs are not user settings — they are what a TV can afford,
/// so they follow the device profile instead of one number for every box:
///
/// * `fps` follows the panel's refresh rate (see [resolveDanmakuFps]): the engine
///   integrates scroll positions against real elapsed time, so a lower `fps`
///   only costs smoothness, never speed — but a step budget above the panel's
///   refresh rate is wasted work.
/// * `rasterizeItems` stays on: each message is rasterized once and every frame
///   then blits one textured quad, instead of re-running its text and stroke
///   ops on every frame. This is the single biggest win on TV hardware.
/// * `maxVisibleCount` is the number of bitmap blits per frame — 40 on a weak
///   GPU, 64 on a box with room to spare.
/// * `emitInterval` is a *ceiling* on how fast messages are admitted, not a
///   rate: a quiet room is unaffected, a burst is paced. 50ms keeps a busy chat
///   readable, 100ms is headroom for the weakest boxes.
/// * `pictureCacheMaxSize` / `rasterCacheMaxBytes` bound the bitmap caches (one
///   bitmap per distinct message, ~40 KB at 1080p/20px). Both are a texture
///   budget: a few MB on a 2 GB box, ~10 MB on a box that can spare it.
///
/// Style and lane-geometry changes applied through [BarrageConfig.copyWith]
/// restyle the on-screen messages immediately (the engine re-lays-out and
/// re-bakes them in place), so setting switches show up without waiting for
/// current messages to scroll off.
BarrageConfig buildDanmakuConfig(
  DanmakuSettingsModel settings, {
  String? fontFamily,
  double? refreshRate,
  bool? lowEndDevice,
}) {
  final double fontSize = settings.danmakuFontSize;
  // An unprobed device reports itself as healthy, so a box that never answered
  // the probe keeps the full pipeline rather than being tuned down blindly.
  // [lowEndDevice] overrides the probe (tests pin both branches with it).
  final bool lowEnd = lowEndDevice ?? GlobalPlayerService.instance.deviceProfile.isLowEnd;

  return BarrageConfig(
    emitInterval: lowEnd ? 0.1 : 0.05,
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
    maxVisibleCount: lowEnd ? 40 : 64,
    // Spelled out rather than left to the package default: this is the switch the
    // whole TV tuning rests on, and it must not follow a future default change.
    rasterizeItems: true,
    pictureCacheMaxSize: lowEnd ? 96 : 256,
    rasterCacheMaxBytes: lowEnd ? 12 * 1024 * 1024 : 32 * 1024 * 1024,
    trackHeight: (fontSize * 1.55).clamp(24.0, 64.0).toDouble(),
    emojiSize: (fontSize * 1.3).clamp(16.0, 48.0).toDouble(),
    // Burst dispatch and overflow behaviour, user-tunable.
    realtimeMode: settings.danmakuRealtimeMode,
    maxPendingCount: settings.danmakuMaxPendingCount,
    maxPendingAge: Duration(seconds: settings.danmakuMaxPendingAge),
    overlapSafeGap: settings.danmakuOverlapSafeGap,
    fixedDuration: Duration(seconds: settings.danmakuFixedDuration),
    // Shadow rendering, user-tunable (baked once per message, not a per-frame cost).
    showShadow: settings.danmakuShowShadow,
    shadowBlur: settings.danmakuShadowBlur,
    letterSpacing: settings.danmakuLetterSpacing,
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
  if (rate == null || !rate.isFinite || rate <= 0) return _lowEndCapped(60);
  // Halo/VRR panels report odd values; snapping to the usual steps keeps the engine's
  // telemetry stable and never leaves it below 30 or above 240.
  return _lowEndCapped(rate.round().clamp(30, 240));
}

/// Danmaku frame budget drops to 30 on low-end devices (32-bit-only boxes
/// included).
///
/// Danmaku is per-frame layout plus GPU compositing; in auto mode it follows
/// the display refresh rate (60fps on a 60Hz TV), which competes with video
/// rendering. Boxes that already struggle to hardware-decode 1080p trade
/// danmaku smoothness for video frames. The manual setting is an explicit
/// user choice and is left alone here.
int _lowEndCapped(int fps) {
  if (!GlobalPlayerService.instance.deviceProfile.isLowEnd) return fps;
  return fps > 30 ? 30 : fps;
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
