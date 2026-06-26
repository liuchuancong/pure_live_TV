import 'dart:io';
import 'dart:async';
import 'package:logger/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:pure_live/utils/date_time_utils.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pure_live/services/settings/settings.dart';

class Log {
  static final List<DebugLogModel> _allLogs = [];
  static List<DebugLogModel> get allLogs => _allLogs;
  static bool _logInitFlag = false;

  static void dispose() {
    _logInitFlag = false;
    _allLogs.clear();
  }

  static void clearAllDebugLogs() {
    _allLogs.clear();
  }

  static List<String> get formattedLogs {
    return _allLogs.map((log) {
      final timeStr = DateTimeUtils.timeFormat.format(log.datetime);
      return '[$timeStr] ${log.content}';
    }).toList();
  }

  static Future<void> toggleLogEnable(bool enable) async {
    if (!enable) {
      dispose();
      return;
    }
    if (_logInitFlag) return;
    await _writeHeaderInfoToMemory();
    _logInitFlag = true;
  }

  static Future<void> _writeHeaderInfoToMemory() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final deviceInfo = DeviceInfoPlugin();
      List<String> headerLines = [];

      headerLines.add("=========================================================");
      headerLines.add("  ____  _   _ ____  _____   _     _____     _______ ");
      headerLines.add(" |  _ \\| | | |  _ \\| ____| | |   |_ _\\ \\   / / ____|");
      headerLines.add(" | |_) | | | | |_) |  _|   | |    | | \\ \\ / /|  _|  ");
      headerLines.add(" |  __/| |_| |  _ <| |___  | |___ | |  \\ V / | |___ ");
      headerLines.add(" |_|    \\___/|_| \\_\\_____| |_____|___|  \\_/  |_____|");
      headerLines.add("=========================================================");
      headerLines.add(" 🕒 Current Time : ${DateTime.now()}");
      headerLines.add(" 📱 Platform     : ${Platform.operatingSystem}");
      headerLines.add(" ⚙️ OS Version   : ${Platform.operatingSystemVersion}");
      headerLines.add(" 🌐 Locale       : ${Platform.localeName}");
      headerLines.add(" 📦 App Version  : v${packageInfo.version} (${packageInfo.buildNumber})");

      String model = "Unknown";
      if (Platform.isAndroid) {
        final info = await deviceInfo.androidInfo;
        model = "${info.brand} ${info.model} (API ${info.version.sdkInt})";
      } else if (Platform.isIOS) {
        final info = await deviceInfo.iosInfo;
        model = "${info.name} ${info.systemVersion}";
      } else if (Platform.isLinux) {
        final info = await deviceInfo.linuxInfo;
        model = "${info.name} (${info.versionId})";
      } else if (Platform.isMacOS) {
        final info = await deviceInfo.macOsInfo;
        model = "${info.computerName} (macOS ${info.osRelease})";
      } else if (Platform.isWindows) {
        final info = await deviceInfo.windowsInfo;
        model = "${info.computerName} (Build ${info.buildNumber})";
      }
      headerLines.add(" 💻 Device Model : $model");
      headerLines.add("=========================================================\n");

      for (var line in headerLines) {
        addDebugLog(line, Colors.blue);
      }
    } catch (e, stackTrace) {
      if (!kReleaseMode) {
        addDebugLog('写入日志头部信息失败:$e\r\n$stackTrace', Colors.red);
      }
    }
  }

  static void addDebugLog(String content, [Color? color]) {
    if (kReleaseMode) return;
    if (!SettingsService.to.logState.storedEnableLog) return;

    String processedContent = content;
    if (content.contains("请求响应")) {
      processedContent = content.split("\n").join('\n💡 ');
    }
    _allLogs.add(DebugLogModel(DateTime.now(), processedContent, color: color));
  }

  static final Logger logger = Logger(
    filter: ProductionFilter(),
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.none,
    ),
    output: kReleaseMode ? _NullOutput() : ConsoleOutput(),
  );

  static void d(String message) {
    if (!kReleaseMode) {
      addDebugLog(message, Colors.orange);
      logger.d(message);
    }
  }

  static void i(String message) {
    if (!kReleaseMode) {
      addDebugLog(message, Colors.blue);
      logger.i(message);
    }
  }

  static void e(String message, StackTrace stackTrace) {
    if (!kReleaseMode) {
      addDebugLog('$message\r\n\r\n$stackTrace', Colors.red);
      logger.e(message, stackTrace: stackTrace);
    }
  }

  static void w(String message) {
    if (!kReleaseMode) {
      addDebugLog(message, Colors.pink);
      logger.w(message);
    }
  }

  static void logPrint(dynamic obj) {
    final String content = obj.toString();
    if (!kReleaseMode) {
      addDebugLog(content, Colors.red);
      if (kDebugMode) {
        print(content);
      }
    }
  }
}

class _NullOutput extends LogOutput {
  @override
  void output(OutputEvent event) {}
}

class DebugLogModel {
  final String content;
  final DateTime datetime;
  final Color? color;
  DebugLogModel(this.datetime, this.content, {this.color});
}
