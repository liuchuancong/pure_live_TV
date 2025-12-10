import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class VersionUtil {
  static const String version = '2.0.5';
  static const String projectUrl = 'https://github.com/liuchuancong/pure_live_TV';
  static const String releaseUrl = 'https://api.github.com/repos/liuchuancong/pure_live_TV/releases';
  static const String issuesUrl = 'https://github.com/liuchuancong/pure_live_TV/issues';
  static const String githubUrl = 'https://github.com/liuchuancong';
  static const String email = '17792321552@163.com';
  static const String emailUrl = 'mailto:17792321552@163.com?subject=PureLive Feedback';
  static const String telegramGroup = 't.me/pure_live_channel';
  static const String telegramGroupUrl = 'https://t.me/pure_live_channel';

  static String latestVersion = version;
  static String latestUpdateLog = '';
  static List allReleased = [];

  final isHasNewVersion = false.obs;
  Future<void> checkUpdate() async {
    try {
      var response = await http.get(Uri.parse(releaseUrl));
      allReleased = await jsonDecode(response.body);
      var latest = allReleased[0];
      latestVersion = latest['tag_name'].replaceAll('v', '');
      latestUpdateLog = latest['body'];
      isHasNewVersion.value = hasNewVersion();
    } catch (e) {
      latestUpdateLog = e.toString();
      isHasNewVersion.value = false;
    }
  }

  static bool hasNewVersion() {
    List latestVersions = latestVersion.split('-')[0].split('.');
    List versions = version.split('-')[0].split('.');
    for (int i = 0; i < latestVersions.length; i++) {
      if (int.parse(latestVersions[i]) > int.parse(versions[i])) {
        return true;
      } else if (int.parse(latestVersions[i]) < int.parse(versions[i])) {
        return false;
      }
    }
    return false;
  }
}
