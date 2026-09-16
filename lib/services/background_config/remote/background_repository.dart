import 'package:pure_live/services/background_config/local/local_wallpapers.dart';
import 'package:pure_live/services/background_config/remote/background_catalog.dart';
import 'package:pure_live/services/background_config/remote/itab_client.dart';

/// Loads wallpaper entries one page at a time.
///
/// Nothing here reads a git repository. The source tree is a constant
/// ([BackgroundCatalog.builtIn]) and the pictures come from the iTab API, which
/// answers in a few hundred milliseconds where the GitHub mirror chain needed a
/// probe plus one file download per category.
///
/// The three fixed sets — solid colours, live wallpapers, deepin — never leave
/// the device: [isLocalSource] tells the paging core to pull them in one go and
/// slice them locally.
class BackgroundRepository {
  BackgroundRepository._();

  static final BackgroundRepository instance = BackgroundRepository._();

  /// Page sizes the iTab endpoints use. `size` is a server-side promise: ask for
  /// 24 from `/bing/list` and it still answers with 16.
  static const int officialPageSize = 24;
  static const int bingPageSize = 16;

  /// The compiled-in source tree; there is nothing to download.
  BackgroundCatalog loadCatalog() => BackgroundCatalog.builtIn();

  /// True for sources whose entries are compiled in and never fetched.
  bool isLocalSource(String sourceId) =>
      sourceId == BackgroundSourceIds.solidColor ||
      sourceId == BackgroundSourceIds.deepin;

  /// Entries of a local source.
  List<BackgroundItem> localItems(String sourceId) => LocalWallpapers.of(sourceId);

  /// Server page size for a paged source.
  int serverPageSize(String sourceId) =>
      sourceId == BackgroundSourceIds.bing ? bingPageSize : officialPageSize;

  /// One page of a paged source, 1-based.
  Future<List<BackgroundItem>> fetchPage({
    required BackgroundSource source,
    required BackgroundCategory category,
    required int page,
    required int size,
  }) async {
    final String route;
    final Map<String, dynamic> query;
    String? nameKey;
    var uhd = false;
    var video = false;

    if (source.id == BackgroundSourceIds.wallhaven) {
      route = '/wallpaper/wallhaven';
      query = <String, dynamic>{
        'sr': ItabClient.resolution,
        // The "popular" group has no filter at all; every other group is a
        // `q=id:<n>` selector.
        if (category.apiQuery.isNotEmpty) 'q': category.apiQuery,
      };
    } else if (source.id == BackgroundSourceIds.bing) {
      route = '/bing/list';
      query = const <String, dynamic>{};
      nameKey = 'copyright';
      uhd = true;
    } else if (source.id == BackgroundSourceIds.video) {
      // Live wallpapers page from the API too: the rows carry the mp4 url plus
      // its thumbnail and poster renditions, no token required.
      route = '/wallpaper/video/list';
      query = const <String, dynamic>{'sortKey': 'updateTime'};
      video = true;
    } else {
      route = '/wallpaper/list';
      query = <String, dynamic>{
        'sr': ItabClient.resolution,
        'category': category.apiQuery,
        'sortKey': 'updateTime',
      };
    }

    final json = await ItabClient.instance.getJson(route, <String, dynamic>{
      ...query,
      'size': '$size',
      'page': '$page',
    });

    final rows = json['data'];
    if (rows is! List) return const <BackgroundItem>[];

    final items = <BackgroundItem>[];
    for (final row in rows) {
      if (row is! Map) continue;
      final item = _item(
        Map<String, dynamic>.from(row),
        nameKey: nameKey,
        uhd: uhd,
        video: video,
      );
      if (item != null) items.add(item);
    }
    return items;
  }

  /// One API row → one entry. Rows without a picture are dropped.
  static BackgroundItem? _item(
    Map<String, dynamic> row, {
    String? nameKey,
    bool uhd = false,
    bool video = false,
  }) {
    var raw = (video ? row['url'] : (row['raw'] ?? row['url']))?.toString() ?? '';
    if (raw.isEmpty) return null;
    if (uhd) raw = _bingUhd(raw);

    final thumb = row['thumb']?.toString() ?? '';
    final poster = row['poster']?.toString() ?? '';
    String name = row['name']?.toString() ?? '';
    if (name.isEmpty && nameKey != null) name = row[nameKey]?.toString() ?? '';
    if (name.isEmpty) name = _stem(raw);

    return BackgroundItem(
      file: raw,
      // Official, Wallhaven and Bing rows carry their own grid copy; the video
      // endpoint ships thumb + poster renditions. Anything else gets a
      // server-side resize of the full picture.
      thumb: thumb.isNotEmpty ? thumb : cdnThumb(raw),
      poster: video && poster.isNotEmpty ? poster : null,
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
