import 'dart:convert';
import 'dart:typed_data';

import 'package:uuid/uuid.dart';
import 'package:webdav_client/webdav_client.dart' as webdav;

import 'package:pure_live/services/backup/backup_controller.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:pure_live/services/webdav/webdav_config.dart';

/// Thin WebDAV client used for settings backup and restore.
class WebDavSyncService {
  WebDavSyncService({required String url, required String username, required String password})
    : _client = webdav.newClient(url.trim(), user: username, password: password, debug: false);

  final webdav.Client _client;

  webdav.Client get client => _client;

  /// readDir validates the HTTP response and parses the XML. An empty list
  /// means success, not failure.
  Future<List<webdav.File>> readDirectory(String path) => _client.readDir(path);

  Future<List<int>> readFile(String path) => _client.read(path);

  Future<void> writeFile(String path, Uint8List bytes) => _client.write(path, bytes);

  Future<void> removeFile(String path) => _client.remove(path);

  /// Connectivity check: tries to list the root directory.
  Future<bool> testConnection() async {
    try {
      await _client.ping();
      return true;
    } catch (_) {
      return false;
    }
  }

  void close() => _client.c.close(force: true);

  /// Validates a directory-style base URL.
  static bool isValidAddress(String address) {
    final value = address.trim();
    if (value.isEmpty || RegExp(r'[\x00-\x1f\x7f\\]').hasMatch(value)) return false;
    // Uri normalises an empty user-info marker away, so check before parsing.
    if (RegExp(r'^https?://[^/?#]*@', caseSensitive: false).hasMatch(value)) return false;
    try {
      final uri = Uri.tryParse(value);
      if (uri == null ||
          (uri.scheme != 'http' && uri.scheme != 'https') ||
          !uri.hasAuthority ||
          uri.host.isEmpty ||
          uri.authority.contains('@') ||
          uri.hasQuery ||
          uri.hasFragment) {
        return false;
      }
      final host = Uri.decodeComponent(uri.host);
      return !RegExp(r'[\s/\\?#@]').hasMatch(host) && uri.port > 0 && uri.port <= 65535;
    } on FormatException {
      return false;
    }
  }
}

/// Upload, download and delete flows for WebDAV backups, including file
/// naming rules, encoding and the restore sequence.
class WebDavBackupService {
  WebDavBackupService({this.now});

  final DateTime Function()? now;

  BackupController get _backup => SettingsService.to.container!.read(backupControllerProvider.notifier);

  static String buildBackupFileName([DateTime? time]) {
    final t = time ?? DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    final dateStr = '${t.year}-${two(t.month)}-${two(t.day)}T${two(t.hour)}_${two(t.minute)}_${two(t.second)}';
    // A bare timestamp can collide within the same second, so a uuid is appended.
    return 'purelive_${dateStr}_${const Uuid().v4()}.txt';
  }

  /// Uploads every current setting as a backup and returns the remote path.
  Future<String> uploadBackup(
    WebDAVConfig config, {
    String dirPath = '/',
    String? fileName,
  }) async {
    final path = dirPath.endsWith('/') ? dirPath : '$dirPath/';
    final remotePath = '$path${fileName ?? buildBackupFileName(now?.call())}';
    final bytes = utf8.encode(jsonEncode(_backup.exportAllSettings()));
    final service = WebDavSyncService(
      url: config.address,
      username: config.username,
      password: config.password,
    );
    try {
      await service.writeFile(remotePath, bytes);
    } finally {
      service.close();
    }
    return remotePath;
  }

  /// Downloads a remote backup and restores every setting from it.
  Future<void> downloadAndRestore(WebDAVConfig config, String remotePath) async {
    final service = WebDavSyncService(
      url: config.address,
      username: config.username,
      password: config.password,
    );
    try {
      final bytes = await service.readFile(remotePath);
      final data = jsonDecode(utf8.decode(bytes));
      if (data is! Map<String, dynamic>) {
        throw const FormatException('Invalid WebDAV backup payload');
      }
      await _backup.restoreAllSettings(data);
    } finally {
      service.close();
    }
  }

  /// Deletes a remote backup file.
  Future<void> deleteRemoteFile(WebDAVConfig config, String remotePath) async {
    final service = WebDavSyncService(
      url: config.address,
      username: config.username,
      password: config.password,
    );
    try {
      await service.removeFile(remotePath);
    } finally {
      service.close();
    }
  }

  /// Lists the backup files in the remote directory (.txt only).
  Future<List<webdav.File>> listBackups(WebDAVConfig config, {String dirPath = '/'}) async {
    final service = WebDavSyncService(
      url: config.address,
      username: config.username,
      password: config.password,
    );
    try {
      final files = await service.readDirectory(dirPath);
      return files.where((f) => (f.name ?? '').toLowerCase().endsWith('.txt')).toList();
    } finally {
      service.close();
    }
  }

  /// Connectivity check.
  static Future<bool> testConnection(WebDAVConfig config) {
    final service = WebDavSyncService(
      url: config.address,
      username: config.username,
      password: config.password,
    );
    return service.testConnection().whenComplete(service.close);
  }
}
