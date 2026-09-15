import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/services/background_config/remote/background_catalog.dart';
import 'package:pure_live/services/background_config/remote/background_mirror.dart';

/// 拉取远端背景目录。
///
/// 索引和分片都做内存缓存：同一分类来回切换标签时不会重复请求。
/// 单次请求失败会作废当前镜像并换一个基址重试一次。
class BackgroundRepository {
  BackgroundRepository._();

  static final BackgroundRepository instance = BackgroundRepository._();

  static const String catalogPath = 'catalog.json';

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 30),
      headers: const {'User-Agent': 'pure_live_TV'},
      responseType: ResponseType.json,
    ),
  );

  BackgroundCatalog? _catalog;
  final Map<String, BackgroundShard> _shards = <String, BackgroundShard>{};
  final Map<String, Future<BackgroundShard>> _inflight =
      <String, Future<BackgroundShard>>{};

  BackgroundCatalog? get cachedCatalog => _catalog;

  /// 已缓存的分片，用于先渲染后刷新
  BackgroundShard? cachedShard(BackgroundCategory category) =>
      _shards[category.catalog];

  Future<BackgroundCatalog> loadCatalog({bool force = false}) async {
    if (!force && _catalog != null) return _catalog!;
    try {
      final json = await _getJson(catalogPath);
      final catalog = BackgroundCatalog.fromJson(json);
      if (catalog.isEmpty) {
        throw const FormatException('远端目录为空');
      }
      _catalog = catalog;
    } catch (_) {
      // 仓库里没有预生成的 catalog.json 时用内置结构和 mapping.json 工作
      _catalog ??= BackgroundCatalog.builtIn();
      if (force) rethrow;
    }
    return _catalog!;
  }

  Future<BackgroundShard> loadShard(
    BackgroundSource source,
    BackgroundCategory category, {
    bool force = false,
  }) => loadShardPath(
    category.catalog,
    category: category,
    kind: source.kind,
    sourceId: source.id,
    force: force,
  );

  Future<BackgroundShard> loadShardPath(
    String key, {
    required BackgroundCategory category,
    required BackgroundKind kind,
    required String sourceId,
    bool force = false,
  }) {
    if (key.isEmpty) {
      return Future<BackgroundShard>.error(
        const FormatException('分片路径为空'),
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

  /// 网格缩略图。
  ///
  /// 仓库里存的是 2560px 原图（单张几百 KB），直接铺满一屏网格会一次拉几十 MB。
  /// 这里借 wsrv.nl 做实时缩放，缩略图大约 15~25 KB。代理不可用时
  /// [CachedNetworkImage] 的 errorWidget 会兜底，点选仍用原图地址。
  static String thumbnail(String rawUrl, {int width = 400, int height = 225}) =>
      'https://wsrv.nl/?url=${Uri.encodeComponent(rawUrl)}'
      '&w=$width&h=$height&fit=cover&output=webp&q=72';

  /// 资源的完整远端地址（自动走当前最优镜像）
  Future<String> urlOf(String path) => BackgroundMirror.url(path);

  /// 同步版本，仅在已知镜像基址可用时调用
  String? urlOfSync(String? base, String path) =>
      base == null ? null : BackgroundMirror.urlWith(base, path);

  Future<String> currentBase() => BackgroundMirror.resolve();

  void clear() {
    _catalog = null;
    _shards.clear();
    _inflight.clear();
  }

  /// 带一次换镜像重试的 GET，返回原始 JSON（对象或数组）。
  ///
  /// 404 说明文件本来就不存在（比如仓库没放 catalog.json），
  /// 这时不该作废镜像，直接抛给调用方走兜底。
  Future<dynamic> _getRaw(String path, {bool retried = false}) async {
    final base = await BackgroundMirror.resolve(force: retried);
    final url = BackgroundMirror.urlWith(base, path);
    try {
      final res = await _dio.get<dynamic>(url);
      return _decode(res.data);
    } on DioException catch (error) {
      final notFound = error.response?.statusCode == 404;
      if (retried || notFound) rethrow;
      await BackgroundMirror.invalidate(base);
      return _getRaw(path, retried: true);
    } catch (_) {
      if (retried) rethrow;
      // 当前镜像可能已经失效，作废后换一个再来
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
    throw const FormatException('返回内容不是 JSON 对象');
  }

  /// 部分镜像会以 text/plain 返回，这里统一兜底解析。
  dynamic _decode(dynamic data) {
    if (data is Map || data is List) return data;
    if (data is String && data.isNotEmpty) return jsonDecode(data);
    throw const FormatException('返回内容不是合法 JSON');
  }
}

final backgroundRepositoryProvider = Provider<BackgroundRepository>(
  (ref) => BackgroundRepository.instance,
);

/// 远端背景总索引
final backgroundCatalogProvider = FutureProvider<BackgroundCatalog>(
  (ref) => BackgroundRepository.instance.loadCatalog(),
);

/// 某个分类下的资源清单。
///
/// key 用记录（sourceId, kind, category）：[BackgroundCategory] 实现了
/// == / hashCode，String 和 enum 也是值语义，整条 key 结构相等，
/// 同分类来回切标签不会重复请求。
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
