import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/services/background_config/local/local_wallpapers.dart';
import 'package:pure_live/services/background_config/remote/background_catalog.dart';
import 'package:pure_live/services/background_config/remote/itab_client.dart';

/// Loads wallpaper entries.
///
/// Nothing here reads a git repository any more. The source tree is a constant
/// ([BackgroundCatalog.builtIn]) and the pictures come from the iTab API, which
/// answers in a few hundred milliseconds where the GitHub mirror chain needed a
/// probe plus one file download per category. The three fixed sets — solid
/// colours, live wallpapers, deepin — never leave the device.
///
/// Loaded categories are cached in memory, so re-entering a category does not
/// refetch and flipping between them stays instant.
class BackgroundRepository {
  BackgroundRepository._();

  static final BackgroundRepository instance = BackgroundRepository._();

  /// Official and Wallhaven pages hold 24 entries each.
  static const int _pageSize = 24;

  /// Bing's endpoint ignores anything but 16.
  static const int _bingPageSize = 16;

  /// Upper bound per category; 10 pages is the depth the old catalog shipped.
  static const int _maxPages = 10;

  final Map<String, BackgroundShard> _shards = <String, BackgroundShard>{};
  final Map<String, Future<BackgroundShard>> _inflight =
      <String, Future<BackgroundShard>>{};

  /// The compiled-in source tree; there is nothing to download.
  BackgroundCatalog loadCatalog() => BackgroundCatalog.builtIn();

  /// Entries of one category, fetching only on the first call.
  Future<BackgroundShard> loadShard({
    required BackgroundSource source,
    required BackgroundCategory category,
  }) {
    final String key = '${source.id}|${category.id}';
    final cached = _shards[key];
    if (cached != null) return Future<BackgroundShard>.value(cached);
    final pending = _inflight[key];
    if (pending != null) return pending;

    final future = _fetch(source, category)
        .then((shard) {
          _shards[key] = shard;
          return shard;
        })
        .whenComplete(() => _inflight.remove(key));
    _inflight[key] = future;
    return future;
  }

  void clear() {
    _shards.clear();
    _inflight.clear();
  }

  Future<BackgroundShard> _fetch(
    BackgroundSource source,
    BackgroundCategory category,
  ) async {
    switch (source.id) {
      case BackgroundSourceIds.solidColor:
        return LocalWallpapers.solidShard(source, category);
      case BackgroundSourceIds.video:
        return LocalWallpapers.videoShard(source, category);
      case BackgroundSourceIds.deepin:
        return LocalWallpapers.deepinShard(source, category);
    }

    final List<BackgroundItem> items;
    if (source.id == BackgroundSourceIds.wallhaven) {
      items = await _page(
        '/wallpaper/wallhaven',
        <String, dynamic>{
          'sr': ItabClient.resolution,
          if (category.apiQuery.isNotEmpty) 'q': category.apiQuery,
        },
        _pageSize,
      );
    } else if (source.id == BackgroundSourceIds.bing) {
      items = await _page(
        '/bing/list',
        const <String, dynamic>{},
        _bingPageSize,
        nameKey: 'copyright',
        uhd: true,
      );
    } else {
      items = await _page(
        '/wallpaper/list',
        <String, dynamic>{
          'sr': ItabClient.resolution,
          'category': category.apiQuery,
          'sortKey': 'updateTime',
        },
        _pageSize,
      );
    }

    return BackgroundShard(
      source: source.id,
      category: category.id,
      name: category.name,
      kind: source.kind,
      count: items.length,
      items: items,
    );
  }

  /// Walks the pages of one endpoint until it runs out of entries.
  Future<List<BackgroundItem>> _page(
    String route,
    Map<String, dynamic> query,
    int size, {
    String? nameKey,
    bool uhd = false,
  }) async {
    final items = <BackgroundItem>[];
    for (var page = 1; page <= _maxPages; page++) {
      final json = await ItabClient.instance.getJson(route, <String, dynamic>{
        ...query,
        'size': '$size',
        'page': '$page',
      });

      final rows = json['data'];
      if (rows is! List || rows.isEmpty) break;
      for (final row in rows) {
        if (row is! Map) continue;
        final item = _item(
          Map<String, dynamic>.from(row),
          nameKey: nameKey,
          uhd: uhd,
        );
        if (item != null) items.add(item);
      }

      if (rows.length < size) break;
      final count = (json['count'] as num?)?.toInt();
      if (count != null && count > 0 && items.length >= count) break;
    }
    return items;
  }

  /// One API row → one entry. Rows without a picture are dropped.
  static BackgroundItem? _item(
    Map<String, dynamic> row, {
    String? nameKey,
    bool uhd = false,
  }) {
    var raw = (row['raw'] ?? row['url'])?.toString() ?? '';
    if (raw.isEmpty) return null;
    if (uhd) raw = _bingUhd(raw);

    final thumb = row['thumb']?.toString() ?? '';
    String name = row['name']?.toString() ?? '';
    if (name.isEmpty && nameKey != null) name = row[nameKey]?.toString() ?? '';
    if (name.isEmpty) name = _stem(raw);

    return BackgroundItem(
      file: raw,
      // Official, Wallhaven and Bing rows carry their own grid copy. Anything
      // else gets a server-side resize of the full picture.
      thumb: thumb.isNotEmpty ? thumb : cdnThumb(raw),
      id: (row['id'] ?? row['_id'])?.toString(),
      name: name,
    );
  }

  /// Bing's daily endpoint hands out the 1920x1080 rendition; the same id with
  /// `_UHD.jpg` is the 4K original — the exact swap the extension's "download
  /// 4K wallpaper" button performs.
  static String _bingUhd(String raw) => raw.replaceFirst(
    '1920x1080.jpg&rf=LaDigue_1920x1080.jpg&pid=hp',
    'UHD.jpg',
  );

  /// Last path segment without its extension, used as a display fallback.
  static String _stem(String url) {
    final path = url.split('?').first;
    final name = path.split('/').last;
    final dot = name.lastIndexOf('.');
    return dot > 0 ? name.substring(0, dot) : name;
  }
}

/// The source tree, available synchronously.
final backgroundCatalogProvider = Provider<BackgroundCatalog>(
  (ref) => BackgroundRepository.instance.loadCatalog(),
);

/// Item list for one category.
///
/// The key is a record of (sourceId, categoryId); both are strings, so the key
/// is structurally equal across rebuilds and switching categories does not
/// refetch.
final backgroundShardProvider =
    FutureProvider.family<
      BackgroundShard,
      ({String sourceId, String categoryId})
    >((ref, key) {
      final catalog = BackgroundRepository.instance.loadCatalog();
      final source = catalog.sourceById(key.sourceId);
      if (source == null) {
        throw StateError('unknown wallpaper source: ${key.sourceId}');
      }
      final categories = source.visibleCategories;
      if (categories.isEmpty) {
        throw StateError('wallpaper source has no category: ${key.sourceId}');
      }
      BackgroundCategory category = categories.first;
      for (final candidate in categories) {
        if (candidate.id == key.categoryId) {
          category = candidate;
          break;
        }
      }
      return BackgroundRepository.instance.loadShard(
        source: source,
        category: category,
      );
    });
