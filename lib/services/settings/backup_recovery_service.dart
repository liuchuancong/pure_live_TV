import 'dart:convert';
import 'dart:io';

import 'package:pure_live/shared/common/http_client.dart';
import 'package:pure_live/services/backup/backup_controller.dart';
import 'package:pure_live/services/settings/settings.dart';

/// Writes local backup files and pushes them to a LAN peer.
///
/// Pickers and other UI stay in the pages; this service keeps the business logic only.
class BackupRecoveryService {
  BackupRecoveryService();

  BackupController get _backup => SettingsService.to.container!.read(backupControllerProvider.notifier);

  /// Writes every setting to the given backup file. Naming it by date is the
  /// caller's responsibility.
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

  /// Restores every setting from a local file.
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

  /// Pushes the flat settings document to a LAN HTTP endpoint.
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
