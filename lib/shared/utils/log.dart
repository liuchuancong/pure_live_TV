import 'dart:io';
import 'dart:async';

import 'package:logger/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:pure_live/app/bootstrap/app_path_manager.dart';
import 'package:pure_live/shared/utils/date_time_utils.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pure_live/services/settings/settings.dart';

/// Application log.
///
/// Two independent sinks are supported: a bounded in-memory buffer that the LAN
/// remote reads, and an optional log file on the device. The file sink is what
/// makes a problem on a release build diagnosable, because a TV has no console
/// and the buffer is empty for users who never opened the remote.
class Log {
  /// Upper bound of the in-memory buffer; the oldest entries are dropped first
  /// so a long-running session cannot grow without limit.
  static const int maxDebugEntries = 2000;

  static final List<DebugLogModel> _allLogs = [];
  static LogFileWriter? _logFileWriter;
  static int _statusGeneration = 0;

  static List<DebugLogModel> get allLogs => List<DebugLogModel>.unmodifiable(_allLogs);

  static bool get fileLoggingEnabled => _logFileWriter != null;

  /// Whether runtime messages should be buffered.
  ///
  /// Debug builds always buffer; a release build buffers only after the user
  /// turns local logging on, so the remote log page stays cheap by default.
  @visibleForTesting
  static bool shouldBufferRuntimeLog({required bool releaseMode, required bool localLoggingEnabled}) {
    return !releaseMode || localLoggingEnabled;
  }

  static bool get _localLoggingEnabled {
    try {
      return SettingsService.to.logState.storedEnableLog;
    } catch (_) {
      return false;
    }
  }

  static void clearAllDebugLogs() => _allLogs.clear();

  static void clearDebugLogs() => clearAllDebugLogs();

  static List<String> get formattedLogs {
    return _allLogs.map((log) {
      final timeStr = DateTimeUtils.timeFormat.format(log.datetime);
      return '[$timeStr] ${log.content}';
    }).toList();
  }

  /// Starts or stops the log file sink.
  ///
  /// Returns whether the requested state is in effect; the caller shows the
  /// failure instead of leaving a switch that claims to be on.
  static Future<bool> setEnabled(bool enabled) async {
    final generation = ++_statusGeneration;
    await _closeActiveResources();
    if (generation != _statusGeneration) return false;
    if (!enabled) return true;

    final writer = LogFileWriter();
    if (!await writer.init()) {
      await writer.close();
      return false;
    }
    if (generation != _statusGeneration) {
      await writer.close();
      return false;
    }
    _logFileWriter = writer;
    await _writeHeaderInfoToMemory();
    return true;
  }

  /// Compatibility wrapper kept for callers that only toggle the log state.
  static Future<void> toggleLogEnable(bool enable) async {
    await setEnabled(enable);
  }

  static Future<void> init() async {
    await setEnabled(_localLoggingEnabled);
  }

  static void dispose() {
    _statusGeneration++;
    final writer = _logFileWriter;
    _logFileWriter = null;
    if (writer != null) unawaited(writer.close());
  }

  static Future<void> _closeActiveResources() async {
    final writer = _logFileWriter;
    _logFileWriter = null;
    if (writer != null) await writer.close();
  }

  static Future<bool> updateLogStatus() => setEnabled(_localLoggingEnabled);

  static void writeLog(Object content, [Level level = Level.info]) {
    final writer = _logFileWriter;
    if (writer == null) return;
    writer.write('[${level.name.toUpperCase()}] ${DateTimeUtils.timeFormat.format(DateTime.now())}: $content');
  }

  static Future<void> _writeHeaderInfoToMemory() async {
    for (final line in await headerLines()) {
      addDebugLog(line, Colors.blue);
    }
  }

  /// Session header shared by the in-memory buffer and the log file.
  static Future<List<String>> headerLines() async {
    final headerLines = <String>[];
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final deviceInfo = DeviceInfoPlugin();

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
    } catch (e, stackTrace) {
      headerLines.add('Log header unavailable: $e\n$stackTrace');
    }
    return headerLines;
  }

  static void addDebugLog(String content, [Color? color]) {
    _allLogs.add(DebugLogModel(DateTime.now(), content, color: color));
    final overflow = _allLogs.length - maxDebugEntries;
    if (overflow > 0) _allLogs.removeRange(0, overflow);
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
    if (shouldBufferRuntimeLog(releaseMode: kReleaseMode, localLoggingEnabled: _localLoggingEnabled)) {
      addDebugLog(message, Colors.orange);
    }
    if (!kReleaseMode) logger.d(message);
    if (fileLoggingEnabled) writeLog(message, Level.debug);
  }

  static void i(String message) {
    if (shouldBufferRuntimeLog(releaseMode: kReleaseMode, localLoggingEnabled: _localLoggingEnabled)) {
      addDebugLog(message, Colors.blue);
    }
    if (!kReleaseMode) logger.i(message);
    if (fileLoggingEnabled) writeLog(message, Level.info);
  }

  static void e(String message, StackTrace stackTrace) {
    if (shouldBufferRuntimeLog(releaseMode: kReleaseMode, localLoggingEnabled: _localLoggingEnabled)) {
      addDebugLog('$message\r\n\r\n$stackTrace', Colors.red);
    }
    if (!kReleaseMode) logger.e(message, stackTrace: stackTrace);
    if (fileLoggingEnabled) writeLog("$message\n$stackTrace", Level.error);
  }

  static void w(String message) {
    if (shouldBufferRuntimeLog(releaseMode: kReleaseMode, localLoggingEnabled: _localLoggingEnabled)) {
      addDebugLog(message, Colors.pink);
    }
    if (!kReleaseMode) logger.w(message);
    if (fileLoggingEnabled) writeLog(message, Level.warning);
  }

  static void logPrint(dynamic obj) {
    final String content = obj.toString();
    if (shouldBufferRuntimeLog(releaseMode: kReleaseMode, localLoggingEnabled: _localLoggingEnabled)) {
      addDebugLog(content, Colors.red);
    }
    if (!kReleaseMode && kDebugMode) debugPrint(content);
    if (fileLoggingEnabled) writeLog(content, Level.info);
  }
}

class _NullOutput extends LogOutput {
  @override
  void output(OutputEvent event) {}
}

/// Appends runtime messages to one timestamped file per session.
class LogFileWriter {
  LogFileWriter() {
    String two(int value) => value.toString().padLeft(2, '0');
    final now = DateTime.now();
    _fileName =
        '${now.year}-${two(now.month)}-${two(now.day)}_${two(now.hour)}-${two(now.minute)}-${two(now.second)}.log';
  }

  late final String _fileName;
  IOSink? _fileWriter;
  bool _isInitialized = false;

  /// Directory the current session writes to, exposed so the settings page can
  /// tell the user where the file is.
  static Directory? lastLogDirectory;

  Future<bool> init() async {
    if (_isInitialized) return true;

    try {
      final logDir = await AppPathManager().logsDir;
      lastLogDirectory = logDir;
      final logFile = File('${logDir.path}${Platform.pathSeparator}$_fileName');
      _fileWriter = logFile.openWrite(mode: FileMode.append);
      _isInitialized = true;
      await _writeSystemInfo();
      return true;
    } catch (e, stackTrace) {
      debugPrint('Init log file failed: $e\n$stackTrace');
      return false;
    }
  }

  void write(String content) {
    if (!_isInitialized) return;
    _fileWriter?.write('$content\r\n');
  }

  Future<void> close() async {
    await _fileWriter?.flush();
    await _fileWriter?.close();
    _fileWriter = null;
    _isInitialized = false;
  }

  Future<void> _writeSystemInfo() async {
    try {
      for (final line in await Log.headerLines()) {
        _fileWriter?.write('$line\r\n');
      }
      await _fileWriter?.flush();
    } catch (e, stackTrace) {
      debugPrint('Write log header failed: $e\n$stackTrace');
    }
  }
}

class DebugLogModel {
  final String content;
  final DateTime datetime;
  final Color? color;
  DebugLogModel(this.datetime, this.content, {this.color});
}
