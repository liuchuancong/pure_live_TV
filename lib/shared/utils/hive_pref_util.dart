import 'dart:convert';
import 'package:hive_ce/hive.dart';

class HivePrefUtil {
  static late Box _box;

  static bool _initialized = false;

  /// Whether [init] has opened the box.
  ///
  /// Preference *reads* outside the app's bootstrap (a widget test, or a widget
  /// built before the store is up) fall back to their defaults instead of
  /// throwing `LateInitializationError` on `_box`.
  static bool get isInitialized => _initialized;

  /// The store when it is up, `null` before bootstrap.
  ///
  /// Every read goes through this instead of touching [_box] directly: the
  /// contract documented on [isInitialized] is that a read outside bootstrap
  /// returns its default, but reading `_box` threw `LateInitializationError`
  /// instead. That surfaced as a provider stuck in error state the moment a page
  /// watched one (the settings catalog and its update badge, for example).
  static Box? get _readable => _initialized ? _box : null;

  static Future<void> init() async {
    if (!Hive.isBoxOpen('app_settings')) {
      _box = await Hive.openBox('app_settings');
    } else {
      _box = Hive.box('app_settings');
    }
    _initialized = true;
  }

  static dynamic getAnyPref(String key) {
    return _readable?.get(key);
  }

  static void setObject(String key, dynamic value) {
    _box.put(key, jsonEncode(value));
  }

  static T? getObject<T>(String key, T Function(dynamic) fromJson) {
    final String? jsonString = _readable?.get(key);
    if (jsonString == null) return null;
    try {
      return fromJson(jsonDecode(jsonString));
    } catch (e) {
      return null;
    }
  }

  static List<T> getObjectList<T>(String key, T Function(Map<String, dynamic>) factory) {
    final rawList = _readable?.get(key);
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
      // Unsupported value types such as Map or a custom object are rejected here.
      throw ArgumentError(
        'Unsupported value type for key "$key": ${value.runtimeType}. '
        'Only String, int, bool, double, and List<String> are supported.',
      );
    }
    return Future.value(true);
  }

  static bool? getBool(String key) {
    final value = _readable?.get(key);
    return value is bool ? value : null;
  }

  static Future<bool> setBool(String key, bool value) {
    _box.put(key, value);
    return Future.value(true);
  }

  static int? getInt(String key) {
    final value = _readable?.get(key);
    return value is int ? value : null;
  }

  static Future<bool> setInt(String key, int value) {
    _box.put(key, value);
    return Future.value(true);
  }

  static String? getString(String key) {
    final value = _readable?.get(key);
    return value is String ? value : null;
  }

  static Future<bool> setString(String key, String value) {
    _box.put(key, value);
    return Future.value(true);
  }

  static double? getDouble(String key) {
    final value = _readable?.get(key);
    return value is double ? value : null;
  }

  static Future<bool> setDouble(String key, double value) {
    _box.put(key, value);
    return Future.value(true);
  }

  static List<String>? getStringList(String key) {
    final value = _readable?.get(key);
    return value is List<String> ? value : null;
  }

  static Future<bool> setStringList(String key, List<String> value) {
    _box.put(key, value);
    return Future.value(true);
  }
}
