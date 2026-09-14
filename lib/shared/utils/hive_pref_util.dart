import 'dart:convert';
import 'package:hive_ce/hive.dart';

class HivePrefUtil {
  static late Box _box;

  static Future<void> init() async {
    if (!Hive.isBoxOpen('app_settings')) {
      _box = await Hive.openBox('app_settings');
    } else {
      _box = Hive.box('app_settings');
    }
  }

  static dynamic getAnyPref(String key) {
    return _box.get(key);
  }

  static void setObject(String key, dynamic value) {
    _box.put(key, jsonEncode(value));
  }

  static T? getObject<T>(String key, T Function(dynamic) fromJson) {
    final String? jsonString = _box.get(key);
    if (jsonString == null) return null;
    try {
      return fromJson(jsonDecode(jsonString));
    } catch (e) {
      return null;
    }
  }

  static List<T> getObjectList<T>(String key, T Function(Map<String, dynamic>) factory) {
    final rawList = _box.get(key);
    if (rawList is! List) return [];

    return rawList.map<T>((item) {
      if (item is String) {
        return factory(Map<String, dynamic>.from(jsonDecode(item)));
      }
      if (item is Map) {
        return factory(Map<String, dynamic>.from(item));
      }
      return factory({});
    }).toList();
  }

  static Future<void> setObjectList<T>(String key, List<T> list, Map<String, dynamic> Function(T) toJson) async {
    final serializedList = list.map((item) => jsonEncode(toJson(item))).toList();
    await _box.put(key, serializedList);
  }

  static Future<bool> setAnyPref(String key, dynamic value) {
    if (value is String) {
      _box.put(key, value);
    } else if (value is int) {
      _box.put(key, value);
    } else if (value is bool) {
      _box.put(key, value);
    } else if (value is double) {
      _box.put(key, value);
    } else if (value is List<String>) {
      _box.put(key, value);
    } else {
      // 如果传入不支持的类型（如 Map、自定义对象），可选择抛异常或忽略
      throw ArgumentError(
        'Unsupported value type for key "$key": ${value.runtimeType}. '
        'Only String, int, bool, double, and List<String> are supported.',
      );
    }
    return Future.value(true);
  }

  static bool? getBool(String key) {
    final value = _box.get(key);
    return value is bool ? value : null;
  }

  static Future<bool> setBool(String key, bool value) {
    _box.put(key, value);
    return Future.value(true);
  }

  static int? getInt(String key) {
    final value = _box.get(key);
    return value is int ? value : null;
  }

  static Future<bool> setInt(String key, int value) {
    _box.put(key, value);
    return Future.value(true);
  }

  static String? getString(String key) {
    final value = _box.get(key);
    return value is String ? value : null;
  }

  static Future<bool> setString(String key, String value) {
    _box.put(key, value);
    return Future.value(true);
  }

  static double? getDouble(String key) {
    final value = _box.get(key);
    return value is double ? value : null;
  }

  static Future<bool> setDouble(String key, double value) {
    _box.put(key, value);
    return Future.value(true);
  }

  static List<String>? getStringList(String key) {
    final value = _box.get(key);
    return value is List<String> ? value : null;
  }

  static Future<bool> setStringList(String key, List<String> value) {
    _box.put(key, value);
    return Future.value(true);
  }
}
