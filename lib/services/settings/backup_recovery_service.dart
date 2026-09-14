import 'dart:convert';
import 'dart:io';

import 'package:pure_live/core/common/http_client.dart';
import 'package:pure_live/services/back_up/backup_controller.dart';
import 'package:pure_live/services/settings/settings.dart';

/// 同步自 pure_live BackupRecoveryService（插件层）：
/// 本地备份文件写入与局域网推送。文件选择器 UI 由 TV 端页面自行实现，
/// 这里仅保留纯业务能力。
class BackupRecoveryService {
  BackupRecoveryService();

  BackupController get _backup => SettingsService.to.container!.read(backupControllerProvider.notifier);

  /// 把全部设置写入指定备份文件（日期命名由调用方负责）。
  Future<File?> createAppSettingsBackup(String backupDirectory, {DateTime? now}) async {
    final dateStr = _formatBackupTimestamp(now ?? DateTime.now());
    final file = File('$backupDirectory/purelive_$dateStr.txt');
    if (_backup.backup(file)) {
      if (_backup.backupDirectory.isEmpty) {
        await _backup.setBackupDirectory(backupDirectory);
      }
      return file;
    }
    return null;
  }

  /// 从本地文件恢复全部设置。
  Future<bool> recoverSettingsFromFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return false;
    return _backup.recover(file);
  }

  Future<String?> updateBackupDirectory(String? selectedDirectory) async {
    if (selectedDirectory == null) return null;
    await _backup.setBackupDirectory(selectedDirectory);
    return selectedDirectory;
  }

  /// 同步自 pure_live：把扁平 TV 设置推送到局域网 HTTP 服务。
  Future<bool> pushSettingsToRemoteServer(String httpAddress) async {
    try {
      final response = await HttpClient.instance.postJson(
        '$httpAddress/api/setSettings',
        queryParameters: {"settings": jsonEncode(_backup.exportToTVSettings())},
      );
      return jsonDecode(response)['data'] ?? false;
    } catch (_) {
      return false;
    }
  }

  static String _formatBackupTimestamp(DateTime time) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${time.year}-${two(time.month)}-${two(time.day)}T'
        '${two(time.hour)}_${two(time.minute)}_${two(time.second)}';
  }
}
