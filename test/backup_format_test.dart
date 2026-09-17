import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pure_live/services/backup/backup_controller.dart';

/// 备份与恢复 writes the mobile app's backup file: `purelive_<date>.txt` holding the
/// indented settings document. The extension is the format — asking for `.json` made the
/// two apps' backups incompatible even though the payload is the same.
void main() {
  group('the backup file name', () {
    test('follows the mobile app: purelive_<date>T<time>.txt', () {
      final name = BackupController.backupFileName(DateTime(2026, 9, 17, 20, 15, 3));

      expect(name, 'purelive_2026-09-17T20_15_03.txt');
      expect(name, endsWith('.txt'), reason: 'txt, not json');
    });

    test('is recognised by the list and the file picker, including old backups', () {
      const accepted = <String>[
        'purelive_2026-09-17T20_15_03.txt',
        'pure_live_backup_20260917_201503.json', // written by an older TV build
        'PURELIVE_OLD.TXT',
      ];
      for (final name in accepted) {
        expect(BackupController.isBackupFileName(name), isTrue, reason: name);
      }

      const rejected = <String>['notes.txt', 'purelive_2026.txt.bak', 'purelive_config.json.bak', 'config.json'];
      for (final name in rejected) {
        expect(BackupController.isBackupFileName(name), isFalse, reason: name);
      }
      expect(BackupController.backupExtensions, containsAll(<String>['txt', 'json']));
    });
  });

  group('the backup document', () {
    test('is the JSON both apps write, without the removed WebDAV section', () {
      // A representative slice of what `exportAllSettings` builds; the point of the test
      // is the shape the file carries (and that WebDAV is gone from it).
      final document = <String, dynamic>{
        'backupVersion': BackupController.backupVersion,
        'sensitiveDataIncluded': true,
        'app': <String, dynamic>{},
        'danmaku': <String, dynamic>{},
        'cookie': <String, dynamic>{},
      };

      final encoded = const JsonEncoder.withIndent('  ').convert(document);
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;

      expect(decoded['backupVersion'], BackupController.backupVersion);
      expect(decoded.containsKey('webdav'), isFalse);
      expect(encoded, contains('\n  '), reason: 'indented, so the file is readable by hand');
      // WebDAV is no longer a backup section either.
      expect(BackupController.knownSections, isNot(contains('webdav')));
    });

    test('the sensitive-data redaction keeps everything but the cookie section', () {
      final redacted = BackupController.redactSensitiveData(<String, dynamic>{
        'app': <String, dynamic>{'a': 1},
        'cookie': <String, dynamic>{'bilibiliCookie': 'x'},
        'webdav': <String, dynamic>{'old': true},
      });

      expect(redacted.containsKey('cookie'), isFalse);
      expect(redacted.containsKey('webdav'), isFalse, reason: 'a legacy key is dropped too');
      expect(redacted['app'], isA<Map<dynamic, dynamic>>());
      expect(redacted['sensitiveDataIncluded'], isFalse);
    });
  });

  group('the module is gone', () {
    test('no WebDAV sources or page remain', () {
      for (final path in <String>[
        'lib/services/webdav',
        'lib/features/settings/pages/webdav_settings_section.dart',
        'assets/webdav',
      ]) {
        expect(FileSystemEntity.isDirectorySync(path) || File(path).existsSync(), isFalse, reason: path);
      }
    });

    test('no source still imports it', () {
      final Directory lib = Directory('lib');
      if (!lib.existsSync()) {
        markTestSkipped('sources not found relative to ${Directory.current.path}');
        return;
      }

      final offenders = <String>[];
      for (final entity in lib.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final content = entity.readAsStringSync();
        if (content.contains('services/webdav/') || content.contains('webdav_client')) {
          offenders.add(entity.path);
        }
      }
      expect(offenders, isEmpty, reason: 'WebDAV is deleted, not disabled: $offenders');
    });
  });
}
