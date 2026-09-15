import 'package:pure_live/shared/platform/race_http.dart';
import 'package:pure_live/shared/utils/githup_mirror.dart';
import 'package:pure_live/shared/utils/hive_pref_util.dart';

/// Resolves one base URL for every background asset.
///
/// Mirror generation and racing are delegated to the shared [GitHubMirror]
/// and [RaceHttp]. This class only adds a caching policy on top: racing once
/// per file would mean a full round of probes for every thumbnail, so the
/// winning base is stored and reused until it goes stale or a download
/// against it fails.
class BackgroundMirror {
  BackgroundMirror._();

  static final GitHubMirror _repo = GitHubMirror(
    owner: 'liuchuancong',
    repo: 'background',
  );

  /// Small file used to pick the base.
  static const String probeFile = 'catalog.json';

  static const Duration _probeTimeout = Duration(seconds: 15);
  static const Duration _cacheTtl = Duration(hours: 6);
  static const String _kBase = 'bgMirrorBase';
  static const String _kProbedAt = 'bgMirrorProbedAt';

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

  /// Never throws: a failed probe falls back to the CDN entry, so a network
  /// problem degrades the feature instead of breaking the page.
  static Future<String> _probe() async {
    // Every mirror URL is "<base>/<path>", so any of them can be trimmed back
    // to the shared prefix. The CDN entry is the default because the racer
    // reports no winner when the probe file is simply absent.
    var base = _baseOf(_repo.jsdelivr(probeFile));
    try {
      final fastest = await RaceHttp.findFastestUrl(
        _repo.mirrors(probeFile),
        timeout: _probeTimeout,
      );
      if (fastest != null && fastest.isNotEmpty) {
        base = _baseOf(fastest);
      }
    } catch (_) {
      // Keep the CDN default.
    }
    try {
      await HivePrefUtil.setString(_kBase, base);
      await HivePrefUtil.setInt(
        _kProbedAt,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (_) {
      // Caching is best effort; the value still works for this session.
    }
    return base;
  }

  /// Drops the probe file suffix, leaving a prefix usable for any other path.
  static String _baseOf(String url) {
    final suffix = '/$probeFile';
    return url.endsWith(suffix)
        ? url.substring(0, url.length - suffix.length)
        : url;
  }

  /// Called when downloads against [failedBase] fail, so the next resolve
  /// probes again instead of reusing a dead base.
  static Future<void> invalidate([String? failedBase]) async {
    if (failedBase != null && failedBase == _resolved) {
      _resolved = null;
      await HivePrefUtil.setInt(_kProbedAt, 0);
    }
  }

  /// Full URL for a stored path, awaiting the probe if needed.
  static Future<String> url(String path) async {
    final base = await resolve();
    return urlWith(base, path);
  }

  /// Synchronous variant for callers that already hold a base URL.
  static String urlWith(String base, String path) =>
      '$base/${path.startsWith('/') ? path.substring(1) : path}';
}
