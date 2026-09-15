import 'dart:async';

import 'package:dio/dio.dart';
import 'package:pure_live/shared/utils/hive_pref_util.dart';

/// Resolves the fastest base URL for remote asset files.
///
/// Direct requests to the origin host often drop mid-handshake, especially
/// when several large files are fetched at once. This keeps a list of mirror
/// prefixes, probes one small file on all of them in parallel, keeps whichever
/// answers first, and caches the winner so later requests reuse one base.
///
/// A failed probe never throws: it falls back to the first candidate and
/// leaves retrying to the caller.
class BackgroundMirror {
  BackgroundMirror._();

  static const String owner = 'liuchuancong';
  static const String repo = 'background';
  static const String branch = 'master';

  /// Small file used for probing.
  static const String probeFile = 'catalog.json';

  static const Duration _cacheTtl = Duration(hours: 6);
  static const Duration _probeTimeout = Duration(seconds: 15);
  static const String _kBase = 'bgMirrorBase';
  static const String _kProbedAt = 'bgMirrorProbedAt';

  /// Mirror templates, in priority order. Placeholders get substituted.
  /// The first entry is also the fallback when every probe fails.
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
      // Statuses are inspected by hand below, so only hard failures throw.
      validateStatus: (code) => code != null && code < 500,
    ),
  );

  static String? _resolved;
  static Future<String>? _resolving;

  /// Returns the best base URL, probing at most once for concurrent callers.
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

  /// Probes all mirrors in parallel; the first success wins.
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
        // Only the first few bytes are needed to tell whether it answers.
        options: Options(headers: const {'Range': 'bytes=0-255'}),
      );
      final code = res.statusCode ?? 0;
      // 404 also counts as reachable: the mirror answered normally and simply
      // does not have this file. The probe target is an optional prebuilt
      // index that may legitimately be absent, so treating 404 as failure
      // would disqualify every mirror and collapse to a fixed first choice.
      return code == 200 || code == 206 || code == 404;
    } catch (_) {
      return false;
    }
  }

  /// Called when downloads against [failedBase] fail, so the next resolve
  /// probes again instead of reusing a dead base.
  static Future<void> invalidate([String? failedBase]) async {
    if (failedBase != null && failedBase == _resolved) {
      _resolved = null;
      await HivePrefUtil.setInt(_kProbedAt, 0);
    }
  }

  /// Repo-relative path to a full URL, awaiting the probe if needed.
  static Future<String> url(String path) async {
    final base = await resolve();
    return '$base/${_clean(path)}';
  }

  /// Synchronous variant for callers that already hold a base URL.
  static String urlWith(String base, String path) => '$base/${_clean(path)}';

  static String _clean(String path) =>
      path.startsWith('/') ? path.substring(1) : path;
}
