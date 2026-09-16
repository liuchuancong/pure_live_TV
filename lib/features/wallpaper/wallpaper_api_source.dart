import 'dart:math';
import 'dart:typed_data';
import 'package:dio/dio.dart';

/// How a random-image API hands over its picture.
///
/// The distinction matters and is easy to get wrong: the endpoints in this file
/// look alike but behave completely differently. Measured behaviour:
///
/// * `https://v2.xxapi.cn/api/wallpaper` answers
///   `{"code":200,"data":"https://images.xxapi.cn/…jpg"}` — a JSON envelope, not
///   a picture. Downloading the response as image bytes yields a few hundred
///   bytes of JSON and nothing else, which is why this source used to fail.
/// * `https://jkapi.com/api/<name>` answers an **HTML page** unless it is asked
///   for JSON, and then it carries `image_url` or `content`.
/// * `https://t.alcy.cc/` on its own answers an HTML page; only the category
///   path (`https://t.alcy.cc/ycy`) streams a picture, and each category is
///   listed as its own entry.
/// * Everything else (picsum, dmoe, loliapi, mtyqx, …) redirects straight to an
///   image and needs no decoding at all.
enum WallpaperApiKind {
  /// The URL itself streams an image, following redirects.
  direct,

  /// The URL answers JSON (or an HTML page unless JSON is requested) carrying
  /// the real image address.
  json,

  /// t.alcy.cc style: the category is a URL path segment.
  alcy,
}

/// One random-wallpaper API source.
///
/// Names are brand labels and stay untranslated on purpose.
class WallpaperApiSource {
  const WallpaperApiSource({required this.name, required this.url, this.kind = WallpaperApiKind.direct, this.apiKey});

  final String name;
  final String url;
  final WallpaperApiKind kind;

  /// Some JSON endpoints need a key appended as `type=json&apiKey=<key>`.
  final String? apiKey;

  /// Categories accepted as a path segment by the alcy host.
  ///
  /// Only the ones that still resolve are listed: `ai` and `aimp` are published
  /// by the old app but the host answers 404 for both, and a dead entry in the
  /// random pool would just burn a request.
  static const List<String> alcyCategories = <String>[
    'ycy',
    'moez',
    'ysz',
    'ys',
    'mp',
    'moemp',
    'ysmp',
    'tx',
    'lai',
    'xhl',
    'bd',
  ];

  /// The alcy host, shared by the random entry and its per-category entries.
  static const String alcyBase = 'https://t.alcy.cc/';

  String get host => Uri.tryParse(url)?.host ?? url;
}

/// One row on the random-API page: a family of random-image sources.
///
/// The picker is two levels because the flat list reached nearly thirty entries
/// once 栗次元's categories became individual sources. A group row opens
/// [sources] on a page of its own.
class WallpaperApiGroup {
  const WallpaperApiGroup({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.sources,
  });

  final String id;
  final String name;
  final String nameEn;
  final List<WallpaperApiSource> sources;

  /// Display name for [languageCode], falling back to whichever is present.
  String localizedName(String languageCode) {
    if (languageCode == 'zh') return name.isNotEmpty ? name : nameEn;
    return nameEn.isNotEmpty ? nameEn : name;
  }
}

/// The groups, in the order the API page lists them.
final List<WallpaperApiGroup> kWallpaperApiGroups = <WallpaperApiGroup>[
  WallpaperApiGroup(
    id: 'bing',
    name: '必应壁纸',
    nameEn: 'Bing',
    sources: <WallpaperApiSource>[
      const WallpaperApiSource(name: '必应随机', url: 'https://bing.img.run/rand.php'),
      const WallpaperApiSource(
        name: '无铭必应每日壁纸',
        url: 'https://jkapi.com/api/bing_img',
        kind: WallpaperApiKind.json,
        apiKey: '0f57c17bca42966996d6a8bc28594858',
      ),
    ],
  ),
  WallpaperApiGroup(
    id: 'alcy',
    name: '栗次元',
    nameEn: 'Alcy',
    sources: <WallpaperApiSource>[
      const WallpaperApiSource(
        name: '栗次元 · 随机',
        url: WallpaperApiSource.alcyBase,
        kind: WallpaperApiKind.alcy,
      ),
      for (final String category in WallpaperApiSource.alcyCategories)
        WallpaperApiSource(
          name: '栗次元 · $category',
          url: '${WallpaperApiSource.alcyBase}$category',
        ),
    ],
  ),
  WallpaperApiGroup(
    id: 'wuming',
    name: '无铭 API',
    nameEn: 'Wuming API',
    sources: <WallpaperApiSource>[
      const WallpaperApiSource(
        name: '无铭随机美囡图片',
        url: 'https://jkapi.com/api/meinv_img',
        kind: WallpaperApiKind.json,
        apiKey: '872080c8858c40e6a1eb2ba86694d4d8',
      ),
      const WallpaperApiSource(
        name: '无铭随机黑丝图片',
        url: 'https://jkapi.com/api/heisi_img',
        kind: WallpaperApiKind.json,
        apiKey: '0c0c7a39e084db0e9c7cf2e25318f42c',
      ),
      const WallpaperApiSource(
        name: '无铭随机白丝图片',
        url: 'https://jkapi.com/api/baisi_img',
        kind: WallpaperApiKind.json,
        apiKey: '7605369407c689e9b2804bfc56a82ac7',
      ),
      const WallpaperApiSource(
        name: '无铭随机抖音美女图片',
        url: 'https://jkapi.com/api/dymm_img',
        kind: WallpaperApiKind.json,
        apiKey: '7b6c5500e52878bc46264cd140196699',
      ),
      const WallpaperApiSource(
        name: '无铭半次元cosplay',
        url: 'https://jkapi.com/api/bcy_cos',
        kind: WallpaperApiKind.json,
        apiKey: 'f5bce3b84b7409fbe8abb2246b46f4c8',
      ),
      const WallpaperApiSource(
        name: '无铭动漫壁纸',
        url: 'https://jkapi.com/api/dm_wallpaper',
        kind: WallpaperApiKind.json,
        apiKey: '95e3a0e608a8b1bed6d513346f929202',
      ),
      const WallpaperApiSource(
        name: '无铭随机唯美女生图片',
        url: 'https://jkapi.com/api/wm_girl',
        kind: WallpaperApiKind.json,
        apiKey: '0a7c2239bc57624cac60967937da8a1b',
      ),
    ],
  ),
  WallpaperApiGroup(
    id: 'misc',
    name: '其他图源',
    nameEn: 'Other sources',
    sources: <WallpaperApiSource>[
      const WallpaperApiSource(
        name: '小晓API',
        url: 'https://v2.xxapi.cn/api/wallpaper',
        kind: WallpaperApiKind.json,
      ),
      const WallpaperApiSource(name: 'mtyqx', url: 'https://api.mtyqx.cn/tapi/random.php'),
      const WallpaperApiSource(name: 'picsum', url: 'https://picsum.photos/1280/720/?blur=10'),
      const WallpaperApiSource(name: 'dmoe', url: 'https://www.dmoe.cc/random.php'),
      const WallpaperApiSource(name: 'loliApi', url: 'https://www.loliapi.com/bg/'),
      const WallpaperApiSource(name: 'catvod', url: 'https://pictures.catvod.eu.org/'),
    ],
  ),
];

/// Every source across every group.
final List<WallpaperApiSource> kWallpaperApiSources = <WallpaperApiSource>[
  for (final WallpaperApiGroup group in kWallpaperApiGroups) ...group.sources,
];

/// Desktop UA: several of these APIs reject app-like agents or answer HTML.
const String _kDesktopUa =
    'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.5845.97 Safari/537.36';

final Dio _dio = Dio(
  BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
    followRedirects: true,
    headers: {'User-Agent': _kDesktopUa},
  ),
);

final Random _random = Random();

/// Resolves [source] to a concrete image and downloads it.
///
/// Random APIs return a different picture per request, so the bytes (not the
/// URL) are what can be applied as a background. Returns null when the API
/// answered but carried no usable picture — a JSON body or an HTML page passed
/// off as an image is rejected rather than committed as a wallpaper.
Future<Uint8List?> fetchRandomImage(WallpaperApiSource source) async {
  final String? imageUrl = switch (source.kind) {
    WallpaperApiKind.direct => source.url,
    WallpaperApiKind.alcy =>
      '${source.url}${WallpaperApiSource.alcyCategories[_random.nextInt(WallpaperApiSource.alcyCategories.length)]}',
    WallpaperApiKind.json => await _resolveJsonUrl(source),
  };
  if (imageUrl == null || imageUrl.isEmpty) return null;
  return _downloadImage(imageUrl);
}

/// Asks a JSON endpoint where the picture is.
Future<String?> _resolveJsonUrl(WallpaperApiSource source) async {
  final String? apiKey = source.apiKey;
  final String query = apiKey == null ? '' : '${source.url.contains('?') ? '&' : '?'}type=json&apiKey=$apiKey';

  final response = await _dio.get<dynamic>('${source.url}$query');
  return _pickUrl(response.data);
}

/// Finds the image address in whichever shape the endpoint uses.
///
/// Known shapes:
/// * `{"image_url": "…"}` / `{"content": "…"}`   (jkapi)
/// * `{"code":200,"data":"…"}`                  (xxapi)
/// * `{"data":{"url":"…"}}`                     (defensive)
String? _pickUrl(dynamic data) {
  if (data is String) {
    final String value = _unescape(data.trim());
    return value.startsWith('http') ? value : null;
  }
  if (data is Map) {
    for (final String key in const <String>[
      'image_url',
      'imageUrl',
      'content',
      'url',
      'img',
      'imgurl',
      'data',
      'image',
    ]) {
      final String? found = _pickUrl(data[key]);
      if (found != null) return found;
    }
    return null;
  }
  if (data is List && data.isNotEmpty) return _pickUrl(data.first);
  return null;
}

/// JSON bodies come back with HTML-escaped query separators (`&amp;`), which
/// would otherwise be sent verbatim to the image host.
String _unescape(String url) => url.replaceAll('&amp;', '&');

Future<Uint8List?> _downloadImage(String url) async {
  final response = await _dio.get<List<int>>(url, options: Options(responseType: ResponseType.bytes));
  final bytes = response.data;
  if (bytes == null || bytes.length < 256) return null;
  final data = Uint8List.fromList(bytes);
  // A JSON envelope or an HTML error page is not a wallpaper. Sniffing the
  // magic bytes is what keeps "the API answered" from meaning "the background
  // is now a page of text".
  return _looksLikeImage(data) ? data : null;
}

bool _looksLikeImage(Uint8List bytes) {
  if (bytes.length < 12) return false;
  // JPEG
  if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) return true;
  // PNG
  if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) return true;
  // GIF
  if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) return true;
  // BMP
  if (bytes[0] == 0x42 && bytes[1] == 0x4D) return true;
  // WEBP: "RIFF"…"WEBP"
  if (bytes[0] == 0x52 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46 &&
      bytes[3] == 0x46 &&
      bytes[8] == 0x57 &&
      bytes[9] == 0x45 &&
      bytes[10] == 0x42 &&
      bytes[11] == 0x50) {
    return true;
  }
  // HEIC/AVIF: an ISO base media "ftyp" box.
  if (bytes[4] == 0x66 && bytes[5] == 0x74 && bytes[6] == 0x79 && bytes[7] == 0x70) return true;
  return false;
}
