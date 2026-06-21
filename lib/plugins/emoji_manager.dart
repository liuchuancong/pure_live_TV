import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:pure_live/core/emoji/models/unified_emoji_model.dart';

class EmojiManager {
  static final EmojiManager instance = EmojiManager._internal();
  factory EmojiManager() => instance;
  EmojiManager._internal();

  static const int _maxCacheSize = 100;
  static const int _batchSize = 10;
  static const int maxDecodeWidth = 40;
  static const int maxDecodeHeight = 40;

  static final Map<String, ui.Image> _cache = {};
  static final List<String> _insertionOrder = [];
  String? _currentLoadedSite;
  RegExp? _emojiRegex;

  Map<String, ui.Image> get cache => _cache;
  List<String> get insertionOrder => _insertionOrder;
  RegExp? get emojiRegex => _emojiRegex;

  Future<void> preload(String site) async {
    if (_currentLoadedSite == site) return;

    clearCache();

    List<UnifiedEmojiModel> unifiedList = [];
    try {
      final jsonStr = await rootBundle.loadString('assets/emo/json/$site.json');
      unifiedList = UnifiedEmojiModel.parseToUnifiedList(jsonStr, site);
    } catch (_) {
      return;
    }

    if (unifiedList.isEmpty) return;

    final Map<String, List<String>> assetPathToKeys = {};
    for (final emoji in unifiedList) {
      if (emoji.localFile.isEmpty) continue;

      final String fullAssetPath = 'assets/emo/images/$site/${emoji.localFile}';

      if (emoji.primaryKey.isNotEmpty) {
        assetPathToKeys.putIfAbsent(fullAssetPath, () => []).add(emoji.primaryKey);
      }
      if (emoji.secondaryKey != null && emoji.secondaryKey!.isNotEmpty) {
        assetPathToKeys.putIfAbsent(fullAssetPath, () => []).add(emoji.secondaryKey!);
      }
    }

    // Batched loading to limit memory spike
    final entries = assetPathToKeys.entries.toList();
    for (int i = 0; i < entries.length; i += _batchSize) {
      final batch = entries.sublist(i, (i + _batchSize).clamp(0, entries.length));
      await Future.wait(batch.map((entry) async {
        final assetPath = entry.key;
        final keys = entry.value;

        try {
          final assetData = await rootBundle.load(assetPath);
          final bytes = assetData.buffer.asUint8List();

          final codec = await ui.instantiateImageCodec(bytes, targetWidth: maxDecodeWidth, targetHeight: maxDecodeHeight);
          final frame = await codec.getNextFrame();

          for (final key in keys) {
            _addToCache(key, frame.image);
          }
        } catch (_) {}
      }));
    }

    _rebuildRegex();
    _currentLoadedSite = site;
  }

  void _rebuildRegex() {
    if (_cache.isEmpty) {
      _emojiRegex = null;
      return;
    }

    final keys = _cache.keys.toList()..sort((a, b) => b.length.compareTo(a.length));

    final pattern = keys.map(RegExp.escape).join('|');

    _emojiRegex = RegExp(pattern);
  }

  void _addToCache(String key, ui.Image image) {
    if (_cache.containsKey(key)) {
      if (_cache[key] == image) {
        return;
      }
      _cache[key]?.dispose();
      _insertionOrder.remove(key);
    }
    // Evict oldest entries when cache exceeds limit
    while (_cache.length >= _maxCacheSize && _insertionOrder.isNotEmpty) {
      final oldest = _insertionOrder.removeAt(0);
      _cache[oldest]?.dispose();
      _cache.remove(oldest);
    }
    _cache[key] = image;
    _insertionOrder.add(key);
  }

  void clearCache() {
    final Set<ui.Image> uniqueImages = _cache.values.toSet();
    for (final img in uniqueImages) {
      img.dispose();
    }
    _cache.clear();
    _insertionOrder.clear();
    _emojiRegex = null;
    _currentLoadedSite = null;
  }

  static ui.Image? getEmoji(String emojiText) => _cache[emojiText];

  @visibleForTesting
  void addToCacheForTesting(String key, ui.Image image) => _addToCache(key, image);
}
