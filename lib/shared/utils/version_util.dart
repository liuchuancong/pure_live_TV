import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pure_live/shared/platform/race_http.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:pure_live/shared/utils/githup_mirror.dart';
import 'package:pure_live/shared/utils/platform_utils.dart';

/// Download URLs assembled from the release identity itself, following the
/// names the Android release workflow uploads:
/// `{projectUrl}/releases/download/v{version}/PureLive-TV-{abi}-{renderer}.apk`.
///
/// The last resort of the update flow: the release's real asset list and the
/// releases.json file list are tried first, and this fills in when a release
/// was published with the standard names but no matching entry was read — the
/// state an up-to-date device is in, where nothing an update check returned
/// carries a file list.
class ReleaseAssetUrls {
  const ReleaseAssetUrls({required this.projectUrl, required this.version});

  final String projectUrl;
  final String version;

  String get normalizedVersion {
    final value = version.trim();
    return value.startsWith('v') || value.startsWith('V') ? value.substring(1) : value;
  }

  bool get isValid {
    final uri = Uri.tryParse(projectUrl.trim());
    final safeVersion =
        RegExp(r'^[0-9A-Za-z][0-9A-Za-z._-]*$').hasMatch(normalizedVersion) && !normalizedVersion.contains('..');
    return uri != null &&
        uri.scheme == 'https' &&
        uri.hasAuthority &&
        !uri.hasQuery &&
        !uri.hasFragment &&
        uri.userInfo.isEmpty &&
        safeVersion;
  }

  String get releaseBase {
    if (!isValid) return '';
    final normalizedProject = projectUrl.trim().replaceFirst(RegExp(r'/+$'), '');
    return '$normalizedProject/releases/download/v$normalizedVersion';
  }

  /// The package for one ABI, e.g. `PureLive-TV-arm64-v8a-skia.apk`. Releases
  /// from before the dual-variant split carry no renderer in the name.
  String apkForAbi(String abi, {String renderer = ''}) {
    if (!isValid) return '';
    final String name = abi.trim().toLowerCase();
    if (name.isEmpty) return '';
    final String tag = renderer.trim().toLowerCase();
    return '$releaseBase/PureLive-TV-$name${tag.isEmpty ? '' : '-$tag'}.apk';
  }
}

/// Version info and update checks.
///
/// State is exposed as plain fields and callbacks, and releases are read from
/// this app repository.
class VersionUtil {
  static PackageInfo? _packageInfo;

  /// Release repository for the TV build.
  static const String updateOwner = 'liuchuancong';
  static const String updateRepository = 'pure_live_TV';
  static final String projectUrl = 'https://github.com/$updateOwner/$updateRepository';
  static final String issuesUrl = '$projectUrl/issues';
  static const String githubUrl = 'https://github.com/liuchuancong';

  static const String email = '17792321552@163.com';
  static const String emailUrl = 'mailto:17792321552@163.com?subject=PureLiveTV Feedback';

  static final String releaseUrl = 'https://api.github.com/repos/$updateOwner/$updateRepository/releases?per_page=30';

  static final GitHubMirror mirror = GitHubMirror(owner: updateOwner, repo: updateRepository, branch: 'master');

  static List<String> get _versionUrls => SettingsService.to.appState.useGitHubOriginForUpdates
      ? [mirror.rawUrl('assets/version.json')]
      : mirror.mirrors('assets/version.json');

  /// Whether a newer version exists. The Riverpod layer can watch this field or
  /// subscribe to onHasNewVersionChanged.
  static bool isHasNewVersion = false;
  static void Function(bool)? onHasNewVersionChanged;

  static String latestVersion = '';
  static int? latestBuildNumber;
  static int latestVersionNum = 0;
  static String latestUpdateLog = '';
  static bool prerelease = false;
  static String downloadUrl = '';
  static Set<String> latestAndroidAbis = const {'arm64-v8a'};
  static bool latestWindowsMsixAvailable = false;

  static Map<String, dynamic>? _cachedVersionJson;

  static Future<void> initPackageInfo() async {
    _packageInfo = await PackageInfo.fromPlatform();
  }

  static String get version {
    if (_packageInfo == null) return '0.0.0';
    return _packageInfo!.version;
  }

  static int get buildNumber {
    if (_packageInfo == null) return 0;
    return int.tryParse(_packageInfo!.buildNumber) ?? 0;
  }

  static void _setHasNewVersion(bool value) {
    if (isHasNewVersion == value) return;
    isHasNewVersion = value;
    onHasNewVersionChanged?.call(value);
  }

  Future<bool> checkUpdate() async {
    if (_cachedVersionJson != null) {
      try {
        _applyVersionData(_cachedVersionJson!);
        _setHasNewVersion(hasNewVersion());
        return true;
      } catch (_) {
        _cachedVersionJson = null;
        _resetAfterFailedCheck();
        return false;
      }
    }

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final urls = _versionUrls.map((e) => '$e?ts=$timestamp').toList();

      final data = await RaceHttp.fetchJson(
        urls,
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (data == null) {
        _resetAfterFailedCheck();
        return false;
      }

      _applyVersionData(data);
      _cachedVersionJson = data;
      _setHasNewVersion(hasNewVersion());
      debugPrint('🏁 Update mirror resolved');
      return true;
    } catch (e) {
      debugPrint('⚠️ Update check failed: $e');
      _resetAfterFailedCheck();
      return false;
    }
  }

  static void _applyVersionData(Map<String, dynamic> data) {
    final selected = selectPlatformVersionData(data, platform: _currentPlatformKey);
    final parsedVersion = selected['version']?.toString().trim() ?? '';
    if (parsedVersion.isEmpty) {
      throw const FormatException('Incomplete release identity');
    }
    // `build_number` is optional in the release manifest: the file published on
    // master carries `version_num` (and sometimes only the version string), and
    // insisting on the field made every check fail with "Incomplete release
    // identity" — so an up-to-date device reported a failed update check.
    final parsedBuildNumber =
        _versionInt(selected['build_number']) ??
        _versionInt(selected['version_num']) ??
        _versionInt(_flattenedVersion(parsedVersion)) ??
        0;
    latestVersion = parsedVersion;
    latestVersionNum = _versionInt(selected['version_num']) ?? 0;
    latestBuildNumber = parsedBuildNumber;
    latestUpdateLog = selected['version_desc']?.toString() ?? '';
    prerelease = selected['prerelease'] == true;
    downloadUrl = selected['download_url']?.toString() ?? '';
    latestAndroidAbis = selectAndroidAbis(selected);
    latestWindowsMsixAvailable = selected['windows_msix_available'] == true;
  }

  /// `2.0.20` → `12020`, the flattened scheme the manifest uses for
  /// `version_num`, so a manifest without a build number still yields one.
  static String? _flattenedVersion(String version) {
    final clean = version.split(RegExp(r'[-+]'))[0].replaceFirst(RegExp('^[vV]'), '').trim();
    final parts = clean.split('.');
    if (parts.isEmpty || int.tryParse(parts[0]) == null) return null;
    final int major = int.parse(parts[0]);
    final int minor = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    final int patch = parts.length > 2 ? int.tryParse(parts[2]) ?? 0 : 0;
    return '${major * 10000 + minor * 100 + patch}';
  }

  /// Only advertises APK variants the release source declares as published;
  /// older sources default to arm64.
  static Set<String> selectAndroidAbis(Map<String, dynamic> data) {
    final raw = data['android_abis'];
    if (raw is! List) return const {'arm64-v8a'};
    return raw.map((item) => item.toString()).where(_supportAndroidAbis.contains).toSet();
  }

  static const Set<String> _supportAndroidAbis = {'arm64-v8a', 'armeabi-v7a', 'x86_64'};

  /// Merges release info per platform field, still accepting the top-level fields
  /// used by older release sources.
  static Map<String, dynamic> selectPlatformVersionData(Map<String, dynamic> data, {required String platform}) {
    final platforms = data['platforms'];
    final platformData = platforms is Map ? platforms[platform] : null;
    if (platformData is! Map) return data;
    return {...data, ...Map<String, dynamic>.from(platformData)};
  }

  static String get _currentPlatformKey {
    if (PlatformUtils.isWindows) return 'windows';
    if (PlatformUtils.isAndroid) return 'android';
    if (PlatformUtils.isMacOS) return 'macos';
    if (PlatformUtils.isIOS) return 'ios';
    if (PlatformUtils.isLinux) return 'linux';
    return 'default';
  }

  static bool hasNewVersion() {
    return isNewerVersion(latestVersion, version);
  }

  static bool isNewerVersion(String latest, String current) {
    try {
      final latestClean = latest.split(RegExp(r'[-+]'))[0].replaceFirst(RegExp('^[vV]'), '').trim();
      final currentClean = current.split(RegExp(r'[-+]'))[0].replaceFirst(RegExp('^[vV]'), '').trim();

      final latestParts = latestClean.split('.').map(int.parse).toList();
      final currentParts = currentClean.split('.').map(int.parse).toList();

      final maxLength = latestParts.length > currentParts.length ? latestParts.length : currentParts.length;

      while (latestParts.length < maxLength) {
        latestParts.add(0);
      }
      while (currentParts.length < maxLength) {
        currentParts.add(0);
      }

      for (int i = 0; i < maxLength; i++) {
        if (latestParts[i] > currentParts[i]) return true;
        if (latestParts[i] < currentParts[i]) return false;
      }
    } catch (_) {}
    return false;
  }

  static int? _versionInt(Object? value) {
    return switch (value) {
      int number => number,
      num number => number.toInt(),
      String text => int.tryParse(text.trim()),
      _ => null,
    };
  }

  void _resetAfterFailedCheck() {
    latestVersion = version;
    latestBuildNumber = buildNumber > 0 ? buildNumber : null;
    latestVersionNum = 0;
    latestUpdateLog = '';
    prerelease = false;
    downloadUrl = '';
    latestAndroidAbis = const {};
    latestWindowsMsixAvailable = false;
    _setHasNewVersion(false);
  }
}
