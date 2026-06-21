import 'dart:convert';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:pure_live/get/get.dart';
import 'package:pure_live/common/services/settings_service.dart';
import 'package:pure_live/common/utils/hive_pref_util.dart';

SettingsService _createService() {
  final svc = SettingsService();
  Get.put<SettingsService>(svc, permanent: false);
  return svc;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUp(() async {
    Get.reset();
    tempDir = await Directory.systemTemp.createTemp('wallpaper_test_');
    Hive.init(tempDir.path);
    await HivePrefUtil.init();
  });

  tearDown(() async {
    try { Get.find<SettingsService>().onClose(); } catch (_) {}
    Get.reset();
    await Future.delayed(const Duration(milliseconds: 100));
    await Hive.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  group('cachedBackgroundFileImage', () {
    test('returns null when currentBoxImage is empty', () {
      final service = _createService();
      service.currentBoxImage.value = '';
      expect(service.cachedBackgroundFileImage, isNull);
    });

    test('returns null when path looks like base64 (not yet migrated)', () {
      final service = _createService();
      service.currentBoxImage.value = 'a' * 600;
      expect(service.cachedBackgroundFileImage, isNull);
    });

    test('returns null when file does not exist', () {
      final service = _createService();
      service.currentBoxImage.value = '/nonexistent/path/bg.jpg';
      expect(service.cachedBackgroundFileImage, isNull);
    });

    test('returns FileImage when file exists', () async {
      final service = _createService();
      final file = File('${tempDir.path}/bg.jpg');
      await file.writeAsBytes([0xFF, 0xD8, 0xFF, 0xE0]);
      service.currentBoxImage.value = file.path;
      final result = service.cachedBackgroundFileImage;
      expect(result, isNotNull);
      expect(result, isA<FileImage>());
    });

    test('caches FileImage for same path', () async {
      final service = _createService();
      final file = File('${tempDir.path}/bg.jpg');
      await file.writeAsBytes([0xFF, 0xD8, 0xFF, 0xE0]);
      service.currentBoxImage.value = file.path;
      final first = service.cachedBackgroundFileImage;
      final second = service.cachedBackgroundFileImage;
      expect(identical(first, second), isTrue);
    });

    test('returns new FileImage when path changes', () async {
      final service = _createService();
      final file1 = File('${tempDir.path}/bg1.jpg');
      final file2 = File('${tempDir.path}/bg2.jpg');
      await file1.writeAsBytes([0xFF, 0xD8]);
      await file2.writeAsBytes([0xFF, 0xD8]);

      service.currentBoxImage.value = file1.path;
      final first = service.cachedBackgroundFileImage;

      service.currentBoxImage.value = file2.path;
      final second = service.cachedBackgroundFileImage;
      expect(identical(first, second), isFalse);
    });
  });

  group('wallpaper migration', () {
    test('skips empty value', () async {
      await HivePrefUtil.setString('currentBoxImage', '');
      final service = _createService();
      expect(service.currentBoxImage.value, isEmpty);
    });

    test('skips short value (already a path)', () async {
      await HivePrefUtil.setString('currentBoxImage', '/some/path/bg.jpg');
      final service = _createService();
      expect(service.currentBoxImage.value, '/some/path/bg.jpg');
    });

    test('base64 migration does not crash when AppPathManager unavailable', () async {
      final fakeBytes = List<int>.filled(400, 0xFF);
      final base64Str = base64Encode(fakeBytes);
      expect(base64Str.length, greaterThan(500));
      await HivePrefUtil.setString('currentBoxImage', base64Str);
      final service = _createService();
      await Future.delayed(const Duration(milliseconds: 200));
      // Migration fails silently (AppPathManager not initialized in test)
      // Value stays as base64 — no crash
      expect(service.currentBoxImage.value, isNotEmpty);
    });
  });
}
