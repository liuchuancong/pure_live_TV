import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
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

/// One line of 本机更新记录.
///
/// Kept in Hive rather than in the state only: the point of the record is to still be
/// there after the restart that the update itself caused.
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

/// One real release asset, as GitHub's releases API reports it.
///
/// The API is the source of truth for what to download: `version.json`'s
/// version/build_number is only a hint and drifts from what was actually
/// published, while the latest release's asset list carries the exact file
/// names and urls.
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

  String get sizeText {
    if (sizeBytes <= 0) return '';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(0)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// The release history payload, newest first.
///
/// The manifest is a JSON array (or an object with a `releases` array) of
/// [ReleaseModel]s; the mobile app sorts it by date and falls back to the version when
/// two entries share one (`version_history.dart`).
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

/// Release notes without the markdown the TV view cannot draw.
///
/// The manifests embed a download table and `#` headers in the changelog; the TV shows
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

/// Everything the update page renders.
class AppUpdateState {
  final AppUpdatePhase phase;
  final String currentVersion;
  final String currentBuild;
  final String latestVersion;
  final String changelog;
  final bool prerelease;
  final List<String> abis;
  final String selectedAbi;
  final String error;

  /// Download progress; [totalBytes] <= 0 means the server sent no length.
  final int receivedBytes;
  final int totalBytes;
  final double speedMbps;

  final List<ReleaseModel> history;
  final bool historyLoading;
  final String? historyError;

  /// 本机更新记录, newest first.
  final List<AppUpdateRecord> records;

  /// The latest release's real assets (GitHub API), empty until fetched.
  final List<ReleaseAssetInfo> latestAssets;

  const AppUpdateState({
    this.phase = AppUpdatePhase.idle,
    this.currentVersion = '',
    this.currentBuild = '',
    this.latestVersion = '',
    this.changelog = '',
    this.prerelease = false,
    this.abis = const [],
    this.selectedAbi = '',
    this.error = '',
    this.receivedBytes = 0,
    this.totalBytes = 0,
    this.speedMbps = 0,
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
    bool? prerelease,
    List<String>? abis,
    String? selectedAbi,
    String? error,
    int? receivedBytes,
    int? totalBytes,
    double? speedMbps,
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
      prerelease: prerelease ?? this.prerelease,
      abis: abis ?? this.abis,
      selectedAbi: selectedAbi ?? this.selectedAbi,
      error: error ?? this.error,
      receivedBytes: receivedBytes ?? this.receivedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      speedMbps: speedMbps ?? this.speedMbps,
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
  /// origin is always appended last.
  static const List<String> _assetMirrors = [
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
    return AppUpdateState(phase: AppUpdatePhase.checking, records: _readRecords());
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
  /// [userInitiated] adds the check itself to 本机更新记录: the startup check runs on every
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
      for (final mirror in _assetMirrors) '$mirror$api',
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
  // 本机更新记录
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

  /// Empties 本机更新记录.
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
    for (final asset in state.latestAssets) {
      if (asset.abi?.toLowerCase() == abi) return asset.url;
    }
    final release = _latestRelease;
    if (release != null) {
      for (final file in release.files) {
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

  /// The size text of the asset for one ABI: the GitHub release's real size
  /// first, the releases.json entry second.
  String? assetSizeFor(String abi) {
    for (final asset in state.latestAssets) {
      if (asset.abi?.toLowerCase() == abi.trim().toLowerCase() && asset.sizeText.isNotEmpty) return asset.sizeText;
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
  // ---------------------------------------------------------------------------

  Future<void> downloadAndInstall([String? abiOverride]) async {
    if (state.phase == AppUpdatePhase.downloading) return;
    final url = resolveAssetUrl(abiOverride);
    if (url == null || !url.startsWith('http')) {
      _patchState(phase: AppUpdatePhase.failed, error: 'no download url');
      return;
    }
    await downloadAndInstallUrl(url);
  }

  /// Downloads an arbitrary release asset (a history version for rollback)
  /// through the same mirror list and installs it.
  Future<void> downloadAndInstallUrl(String url) async {
    if (state.phase == AppUpdatePhase.downloading) return;
    if (!url.startsWith('http')) {
      _patchState(phase: AppUpdatePhase.failed, error: 'no download url');
      return;
    }
    final fileName = _safeFileName(url);
    final candidates = [
      for (final mirror in _assetMirrors)
        if (!url.startsWith('https://github.com/') || mirror != '') '$mirror$url',
      url,
    ];

    _cancelToken = CancelToken();
    _dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 20), receiveTimeout: const Duration(minutes: 30)));
    _patchState(phase: AppUpdatePhase.downloading, receivedBytes: 0, totalBytes: 0, speedMbps: 0, error: '');

    Directory? target;
    try {
      final base = await AppPathManager().getDir(AppPathManager.dirDownload);
      target = Directory('${base.path}${Platform.pathSeparator}update');
      if (!await target.exists()) await target.create(recursive: true);
    } catch (error) {
      _patchState(phase: AppUpdatePhase.failed, error: '$error');
      return;
    }

    Object? lastError;
    for (final candidate in candidates.toSet()) {
      try {
        await _downloadOne(candidate, '${target.path}${Platform.pathSeparator}$fileName');
        if (_cancelToken?.isCancelled == true) return;
        _patchState(phase: AppUpdatePhase.readyToInstall, receivedBytes: state.totalBytes);
        _appendRecord(AppUpdateAction.downloaded, version: state.latestVersion);
        unawaited(_install(target.path, fileName));
        return;
      } catch (error) {
        if (_cancelToken?.isCancelled == true) return;
        lastError = error;
      }
    }
    _patchState(
      phase: AppUpdatePhase.available,
      error: 'download failed: $lastError',
      receivedBytes: 0,
      totalBytes: 0,
    );
    _appendRecord(AppUpdateAction.failed, version: state.latestVersion);
  }

  Future<void> _downloadOne(String url, String destination) async {
    final partial = File('$destination.part');
    if (await partial.exists()) await partial.delete();

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
    await partial.rename(destination);
  }

  /// Hands the downloaded package to the platform installer. Android TVs need
  /// the "install unknown apps" grant for this app first.
  Future<void> _install(String directory, String fileName) async {
    final path = '$directory${Platform.pathSeparator}$fileName';
    if (Platform.isAndroid && fileName.toLowerCase().endsWith('.apk')) {
      try {
        if (await Permission.requestInstallPackages.isDenied) {
          final granted = await Permission.requestInstallPackages.request();
          if (!granted.isGranted) {
            _patchState(error: 'install permission denied');
            return;
          }
        }
      } catch (_) {
        // Some TV boxes throw on the permission check; the installer itself
        // will still fail loudly if the grant is missing.
      }
    }
    final ok = await FileUtils.openFileOrUrl(path);
    if (!ok) {
      _patchState(error: 'installer launch failed');
      _appendRecord(AppUpdateAction.failed, version: state.latestVersion);
      return;
    }
    _appendRecord(AppUpdateAction.installed, version: state.latestVersion);
  }

  Future<void> installDownloaded() async {
    // The installer was already launched right after the download; this re-opens
    // the newest package in the update folder when the user closed it.
    try {
      final base = await AppPathManager().getDir(AppPathManager.dirDownload);
      final dir = Directory('${base.path}${Platform.pathSeparator}update');
      if (!await dir.exists()) return;
      final files = await dir
          .list()
          .where((e) => e is File)
          .toList();
      File? newest;
      for (final entity in files.cast<File>()) {
        if (newest == null || (await entity.lastModified()).isAfter(await newest.lastModified())) {
          newest = entity;
        }
      }
      if (newest != null) await FileUtils.openFileOrUrl(newest.path);
    } catch (_) {}
  }

  void cancelDownload() {
    _cancelToken?.cancel();
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

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void _patchState({
    AppUpdatePhase? phase,
    String? currentVersion,
    String? currentBuild,
    String? latestVersion,
    String? changelog,
    bool? prerelease,
    List<String>? abis,
    String? selectedAbi,
    String? error,
    int? receivedBytes,
    int? totalBytes,
    double? speedMbps,
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
      prerelease: prerelease,
      abis: abis,
      selectedAbi: selectedAbi,
      error: error,
      receivedBytes: receivedBytes,
      totalBytes: totalBytes,
      speedMbps: speedMbps,
      history: history,
      historyLoading: historyLoading,
      historyError: historyError,
      records: records,
      latestAssets: latestAssets,
    );
  }

  String _safeFileName(String url) {
    var name = '';
    try {
      final segments = Uri.parse(url).pathSegments.where((s) => s.trim().isNotEmpty).toList();
      if (segments.isNotEmpty) name = Uri.decodeComponent(segments.last);
    } catch (_) {}
    name = name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    return name.isEmpty ? 'pure_live_tv_update.apk' : name;
  }
}
