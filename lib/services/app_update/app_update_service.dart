import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:pure_live/core/common/api_proxy_policy.dart';
import 'package:pure_live/core/common/http_client.dart';
import 'package:pure_live/core/platform/race_http.dart';
import 'package:pure_live/core/utils/version_util.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:pure_live/core/platform/file_utils.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pure_live/core/utils/hive_pref_util.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pure_live/core/i18n/locale_helper.dart';
import 'package:pure_live/core/models/release_model/release_model.dart';
import 'app_update_models.dart';
export 'app_update_models.dart';

part 'app_update_service.g.dart';

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
  /// outlive it: [AppUpdateController.installDownloaded] hands it to
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
      // asset list that downloads. Fetched in the background so
      // the page can already render, and the rows upgrade when it lands.
      unawaited(_fetchLatestReleaseAssets());
    } catch (error) {
      _patchState(phase: AppUpdatePhase.failed, error: _describeError(error, fallback: i18n('check_update_failed')));
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
      for (final mirror in appUpdateAssetMirrors) '$mirror$api',
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
          // the page draws should match the downloadable files.
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
      Dio(BaseOptions(connectTimeout: const Duration(seconds: 12), receiveTimeout: const Duration(seconds: 12)))
        ..httpClientAdapter = ApiProxyPolicy.dioAdapter;

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

  /// Expected package size in **bytes** for [abi], or 0 when unknown.
  ///
  /// Used to verify the transfer after it completes: the exact byte count the
  /// release publishes is the only proof that a mirror served the whole file.
  /// Matching follows [resolveAssetUrl] (abi, then renderer variant), so the
  /// size belongs to the same asset that gets downloaded.
  int expectedBytesFor(String abi) {
    final String wanted = abi.trim().toLowerCase();
    final String renderer = state.rendererVariant;

    int untagged = 0;
    int anyPackage = 0;

    for (final ReleaseAssetInfo asset in state.latestAssets) {
      if (!asset.isApk || asset.abi != wanted || asset.sizeBytes <= 0) continue;
      if (asset.renderer == renderer) return asset.sizeBytes;
      if (asset.renderer.isEmpty) untagged = untagged == 0 ? asset.sizeBytes : untagged;
      anyPackage = anyPackage == 0 ? asset.sizeBytes : anyPackage;
    }

    final ReleaseModel? release = _latestRelease;
    if (release != null) {
      for (final ReleaseFileModel file in release.files) {
        final int? parsed = parseSizeText(file.size);
        if (parsed == null || parsed <= 0) continue;
        if (abiForAssetName(file.name) != wanted) continue;
        final String tag = rendererForAssetName(file.name);
        if (tag == renderer) return parsed;
        if (tag.isEmpty) untagged = untagged == 0 ? parsed : untagged;
        anyPackage = anyPackage == 0 ? parsed : anyPackage;
      }
      if (release.files.length == 1) {
        final int? parsed = parseSizeText(release.files.first.size);
        if (anyPackage == 0 && parsed != null && parsed > 0) anyPackage = parsed;
      }
    }

    return untagged != 0 ? untagged : anyPackage;
  }

  /// Converts a releases.json size string such as `12.3 MB` into bytes; null when
  /// unparsable.
  ///
  /// The value is rounded for display (see [assetSizeFor]), so callers must
  /// verify with a tolerance instead of treating it as exact.
  static int? parseSizeText(String text) {
    final match = RegExp(r'([0-9]+(?:\.[0-9]+)?)\s*([kKmMgG]?)[bB]').firstMatch(text.trim());
    if (match == null) return null;
    final double value = double.tryParse(match.group(1)!) ?? -1;
    if (value < 0) return null;
    final double scale = switch (match.group(2)!.toLowerCase()) {
      'k' => 1024,
      'm' => 1024 * 1024,
      'g' => 1024 * 1024 * 1024,
      _ => 1,
    };
    return (value * scale).round();
  }

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
      _patchState(phase: AppUpdatePhase.available, error: i18n('update_error_no_url'));
      return false;
    }

    final fileName = safeDownloadFileName(url);
    final candidates = downloadCandidates(url, preferGivenUrl: preferGivenUrl);

    _cancelToken = CancelToken();
    // The APK download is an interface request like any other: behind a
    // configured interface proxy it has to go through it (the mirrors are
    // often only reachable that way).
    _dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 20), receiveTimeout: const Duration(minutes: 30)))
      ..httpClientAdapter = ApiProxyPolicy.dioAdapter;
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
      // Under the app documents dir on purpose: open_filex refuses to hand a
      // package to the installer without the all-files-access grant unless the
      // file lives under dataDir/getExternalFilesDir, and cache-resident APKs
      // made Android 11+ phones and TVs fail to launch the installer at all.
      final Directory documents = await getApplicationDocumentsDirectory();
      target = Directory('${documents.path}${Platform.pathSeparator}update');
      if (!await target.exists()) await target.create(recursive: true);
    } catch (error) {
      _cancelDownload();
      _patchState(phase: AppUpdatePhase.available, error: i18n('update_error_storage'));
      return false;
    }

    // Expected size from release metadata. The finished download must be checked
    // against it, or a mirror's HTML error page commits as an installer.
    final int expectedBytes = expectedBytesFor(state.selectedAbi);

    Object? lastError;
    for (final candidate in candidates.toSet()) {
      final destination = '${target.path}${Platform.pathSeparator}$fileName';
      try {
        await _downloadCandidate(candidate, destination, expectedBytes: expectedBytes);
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
      // lastError is null when the candidate list was empty; never splice that into
    // the message as a dangling "...: null".
      error: _describeError(lastError, fallback: i18n('download_failed')),
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
  Future<void> _downloadCandidate(String url, String destination, {int expectedBytes = 0}) async {
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
      throw FileSystemException(i18n('update_error_package_missing'));
    }

    // Validate before the commit: a rejected package is deleted here, so the
  // installer never sees a partial file.
    final String? invalid = await _validateStagedPackage(partial, expectedBytes: expectedBytes);
    if (invalid != null) {
      await _deleteIfPresent(partial);
      throw FileSystemException(invalid);
    }

    await _commitStagedFile(partial, completed);
  }

  /// Validates the staged package. Returns null when it passes, otherwise the
  /// message to show the user.
  ///
  /// Three checks, cheapest first:
  /// 1. non-empty;
  /// 2. **ZIP magic** - an APK is a ZIP, so the first two bytes must be `PK`.
  ///    A hijacked mirror's HTML error page starts with `<` and is caught here
  ///    without any metadata;
  /// 3. **size** - when release metadata provides one. GitHub's `size` is exact;
  ///    the releases.json string (`12.3 MB`) is rounded, so the comparison keeps
  ///    a 2% tolerance. Truncated transfers (tens of MB short) still fail.
  Future<String?> _validateStagedPackage(File partial, {required int expectedBytes}) async {
    final int actual = await partial.length();
    if (actual <= 0) return i18n('update_error_package_empty');

    RandomAccessFile? head;
    try {
      head = await partial.open();
      final magic = await head.read(2);
      if (magic.length < 2 || magic[0] != 0x50 || magic[1] != 0x4B) {
        return i18n('update_error_package_invalid');
      }
    } catch (_) {
      return i18n('update_error_package_invalid');
    } finally {
      await head?.close();
    }

    if (expectedBytes > 0) {
      final int tolerance = (expectedBytes * 0.02).round().clamp(0, 4 * 1024 * 1024);
      if ((actual - expectedBytes).abs() > tolerance) {
        return i18n(
          'update_error_package_size',
          args: {'expected': _readableBytes(expectedBytes), 'actual': _readableBytes(actual)},
        );
      }
    }
    return null;
  }

  static String _readableBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Maps any thrown error to a presentable message.
  ///
  /// Interpolating `$error` directly has two traps: a DioException's message can
  /// be null (the UI would render "DioException ...: null"), and the text is
  /// English regardless of the app language. Errors are mapped by type; unknown
  /// ones fall back to the caller's message.
  static String _describeError(Object? error, {required String fallback}) {
    if (error == null) return fallback;
    if (error is FileSystemException) {
      final String text = error.message.trim();
      return text.isEmpty ? fallback : text;
    }
    if (error is DioException) {
      return switch (error.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout => i18n('update_error_timeout'),
        DioExceptionType.badResponse => i18n(
          'update_error_http_status',
          args: {'code': '${error.response?.statusCode ?? 0}'},
        ),
        DioExceptionType.connectionError => i18n('update_error_network'),
        DioExceptionType.cancel => fallback,
        DioExceptionType.badCertificate => i18n('update_error_network'),
        DioExceptionType.transformTimeout => i18n('update_error_timeout'),
        DioExceptionType.unknown => i18n('update_error_network'),
      };
    }
    final String text = error.toString().trim();
    if (text.isEmpty || text == 'null' || text.endsWith(': null')) return fallback;
    return text;
  }

  /// Hands the package the download committed to the platform installer.
  ///
  /// Android TVs need the "install unknown apps" grant for this app first; a
  /// denied grant is reported, not thrown, so the dialog can say so.
  Future<AppInstallResult> installDownloaded() async {
    final String packagePath = state.downloadedPath;
    if (packagePath.isEmpty || !await File(packagePath).exists()) {
      _patchState(error: i18n('update_error_package_missing'));
      return AppInstallResult.missingPackage;
    }

    if (Platform.isAndroid && packagePath.toLowerCase().endsWith('.apk')) {
      try {
        if (await Permission.requestInstallPackages.isDenied) {
          final granted = await Permission.requestInstallPackages.request();
          if (!granted.isGranted) {
            _patchState(error: i18n('update_error_install_permission'));
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
      _patchState(error: i18n('update_error_installer_launch'));
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
