import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/shared/common/http_client.dart';
import 'package:pure_live/shared/utils/core_error.dart';
import 'package:pure_live/services/background_config/remote/background_catalog.dart';
import 'package:pure_live/services/background_config/remote/background_mirror.dart';

/// Fetches the remote background catalog.
///
/// Requests go through the app-wide [HttpClient], so the in-app proxy setting
/// and the shared logging apply here too.
///
/// Both the index and the per-category shards are cached in memory, so
/// flipping between tabs of the same category does not refetch. A failed
/// request invalidates the current mirror and retries once against another.
class BackgroundRepository {
  BackgroundRepository._();

  static final BackgroundRepository instance = BackgroundRepository._();

  static const String catalogPath = 'catalog.json';

  BackgroundCatalog? _catalog;
  final Map<String, BackgroundShard> _shards = <String, BackgroundShard>{};
  final Map<String, Future<BackgroundShard>> _inflight =
      <String, Future<BackgroundShard>>{};

  Future<BackgroundCatalog> loadCatalog({bool force = false}) async {
    if (!force && _catalog != null) return _catalog!;
    try {
      final json = await _getJson(catalogPath);
      final catalog = BackgroundCatalog.fromJson(json);
      if (catalog.isEmpty) {
        throw const FormatException('remote catalog is empty');
      }
      _catalog = catalog;
    } catch (_) {
      // No prebuilt index upstream; the built-in structure plus the
      // per-category shards cover the same content.
      _catalog ??= BackgroundCatalog.builtIn();
      if (force) rethrow;
    }
    return _catalog!;
  }

  Future<BackgroundShard> loadShardPath(
    String key, {
    required BackgroundCategory category,
    required BackgroundKind kind,
    required String sourceId,
    bool force = false,
  }) {
    if (key.isEmpty) {
      return Future<BackgroundShard>.error(
        const FormatException('shard path is empty'),
      );
    }
    if (!force) {
      final cached = _shards[key];
      if (cached != null) return Future.value(cached);
      final pending = _inflight[key];
      if (pending != null) return pending;
    }
    final future = _getRaw(key)
        .then(
          (raw) => BackgroundShard.parse(
            raw,
            category: category,
            kind: kind,
            source: sourceId,
          ),
        )
        .then((shard) {
          _shards[key] = shard;
          return shard;
        })
        .whenComplete(() => _inflight.remove(key));
    _inflight[key] = future;
    return future;
  }

  /// Grid thumbnail URL.
  ///
  /// Stored files are full-resolution (a few hundred KB each); covering a
  /// full grid with them would pull tens of MB in one go. A resizing proxy
  /// brings each thumbnail down to roughly 15-25 KB. When the proxy is
  /// unreachable the widget falls back to the original file, so selecting an
  /// item always uses the full-size URL.
  static String thumbnail(String rawUrl, {int width = 400, int height = 225}) =>
      'https://wsrv.nl/?url=${Uri.encodeComponent(rawUrl)}'
      '&w=$width&h=$height&fit=cover&output=webp&q=72';

  /// Full remote URL for a stored path, using the current best mirror.
  Future<String> urlOf(String path) => BackgroundMirror.url(path);

  void clear() {
    _catalog = null;
    _shards.clear();
    _inflight.clear();
  }

  /// GET returning raw JSON (object or array), retrying once on another
  /// mirror.
  ///
  /// A 404 means the file genuinely is not there, so the mirror is kept and
  /// the error is handed to the caller to fall back on.
  Future<dynamic> _getRaw(String path, {bool retried = false}) async {
    final base = await BackgroundMirror.resolve(force: retried);
    final url = BackgroundMirror.urlWith(base, path);
    try {
      return _decode(await HttpClient.instance.getJson(url));
    } catch (error) {
      final notFound = error is HttpError && error.statusCode == 404;
      if (retried || notFound) rethrow;
      // The mirror may have gone away; drop it and try another.
      await BackgroundMirror.invalidate(base);
      return _getRaw(path, retried: true);
    }
  }

  Future<Map<String, dynamic>> _getJson(
    String path, {
    bool retried = false,
  }) async {
    final raw = await _getRaw(path, retried: retried);
    if (raw is Map) return Map<String, dynamic>.from(raw);
    throw const FormatException('response is not a JSON object');
  }

  /// Some mirrors answer with text/plain, so parse defensively.
  dynamic _decode(dynamic data) {
    if (data is Map || data is List) return data;
    if (data is String && data.isNotEmpty) return jsonDecode(data);
    throw const FormatException('response is not valid JSON');
  }
}

/// Remote background index.
final backgroundCatalogProvider = FutureProvider<BackgroundCatalog>(
  (ref) => BackgroundRepository.instance.loadCatalog(),
);

/// Item list for one category.
///
/// The key is a record of (sourceId, kind, category). [BackgroundCategory]
/// implements == and hashCode, and strings and enums already compare by
/// value, so the whole key is structurally equal across rebuilds and
/// switching tabs does not refetch.
final backgroundShardProvider =
    FutureProvider.family<
      BackgroundShard,
      ({String sourceId, BackgroundKind kind, BackgroundCategory category})
    >((ref, key) {
      return BackgroundRepository.instance.loadShardPath(
        key.category.catalog,
        category: key.category,
        kind: key.kind,
        sourceId: key.sourceId,
      );
    });
