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
    final json = await _getJson(catalogPath);
    final catalog = BackgroundCatalog.fromJson(json);
    if (catalog.isEmpty) {
      throw const FormatException('远端目录为空');
    }
    _catalog = catalog;
    return catalog;
  }

  Future<BackgroundShard> loadShard(
    BackgroundCategory category, {
    bool force = false,
  }) {
    final key = category.catalog;
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
    final future = _getJson(key)
        .then(BackgroundShard.fromJson)
        .then((shard) {
          _shards[key] = shard;
          return shard;
        })
        .whenComplete(() => _inflight.remove(key));
    _inflight[key] = future;
    return future;
  }

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

  /// 带一次换镜像重试的 GET。
  Future<Map<String, dynamic>> _getJson(
    String path, {
    bool retried = false,
  }) async {
    final base = await BackgroundMirror.resolve(force: retried);
    final url = BackgroundMirror.urlWith(base, path);
    try {
      final res = await _dio.get<dynamic>(url);
      return _asMap(res.data);
    } catch (_) {
      if (retried) rethrow;
      // 当前镜像可能已经失效，作废后换一个再来
      await BackgroundMirror.invalidate(base);
      return _getJson(path, retried: true);
    }
  }

  /// 部分镜像会以 text/plain 返回，这里统一兜底解析。
  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is String && data.isNotEmpty) {
      final decoded = jsonDecode(data);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    }
    throw const FormatException('返回内容不是合法 JSON 对象');
  }
}

final backgroundRepositoryProvider = Provider<BackgroundRepository>(
  (ref) => BackgroundRepository.instance,
);

/// 远端背景总索引
final backgroundCatalogProvider = FutureProvider<BackgroundCatalog>(
  (ref) => BackgroundRepository.instance.loadCatalog(),
);

/// 某个分类下的资源清单，按分片路径缓存
final backgroundShardProvider =
    FutureProvider.family<BackgroundShard, BackgroundCategory>(
      (ref, category) => BackgroundRepository.instance.loadShard(category),
    );
