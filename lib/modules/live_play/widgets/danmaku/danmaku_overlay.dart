import 'package:flame_barrage/flame_barrage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/modules/live_play/controllers/live_play_controller.dart';
import 'package:pure_live/modules/live_play/models/live_play_args.dart';
import 'package:pure_live/services/index.dart';
import 'package:pure_live/core/plugins/emoji_manager.dart';

/// flame_barrage 弹幕画面层（移植自 pure_live DanmakuManager 的画面部分）。
///
/// 消息的发送/过滤由 [DanmakuSessionController] 负责，这里只消费：
/// - 全局弹幕样式设置 -> BarrageConfig
/// - 会话持有的 BarrageController
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
    // 资产缺失时 preload 内部会安全返回，不阻塞播放。
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
      // 与 pure_live 一致：50ms 准入间隔 + 可见上限，压低布局与绘制压力。
      emitInterval: 0.05,
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
}
