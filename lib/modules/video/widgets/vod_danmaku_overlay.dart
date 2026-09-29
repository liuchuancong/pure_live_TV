import 'dart:async';

import 'package:flame_barrage/flame_barrage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_core/media_core.dart';

import 'package:pure_live/player/danmaku_config_builder.dart';
import 'package:pure_live/modules/vod/api/bilibili_danmaku_api.dart';
import 'package:pure_live/services/index.dart';

/// The VOD danmaku overlay, the live player's engine on a recorded stream:
/// widget only bridges the player position to the engine — the endpoints and
/// parsing live in [BilibiliDanmakuApi] (segmented protobuf reads first, the
/// full XML list as the fallback), and this widget walks the timeline,
/// feeding due items into the [BarrageController].
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
  late final BarrageController _barrage = BarrageController();
  Timer? _timer;

  List<({double time, String text})> _items = const [];
  int _scanIndex = 0;
  int _loadedCid = 0;
  double _lastNow = 0;

  /// Segmented loading (newBV's way): one fetch per ~6 minutes of video, the
  /// segment at the playhead first and its neighbours on demand. Empty map in
  /// the fallback (whole-XML) mode.
  final Map<int, List<({double time, String text})>> _segments = {};
  int _segmentCount = 0;
  final Set<int> _segmentsLoading = {};

  @override
  void initState() {
    super.initState();
    widget.onControllerReady?.call(_barrage);
    _timer = Timer.periodic(const Duration(milliseconds: 250), (_) => _tick());
    _load();
  }

  @override
  void didUpdateWidget(VodDanmakuOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
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
    _segments.clear();
    _segmentsLoading.clear();

    // Segments first (small responses, only the minutes being watched); the
    // one-shot XML is the fallback for a part the view API says nothing about.
    final api = BilibiliDanmakuApi.instance;
    final segments = await api.getDanmakuSegmentCount(aid: widget.aid, cid: widget.cid);
    if (segments > 0) {
      if (!mounted || _loadedCid != widget.cid) return;
      setState(() => _segmentCount = segments);
      unawaited(_ensureSegment(1));
      return;
    }

    setState(() => _segmentCount = 0);
    try {
      final parsed = await api.getDanmakuXml(cid: widget.cid);
      if (!mounted || _loadedCid != widget.cid) return;
      setState(() => _items = parsed);
    } catch (_) {
      // No danmaku is a silent degradation — the video itself is the content.
    }
  }

  static const int _segmentSeconds = 360;

  /// Loads segment [n] (1-based) and folds it into the timeline.
  Future<void> _ensureSegment(int n) async {
    if (n < 1 || n > _segmentCount) return;
    if (_segments.containsKey(n) || _segmentsLoading.contains(n)) return;
    _segmentsLoading.add(n);
    try {
      final items = await BilibiliDanmakuApi.instance.getDanmakuSegment(aid: widget.aid, cid: widget.cid, segment: n);
      if (!mounted || _loadedCid != widget.cid) return;
      setState(() {
        _segments[n] = items;
        _mergeSegments();
      });
    } catch (_) {
      _segments[n] = const [];
    } finally {
      _segmentsLoading.remove(n);
    }
  }

  /// Folds every loaded segment into one sorted timeline and re-derives the
  /// scan pointer for the current position — a late segment must not replay
  /// from the top.
  void _mergeSegments() {
    final merged = <({double time, String text})>[
      for (final list in _segments.values) ...list,
    ]..sort((a, b) => a.time.compareTo(b.time));
    _items = merged;
    _scanIndex = _indexForTime(widget.handle.position.inMilliseconds / 1000.0);
  }

  /// Feeds everything that just came due. A seek backwards rewinds the scan
  /// pointer instead of replaying a stale stream.
  void _tick() {
    if (_segmentCount > 0) {
      // Stay one segment ahead of the playhead; a seek loads where it lands.
      final current = widget.handle.position.inMilliseconds ~/ (_segmentSeconds * 1000) + 1;
      unawaited(_ensureSegment(current));
      unawaited(_ensureSegment(current + 1));
    }
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
