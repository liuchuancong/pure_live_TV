import 'dart:async';

import 'package:dio/dio.dart';
import 'package:pure_live/shared/utils/hive_pref_util.dart';

/// GitHub 原始文件加速。
///
/// 国内直连 `raw.githubusercontent.com` 经常 TLS 断流（curl 35 /
/// SSL_ERROR_SYSCALL），并发大文件时尤其明显。这里维护一组镜像，
/// 启动时并发探测同一张小文件，谁先返回用谁，并把结果缓存 6 小时，
/// 后续所有背景资源都走这个基址。
///
/// 探测失败不会抛异常：退回第一个候选，让上层的重试逻辑处理。
class BackgroundMirror {
  BackgroundMirror._();

  static const String owner = 'liuchuancong';
  static const String repo = 'background';
  static const String branch = 'master';

  /// 探测用的文件，仓库根目录下的小文件
  static const String probeFile = 'catalog.json';

  static const Duration _cacheTtl = Duration(hours: 6);
  static const Duration _probeTimeout = Duration(seconds: 15);
  static const String _kBase = 'bgMirrorBase';
  static const String _kProbedAt = 'bgMirrorProbedAt';

  /// 候选镜像，占位符会被替换。顺序即优先级，全部失败时用第一个。
  static const List<String> templates = <String>[
    'https://cdn.jsdelivr.net/gh/{owner}/{repo}@{branch}',
    'https://raw.gitmirror.com/{owner}/{repo}/{branch}',
    'https://ghproxy.net/https://raw.githubusercontent.com/{owner}/{repo}/{branch}',
    'https://gh-proxy.com/https://raw.githubusercontent.com/{owner}/{repo}/{branch}',
    'https://raw.githubusercontent.com/{owner}/{repo}/{branch}',
  ];

  static String fill(String template) => template
      .replaceAll('{owner}', owner)
      .replaceAll('{repo}', repo)
      .replaceAll('{branch}', branch);

  static List<String> get allBases =>
      templates.map(fill).toList(growable: false);

  static final Dio _probeDio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 6),
      receiveTimeout: const Duration(seconds: 8),
      sendTimeout: const Duration(seconds: 6),
      responseType: ResponseType.plain,
      headers: const {'User-Agent': 'pure_live_TV'},
      // 探测阶段自己处理状态码，避免非 200 直接抛
      validateStatus: (code) => code != null && code < 500,
    ),
  );

  static String? _resolved;
  static Future<String>? _resolving;

  /// 取当前最优基址。并发调用只会探测一次。
  static Future<String> resolve({bool force = false}) {
    if (!force) {
      final cached = _resolved ?? HivePrefUtil.getString(_kBase);
      final probedAt = HivePrefUtil.getInt(_kProbedAt) ?? 0;
      final fresh =
          DateTime.now().millisecondsSinceEpoch - probedAt <
          _cacheTtl.inMilliseconds;
      if (cached != null && cached.isNotEmpty && fresh) {
        _resolved = cached;
        return Future.value(cached);
      }
    }
    return _resolving ??= _probe().then((base) {
      _resolved = base;
      _resolving = null;
      return base;
    });
  }

  /// 并发探测，第一个成功的即胜出；全部失败则退回第一个候选。
  static Future<String> _probe() async {
    final completer = Completer<String>();
    var pending = allBases.length;

    for (final base in allBases) {
      unawaited(
        _isReachable(base).then((ok) {
          if (ok && !completer.isCompleted) completer.complete(base);
        }).whenComplete(() {
          pending--;
          if (pending == 0 && !completer.isCompleted) {
            completer.complete(_fallbackBase());
          }
        }),
      );
    }

    final base = await completer.future.timeout(
      _probeTimeout,
      onTimeout: _fallbackBase,
    );
    await HivePrefUtil.setString(_kBase, base);
    await HivePrefUtil.setInt(
      _kProbedAt,
      DateTime.now().millisecondsSinceEpoch,
    );
    return base;
  }

  static String _fallbackBase() =>
      _resolved ?? HivePrefUtil.getString(_kBase) ?? allBases.first;

  static Future<bool> _isReachable(String base) async {
    try {
      final res = await _probeDio.get<String>(
        '$base/$probeFile',
        // 只取头部若干字节，够判断通不通即可
        options: Options(headers: const {'Range': 'bytes=0-255'}),
      );
      final code = res.statusCode ?? 0;
      // 404 也要算“通”：说明镜像本身正常应答，只是上游没有这个文件。
      // catalog.json 属于可选的预生成索引，仓库里没有是常态，
      // 若把 404 判为失败，所有镜像都会落选、退化成固定选第一个，
      // 就失去了测速的意义。
      return code == 200 || code == 206 || code == 404;
    } catch (_) {
      return false;
    }
  }

  /// 某个基址下载失败时调用，下一次 resolve 会重新测速。
  static Future<void> invalidate([String? failedBase]) async {
    if (failedBase != null && failedBase == _resolved) {
      _resolved = null;
      await HivePrefUtil.setInt(_kProbedAt, 0);
    }
  }

  /// 仓库相对路径 → 完整 URL（自动等测速结果）
  static Future<String> url(String path) async {
    final base = await resolve();
    return '$base/${_clean(path)}';
  }

  /// 已知基址时的同步拼接
  static String urlWith(String base, String path) => '$base/${_clean(path)}';

  static String _clean(String path) =>
      path.startsWith('/') ? path.substring(1) : path;
}
