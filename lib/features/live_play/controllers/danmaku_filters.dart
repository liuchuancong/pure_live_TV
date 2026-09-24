import 'dart:collection';

import 'package:pure_live/shared/models/live_message/live_message_model.dart';

/// Rejects platform backlog and duplicate delivery while keeping memory
/// bounded. Stable platform IDs receive a longer replay window; platforms
/// without IDs use a short text fingerprint window so repeated
/// audience messages remain visible.
///
/// Keeps stable platform IDs in a longer replay window and falls back to a
class DanmakuMessageGate {
  DanmakuMessageGate({
    this.fallbackDuplicateWindow = const Duration(milliseconds: 2500),
    this.stableIdWindow = const Duration(minutes: 10),
    this.maxMessageAge = const Duration(seconds: 45),
    this.maxEntries = 4096,
  });

  final Duration fallbackDuplicateWindow;
  final Duration stableIdWindow;
  final Duration maxMessageAge;
  final int maxEntries;

  final LinkedHashMap<String, DateTime> _seen = LinkedHashMap<String, DateTime>();

  bool accepts(LiveMessage message, {DateTime? now}) {
    final receivedAt = now ?? DateTime.now();
    final sentAt = message.sentAt;
    if (sentAt != null) {
      final age = receivedAt.difference(sentAt);
      if (age > maxMessageAge) return false;
      // A small amount of device/server clock skew is normal. Very large
      // future timestamps are malformed and should not poison the ID cache.
      if (age < const Duration(minutes: -10)) return false;
    }

    final stableId = message.messageId?.trim() ?? '';
    final hasStableId = stableId.isNotEmpty;
    final key = hasStableId
        ? 'id:$stableId'
        : 'text:${message.type.index}:${message.userId?.trim().toLowerCase() ?? ''}:'
              '${message.userName.trim().toLowerCase()}:${message.message.trim()}';
    final duplicateWindow = hasStableId ? stableIdWindow : fallbackDuplicateWindow;

    final previous = _seen.remove(key);
    if (previous != null && receivedAt.difference(previous) <= duplicateWindow) {
      _seen[key] = previous;
      return false;
    }

    _seen[key] = receivedAt;
    _evictExpired(receivedAt);
    return true;
  }

  void clear() => _seen.clear();

  void _evictExpired(DateTime now) {
    final oldestAllowed = now.subtract(stableIdWindow);
    while (_seen.isNotEmpty && _seen.values.first.isBefore(oldestAllowed)) {
      _seen.remove(_seen.keys.first);
    }
    while (_seen.length > maxEntries) {
      _seen.remove(_seen.keys.first);
    }
  }
}

/// Collapses a short burst of identical audience text into its first message.
///
/// Separate from [DanmakuMessageGate]: the gate rejects
/// replayed packets from one sender/ID, while this optional user-facing filter
/// suppresses copy-paste text sent by different accounts. Local and system
/// messages are never affected.
///
/// Uses a short text window so repeated audience messages stay visible.
class RepeatedDanmakuFilter {
  RepeatedDanmakuFilter({this.maxEntries = 1024});

  final int maxEntries;
  final LinkedHashMap<String, DateTime> _lastSeen = LinkedHashMap<String, DateTime>();

  bool accepts(LiveMessage message, {required bool enabled, required Duration window, DateTime? now}) {
    if (!enabled) {
      if (_lastSeen.isNotEmpty) _lastSeen.clear();
      return true;
    }
    if (message.type != LiveMessageType.chat || message.isLocal) return true;

    final normalized = message.message.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
    if (normalized.isEmpty) return true;

    final receivedAt = now ?? DateTime.now();
    final previous = _lastSeen.remove(normalized);
    _lastSeen[normalized] = receivedAt;
    _evict(receivedAt, window);
    return previous == null || receivedAt.difference(previous) > window;
  }

  void clear() => _lastSeen.clear();

  void _evict(DateTime now, Duration window) {
    final oldestAllowed = now.subtract(window);
    while (_lastSeen.isNotEmpty && _lastSeen.values.first.isBefore(oldestAllowed)) {
      _lastSeen.remove(_lastSeen.keys.first);
    }
    while (_lastSeen.length > maxEntries) {
      _lastSeen.remove(_lastSeen.keys.first);
    }
  }
}

/// Filters similar danmaku messages within a configurable time window.
///
/// A message is considered a duplicate when its similarity score with
/// a recently cached message reaches [similarityThreshold].
///
/// Similarity uses a self-contained Levenshtein partial ratio, so no extra
/// fuzzy-matching dependency is required.
class DanmakuSimilarityFilter {
  DanmakuSimilarityFilter({
    int similarityThreshold = 85,
    Duration cacheDuration = const Duration(seconds: 3),
    int maxCacheSize = 100,
    int maxComparisons = 96,
    DateTime Function()? clock,
  })  : _similarityThreshold = similarityThreshold.clamp(0, 100),
        _similarityCacheDuration = cacheDuration,
        _maxCacheSize = maxCacheSize.clamp(1, 1000),
        _maxComparisons = maxComparisons.clamp(1, 256),
        _clock = clock ?? DateTime.now;

  /// Minimum similarity score required to treat a message as a duplicate.
  int _similarityThreshold;

  /// How long a message remains in the similarity cache.
  Duration _similarityCacheDuration;

  /// Maximum number of messages kept in the similarity cache.
  int _maxCacheSize;

  /// Bounds fuzzy work per incoming packet.
  final int _maxComparisons;

  final DateTime Function() _clock;

  final LinkedHashMap<String, _CachedDanmaku> _cache = LinkedHashMap();

  void updateConfig({int? similarityThreshold, Duration? cacheDuration, int? maxCacheSize}) {
    if (similarityThreshold != null) {
      _similarityThreshold = similarityThreshold.clamp(0, 100);
    }
    if (cacheDuration != null) {
      _similarityCacheDuration = cacheDuration;
    }
    if (maxCacheSize != null) {
      _maxCacheSize = maxCacheSize.clamp(1, 1000);
      _trimCache();
    }
  }

  /// Returns `true` when the message is considered new; `false` when it is
  /// too similar to a recently displayed message.
  bool shouldDisplay(String text) {
    final normalizedText = _normalizeText(text);
    if (normalizedText.isEmpty) return false;

    final now = _clock();
    _removeExpiredEntries(now);

    // Exact match can be handled without running the similarity algorithm.
    final cachedMessage = _cache[normalizedText];
    if (cachedMessage != null) {
      cachedMessage.count++;
      cachedMessage.lastSeenAt = now;
      _markAsNewest(normalizedText, cachedMessage);
      return false;
    }

    // Compare only the newest bounded window. Iteration stays allocation
    // free; old retained entries are skipped before fuzzy matching begins.
    final int incomingLength = normalizedText.length;
    var skipped = (_cache.length - _maxComparisons).clamp(0, _cache.length);
    for (final entry in _cache.entries) {
      if (skipped > 0) {
        skipped--;
        continue;
      }
      final cached = entry.value;
      // Partial ratio can never exceed 200 * shorter / (shorter + longer), so a
      // length gate rejects impossible candidates before the O(n*m) comparison.
      final int cachedLength = cached.text.length;
      final int shorter = incomingLength < cachedLength ? incomingLength : cachedLength;
      final int longer = incomingLength < cachedLength ? cachedLength : incomingLength;
      if (shorter == 0 || 200 * shorter < _similarityThreshold * (shorter + longer)) continue;
      if (_partialRatio(cached.text, normalizedText) >= _similarityThreshold) {
        cached.count++;
        cached.lastSeenAt = now;
        _markAsNewest(entry.key, cached);
        return false;
      }
    }

    _cache[normalizedText] = _CachedDanmaku(text: normalizedText, lastSeenAt: now);
    _trimCache();
    return true;
  }

  void clear() => _cache.clear();

  int get cacheSize => _cache.length;

  void _removeExpiredEntries(DateTime now) {
    _cache.removeWhere((_, cached) => now.difference(cached.lastSeenAt) > _similarityCacheDuration);
  }

  void _trimCache() {
    while (_cache.length > _maxCacheSize) {
      _cache.remove(_cache.keys.first);
    }
  }

  void _markAsNewest(String key, _CachedDanmaku value) {
    _cache.remove(key);
    _cache[key] = value;
  }

  /// Removes whitespace characters without modifying the actual message.
  String _normalizeText(String text) => text.trim();

  /// Best similarity of [needle] against any substring window of [haystack],
  /// 0 - 100. Equivalent in spirit to fuzzywuzzy's partialRatio, computed
  /// with a bounded two-row Levenshtein distance.
  int _partialRatio(String needle, String haystack) {
    if (needle.isEmpty || haystack.isEmpty) return 0;
    if (needle == haystack) return 100;
    if (haystack.contains(needle)) return 100;

    final needleLen = needle.length;
    if (haystack.length < needleLen) {
      return _ratio(needle, haystack);
    }

    // Bound the window scan for very long messages.
    final step = needleLen > 64 ? 2 : 1;
    var best = 0;
    for (var start = 0; start + needleLen <= haystack.length; start += step) {
      final window = haystack.substring(start, start + needleLen);
      final score = _ratio(needle, window);
      if (score > best) {
        best = score;
        if (best == 100) return best;
      }
    }
    return best;
  }

  int _ratio(String a, String b) {
    final maxLen = a.length > b.length ? a.length : b.length;
    if (maxLen == 0) return 100;
    final distance = _levenshtein(a, b);
    return ((1 - distance / maxLen) * 100).round().clamp(0, 100);
  }

  int _levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    final aChars = a.codeUnits;
    final bChars = b.codeUnits;

    var previous = List<int>.generate(bChars.length + 1, (j) => j);
    var current = List<int>.filled(bChars.length + 1, 0);

    for (var i = 1; i <= aChars.length; i++) {
      current[0] = i;
      final ca = aChars[i - 1];
      for (var j = 1; j <= bChars.length; j++) {
        final cost = ca == bChars[j - 1] ? 0 : 1;
        final deletion = previous[j] + 1;
        final insertion = current[j - 1] + 1;
        final substitution = previous[j - 1] + cost;
        var value = deletion < insertion ? deletion : insertion;
        if (substitution < value) value = substitution;
        current[j] = value;
      }
      final swap = previous;
      previous = current;
      current = swap;
    }
    return previous[bChars.length];
  }
}

class _CachedDanmaku {
  _CachedDanmaku({required this.text, required this.lastSeenAt}) : count = 1;

  final String text;

  DateTime lastSeenAt;

  int count;
}
