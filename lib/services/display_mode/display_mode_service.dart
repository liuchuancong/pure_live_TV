import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pure_live/services/settings/settings.dart';

/// 同步自 pure_live DisplayModeInfo：Android TV 刷新率信息快照。
@immutable
class DisplayModeInfo {
  const DisplayModeInfo({
    required this.enabled,
    required this.currentRefreshRate,
    required this.maxRefreshRate,
    required this.preferredRefreshRate,
    required this.supportedRefreshRates,
    this.requestedRefreshRate,
    this.displayId,
    this.width,
    this.height,
  });

  final bool enabled;
  final double currentRefreshRate;
  final double maxRefreshRate;
  final double preferredRefreshRate;
  final List<double> supportedRefreshRates;
  final double? requestedRefreshRate;
  final int? displayId;
  final int? width;
  final int? height;

  factory DisplayModeInfo.fromMap(Map<dynamic, dynamic> map) {
    double number(String key, [double fallback = 0]) {
      final value = map[key];
      return value is num ? value.toDouble() : fallback;
    }

    final rates = (map['supportedRefreshRates'] as List<dynamic>? ?? const [])
        .whereType<num>()
        .map((value) => value.toDouble())
        .toList(growable: false);

    return DisplayModeInfo(
      enabled: map['enabled'] == true,
      currentRefreshRate: number('currentRefreshRate'),
      maxRefreshRate: number('maxRefreshRate'),
      preferredRefreshRate: number('preferredRefreshRate'),
      supportedRefreshRates: rates,
      requestedRefreshRate: map['requestedRefreshRate'] is num ? number('requestedRefreshRate') : null,
      displayId: (map['displayId'] as num?)?.toInt(),
      width: (map['width'] as num?)?.toInt(),
      height: (map['height'] as num?)?.toInt(),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DisplayModeInfo &&
        other.enabled == enabled &&
        other.currentRefreshRate == currentRefreshRate &&
        other.maxRefreshRate == maxRefreshRate &&
        other.preferredRefreshRate == preferredRefreshRate &&
        other.requestedRefreshRate == requestedRefreshRate &&
        other.displayId == displayId &&
        other.width == width &&
        other.height == height &&
        listEquals(other.supportedRefreshRates, supportedRefreshRates);
  }

  @override
  int get hashCode => Object.hash(
    enabled,
    currentRefreshRate,
    maxRefreshRate,
    preferredRefreshRate,
    requestedRefreshRate,
    displayId,
    width,
    height,
    Object.hashAll(supportedRefreshRates),
  );
}

/// 同步自 pure_live DisplayModeService：
/// 通过原生 MethodChannel（pure_live/display_mode）切换 Android TV 刷新率。
/// TV 端未引入 flutter_displaymode 包，因此保留 MethodChannel 方案，
/// MissingPluginException 时安全降级为无操作。
class DisplayModeService {
  DisplayModeService._();

  static const MethodChannel _channel = MethodChannel('pure_live/display_mode');
  static final ValueNotifier<DisplayModeInfo?> info = ValueNotifier<DisplayModeInfo?>(null);
  static bool _handlerInstalled = false;

  static void _ensureHandler() {
    if (_handlerInstalled) return;
    _handlerInstalled = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method != 'displayModeChanged' || call.arguments is! Map) return;
      _publish(DisplayModeInfo.fromMap(Map<dynamic, dynamic>.from(call.arguments as Map)));
    });
  }

  static void _publish(DisplayModeInfo next) {
    if (info.value == next) return;
    info.value = next;
  }

  /// 切换高刷新率模式；平台侧未实现时返回 null。
  static Future<DisplayModeInfo?> setHighRefreshRate(bool enabled) async {
    _ensureHandler();
    try {
      final result = await _channel.invokeMapMethod<dynamic, dynamic>('setHighRefreshRate', {'enabled': enabled});
      if (result == null) return null;
      final parsed = DisplayModeInfo.fromMap(result);
      _publish(parsed);
      return parsed;
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  static Future<DisplayModeInfo?> refreshInfo() async {
    _ensureHandler();
    try {
      final result = await _channel.invokeMapMethod<dynamic, dynamic>('getDisplayModeInfo');
      if (result == null) return null;
      final parsed = DisplayModeInfo.fromMap(result);
      _publish(parsed);
      return parsed;
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  /// 按应用设置（AppSettingsModel.refreshRateMode）应用刷新率模式。
  /// 支持：''（不动）、'auto'（系统默认）、'high'（最高刷新率）。
  static Future<void> applyRefreshRateMode([String? mode]) async {
    final refreshRateMode = mode ?? SettingsService.to.appState.refreshRateMode;
    switch (refreshRateMode.trim().toLowerCase()) {
      case 'high':
        await setHighRefreshRate(true);
        break;
      case 'auto':
      case '':
        break;
      default:
        break;
    }
  }
}
