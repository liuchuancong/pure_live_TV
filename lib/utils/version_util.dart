import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pure_live/plugins/race_http.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:pure_live/utils/githup_mirror.dart';
import 'package:pure_live/utils/platform_utils.dart';

/// 版本与更新检查（同步自 pure_live 的 VersionUtil，GetX Rx 改为普通字段/回调，
/// 仓库指向 pure_live_TV 的发布渠道）。
class VersionUtil {
  static PackageInfo? _packageInfo;

  /// TV 版发布仓库
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

  /// 是否有新版本；Riverpod 层可 watch 该字段或接收 onChanged 回调
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
      debugPrint('🏁 更新线路成功');
      return true;
    } catch (e) {
      debugPrint('⚠️ 更新检查失败: $e');
      _resetAfterFailedCheck();
      return false;
    }
  }

  static void _applyVersionData(Map<String, dynamic> data) {
    final selected = selectPlatformVersionData(data, platform: _currentPlatformKey);
    final parsedVersion = selected['version']?.toString().trim() ?? '';
    final parsedBuildNumber = _versionInt(selected['build_number']);
    if (parsedVersion.isEmpty || parsedBuildNumber == null || parsedBuildNumber <= 0) {
      throw const FormatException('Incomplete release identity');
    }
    latestVersion = parsedVersion;
    latestVersionNum = _versionInt(selected['version_num']) ?? 0;
    latestBuildNumber = parsedBuildNumber;
    latestUpdateLog = selected['version_desc']?.toString() ?? '';
    prerelease = selected['prerelease'] == true;
    downloadUrl = selected['download_url']?.toString() ?? '';
    latestAndroidAbis = selectAndroidAbis(selected);
    latestWindowsMsixAvailable = selected['windows_msix_available'] == true;
  }

  /// 只宣传发布源声明已发布的 APK 变体；旧发布源默认 arm64
  static Set<String> selectAndroidAbis(Map<String, dynamic> data) {
    final raw = data['android_abis'];
    if (raw is! List) return const {'arm64-v8a'};
    return raw.map((item) => item.toString()).where(_supportAndroidAbis.contains).toSet();
  }

  static const Set<String> _supportAndroidAbis = {'arm64-v8a', 'armeabi-v7a', 'x86_64'};

  /// 按平台字段合并发布信息，兼容旧发布源的顶层字段
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
