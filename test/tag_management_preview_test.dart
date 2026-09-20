import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_localization/easy_localization.dart' as ez;
import 'package:pure_live/features/settings/pages/tag_management_section.dart';
import 'package:pure_live/services/tag_management/tag_management_controller.dart';
import 'package:pure_live/services/tag_management/tag_management_model.dart';
import 'package:pure_live/services/tag_management/live_tag.dart';
import 'package:pure_live/shared/dialog/index.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/widgets/index.dart';

/// Renders the rebuilt tag management page (chip cloud + add row) and its two
/// dialogs to PNGs for review without a device.
///
/// Run: flutter test test/tag_management_preview_test.dart
void main() {
  testWidgets('render tag management previews', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final Uint8List fontBytes = File('assets/MiSans-Regular.ttf').readAsBytesSync();
    for (final String family in <String>['MiSans', 'Roboto']) {
      final FontLoader loader = FontLoader(family)
        ..addFont(Future<ByteData>.value(ByteData.view(fontBytes.buffer)));
      await loader.load();
    }

    final fake = _FakeTagController(
      TagManagementModel(
        tags: [
          LiveTag(id: '1', name: '王者荣耀', description: '开黑直播'),
          LiveTag(id: '2', name: '户外'),
          LiveTag(id: '3', name: '电子竞技', description: 'LOL / Dota2 / CS2'),
          LiveTag(id: '4', name: '唱歌'),
          LiveTag(id: '5', name: '一起看电影'),
        ],
      ),
    );

    Future<void> snap(String file) async {
      await tester.runAsync(() async {
        final RenderRepaintBoundary boundary =
            tester.renderObject<RenderRepaintBoundary>(find.byKey(const Key('tag-page')));
        final ui.Image image = await boundary.toImage();
        final ByteData? data = await image.toByteData(format: ui.ImageByteFormat.png);
        File('test/goldens/$file').writeAsBytesSync(data!.buffer.asUint8List());
      });
    }

    await tester.pumpWidget(
      ProviderScope(
        overrides: [tagManagementControllerProvider.overrideWith(() => fake)],
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
              // The app's own theme builder: TvSettingsRow reads the Material
              // colorScheme, which a bare ThemeData leaves light/white.
              theme: buildTvThemeData(
                palette: blueTvTheme,
                brightness: Brightness.dark,
                baseTextTheme: ThemeData(brightness: Brightness.dark).textTheme,
                fontFamily: 'MiSans',
                colorScheme: ColorScheme.fromSeed(seedColor: blueTvTheme.focusColor, brightness: Brightness.dark),
              ),
              home: RepaintBoundary(
                key: const Key('tag-page'),
                child: Scaffold(
                  backgroundColor: blueTvTheme.backgroundColor,
                  body: Padding(
                    padding: const EdgeInsets.all(40),
                    child: const TagManagementSectionPage(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    // RemoteSyncQrCard animates forever; a fixed pump is the settle.
    await tester.pump(const Duration(milliseconds: 1200));

    Directory('test/goldens').createSync(recursive: true);
    await snap('tag_page_chips.png');

    // Tap the first chip: the tag detail dialog (查看 + 删除). The dialog
    // paints in the navigator's overlay, outside the page boundary, so it is
    // verified programmatically rather than in the PNG.
    await tester.tap(find.text('王者荣耀'), warnIfMissed: true);
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.byType(TvDialog), findsOneWidget, reason: 'chip tap opens the detail dialog');
    // Unlocalized test shell: i18n falls back to the key, which is what the
    // matchers target (same convention as app_update_test).
    expect(find.text('tag_detail'), findsOneWidget, reason: 'dialog title 标签详情');
    expect(find.text('delete'), findsOneWidget, reason: 'the delete action');
    // 'cancel' sits in the offline label table, which translates it to 取消.
    await tester.tap(find.text('取消'));
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.byType(TvDialog), findsNothing, reason: 'cancel closes the dialog');

    // Tap the add row: the two-field add dialog.
    await tester.tap(find.text('ui_add'));
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.byType(TvDialog), findsOneWidget, reason: 'add opens the create dialog');
    expect(find.byType(TvInputField), findsNWidgets(2), reason: 'name + description fields');
  });
}

class _FakeTagController extends TagManagementController {
  _FakeTagController(this.initial);

  final TagManagementModel initial;

  @override
  TagManagementModel build() => initial;
}
