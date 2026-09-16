import 'package:flame_barrage/flame_barrage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/features/live_play/controllers/live_play_controller.dart';
import 'package:pure_live/features/live_play/models/live_play_args.dart';
import 'package:pure_live/services/index.dart';
import 'package:pure_live/shared/emoji/emoji_manager.dart';

/// flame_barrage overlay drawn on top of the video.
///
/// Message transport and filtering belong to [DanmakuSessionController]; this
/// widget only consumes the global style settings and the session controller.
class DanmakuOverlay extends ConsumerStatefulWidget {
  final LivePlayArgs args;

  const DanmakuOverlay({super.key, required this.args});

  @override
  ConsumerState<DanmakuOverlay> createState() => _DanmakuOverlayState();
}

class _DanmakuOverlayState extends ConsumerState<DanmakuOverlay> {
  String? _preloadedPlatform;

  @override
  void initState() {
    super.initState();
    _preloadEmoji();
  }

  void _preloadEmoji() {
    final platform = widget.args.platform;
    if (_preloadedPlatform == platform) return;
    _preloadedPlatform = platform;
    // A missing asset makes preload return safely instead of blocking playback.
    EmojiManager().preload(platform);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(danmakuSettingsControllerProvider);
    final session = ref.watch(danmakuSessionControllerProvider(widget.args));

    if (settings.hideDanmaku || !settings.enableDanmakuDisplay) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: FlameBarrageWidget(
        config: _buildConfig(settings),
        emojiAtlas: EmojiAtlas.instance,
        controller: session.barrageController,
      ),
    );
  }

  BarrageConfig _buildConfig(DanmakuSettingsModel settings) {
    final fps = settings.danmakuAutoFps ? 60 : settings.danmakuFps.clamp(30, 240);
    final fontSize = settings.danmakuFontSize;
    return BarrageConfig(
      // 50ms admit interval plus a visible cap keeps layout and paint cost low.
      emitInterval: 0.05,
      fontFamily: _resolveFontFamily(settings),
      fontSize: fontSize,
      area: settings.danmakuArea,
      topAreaDistance: settings.danmakuTopArea,
      bottomAreaDistance: settings.danmakuBottomArea,
      baseSpeed: settings.danmakuSpeed,
      opacity: settings.danmakuOpacity,
      fontWeight: FontWeight(settings.danmakuFontWeight.clamp(100, 900)),
      strokeWidth: settings.danmakuFontBorder,
      showStroke: settings.enableDanmakuStroke,
      noEmojiMode: settings.noEmojiMode,
      fps: fps,
      maxVisibleCount: 48,
      trackHeight: (fontSize * 1.55).clamp(24.0, 64.0).toDouble(),
      emojiSize: (fontSize * 1.3).clamp(16.0, 48.0).toDouble(),
    );
  }

  /// The danmaku font follows its own setting; `Default` falls back to the
  /// app-wide font so danmaku keeps matching the UI until a dedicated danmaku
  /// font is picked. The flame engine re-keys its paragraph cache on
  /// fontFamily, so switching applies to newly painted danmaku at once.
  String? _resolveFontFamily(DanmakuSettingsModel settings) {
    final String danmaku = settings.danmakuFontFamilyName;
    if (danmaku != 'Default' && danmaku.isNotEmpty) return danmaku;
    final String app = ref.watch(fontSettingsControllerProvider).value?.fontFamilyName ?? 'Default';
    return app != 'Default' && app.isNotEmpty ? app : null;
  }
}
