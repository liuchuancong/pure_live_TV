import 'dart:io';
import 'dart:convert';
import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pure_live/core/iptv/src/m3u_item.dart';
import 'package:pure_live/core/iptv/src/m3u_list.dart';

class IptvUtils {
  static const String directoryPath = '/assets/iptv/';
  static const String category = 'category';
  static const String recomand = 'recomand';

  static Future<List<IptvCategory>> readCategory() async {
    try {
      var dir = await getApplicationCacheDirectory();
      final categories = File('${dir.path}${Platform.pathSeparator}categories.json');
      String jsonData = await categories.readAsString();
      List jsonArr = jsonData.isNotEmpty ? jsonDecode(jsonData) : [];
      List<IptvCategory> categoriesArr = jsonArr.map((e) => IptvCategory.fromJson(e)).toList();
      return categoriesArr;
    } catch (e) {
      return [];
    }
  }

  static Future loadNetworkM3u8() async {
    Dio dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      //响应时间为3秒
      receiveTimeout: const Duration(seconds: 10),
    ));
    try {
      var dir = await getApplicationCacheDirectory();
      final m3ufile = File("${dir.path}${Platform.pathSeparator}global.m3u");
      await dio.download('https://live.fanmingming.com/tv/m3u/global.m3u', m3ufile.path);
    } catch (e) {
      log(e.toString());
    }
  }

  static Future<String> loadJsonFromAssets(String assetsPath) async {
    return await rootBundle.loadString(assetsPath);
  }

  static Future<List<M3uItem>> readCategoryItems(filePath) async {
    List<M3uItem> list = [];
    try {
      final m3uList = await M3uList.loadFromFile(filePath);
      for (M3uItem item in m3uList.items) {
        list.add(item);
      }
    } catch (e) {
      log(e.toString());
    }
    return list;
  }

  static Future<List<M3uItem>> readRecommandsItems() async {
    List<M3uItem> list = [];
    try {
      var dir = await getApplicationCacheDirectory();
      final m3ufile = File("${dir.path}${Platform.pathSeparator}hot.m3u");
      if (m3ufile.existsSync()) {
        final m3uList = await M3uList.loadFromFile(m3ufile.path);
        for (M3uItem item in m3uList.items) {
          list.add(item);
        }
      }
    } catch (e) {
      log(e.toString());
    }
    return list;
  }

  static Future<bool> recover(File file) async {
    return true;
  }
}

class IptvCategory {
  String? id;
  String? name;
  String? path;

  IptvCategory({this.id, this.name, this.path});

  factory IptvCategory.fromJson(Map<String, dynamic> json) {
    return IptvCategory(
      name: json['name'],
      id: json['id'],
      path: json['path'],
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'id': id,
        'path': path,
      };
}

class IptvCategoryItem {
  final String id;
  final String name;
  final String liveUrl;

  IptvCategoryItem({required this.id, required this.name, required this.liveUrl});

  factory IptvCategoryItem.fromJson(Map<String, dynamic> json) {
    return IptvCategoryItem(
      name: json['name'],
      id: json['id'],
      liveUrl: json['liveUrl'],
    );
  }
}
