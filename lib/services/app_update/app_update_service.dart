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
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_update_service.g.dart';

enum AppUpdatePhase { idle, checking, upToDate, available, downloading, readyToInstall, failed }

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
  });

  double get progress => totalBytes > 0 ? (receivedBytes / totalBytes).clamp(0.0, 1.0) : 0;

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
    return AppUpdateState(phase: AppUpdatePhase.checking);
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

  Future<void> check() async {
    if (_checking) return;
    _checking = true;
    _patchState(phase: AppUpdatePhase.checking, error: '');
    try {
      final ok = await VersionUtil().checkUpdate();
      final hasUpdate = ok && VersionUtil.hasNewVersion();
      final abis = VersionUtil.latestAndroidAbis.toList()..sort();
      if (!hasUpdate) {
        _patchState(phase: AppUpdatePhase.upToDate, latestVersion: VersionUtil.latestVersion, abis: abis);
        return;
      }
      final history = state.history;
      _patchState(
        phase: AppUpdatePhase.available,
        latestVersion: VersionUtil.latestVersion,
        changelog: _cleanChangelog(VersionUtil.latestUpdateLog),
        prerelease: VersionUtil.prerelease,
        abis: abis,
        selectedAbi: abis.contains(state.selectedAbi) || state.selectedAbi.isEmpty
            ? (abis.contains('arm64-v8a') ? 'arm64-v8a' : (abis.isEmpty ? '' : abis.first))
            : state.selectedAbi,
        // Default asset URL comes from the history entry matching the version,
        // or the manifest's own download_url as a last resort.
        history: history,
      );
    } catch (error) {
      _patchState(phase: AppUpdatePhase.failed, error: '$error');
    } finally {
      _checking = false;
    }
  }

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
      final releases = _parseHistory(decoded);
      releases.sort((a, b) => b.version.compareTo(a.version));
      _patchState(history: releases, historyLoading: false);
    } catch (error) {
      _patchState(historyLoading: false, historyError: '$error');
    }
  }

  List<ReleaseModel> _parseHistory(Object? decoded) {
    final rawList = switch (decoded) {
      final List values => values,
      final Map values when values['releases'] is List => values['releases'] as List,
      _ => null,
    };
    if (rawList == null) throw const FormatException('Invalid release history payload');
    final releases = <ReleaseModel>[];
    for (final entry in rawList) {
      if (entry is! Map) continue;
      final release = ReleaseModel.fromJson(Map<String, dynamic>.from(entry));
      if (release.version.trim().isEmpty) continue;
      releases.add(release);
    }
    return releases;
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

  /// Release asset for the selected ABI: the history entry's file list first
  /// (it carries real urls and sizes), the manifest download_url last.
  String? resolveAssetUrl([String? abiOverride]) {
    final abi = (abiOverride ?? state.selectedAbi).trim();
    final release = _latestRelease;
    if (release != null) {
      for (final file in release.files) {
        if (file.name.trim().toLowerCase() == abi.toLowerCase() && file.url.startsWith('http')) {
          return file.url;
        }
      }
    }
    final direct = VersionUtil.downloadUrl;
    if (direct.toLowerCase().endsWith('.apk')) return direct;
    return null;
  }

  void pickAbi(String abi) => _patchState(selectedAbi: abi);

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
    }
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
    );
  }

  /// Changelogs often embed the release download table; the page only wants
  /// the actual notes.
  String _cleanChangelog(String raw) {
    final lines = raw.split('\n');
    return lines.where((line) => !line.trimLeft().startsWith('|')).join('\n').trim();
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
