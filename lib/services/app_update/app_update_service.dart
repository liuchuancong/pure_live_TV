import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;
import 'package:pure_live/app/bootstrap/app_path_manager.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:pure_live/shared/common/http_client.dart';
import 'package:pure_live/shared/platform/file_utils.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pure_live/shared/models/release_model/release_model.dart';
import 'package:pure_live/shared/platform/race_http.dart';
import 'package:pure_live/shared/utils/version_util.dart';
import 'package:pure_live/shared/utils/hive_pref_util.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

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

/// One release asset from GitHub's releases API — the source of truth for
/// downloads (version.json is only a hint).
class ReleaseAssetInfo {
  const ReleaseAssetInfo({required this.name, required this.url, required this.sizeBytes});

  final String name;
  final String url;
  final int sizeBytes;

  /// `arm64-v8a`, `armeabi-v7a` or `x86_64` when the file name carries one,
  /// null for anything else (source zips, checksums, …).
  String? get abi {
    for (final candidate in const ['arm64-v8a', 'armeabi-v7a', 'x86_64']) {
      if (name.toLowerCase().contains(candidate)) return candidate;
    }
    return null;
  }

  bool get isApk => name.toLowerCase().endsWith('.apk');

  /// `impeller` / `skia` when the file name carries the renderer tag, '' for
  /// the pre-variant asset naming.
  String get renderer {
    final lower = name.toLowerCase();
    if (lower.contains('skia')) return 'skia';
    if (lower.contains('impeller')) return 'impeller';
    return '';
  }

  String get sizeText {
    if (sizeBytes <= 0) return '';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(0)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
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

  /// Proxies tried in order for release assets hosted on github.com; the plain
  /// origin is always appended last. Public: the download page renders one
  /// pickable source button per entry, in this order.
  static const List<String> assetMirrors = [
    'https://gh-proxy.org/',
    'https://ghfast.top/',
    'https://ghproxy.net/',
    'https://wget.la/',
    'https://gh.h233.eu.org/',
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
    final api = 'https://api.github.com/repos/${VersionUtil.updateOwner}/${VersionUtil.updateRepository}/releases?per_page=10';
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

  /// Picks the newest non-prerelease release from the list (falling back to
  /// the first entry) and maps its assets.
  List<ReleaseAssetInfo>? _parseLatestReleaseAssets(Object? decoded) {
    if (decoded is! List || decoded.isEmpty) return null;
    Map<String, dynamic>? release;
    for (final entry in decoded) {
      if (entry is Map && entry['prerelease'] != true) {
        release = Map<String, dynamic>.from(entry);
        break;
      }
    }
    release ??= Map<String, dynamic>.from(decoded.first as Map);
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

  Dio _dioForApi() => Dio(BaseOptions(connectTimeout: const Duration(seconds: 12), receiveTimeout: const Duration(seconds: 12)));

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
      final url = await RaceHttp.findFastestUrl(
        [for (final s in sources) '$s?ts=${DateTime.now().millisecondsSinceEpoch}'],
      );
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
  /// second, the manifest download_url third, and the standard asset name
  /// assembled from the release identity last.
  String? resolveAssetUrl([String? abiOverride]) {
    final abi = (abiOverride ?? state.selectedAbi).trim().toLowerCase();
    final renderer = state.rendererVariant;

    // Release assets carry the renderer tag since the dual-variant builds;
    // prefer the exact variant, fall back to the legacy untagged naming for
    // releases published before the split.
    String? exact;
    String? untagged;
    for (final asset in state.latestAssets) {
      if (asset.abi?.toLowerCase() != abi || !asset.isApk) continue;
      if (asset.renderer == renderer) {
        exact = asset.url;
        break;
      }
      if (asset.renderer.isEmpty) untagged ??= asset.url;
    }
    if (exact != null) return exact;

    final release = _latestRelease;
    if (release != null) {
      for (final file in release.files) {
        final lower = file.name.trim().toLowerCase();
        if (!lower.startsWith(abi) || !file.url.startsWith('http')) continue;
        if (lower.contains(renderer)) return file.url;
      }
    }
    if (untagged != null) return untagged;

    final release2 = _latestRelease;
    if (release2 != null) {
      for (final file in release2.files) {
        if (file.name.trim().toLowerCase() == abi && file.url.startsWith('http')) {
          return file.url;
        }
      }
    }

    final direct = VersionUtil.downloadUrl;
    if (direct.toLowerCase().endsWith('.apk')) return direct;
    final assembled = ReleaseAssetUrls(
      projectUrl: VersionUtil.projectUrl,
      version: state.latestVersion,
      buildNumber: VersionUtil.latestBuildNumber ?? 0,
    ).urlForAbi(abi);
    return assembled.startsWith('http') ? assembled : null;
  }

  void pickAbi(String abi) => _patchState(selectedAbi: abi);

  void pickRenderer(String renderer) {
    final value = renderer == 'skia' ? 'skia' : 'impeller';
    HivePrefUtil.setString('updateRendererVariant', value);
    _patchState(rendererVariant: value);
  }

  /// The size text of the asset for one ABI: the GitHub release's real size
  /// first, the releases.json entry second.
  String? assetSizeFor(String abi) {
    final renderer = state.rendererVariant;
    for (final asset in state.latestAssets) {
      if (asset.abi?.toLowerCase() != abi.trim().toLowerCase()) continue;
      if (asset.sizeText.isEmpty) continue;
      // Variant-tagged assets first; untagged ones answer for both variants.
      if (asset.renderer.isEmpty || asset.renderer == renderer) return asset.sizeText;
    }
    final ReleaseModel? release = _latestRelease;
    if (release == null) return null;
    for (final ReleaseFileModel file in release.files) {
      if (file.name.trim().toLowerCase() == abi.trim().toLowerCase() && file.size.isNotEmpty) return file.size;
    }
    if (release.files.length == 1 && release.files.first.size.isNotEmpty) return release.files.first.size;
    return null;
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
    // The download page hands over an explicitly picked source: it goes first
    // so "source 3" really downloads from source 3, with the remaining mirrors
    // kept as fallback. The plain path keeps mirror-first ordering.
    final mirrorCandidates = <String>[for (final mirror in assetMirrors) '$mirror$url'];
    final candidates = preferGivenUrl
        ? <String>[url, ...mirrorCandidates, url]
        : <String>[...mirrorCandidates, url];

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
        _patchState(
          phase: AppUpdatePhase.readyToInstall,
          receivedBytes: state.totalBytes,
          downloadedPath: destination,
        );
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
