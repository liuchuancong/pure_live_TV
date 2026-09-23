import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;
import 'package:pure_live/shared/common/http_client.dart';
import 'package:pure_live/shared/platform/race_http.dart';
import 'package:pure_live/shared/utils/version_util.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:pure_live/shared/platform/file_utils.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pure_live/shared/utils/hive_pref_util.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pure_live/app/bootstrap/app_path_manager.dart';
import 'package:pure_live/shared/models/release_model/release_model.dart';

part 'app_update_service.g.dart';

enum AppUpdatePhase { idle, checking, upToDate, available, downloading, readyToInstall, failed }

/// What the app did to this device's copy of itself.
enum AppUpdateAction { checked, available, downloaded, installed, failed }

/// What happened when a downloaded package was handed to the installer.
///
/// The download dialog owns the install action, so the controller reports the
/// outcome instead of showing anything itself: the caller picks the message.
enum AppInstallResult { launched, permissionDenied, launchFailed, missingPackage }

/// One line of local update log; kept in Hive so it survives the restart.
class AppUpdateRecord {
  const AppUpdateRecord({required this.version, required this.action, required this.time});

  final String version;
  final AppUpdateAction action;
  final DateTime time;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'version': version,
    'action': action.name,
    'time': time.toIso8601String(),
  };

  /// Lenient on purpose: one unreadable entry must not drop the whole log.
  static AppUpdateRecord fromJson(Map<String, dynamic> json) {
    final String name = '${json['action']}';
    AppUpdateAction action = AppUpdateAction.checked;
    for (final AppUpdateAction candidate in AppUpdateAction.values) {
      if (candidate.name == name) action = candidate;
    }
    return AppUpdateRecord(
      version: '${json['version'] ?? ''}',
      action: action,
      time: DateTime.tryParse('${json['time']}') ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

/// The ABI one release asset name belongs to, null when the name carries none
/// (checksums, source zips, …).
///
/// Matched as a token instead of a prefix: the TV packages are named
/// `PureLive-TV-arm64-v8a-impeller.apk`, the older mobile ones
/// `PureLive-2.0.20-12020-android-arm64-v8a-release.apk` and `app-armeabi-v7a-release.apk`,
/// and the manifest writes a bare `arm64-v8a` — a `startsWith` test sees none of
/// the prefixed ones.
String? abiForAssetName(String name) {
  final String lower = name.trim().toLowerCase();
  for (final String abi in const <String>['arm64-v8a', 'armeabi-v7a', 'x86_64']) {
    // Boundaries keep `armeabi-v7a` from answering for `arm64-v8a`.
    if (RegExp(
      '(^|[^a-z0-9])${RegExp.escape(abi)}'
      r'([^a-z0-9]|$)',
    ).hasMatch(lower))
      return abi;
  }
  return null;
}

/// `impeller` / `skia` when the name carries the renderer tag, '' for the
/// pre-variant asset naming.
String rendererForAssetName(String name) {
  final String lower = name.trim().toLowerCase();
  if (lower.contains('skia')) return 'skia';
  if (lower.contains('impeller')) return 'impeller';
  return '';
}

/// Whether an entry is an installable package. The GitHub API names end in
/// `.apk`; the releases.json entries carry the extension on the url instead.
bool isApkAsset(String name, String url) {
  final String fileName = name.trim().toLowerCase();
  if (fileName.endsWith('.apk')) return true;
  return url.trim().toLowerCase().split('?').first.endsWith('.apk');
}

/// One release asset from GitHub's releases API — the source of truth for
/// downloads (version.json is only a hint).
class ReleaseAssetInfo {
  const ReleaseAssetInfo({required this.name, required this.url, required this.sizeBytes});

  final String name;
  final String url;
  final int sizeBytes;

  /// `arm64-v8a`, `armeabi-v7a` or `x86_64` when the file name carries one,
  /// null for anything else.
  String? get abi => abiForAssetName(name);

  bool get isApk => isApkAsset(name, url);

  /// `impeller` / `skia` when the file name carries the renderer tag.
  String get renderer => rendererForAssetName(name);

  String get sizeText {
    if (sizeBytes <= 0) return '';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(0)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// The release of an API payload (`/releases`) that describes [version].
///
/// The entry whose tag is that version wins, the newest non-prerelease release
/// answers when the version is not published, and a payload of nothing but
/// prereleases still describes its first entry. The manifest is what the update
/// page shows, so a manifest behind the newest release must not pair its notes
/// with that release's files.
Map<String, dynamic>? selectReleaseEntry(Object? decoded, String version) {
  if (decoded is! List || decoded.isEmpty) return null;
  final String wanted = version.trim().replaceFirst(RegExp('^[vV]'), '');
  Map<String, dynamic>? newest;
  for (final entry in decoded) {
    if (entry is! Map) continue;
    final map = Map<String, dynamic>.from(entry);
    if (map['prerelease'] == true) continue;
    newest ??= map;
    if (wanted.isEmpty) continue;
    final tag = '${map['tag_name'] ?? map['name'] ?? ''}'.trim().replaceFirst(RegExp('^[vV]'), '');
    if (tag == wanted) return map;
  }
  if (newest != null) return newest;
  final first = decoded.first;
  return first is Map ? Map<String, dynamic>.from(first) : null;
}

/// The release history payload (JSON array or `releases` object), newest first.
List<ReleaseModel> parseReleaseHistoryPayload(Object? decoded) {
  final rawList = switch (decoded) {
    final List values => values,
    final Map values when values['releases'] is List => values['releases'] as List,
    _ => null,
  };
  if (rawList == null) throw const FormatException('Invalid release history payload');

  final releases = <ReleaseModel>[];
  for (final entry in rawList) {
    if (entry is! Map) continue;
    try {
      final json = Map<String, dynamic>.from(entry);
      // `author` is required by the model but not every manifest entry has one; the
      // release list would otherwise fail to load over a missing avatar.
      json['author'] ??= <String, dynamic>{};
      final release = ReleaseModel.fromJson(json);
      if (release.version.trim().isEmpty) continue;
      releases.add(release);
    } catch (_) {
      // One unreadable entry must not cost the whole history.
      continue;
    }
  }
  releases.sort((left, right) {
    final byDate = right.date.compareTo(left.date);
    return byDate != 0 ? byDate : right.version.compareTo(left.version);
  });
  return releases;
}

/// Release notes stripped of markdown the TV view cannot draw. Manifests embed
/// plain text, so the table rows and the `#`/`---` markers are dropped and the header
/// text is kept.
String cleanReleaseNotes(String raw) {
  final buffer = <String>[];
  for (final line in raw.split('\n')) {
    final trimmed = line.trimLeft();
    if (trimmed.startsWith('|')) continue;
    if (trimmed.startsWith('---')) continue;
    if (trimmed.startsWith('#')) {
      final withoutHash = trimmed.replaceFirst(RegExp(r'^#+\s*'), '');
      if (withoutHash.isNotEmpty) buffer.add(withoutHash);
      continue;
    }
    buffer.add(line);
  }
  return buffer.join('\n').trim();
}

/// Longest file name (in UTF-8 bytes) [safeDownloadFileName] may return.
///
/// The cap keeps the name inside the 255-byte limit every filesystem the TV
/// build writes to enforces, with room left for the `.part` / `.previous`
/// staging suffixes the download uses.
const int _maxDownloadBaseNameBytes = 240;
const int _maxDownloadExtensionBytes = 32;

/// Turns [url] (or [suggestedName]) into a file name that is safe on every
/// filesystem the TV build writes to.
///
/// Ported from the mobile app's updater: the release asset names carry spaces,
/// non-ASCII characters and occasionally path separators, and the `.part` /
/// `.previous` staging files add to the name, so the result has to be a valid
/// single path segment and short enough to leave room for those suffixes.
String safeDownloadFileName(String url, {String? suggestedName}) {
  var candidate = suggestedName?.trim() ?? '';

  if (candidate.isEmpty) {
    try {
      final uri = Uri.parse(url.trim());
      final segments = uri.pathSegments.where((segment) => segment.trim().isNotEmpty).toList();

      if (segments.isNotEmpty) {
        candidate = segments.last;
      }
    } catch (_) {}
  }

  try {
    candidate = Uri.decodeComponent(candidate);
  } catch (_) {}

  candidate = candidate.replaceAll('\\', '/').split('/').last.trim();

  candidate = candidate
      .replaceAll(RegExp(r'[\x00-\x1F\x7F<>:"/\\|?*\u202A-\u202E\u2066-\u2069]'), '_')
      .replaceFirst(RegExp(r'^[. ]+'), '')
      .replaceFirst(RegExp(r'[. ]+$'), '');

  candidate = String.fromCharCodes(candidate.runes);

  if (candidate.isEmpty || candidate == '.' || candidate == '..') {
    candidate = 'PureLive-tv-update.apk';
  }

  if (RegExp(r'^(con|prn|aux|nul|com[1-9]|lpt[1-9])(?:\.|$)', caseSensitive: false).hasMatch(candidate)) {
    candidate = '_$candidate';
  }

  return _fitDownloadBaseName(candidate);
}

/// Shortens [candidate] to [_maxDownloadBaseNameBytes] without splitting a
/// multi-byte character, keeping the extension and adding a content hash so two
/// different long names cannot collide on the same shortened one.
String _fitDownloadBaseName(String candidate) {
  if (utf8.encode(candidate).length <= _maxDownloadBaseNameBytes) {
    return candidate;
  }

  final rawExtension = path.extension(candidate);
  final extension = _truncateUtf8(rawExtension, _maxDownloadExtensionBytes);

  final stem = rawExtension.isEmpty ? candidate : candidate.substring(0, candidate.length - rawExtension.length);

  final digest = sha256.convert(utf8.encode(candidate)).toString().substring(0, 12);

  final suffix = '-$digest$extension';

  final stemBudget = _maxDownloadBaseNameBytes - utf8.encode(suffix).length;

  var fittedStem = _truncateUtf8(stem, stemBudget);

  if (fittedStem.isEmpty) {
    fittedStem = _truncateUtf8('PureLive', stemBudget);
  }

  return '$fittedStem$suffix';
}

String _truncateUtf8(String value, int maxBytes) {
  if (maxBytes <= 0 || value.isEmpty) {
    return '';
  }

  final buffer = StringBuffer();
  var usedBytes = 0;

  for (final rune in value.runes) {
    final scalar = String.fromCharCode(rune);
    final scalarBytes = utf8.encode(scalar).length;

    if (usedBytes + scalarBytes > maxBytes) {
      break;
    }

    buffer.write(scalar);
    usedBytes += scalarBytes;
  }

  return buffer.toString();
}

/// The mirror prefix [url] already carries, '' when it is the plain github url.
String _mirrorPrefixOf(String url) {
  for (final String mirror in AppUpdateController.assetMirrors) {
    if (url.startsWith(mirror)) return mirror;
  }
  return '';
}

/// The urls one download tries, in order.
///
/// [url] is either a plain release url or one already behind a mirror — the
/// download page builds its sources that way. The picked source goes first when
/// [preferGivenUrl] ("source 3" really means source 3), the remaining mirrors
/// follow, and the plain origin is always last.
///
/// Every candidate is built from the github url the given one wraps: a proxy
/// prefix stacked on an already prefixed url (`proxy/proxy/github.com/…`) is a
/// request no proxy can serve, which used to leave the fallback chain dead.
List<String> downloadCandidates(String url, {bool preferGivenUrl = false}) {
  final String used = _mirrorPrefixOf(url);
  final String origin = used.isEmpty ? url : url.substring(used.length);
  return <String>[
    if (preferGivenUrl) url,
    for (final String mirror in AppUpdateController.assetMirrors)
      if (mirror != used) '$mirror$origin',
    origin,
  ];
}

/// Everything the update page renders.
class AppUpdateState {
  final AppUpdatePhase phase;
  final String currentVersion;
  final String currentBuild;
  final String latestVersion;
  final String changelog;

  /// The manifest's update log as the author wrote it — markdown kept, unlike
  /// [changelog] which is stripped for the plain-text preview. The download
  /// page renders this through markdown_widget.
  final String changelogMarkdown;
  final bool prerelease;
  final List<String> abis;
  final String selectedAbi;

  /// 'impeller' (default) or 'skia' — which renderer variant to download.
  final String rendererVariant;
  final String error;

  /// Download progress; [totalBytes] <= 0 means the server sent no length.
  final int receivedBytes;
  final int totalBytes;
  final double speedMbps;

  /// Absolute path of the package the last successful download committed.
  ///
  /// The download dialog owns the transfer, so the finished package has to
  /// outlive it: this is what [AppUpdateController.installDownloaded] hands to
  /// the installer, and what the download page's install row acts on.
  final String downloadedPath;

  final List<ReleaseModel> history;
  final bool historyLoading;
  final String? historyError;

  /// local update log, newest first.
  final List<AppUpdateRecord> records;

  /// The latest release's real assets (GitHub API), empty until fetched.
  final List<ReleaseAssetInfo> latestAssets;

  const AppUpdateState({
    this.phase = AppUpdatePhase.idle,
    this.currentVersion = '',
    this.currentBuild = '',
    this.latestVersion = '',
    this.changelog = '',
    this.changelogMarkdown = '',
    this.prerelease = false,
    this.abis = const [],
    this.selectedAbi = '',
    this.rendererVariant = 'impeller',
    this.error = '',
    this.receivedBytes = 0,
    this.totalBytes = 0,
    this.speedMbps = 0,
    this.downloadedPath = '',
    this.history = const [],
    this.historyLoading = false,
    this.historyError,
    this.records = const [],
    this.latestAssets = const [],
  });

  double get progress => totalBytes > 0 ? (receivedBytes / totalBytes).clamp(0.0, 1.0) : 0;

  /// Seconds left, or null while the size or the speed is unknown.
  int? get remainingSeconds {
    if (totalBytes <= 0 || receivedBytes <= 0 || speedMbps <= 0) return null;
    final double remainingMb = (totalBytes - receivedBytes) / (1024 * 1024);
    final double seconds = remainingMb / speedMbps;
    return seconds.isFinite && seconds >= 0 ? seconds.round() : null;
  }

  AppUpdateState copyWith({
    AppUpdatePhase? phase,
    String? currentVersion,
    String? currentBuild,
    String? latestVersion,
    String? changelog,
    String? changelogMarkdown,
    bool? prerelease,
    List<String>? abis,
    String? selectedAbi,
    String? rendererVariant,
    String? error,
    int? receivedBytes,
    int? totalBytes,
    double? speedMbps,
    String? downloadedPath,
    List<ReleaseModel>? history,
    bool? historyLoading,
    String? historyError,
    List<AppUpdateRecord>? records,
    List<ReleaseAssetInfo>? latestAssets,
  }) {
    return AppUpdateState(
      phase: phase ?? this.phase,
      currentVersion: currentVersion ?? this.currentVersion,
      currentBuild: currentBuild ?? this.currentBuild,
      latestVersion: latestVersion ?? this.latestVersion,
      changelog: changelog ?? this.changelog,
      changelogMarkdown: changelogMarkdown ?? this.changelogMarkdown,
      prerelease: prerelease ?? this.prerelease,
      abis: abis ?? this.abis,
      selectedAbi: selectedAbi ?? this.selectedAbi,
      rendererVariant: rendererVariant ?? this.rendererVariant,
      error: error ?? this.error,
      receivedBytes: receivedBytes ?? this.receivedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      speedMbps: speedMbps ?? this.speedMbps,
      downloadedPath: downloadedPath ?? this.downloadedPath,
      history: history ?? this.history,
      historyLoading: historyLoading ?? this.historyLoading,
      historyError: historyError,
      records: records ?? this.records,
      latestAssets: latestAssets ?? this.latestAssets,
    );
  }
}

/// Online update for the TV build: version check through the existing
/// [VersionUtil] mirror race, release history from `assets/releases.json`,
/// APK download with mirror fallback and progress, then the package installer.
@Riverpod(keepAlive: true)
class AppUpdateController extends _$AppUpdateController {
  Dio? _dio;
  CancelToken? _cancelToken;
  bool _checking = false;

  /// Proxies for GitHub Release assets (binaries, archives, model weights).
  ///
  /// Only `asset` matters here — the GitHub API is not used. Entries marked
  /// with 206 support HTTP Range, so interrupted downloads can resume.
  static const List<String> assetMirrors = [
    // 🟢 asset=206: resumable, best for large files
    'https://cdn.gh-proxy.org/',
    'https://edgeone.gh-proxy.org/',
    'https://hk.gh-proxy.org/',
    'https://gh.noki.eu.org/',
    'https://gh-proxy.com/',
    'https://slink.ltd/',
    'https://gh.catmak.name/',
    'https://proxy.gitwarp.top/',
    'https://github.ednovas.xyz/',
    'https://ghproxy.monkeyray.net/',
    'https://fastgit.cc/',
    'https://ghfile.geekertao.top/',

    // 🟠 asset=200: works, but no resume
    'https://gh-proxy.org/',
    'https://ghproxy.net/',
    'https://wget.la/',
    'https://git.yylx.win/',
    'https://g.blfrp.cn/',
  ];

  @override
  AppUpdateState build() {
    ref.onDispose(_cancelDownload);
    unawaited(_bootstrap());
    final savedRenderer = HivePrefUtil.getString('updateRendererVariant');
    return AppUpdateState(
      phase: AppUpdatePhase.checking,
      records: _readRecords(),
      rendererVariant: savedRenderer == 'skia' ? 'skia' : 'impeller',
    );
  }

  Future<void> _bootstrap() async {
    await _loadCurrentVersion();
    await check();
    unawaited(loadHistory());
  }

  Future<void> _loadCurrentVersion() async {
    try {
      await VersionUtil.initPackageInfo();
    } catch (_) {
      return;
    }
    _patchState(currentVersion: VersionUtil.version, currentBuild: '${VersionUtil.buildNumber}');
  }

  /// Checks the repo manifest.
  ///
  /// [userInitiated] adds the check itself to local update log: the startup check runs on every
  /// launch, and a log full of those would bury the entries that matter (a version was
  /// found, downloaded, installed).
  Future<void> check({bool userInitiated = false}) async {
    if (_checking) return;
    _checking = true;
    _patchState(phase: AppUpdatePhase.checking, error: '');
    try {
      final ok = await VersionUtil().checkUpdate();
      final hasUpdate = ok && VersionUtil.hasNewVersion();
      final abis = VersionUtil.latestAndroidAbis.toList()..sort();
      if (!hasUpdate) {
        _patchState(phase: AppUpdatePhase.upToDate, latestVersion: VersionUtil.latestVersion, abis: abis);
        if (userInitiated) _appendRecord(AppUpdateAction.checked, version: VersionUtil.version);
        // The download page opens from the up-to-date state as well, and the
        // manifest says nothing about the files a release published: without
        // this its sources would be names assembled from the version alone.
        // Only when the manifest answered — a check that failed has no release
        // to ask GitHub about.
        if (ok) unawaited(_fetchLatestReleaseAssets());
        return;
      }
      final history = state.history;
      _patchState(
        phase: AppUpdatePhase.available,
        latestVersion: VersionUtil.latestVersion,
        changelog: cleanReleaseNotes(VersionUtil.latestUpdateLog),
        changelogMarkdown: VersionUtil.latestUpdateLog.trim(),
        prerelease: VersionUtil.prerelease,
        abis: abis,
        selectedAbi: abis.contains(state.selectedAbi) || state.selectedAbi.isEmpty
            ? (abis.contains('arm64-v8a') ? 'arm64-v8a' : (abis.isEmpty ? '' : abis.first))
            : state.selectedAbi,
        history: history,
      );
      _appendRecord(AppUpdateAction.available, version: VersionUtil.latestVersion);
      // The manifest's version/build_number is a hint; the release's real
      // asset list is what actually downloads. Fetched in the background so
      // the page can already render, and the rows upgrade when it lands.
      unawaited(_fetchLatestReleaseAssets());
    } catch (error) {
      _patchState(phase: AppUpdatePhase.failed, error: '$error');
      _appendRecord(AppUpdateAction.failed, version: state.latestVersion);
    } finally {
      _checking = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Latest release assets (GitHub API through the proxy list)
  // ---------------------------------------------------------------------------

  /// The latest release as GitHub reports it, asked through the origin or one
  /// of the proxies (the same prefixes the download path uses, in front of
  /// `api.github.com`). Returns null when no candidate answered.
  Future<List<ReleaseAssetInfo>?> _fetchLatestReleaseAssets() async {
    final api =
        'https://api.github.com/repos/${VersionUtil.updateOwner}/${VersionUtil.updateRepository}/releases?per_page=10';
    final candidates = <String>[
      if (SettingsService.to.appState.useGitHubOriginForUpdates) api,
      for (final mirror in assetMirrors) '$mirror$api',
      // The origin last for the mirrored list: it is the slowest path from a
      // TV box, but a correct answer beats a fast failure.
      if (!SettingsService.to.appState.useGitHubOriginForUpdates) api,
    ];
    for (final url in candidates) {
      final dio = _dioForApi();
      try {
        final data = await dio.get<String>(
          url,
          options: Options(
            headers: {'Accept': 'application/vnd.github+json', 'User-Agent': 'PureLiveTV'},
            responseType: ResponseType.plain,
          ),
        );
        final decoded = jsonDecode(data.data ?? '');
        final assets = _parseLatestReleaseAssets(decoded);
        if (assets != null) {
          final abis = assets.map((a) => a.abi).whereType<String>().toSet().toList()..sort();
          // Real assets win over the manifest's declared ABI list: the rows
          // the page draws should be exactly the files that can download.
          _patchState(latestAssets: assets, abis: abis.isNotEmpty ? abis : null);
          return assets;
        }
      } catch (_) {
        // Try the next candidate.
      } finally {
        dio.close();
      }
    }
    return null;
  }

  /// Picks the release the page is about (see [selectReleaseEntry]) and maps
  /// its assets.
  List<ReleaseAssetInfo>? _parseLatestReleaseAssets(Object? decoded) {
    final release = selectReleaseEntry(decoded, state.latestVersion);
    if (release == null) return null;
    final assets = release['assets'];
    if (assets is! List) return null;
    final result = <ReleaseAssetInfo>[];
    for (final asset in assets) {
      if (asset is! Map) continue;
      final name = '${asset['name'] ?? ''}'.trim();
      final url = '${asset['browser_download_url'] ?? ''}'.trim();
      if (name.isEmpty || !url.startsWith('http')) continue;
      if (!name.toLowerCase().endsWith('.apk')) continue; // TV installs APKs only.
      result.add(ReleaseAssetInfo(name: name, url: url, sizeBytes: (asset['size'] as num?)?.toInt() ?? 0));
    }
    return result;
  }

  Dio _dioForApi() =>
      Dio(BaseOptions(connectTimeout: const Duration(seconds: 12), receiveTimeout: const Duration(seconds: 12)));

  // ---------------------------------------------------------------------------
  // Release history (assets/releases.json through the repo mirrors)
  // ---------------------------------------------------------------------------

  Future<void> loadHistory() async {
    if (state.historyLoading) return;
    _patchState(historyLoading: true, historyError: null);
    try {
      final mirror = VersionUtil.mirror;
      final useOrigin = SettingsService.to.appState.useGitHubOriginForUpdates;
      final sources = useOrigin ? [mirror.rawUrl('assets/releases.json')] : mirror.mirrors('assets/releases.json');
      final url = await RaceHttp.findFastestUrl([
        for (final s in sources) '$s?ts=${DateTime.now().millisecondsSinceEpoch}',
      ]);
      if (url == null) throw StateError('no mirror responded');
      final data = await HttpClient.instance.getJson(url);
      final decoded = data is String ? jsonDecode(data) : data;
      final releases = parseReleaseHistoryPayload(decoded);
      _patchState(history: releases, historyLoading: false);
    } catch (error) {
      _patchState(historyLoading: false, historyError: '$error');
    }
  }

  // ---------------------------------------------------------------------------
  // local update log
  // ---------------------------------------------------------------------------

  static const String _recordsKey = 'appUpdateRecords';

  /// How many entries the log keeps; the oldest fall off the end.
  static const int _maxRecords = 40;

  List<AppUpdateRecord> _readRecords() {
    try {
      return HivePrefUtil.getObjectList<AppUpdateRecord>(_recordsKey, AppUpdateRecord.fromJson);
    } catch (_) {
      // The store is not up yet (or the log is unreadable): start empty.
      return const <AppUpdateRecord>[];
    }
  }

  void _appendRecord(AppUpdateAction action, {String? version}) {
    final AppUpdateRecord record = AppUpdateRecord(
      version: (version ?? state.latestVersion).trim(),
      action: action,
      time: DateTime.now(),
    );
    final List<AppUpdateRecord> next = <AppUpdateRecord>[record, ...state.records];
    if (next.length > _maxRecords) next.removeRange(_maxRecords, next.length);
    _patchState(records: next);
    unawaited(HivePrefUtil.setObjectList<AppUpdateRecord>(_recordsKey, next, (entry) => entry.toJson()));
  }

  /// Empties local update log.
  void clearRecords() {
    _patchState(records: const <AppUpdateRecord>[]);
    unawaited(HivePrefUtil.setObjectList<AppUpdateRecord>(_recordsKey, const <AppUpdateRecord>[], (e) => e.toJson()));
  }

  // ---------------------------------------------------------------------------
  // Asset resolution
  // ---------------------------------------------------------------------------

  /// The history entry for the latest version, matched with or without the
  /// leading `v`.
  ReleaseModel? get _latestRelease {
    final latest = state.latestVersion;
    if (latest.isEmpty || state.history.isEmpty) return null;
    for (final release in state.history) {
      if (release.version == latest || release.version.replaceFirst(RegExp('^[vV]'), '') == latest) {
        return release;
      }
    }
    return null;
  }

  /// Release asset for the selected ABI: the GitHub release's real file first
  /// (exact name and url, straight from the API), the releases.json file list
  /// second, the manifest's download_url third, and the standard asset name
  /// assembled from the release identity last.
  ///
  /// Within both file lists the preference is the same: the selected renderer
  /// variant, then the legacy untagged name (releases from before the
  /// dual-variant split), then any package published for the ABI.
  String? resolveAssetUrl([String? abiOverride]) {
    final String abi = (abiOverride ?? state.selectedAbi).trim().toLowerCase();
    final String renderer = state.rendererVariant;

    final List<({String name, String url})> published = <({String name, String url})>[
      for (final ReleaseAssetInfo asset in state.latestAssets)
        if (asset.isApk) (name: asset.name, url: asset.url),
      for (final ReleaseFileModel file in _latestRelease?.files ?? const <ReleaseFileModel>[])
        if (isApkAsset(file.name, file.url) && file.url.startsWith('http')) (name: file.name, url: file.url),
    ];

    String? untagged;
    String? anyPackage;
    for (final ({String name, String url}) asset in published) {
      if (abiForAssetName(asset.name) != abi) continue;
      final String tag = rendererForAssetName(asset.name);
      if (tag == renderer) return asset.url;
      if (tag.isEmpty) untagged ??= asset.url;
      anyPackage ??= asset.url;
    }
    if (untagged != null) return untagged;
    if (anyPackage != null) return anyPackage;

    final direct = VersionUtil.downloadUrl;
    if (direct.toLowerCase().endsWith('.apk')) return direct;
    final assembled = ReleaseAssetUrls(
      projectUrl: VersionUtil.projectUrl,
      version: state.latestVersion,
    ).apkForAbi(abi, renderer: renderer);
    return assembled.startsWith('http') ? assembled : null;
  }

  void pickAbi(String abi) => _patchState(selectedAbi: abi);

  void pickRenderer(String renderer) {
    final value = renderer == 'skia' ? 'skia' : 'impeller';
    HivePrefUtil.setString('updateRendererVariant', value);
    _patchState(rendererVariant: value);
  }

  /// The size text of the asset for one ABI: the GitHub release's real size
  /// first, the releases.json entry second, matched the same way
  /// [resolveAssetUrl] matches the file itself.
  String? assetSizeFor(String abi) {
    final String wanted = abi.trim().toLowerCase();
    final String renderer = state.rendererVariant;

    String? untagged;
    String? anyPackage;

    for (final ReleaseAssetInfo asset in state.latestAssets) {
      if (asset.abi != wanted || asset.sizeText.isEmpty) continue;
      if (asset.renderer == renderer) return asset.sizeText;
      if (asset.renderer.isEmpty) untagged ??= asset.sizeText;
      anyPackage ??= asset.sizeText;
    }

    final ReleaseModel? release = _latestRelease;
    if (release != null) {
      for (final ReleaseFileModel file in release.files) {
        if (file.size.isEmpty) continue;
        if (abiForAssetName(file.name) != wanted) continue;
        final String tag = rendererForAssetName(file.name);
        if (tag == renderer) return file.size;
        if (tag.isEmpty) untagged ??= file.size;
        anyPackage ??= file.size;
      }
      if (release.files.length == 1 && release.files.first.size.isNotEmpty) {
        anyPackage ??= release.files.first.size;
      }
    }

    return untagged ?? anyPackage;
  }

  /// The size text of the asset that would be installed for the selected ABI, when the
  /// history entry for that version carries one.
  String? get selectedAssetSize => assetSizeFor(state.selectedAbi);

  // ---------------------------------------------------------------------------
  // Download + install
  //
  // The transfer is owned by the update dialog, which draws the progress,
  // offers the cancel and drives the install. What stays here is what the
  // dialog must not own: the mirror candidate list, the private destination
  // directory, the staged commit of the package, the local update log and the
  // "install unknown apps" grant.
  // ---------------------------------------------------------------------------

  /// Downloads one release asset into the app's private download directory.
  ///
  /// The candidates are tried in order — the picked source first when the
  /// download page handed one over, the app's mirror list otherwise, the plain
  /// origin always last — so a dead mirror costs one attempt instead of the
  /// whole download. Progress is published through [AppUpdateState] for the
  /// caller to render, and the committed path is kept in
  /// [AppUpdateState.downloadedPath] so the install survives the dialog.
  ///
  /// Returns true when a package was committed.
  Future<bool> downloadAsset(String url, {bool preferGivenUrl = false}) async {
    if (state.phase == AppUpdatePhase.downloading) return false;
    if (!url.startsWith('http')) {
      _patchState(phase: AppUpdatePhase.available, error: 'no download url');
      return false;
    }

    final fileName = safeDownloadFileName(url);
    final candidates = downloadCandidates(url, preferGivenUrl: preferGivenUrl);

    _cancelToken = CancelToken();
    _dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 20), receiveTimeout: const Duration(minutes: 30)));
    _patchState(
      phase: AppUpdatePhase.downloading,
      receivedBytes: 0,
      totalBytes: 0,
      speedMbps: 0,
      downloadedPath: '',
      error: '',
    );

    Directory? target;
    try {
      final base = await AppPathManager().getDir(AppPathManager.dirDownload);
      target = Directory('${base.path}${Platform.pathSeparator}update');
      if (!await target.exists()) await target.create(recursive: true);
    } catch (error) {
      _cancelDownload();
      _patchState(phase: AppUpdatePhase.available, error: '$error');
      return false;
    }

    Object? lastError;
    for (final candidate in candidates.toSet()) {
      final destination = '${target.path}${Platform.pathSeparator}$fileName';
      try {
        await _downloadCandidate(candidate, destination);
        if (_cancelToken?.isCancelled == true) return false;
        _cancelDownload();
        _patchState(phase: AppUpdatePhase.readyToInstall, receivedBytes: state.totalBytes, downloadedPath: destination);
        _appendRecord(AppUpdateAction.downloaded, version: state.latestVersion);
        return true;
      } catch (error) {
        if (_cancelToken?.isCancelled == true) return false;
        lastError = error;
      }
    }

    _cancelDownload();
    _patchState(
      phase: AppUpdatePhase.available,
      error: 'download failed: $lastError',
      receivedBytes: 0,
      totalBytes: 0,
      speedMbps: 0,
    );
    _appendRecord(AppUpdateAction.failed, version: state.latestVersion);
    return false;
  }

  /// Streams one candidate into `<destination>.part`, then commits it.
  ///
  /// The package is never written where the installer can see a half-file: the
  /// bytes land in a staging file, and only a completed transfer is renamed
  /// onto [destination].
  Future<void> _downloadCandidate(String url, String destination) async {
    final completed = File(destination);
    final partial = File('$destination.part');

    await _recoverInterruptedCommit(completed);
    await _deleteIfPresent(partial);

    var lastTick = DateTime.now();
    var lastBytes = 0;
    await _dio!.download(
      url,
      partial.path,
      cancelToken: _cancelToken,
      options: Options(headers: {'User-Agent': 'PureLiveTV'}, responseType: ResponseType.bytes),
      onReceiveProgress: (received, total) {
        final now = DateTime.now();
        final dt = now.difference(lastTick).inMilliseconds;
        if (dt >= 500) {
          final speed = (received - lastBytes) / (dt / 1000) / (1024 * 1024);
          lastTick = now;
          lastBytes = received;
          _patchState(receivedBytes: received, totalBytes: total, speedMbps: speed);
        } else {
          _patchState(receivedBytes: received, totalBytes: total);
        }
      },
    );

    if (!await partial.exists()) {
      throw const FileSystemException('Downloaded staging file is missing');
    }

    await _commitStagedFile(partial, completed);
  }

  /// Hands the package the download committed to the platform installer.
  ///
  /// Android TVs need the "install unknown apps" grant for this app first; a
  /// denied grant is reported, not thrown, so the dialog can say so.
  Future<AppInstallResult> installDownloaded() async {
    final String packagePath = state.downloadedPath;
    if (packagePath.isEmpty || !await File(packagePath).exists()) {
      _patchState(error: 'install package missing');
      return AppInstallResult.missingPackage;
    }

    if (Platform.isAndroid && packagePath.toLowerCase().endsWith('.apk')) {
      try {
        if (await Permission.requestInstallPackages.isDenied) {
          final granted = await Permission.requestInstallPackages.request();
          if (!granted.isGranted) {
            _patchState(error: 'install permission denied');
            return AppInstallResult.permissionDenied;
          }
        }
      } catch (_) {
        // Some TV boxes throw on the permission check; the installer itself
        // will still fail loudly if the grant is missing.
      }
    }

    final ok = await FileUtils.openFileOrUrl(packagePath);
    if (!ok) {
      _patchState(error: 'installer launch failed');
      _appendRecord(AppUpdateAction.failed, version: state.latestVersion);
      return AppInstallResult.launchFailed;
    }
    _appendRecord(AppUpdateAction.installed, version: state.latestVersion);
    return AppInstallResult.launched;
  }

  /// Aborts the transfer the download dialog started.
  void cancelDownload() {
    _cancelDownload();
    _patchState(phase: AppUpdatePhase.available, receivedBytes: 0, totalBytes: 0, speedMbps: 0);
  }

  void _cancelDownload() {
    try {
      _cancelToken?.cancel();
      _dio?.close(force: true);
    } catch (_) {}
    _cancelToken = null;
    _dio = null;
  }

  Future<void> _deleteIfPresent(File? file) async {
    if (file != null && await file.exists()) {
      await file.delete();
    }
  }

  /// Repairs a commit that a kill (or a battery pull) interrupted between the
  /// backup rename and the staging rename.
  Future<void> _recoverInterruptedCommit(File completedFile) async {
    final backupFile = File('${completedFile.path}.previous');

    if (!await backupFile.exists()) {
      return;
    }

    if (await completedFile.exists()) {
      await backupFile.delete();
    } else {
      await backupFile.rename(completedFile.path);
    }
  }

  /// Moves [partialFile] onto [completedFile], keeping the previous package as
  /// a `.previous` backup until the swap succeeded.
  Future<File> _commitStagedFile(File partialFile, File completedFile) async {
    final backupFile = File('${completedFile.path}.previous');

    await _deleteIfPresent(backupFile);

    final hadPreviousFile = await completedFile.exists();

    if (hadPreviousFile) {
      await completedFile.rename(backupFile.path);
    }

    try {
      final committedFile = await partialFile.rename(completedFile.path);

      await _deleteIfPresent(backupFile);

      return committedFile;
    } catch (_) {
      if (hadPreviousFile && await backupFile.exists() && !await completedFile.exists()) {
        await backupFile.rename(completedFile.path);
      }

      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void _patchState({
    AppUpdatePhase? phase,
    String? currentVersion,
    String? currentBuild,
    String? latestVersion,
    String? changelog,
    String? changelogMarkdown,
    bool? prerelease,
    List<String>? abis,
    String? selectedAbi,
    String? rendererVariant,
    String? error,
    int? receivedBytes,
    int? totalBytes,
    double? speedMbps,
    String? downloadedPath,
    List<ReleaseModel>? history,
    bool? historyLoading,
    String? historyError,
    List<AppUpdateRecord>? records,
    List<ReleaseAssetInfo>? latestAssets,
  }) {
    if (!ref.mounted) return;
    state = state.copyWith(
      phase: phase,
      currentVersion: currentVersion,
      currentBuild: currentBuild,
      latestVersion: latestVersion,
      changelog: changelog,
      changelogMarkdown: changelogMarkdown,
      prerelease: prerelease,
      abis: abis,
      selectedAbi: selectedAbi,
      rendererVariant: rendererVariant,
      error: error,
      receivedBytes: receivedBytes,
      totalBytes: totalBytes,
      speedMbps: speedMbps,
      downloadedPath: downloadedPath,
      history: history,
      historyLoading: historyLoading,
      historyError: historyError,
      records: records,
      latestAssets: latestAssets,
    );
  }
}
