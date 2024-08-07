import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'package:dio/dio.dart' as dio;
import 'package:pure_live/common/index.dart';
import 'package:pure_live/core/iptv/iptv_utils.dart';

class FileRecoverUtils {
  ///获取后缀
  static String getName(String fullName) {
    return fullName.split(Platform.pathSeparator).last;
  }

  ///获取uuid
  static String getUUid() {
    var currentTime = DateTime.now().millisecondsSinceEpoch;
    var randomValue = Random().nextInt(4294967295);
    var result = (currentTime % 10000000000 * 1000 + randomValue) % 4294967295;
    return result.toString();
  }

  ///验证URL
  static bool isUrl(String value) {
    final urlRegExp = RegExp(
        r"((https?:www\.)|(https?:\/\/)|(www\.))[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9]{1,6}(\/[-a-zA-Z0-9()@:%_\+.~#?&\/=]*)?");
    List<String?> urlMatches = urlRegExp.allMatches(value).map((m) => m.group(0)).toList();
    return urlMatches.isNotEmpty;
  }

  ///验证URL
  static bool isHostUrl(String value) {
    final urlRegExp = RegExp(
        r"((https?:www\.)|(https?:\/\/))[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9]{1,6}(\/[-a-zA-Z0-9()@:%_\+.~#?&\/=]*)?");
    List<String?> urlMatches = urlRegExp.allMatches(value).map((m) => m.group(0)).toList();
    return urlMatches.isNotEmpty;
  }

  ///验证URL
  static bool isPort(String value) {
    final portRegExp = RegExp(r"\d+");
    List<String?> portMatches = portRegExp.allMatches(value).map((m) => m.group(0)).toList();
    return portMatches.isNotEmpty;
  }

  Future<bool> recoverNetworkM3u8Backup(String url, String fileName) async {
    var dioInstance = dio.Dio(dio.BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      //响应时间为3秒
      receiveTimeout: const Duration(seconds: 10),
    ));
    var dir = await getApplicationCacheDirectory();
    final m3ufile = File("${dir.path}${Platform.pathSeparator}$fileName.m3u");
    try {
      dio.Response response = await dioInstance.download(url, m3ufile.path);
      if (response.statusCode != 200 && response.statusCode != 304) {
        SmartDialog.showToast("文件下载失败请重试", displayTime: const Duration(seconds: 2));
      }
      List jsonArr = [];
      final categories = File('${dir.path}${Platform.pathSeparator}categories.json');
      if (!categories.existsSync()) {
        categories.createSync();
      }
      String jsonData = await categories.readAsString();
      jsonArr = jsonData.isNotEmpty ? jsonDecode(jsonData) : [];
      List<IptvCategory> categoriesArr = jsonArr.map((e) => IptvCategory.fromJson(e)).toList();
      bool isNotExit = categoriesArr.indexWhere((element) => element.id == url) == -1;
      if (isNotExit) {
        categoriesArr.add(
            IptvCategory(id: url, name: getName(m3ufile.path).replaceAll(RegExp(r'.m3u'), ''), path: m3ufile.path));
      } else {
        var index = categoriesArr.indexWhere((element) => element.id == url);
        categoriesArr[index].name = fileName;
      }

      categories.writeAsStringSync(jsonEncode(categoriesArr.map((e) => e.toJson()).toList()));
      SmartDialog.showToast("恢复备份成功", displayTime: const Duration(seconds: 2));
      return true;
    } catch (e) {
      SmartDialog.showToast("恢复备份失败", displayTime: const Duration(seconds: 2));
      return false;
    }
  }

  Future<bool> recoverM3u8BackupByWeb(String fileString, String fileName) async {
    try {
      var dir = await getApplicationCacheDirectory();
      final m3ufile = File('${dir.path}${Platform.pathSeparator}$fileName');
      m3ufile.writeAsStringSync(fileString);
      List jsonArr = [];
      final categories = File('${dir.path}${Platform.pathSeparator}categories.json');
      if (!categories.existsSync()) {
        categories.createSync();
      }
      String jsonData = await categories.readAsString();
      jsonArr = jsonData.isNotEmpty ? jsonDecode(jsonData) : [];
      List<IptvCategory> categoriesArr = jsonArr.map((e) => IptvCategory.fromJson(e)).toList();
      if (categoriesArr.indexWhere((element) => element.path == m3ufile.path) == -1) {
        categoriesArr.add(IptvCategory(
            id: getUUid(), name: getName(m3ufile.path).replaceAll(RegExp(r'.m3u'), ''), path: m3ufile.path));
      }
      categories.writeAsStringSync(jsonEncode(categoriesArr.map((e) => e.toJson()).toList()));
      SmartDialog.showToast("恢复备份成功", displayTime: const Duration(seconds: 2));
      return true;
    } catch (e) {
      SmartDialog.showToast("恢复备份失败", displayTime: const Duration(seconds: 2));
      return false;
    }
  }
}
