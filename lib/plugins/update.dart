import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

Future<bool> requestStorageInstallPermission() async {
  if (await Permission.requestInstallPackages.isDenied) {
    final status = Permission.requestInstallPackages.request();
    return status.isGranted;
  }
  return true;
}

final List<String> mirrors = [
  'https://gh.llkk.cc/',
  'https://cdn.crashmc.com/',
  'https://wget.la/',
  'https://gh.xxooo.cf/',
  'https://gh-proxy.com/',
  'https://down.npee.cn/?',
  'https://ghproxy.com/',
];

List<String> getMirrorUrls(String apkUrl) {
  final mirrorsUrl = mirrors.map((e) => '$e$apkUrl').toList();
  mirrorsUrl.add(apkUrl);
  return mirrorsUrl;
}

Future<void> downloadAndInstallApk(String apkUrl) async {
  if (Platform.isAndroid) {
    final hasPermission = await requestStorageInstallPermission();
    if (!hasPermission) {
      SmartDialog.showToast('请授予存储权限后再尝试下载安装');
      openAppSettings();
      return;
    }
  }
  final apkName = apkUrl.split('/').last;
  SmartDialog.showLoading(msg: '正在下载 $apkName');
  // 1. 使用镜像
  final url = apkUrl;

  // 2. 获取应用私有目录
  final dir = await getApplicationDocumentsDirectory();

  // 2. 下载到应用私有目录（无需存储权限）
  final file = File('${dir.path}/$apkName');

  final response = await http.get(Uri.parse(url));
  if (response.statusCode == 200) {
    await file.writeAsBytes(response.bodyBytes);
    SmartDialog.dismiss();
    // 3. 调用 open_filex 安装
    try {
      await OpenFilex.open(file.path);
    } catch (e) {
      // 处理错误（如用户禁止安装未知来源）
      debugPrint('安装失败: $e');
    }
  } else {
    SmartDialog.dismiss();
    SmartDialog.showToast('下载失败，请稍后再试');
  }
}
