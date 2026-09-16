import 'dart:math';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Where a random-image API returns its picture.
enum WallpaperApiKind {
  /// The URL itself streams an image on every request.
  direct,

  /// jkapi.com style: a JSON envelope carrying `image_url` / `content`.
  jkapi,

  /// t.alcy.cc style: the category is a URL path segment.
  alcy,
}

/// One random-wallpaper API source, ported from the old pure_live app's
/// `AppConsts.currentBoxImageSources`. Names are brand labels and stay
/// untranslated on purpose.
class WallpaperApiSource {
  final String name;
  final String url;
  final WallpaperApiKind kind;

  /// jkapi requires a per-endpoint key appended as `&apiKey=`.
  final String? apiKey;

  const WallpaperApiSource({
    required this.name,
    required this.url,
    this.kind = WallpaperApiKind.direct,
    this.apiKey,
  });

  String get host => Uri.tryParse(url)?.host ?? url;
}

const List<WallpaperApiSource> kWallpaperApiSources = [
  WallpaperApiSource(name: '必应随机', url: 'https://bing.img.run/rand.php'),
  WallpaperApiSource(name: '小晓API', url: 'https://v2.xxapi.cn/api/wallpaper'),
  WallpaperApiSource(
    name: '无铭必应每日壁纸',
    url: 'https://jkapi.com/api/bing_img',
    kind: WallpaperApiKind.jkapi,
    apiKey: '0f57c17bca42966996d6a8bc28594858',
  ),
  WallpaperApiSource(
    name: '无铭随机美囡图片',
    url: 'https://jkapi.com/api/meinv_img',
    kind: WallpaperApiKind.jkapi,
    apiKey: '872080c8858c40e6a1eb2ba86694d4d8',
  ),
  WallpaperApiSource(
    name: '无铭随机黑丝图片',
    url: 'https://jkapi.com/api/heisi_img',
    kind: WallpaperApiKind.jkapi,
    apiKey: '0c0c7a39e084db0e9c7cf2e25318f42c',
  ),
  WallpaperApiSource(
    name: '无铭随机白丝图片',
    url: 'https://jkapi.com/api/baisi_img',
    kind: WallpaperApiKind.jkapi,
    apiKey: '7605369407c689e9b2804bfc56a82ac7',
  ),
  WallpaperApiSource(
    name: '无铭随机抖音美女图片',
    url: 'https://jkapi.com/api/dymm_img',
    kind: WallpaperApiKind.jkapi,
    apiKey: '7b6c5500e52878bc46264cd140196699',
  ),
  WallpaperApiSource(
    name: '无铭半次元cosplay',
    url: 'https://jkapi.com/api/bcy_cos',
    kind: WallpaperApiKind.jkapi,
    apiKey: 'f5bce3b84b7409fbe8abb2246b46f4c8',
  ),
  WallpaperApiSource(
    name: '无铭动漫壁纸',
    url: 'https://jkapi.com/api/dm_wallpaper',
    kind: WallpaperApiKind.jkapi,
    apiKey: '95e3a0e608a8b1bed6d513346f929202',
  ),
  WallpaperApiSource(
    name: '无铭随机唯美女生图片',
    url: 'https://jkapi.com/api/wm_girl',
    kind: WallpaperApiKind.jkapi,
    apiKey: '0a7c2239bc57624cac60967937da8a1b',
  ),
  WallpaperApiSource(name: 'mtyqx', url: 'https://api.mtyqx.cn/tapi/random.php'),
  WallpaperApiSource(name: '栗次元', url: 'https://t.alcy.cc/', kind: WallpaperApiKind.alcy),
  WallpaperApiSource(name: 'picsum', url: 'https://picsum.photos/1280/720/?blur=10'),
  WallpaperApiSource(name: 'dmoe', url: 'https://www.dmoe.cc/random.php'),
  WallpaperApiSource(name: 'loliApi', url: 'https://www.loliapi.com/bg/'),
  WallpaperApiSource(name: '搏天动漫', url: 'https://api.btstu.cn/sjbz/?lx=dongman'),
  WallpaperApiSource(name: '搏天妹子', url: 'https://api.btstu.cn/sjbz/?lx=meizi'),
  WallpaperApiSource(name: '搏天随机', url: 'https://api.btstu.cn/sjbz/?lx=suiji'),
  WallpaperApiSource(name: 'catvod', url: 'https://pictures.catvod.eu.org/'),
];

/// Desktop UA: several of these APIs reject app-like agents.
const String _kDesktopUa =
    'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.5845.97 Safari/537.36';

/// t.alcy.cc serves one random image per category path; the old app listed the
/// categories but its match never fired, so every request hit the bare host.
const List<String> _kAlcyCategories = [
  'ycy', 'moez', 'ai', 'ysz', 'ys', 'mp', 'moemp', 'ysmp', 'aimp', 'tx', 'lai', 'xhl', 'bd',
];

final Dio _dio = Dio(
  BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'User-Agent': _kDesktopUa},
  ),
);

/// Resolves [source] to a concrete image and downloads it.
///
/// Random APIs return a different picture per request, so the bytes (not the
/// URL) are what can be applied as a background. Returns null when the API
/// answered but carried no usable image.
Future<Uint8List?> fetchRandomImage(WallpaperApiSource source) async {
  final imageUrl = switch (source.kind) {
    WallpaperApiKind.direct => source.url,
    WallpaperApiKind.alcy => '${source.url}${_kAlcyCategories[Random().nextInt(_kAlcyCategories.length)]}',
    WallpaperApiKind.jkapi => await _resolveJkapiUrl(source),
  };
  if (imageUrl == null || imageUrl.isEmpty) return null;

  final response = await _dio.get<List<int>>(
    imageUrl,
    options: Options(responseType: ResponseType.bytes),
  );
  final bytes = response.data;
  if (bytes == null || bytes.length < 1024) return null;
  return Uint8List.fromList(bytes);
}

Future<String?> _resolveJkapiUrl(WallpaperApiSource source) async {
  final apiKey = source.apiKey;
  if (apiKey == null) return null;
  final requestUrl = '${source.url}${source.url.contains('?') ? '&' : '?'}type=json&apiKey=$apiKey';
  final response = await _dio.get(requestUrl);
  final data = response.data;
  if (data is! Map) return null;
  final value = data['image_url'] ?? data['content'];
  return value is String && value.isNotEmpty ? value : null;
}
