import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:pure_live/features/settings/pages/font_family_manager_section.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:pure_live/shared/dialog/index.dart';
import 'package:pure_live/shared/platform/font_download_manager.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/utils/hive_pref_util.dart';
import 'package:pure_live/shared/widgets/index.dart';

/// The font manager mirrors the mobile page (`font_family_manager_page.dart`): a family
/// made of several weight files asks which weight to lock, and the download runs behind
/// a modal that shows the app's loading animation.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final Directory dir = Directory.systemTemp.createTempSync('pure_live_font_test');
    Hive.init(dir.path);
    await HivePrefUtil.init();
    // `AppStatusView` resolves the loading style through the settings service, so the
    // container has to exist before the dialog renders.
    SettingsService.to.init(ProviderContainer());
  });

  group('weight labels', () {
    test('a weight file is labelled by the part after the last dash', () {
      // The mobile rule: `basenameWithoutExtension(path).split('-').last`.
      expect(FontDownloadManager.weightLabelOf('/fonts/foo/SourceHanSans-700.ttf'), '700');
      expect(FontDownloadManager.weightLabelOf('SourceHanSansCN-Bold.otf'), 'Bold');
    });

    test('a file without a dash keeps its whole stem instead of an empty label', () {
      expect(FontDownloadManager.weightLabelOf('/fonts/foo/Regular.ttf'), 'Regular');
    });

    test('only real font extensions count', () {
      expect(FontDownloadManager.isSupportedFontPath('/a/b.ttf'), isTrue);
      expect(FontDownloadManager.isSupportedFontPath('/a/b.OTF'), isTrue);
      expect(FontDownloadManager.isSupportedFontPath('/a/readme.txt'), isFalse);
      expect(FontDownloadManager.isSupportedFontPath('/a/ttf'), isFalse);
    });

    test('the stored file name is the file name, not the path', () {
      expect(FontDownloadManager.fileNameOf('/fonts/foo/SourceHanSans-700.ttf'), 'SourceHanSans-700.ttf');
    });
  });

  Future<void> pumpHost(WidgetTester tester, Future<bool> Function() download) async {
    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(1920, 1080),
        autoRebuild: false,
        minTextAdapt: false,
        splitScreenMode: false,
        child: MaterialApp(
          theme: ThemeData(extensions: <ThemeExtension<dynamic>>[TvThemeExtension(theme: darkTvTheme)]),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TvButton(
                  title: 'open',
                  onTap: () => TvDialogUtils.show<bool>(
                    context: context,
                    builder: (_) => FontDownloadProgressDialog(fontName: '思源黑体', download: download),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Bounded pumps: the dialog's loading animation runs forever, so `pumpAndSettle`
  /// would never return while it is on screen.
  Future<void> pumpFrames(WidgetTester tester, {int frames = 8}) async {
    for (int frame = 0; frame < frames; frame++) {
      await tester.pump(const Duration(milliseconds: 120));
    }
  }

  testWidgets('the download dialog shows the loading animation, then closes with the result', (WidgetTester tester) async {
    final Completer<bool> finished = Completer<bool>();
    await pumpHost(tester, () => finished.future);

    await tester.tap(find.byType(TvButton));
    await pumpFrames(tester);

    expect(find.byType(FontDownloadProgressDialog), findsOneWidget);
    expect(find.byType(AppStatusView), findsOneWidget, reason: 'the wait has to be visible');
    expect(find.text('思源黑体'), findsOneWidget, reason: 'which family is downloading');
    // No way out but the end of the download: the remote cannot dismiss it.
    expect(find.text('close'), findsNothing);
    expect(find.text('cancel'), findsNothing);

    finished.complete(true);
    await pumpFrames(tester);
    expect(find.byType(FontDownloadProgressDialog), findsNothing, reason: 'the dialog closes itself');
  });

  testWidgets('a failed download closes too, instead of waiting forever', (WidgetTester tester) async {
    await pumpHost(tester, () async => false);

    await tester.tap(find.byType(TvButton));
    await pumpFrames(tester);

    expect(find.byType(FontDownloadProgressDialog), findsNothing);
  });
}
