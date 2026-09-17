import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:pure_live/features/settings/pages/app_update_page.dart';
import 'package:pure_live/features/settings/pages/update_history_page.dart';
import 'package:pure_live/services/app_update/app_update_service.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:pure_live/shared/models/release_model/release_model.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/utils/hive_pref_util.dart';
import 'package:pure_live/shared/widgets/index.dart';

/// 在线更新 → 版本历史, and the device record on top of it.
class _FakeUpdateController extends AppUpdateController {
  _FakeUpdateController(this.initial);

  final AppUpdateState initial;
  int loadHistoryCalls = 0;
  String? installedUrl;

  @override
  AppUpdateState build() => initial;

  @override
  Future<void> loadHistory() async => loadHistoryCalls++;

  @override
  Future<void> downloadAndInstallUrl(String url) async => installedUrl = url;
}

ReleaseModel _release({
  required String version,
  required String date,
  String size = '18.4 MB',
  int downloads = 0,
  String title = '',
  String notes = '',
}) {
  return ReleaseModel(
    version: version,
    title: title,
    date: date,
    changeLog: notes,
    author: const AuthorModel(name: 'liuchuancong'),
    files: <ReleaseFileModel>[
      ReleaseFileModel(name: 'arm64-v8a', size: size, downloads: downloads, url: 'https://example.test/$version.apk'),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // `AppStatusView` and the update page read their colours through the settings
    // service, so the store has to exist before either renders.
    final Directory dir = Directory.systemTemp.createTempSync('pure_live_update_test');
    Hive.init(dir.path);
    await HivePrefUtil.init();
    SettingsService.to.init(ProviderContainer());
  });

  group('release history payload', () {
    test('is ordered by date, newest first, with the version as the tie-breaker', () {
      final releases = parseReleaseHistoryPayload(<dynamic>[
        <String, dynamic>{'version': '1.0.0', 'date': '2026-01-01'},
        <String, dynamic>{'version': '1.2.0', 'date': '2026-03-01'},
        <String, dynamic>{'version': '1.1.0', 'date': '2026-01-01'},
      ]);

      expect(releases.map((r) => r.version).toList(), <String>['1.2.0', '1.1.0', '1.0.0']);
    });

    test('accepts the wrapped payload and skips entries without a version', () {
      final releases = parseReleaseHistoryPayload(<String, dynamic>{
        'releases': <dynamic>[
          <String, dynamic>{'version': '2.0.0', 'date': '2026-05-05'},
          <String, dynamic>{'version': '  ', 'date': '2026-05-06'},
          'not a map',
        ],
      });

      expect(releases.length, 1);
      expect(releases.single.version, '2.0.0');
    });

    test('rejects a payload that is neither a list nor a releases map', () {
      expect(() => parseReleaseHistoryPayload(<String, dynamic>{'nope': 1}), throwsFormatException);
    });
  });

  group('release notes', () {
    test('drops the markdown table and the heading markers', () {
      const String raw = '# 更新内容\n\n- 修复了 A\n| 文件 | 大小 |\n| --- | --- |\n---\n- 新增了 B';

      final String cleaned = cleanReleaseNotes(raw);

      expect(cleaned, contains('更新内容'));
      expect(cleaned, contains('修复了 A'));
      expect(cleaned, contains('新增了 B'));
      expect(cleaned, isNot(contains('|')));
      expect(cleaned, isNot(contains('#')));
    });
  });

  group('device record', () {
    test('survives a round trip through json', () {
      final record = AppUpdateRecord(
        version: '1.2.3',
        action: AppUpdateAction.installed,
        time: DateTime(2026, 9, 17, 20, 15),
      );

      final restored = AppUpdateRecord.fromJson(record.toJson());

      expect(restored.version, '1.2.3');
      expect(restored.action, AppUpdateAction.installed);
      expect(restored.time, record.time);
    });

    test('reads an unknown action as a check instead of throwing', () {
      expect(AppUpdateRecord.fromJson(<String, dynamic>{'action': 'wat', 'time': 'nope'}).action, AppUpdateAction.checked);
    });
  });

  group('download progress', () {
    test('reports a remaining time only once the size and the speed are known', () {
      const idle = AppUpdateState(receivedBytes: 100, totalBytes: 1000, speedMbps: 0);
      expect(idle.remainingSeconds, isNull);

      const running = AppUpdateState(receivedBytes: 5 * 1024 * 1024, totalBytes: 10 * 1024 * 1024, speedMbps: 2);
      expect(running.progress, closeTo(0.5, 0.001));
      expect(running.remainingSeconds, 3);
    });
  });

  group('the history page', () {
    Future<_FakeUpdateController> pumpPage(WidgetTester tester, AppUpdateState state) async {
      final fake = _FakeUpdateController(state);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appUpdateControllerProvider.overrideWith(() => fake)],
          child: ScreenUtilPlusInit(
            designSize: const Size(1920, 1080),
            autoRebuild: false,
            minTextAdapt: false,
            splitScreenMode: false,
            child: MaterialApp(
              theme: ThemeData(extensions: <ThemeExtension<dynamic>>[TvThemeExtension(theme: darkTvTheme)]),
              home: const UpdateHistoryPage(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return fake;
    }

    AppUpdateState stateWith({required List<ReleaseModel> history, List<AppUpdateRecord> records = const []}) {
      return AppUpdateState(
        phase: AppUpdatePhase.upToDate,
        currentVersion: '1.2.0',
        currentBuild: '45',
        history: history,
        records: records,
      );
    }

    testWidgets('lists the releases and this device\'s update records', (WidgetTester tester) async {
      final fake = await pumpPage(
        tester,
        stateWith(
          history: <ReleaseModel>[
            _release(version: '1.2.0', date: '2026-03-01', notes: '当前版本'),
            _release(version: '1.1.0', date: '2026-01-01', downloads: 320),
          ],
          records: <AppUpdateRecord>[
            AppUpdateRecord(version: '1.2.0', action: AppUpdateAction.installed, time: DateTime(2026, 9, 17, 20, 15)),
            AppUpdateRecord(version: '1.2.0', action: AppUpdateAction.downloaded, time: DateTime(2026, 9, 17, 20, 12)),
          ],
        ),
      );

      expect(find.text('v1.2.0'), findsWidgets, reason: 'every release gets a row, labelled by version');
      expect(find.text('v1.1.0'), findsOneWidget);
      expect(find.textContaining('2026-01-01'), findsWidgets, reason: 'the release date is part of the row');
      expect(find.textContaining('320 ↓'), findsOneWidget, reason: 'download count when the manifest has one');
      // The device record, newest first, with the version and a timestamp. Unlocalized
      // builds fall back to the key (`i18n` returns it), which is what these match on.
      expect(find.text('update_record_installed'), findsOneWidget);
      expect(find.text('update_record_downloaded'), findsOneWidget);
      expect(find.textContaining('2026-09-17 20:15'), findsOneWidget);

      fake.loadHistoryCalls = 0; // The list was already there: no fetch on open.
      expect(fake.loadHistoryCalls, 0);
    });

    testWidgets('a release opens its notes and can install its asset', (WidgetTester tester) async {
      final fake = await pumpPage(
        tester,
        stateWith(
          history: <ReleaseModel>[_release(version: '1.1.0', date: '2026-01-01', notes: '修复了 A\n新增了 B')],
        ),
      );

      await tester.tap(find.text('v1.1.0'));
      await tester.pumpAndSettle();

      expect(find.textContaining('修复了 A'), findsOneWidget, reason: 'the changelog is in the dialog');
      expect(find.textContaining('新增了 B'), findsOneWidget);

      await tester.tap(find.textContaining('arm64-v8a'));
      await tester.pumpAndSettle();

      expect(fake.installedUrl, 'https://example.test/1.1.0.apk');
    });

    testWidgets('an empty history says so instead of showing nothing', (WidgetTester tester) async {
      await pumpPage(tester, stateWith(history: const <ReleaseModel>[]));

      expect(find.text('update_no_history'), findsOneWidget);
      expect(find.text('update_no_records'), findsOneWidget);
    });
  });

  group('the update page', () {
    Future<void> pumpUpdate(WidgetTester tester, AppUpdateState state) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appUpdateControllerProvider.overrideWith(() => _FakeUpdateController(state))],
          child: ScreenUtilPlusInit(
            designSize: const Size(1920, 1080),
            autoRebuild: false,
            minTextAdapt: false,
            splitScreenMode: false,
            child: MaterialApp(
              theme: ThemeData(extensions: <ThemeExtension<dynamic>>[TvThemeExtension(theme: darkTvTheme)]),
              home: const AppUpdatePage(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('up to date is drawn as a status, with a preview of the releases', (WidgetTester tester) async {
      await pumpUpdate(
        tester,
        AppUpdateState(
          phase: AppUpdatePhase.upToDate,
          currentVersion: '1.2.0',
          currentBuild: '45',
          latestVersion: '1.2.0',
          history: <ReleaseModel>[
            _release(version: '1.2.0', date: '2026-03-01'),
            _release(version: '1.1.0', date: '2026-01-01'),
          ],
        ),
      );

      expect(find.byType(AppStatusView), findsOneWidget, reason: 'the check state has to be visible');
      expect(find.text('already_latest_version'), findsWidgets);
      expect(find.text('version_history'), findsOneWidget, reason: 'the way into the full history');
      expect(find.text('v1.1.0'), findsOneWidget, reason: 'the newest releases are previewed');
    });

    testWidgets('a pending release shows its notes, its assets and the install action', (WidgetTester tester) async {
      await pumpUpdate(
        tester,
        AppUpdateState(
          phase: AppUpdatePhase.available,
          currentVersion: '1.2.0',
          currentBuild: '45',
          latestVersion: '2.0.0',
          changelog: '修复了 A',
          abis: <String>['arm64-v8a', 'armeabi-v7a'],
          selectedAbi: 'arm64-v8a',
          history: <ReleaseModel>[_release(version: '2.0.0', date: '2026-05-05', notes: '修复了 A')],
        ),
      );

      expect(find.textContaining('new_version_found'), findsWidgets);
      expect(find.textContaining('2026-05-05'), findsWidgets, reason: 'release date and size');
      expect(find.text('修复了 A'), findsOneWidget);
      expect(find.text('arm64-v8a'), findsWidgets);
      expect(find.text('armeabi-v7a'), findsOneWidget);
      expect(find.text('update_download_install'), findsOneWidget);
      expect(find.byType(AppStatusView), findsNothing, reason: 'an available update is not a status card');
    });
  });
}
