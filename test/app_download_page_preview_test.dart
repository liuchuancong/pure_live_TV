import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_localization/easy_localization.dart' as ez;
import 'package:hive_ce/hive.dart';
import 'package:pure_live/features/settings/pages/app_download_page.dart';
import 'package:pure_live/services/app_update/app_update_service.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:pure_live/shared/models/release_model/release_model.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/utils/hive_pref_util.dart';

/// Renders [AppDownloadPage] (the 当前版本 download page) to PNGs — top with
/// the per-ABI 下载源 grid, bottom with the markdown release notes.
///
/// Run: flutter test test/app_download_page_preview_test.dart
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final Directory dir = Directory.systemTemp.createTempSync('pure_live_download_preview');
    Hive.init(dir.path);
    await HivePrefUtil.init();
    SettingsService.to.init(ProviderContainer());
  });

  testWidgets('render download page preview', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final Uint8List fontBytes = File('assets/MiSans-Regular.ttf').readAsBytesSync();
    for (final String family in <String>['MiSans', 'Roboto']) {
      final FontLoader loader = FontLoader(family)
        ..addFont(Future<ByteData>.value(ByteData.view(fontBytes.buffer)));
      await loader.load();
    }

    final String originUrl =
        'https://github.com/iuiaoin/pure_live_tv/releases/download/v1.3.0/pure_live_tv_arm64.apk';
    final fake = _FakeUpdateController(
      AppUpdateState(
        phase: AppUpdatePhase.available,
        currentVersion: '1.2.0',
        currentBuild: '45',
        latestVersion: '1.3.0',
        changelog: '修复了 A\n新增了 B',
        changelogMarkdown:
            '# v1.3.0 更新日志\n\n- 修复了**在线更新**在部分电视盒子上的下载失败问题\n- 新增 `下载源` 选择,支持 5 个镜像加速\n- 优化弹幕渲染性能\n\n> 注意:安装时需要授予“安装未知应用”权限。',
        abis: ['arm64-v8a', 'armeabi-v7a', 'x86_64'],
        history: [
          ReleaseModel(
            version: 'v1.3.0',
            date: '2026-09-19',
            author: const AuthorModel(),
            files: [
              ReleaseFileModel(name: 'arm64-v8a', size: '42.5 MB', url: originUrl),
              ReleaseFileModel(name: 'armeabi-v7a', size: '39.1 MB', url: originUrl),
            ],
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appUpdateControllerProvider.overrideWith(() => fake)],
        child: ez.EasyLocalization(
          supportedLocales: const [Locale('zh'), Locale('en')],
          path: 'assets/translations',
          fallbackLocale: const Locale('zh'),
          startLocale: const Locale('zh'),
          useOnlyLangCode: true,
          child: ScreenUtilPlusInit(
            designSize: const Size(1920, 1080),
            autoRebuild: false,
            minTextAdapt: false,
            splitScreenMode: false,
            child: MaterialApp(
              locale: const Locale('zh'),
              theme: ThemeData(extensions: <ThemeExtension<dynamic>>[TvThemeExtension(theme: blueTvTheme)]),
              home: const RepaintBoundary(key: Key('dl-page'), child: AppDownloadPage()),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    Future<void> snap(String file) async {
      await tester.runAsync(() async {
        final RenderRepaintBoundary boundary =
            tester.renderObject<RenderRepaintBoundary>(find.byKey(const Key('dl-page')));
        final ui.Image image = await boundary.toImage();
        final ByteData? data = await image.toByteData(format: ui.ImageByteFormat.png);
        File('test/goldens/$file').writeAsBytesSync(data!.buffer.asUint8List());
      });
    }

    final Directory out = Directory('test/goldens');
    if (!out.existsSync()) out.createSync(recursive: true);
    await snap('download_page_top.png');

    // Bottom of the page: the markdown release notes.
    final scroller = find.byType(Scrollable).first;
    await tester.drag(scroller, const Offset(0, -800));
    await tester.pumpAndSettle();
    await snap('download_page_bottom.png');
  });
}

class _FakeUpdateController extends AppUpdateController {
  _FakeUpdateController(this.initial);

  final AppUpdateState initial;

  @override
  AppUpdateState build() => initial;

  @override
  Future<void> loadHistory() async {}

  @override
  Future<void> downloadAndInstallUrl(String url, {bool preferGivenUrl = false}) async {}
}
