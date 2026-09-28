import 'dart:async';

import 'package:flame_barrage/flame_barrage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_core/media_core.dart';

import 'package:pure_live/player/danmaku_config_builder.dart';
import 'package:pure_live/services/index.dart';
import 'package:pure_live/shared/common/http_client.dart';

/// The VOD danmaku overlay, the live player's engine on a recorded stream:
/// [FlameBarrageWidget] renders, the global 弹幕设置 page styles it, and this
/// widget only bridges the player position to the engine — the full XML list
/// (`/x/v1/dm/list.so`) is parsed once per part and walked against the handle
/// position, feeding due items into the [BarrageController].
///
/// [inject] puts a just-sent comment on screen without waiting for the API.
class VodDanmakuOverlay extends ConsumerStatefulWidget {
  const VodDanmakuOverlay({
    super.key,
    required this.handle,
    required this.cid,
    required this.aid,
    required this.bvid,
    this.onControllerReady,
  });

  final PlayerHandle handle;
  final int cid;
  final int aid;
  final String bvid;

  /// Hands the engine controller to the owner (the player page) so a sent
  /// comment can be echoed locally.
  final ValueChanged<BarrageController>? onControllerReady;

  @override
  ConsumerState<VodDanmakuOverlay> createState() => VodDanmakuOverlayState();
}

class VodDanmakuOverlayState extends ConsumerState<VodDanmakuOverlay> {
  static final RegExp _line = RegExp(r'<d p="([^"]+)"[^>]*>([^<]+)</d>');
  static final RegExp _htmlTag = RegExp(r'<[^>]+>');
  static const Map<String, String> _entities = {
    '&lt;': '<',
    '&gt;': '>',
    '&quot;': '"',
    '&#39;': "'",
    '&apos;': "'",
    '&amp;': '&',
  };

  late final BarrageController _barrage = BarrageController();
  Timer? _timer;

  List<({double time, String text})> _items = const [];
  int _scanIndex = 0;
  int _loadedCid = 0;
  double _lastNow = 0;

  String _unescape(String raw) {
    var text = raw;
    for (final entry in _entities.entries) {
      text = text.replaceAll(entry.key, entry.value);
    }
    return text.replaceAll(_htmlTag, '');
  }

  @override
  void initState() {
    super.initState();
    widget.onControllerReady?.call(_barrage);
    _timer = Timer.periodic(const Duration(milliseconds: 250), (_) => _tick());
    _load();
  }

  @override
  void didUpdateWidget(VodDanmakuOverlay oldWidget) {
    super.didUpdateWidget(old);
    if (oldWidget.cid != widget.cid) _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _barrage.clear();
    super.dispose();
  }

  Future<void> _load() async {
    _items = const [];
    _scanIndex = 0;
    _lastNow = 0;
    _barrage.clear();
    _loadedCid = widget.cid;
    try {
      final xml = await HttpClient.instance.getText(
        'https://api.bilibili.com/x/v1/dm/list.so?oid=${widget.cid}',
        header: {'user-agent': 'Mozilla/5.0', 'referer': 'https://www.bilibili.com/'},
      );
      final parsed = <({double time, String text})>[];
      for (final match in _line.allMatches(xml)) {
        final fields = match.group(1)?.split(',') ?? const [];
        final time = double.tryParse(fields.elementAtOrNull(0) ?? '') ?? -1;
        final mode = int.tryParse(fields.elementAtOrNull(1) ?? '') ?? 1;
        if (time < 0 || mode > 3) continue;
        final text = _unescape(match.group(2) ?? '').trim();
        if (text.isEmpty) continue;
        parsed.add((time: time, text: text));
      }
      parsed.sort((a, b) => a.time.compareTo(b.time));
      if (!mounted || _loadedCid != widget.cid) return;
      setState(() => _items = parsed);
    } catch (_) {
      // No danmaku is a silent degradation — the video itself is the content.
    }
  }

  /// Feeds everything that just came due. A seek backwards rewinds the scan
  /// pointer instead of replaying a stale stream.
  void _tick() {
    if (_items.isEmpty) return;
    final now = widget.handle.position.inMilliseconds / 1000.0;
    if (now < _lastNow - 2.0) {
      _barrage.clear();
      _scanIndex = _indexForTime(now);
    }
    _lastNow = now;
    while (_scanIndex < _items.length && _items[_scanIndex].time <= now) {
      final item = _items[_scanIndex];
      if (item.text.isNotEmpty && now - item.time < 0.6) {
        _barrage.send(BarrageItem(content: item.text, type: BarrageType.scroll));
      }
      _scanIndex++;
    }
  }

  int _indexForTime(double seconds) {
    var at = 0;
    while (at < _items.length && _items[at].time < seconds) {
      at++;
    }
    return at;
  }

  /// Echoes a comment the user just sent, without waiting for the API.
  void inject(String text) {
    _barrage.send(BarrageItem(content: text, type: BarrageType.scroll));
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(danmakuSettingsControllerProvider);
    if (settings.hideDanmaku || !settings.enableDanmakuDisplay) {
      return const SizedBox.shrink();
    }
    return IgnorePointer(
      child: FlameBarrageWidget(
        config: buildDanmakuConfig(settings),
        emojiAtlas: EmojiAtlas.instance,
        controller: _barrage,
      ),
    );
  }
}
