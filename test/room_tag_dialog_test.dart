import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:pure_live/shared/models/live_room/live_room.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/utils/favorite_operation_util.dart';
import 'package:pure_live/shared/utils/hive_pref_util.dart';

/// Switching a room's tags must survive the dialog it is picked in.
///
/// Regression: the dialog held the tag store's notifier *across* the dialog
/// await. Those settings stores are auto-disposed providers, so by the time the
/// user confirmed, the notifier was gone and the save threw
/// "Cannot use the Ref of tagManagementControllerProvider after it has been
/// disposed" — an unhandled exception on device, and the picked tags were lost.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;

  setUpAll(() async {
    final Directory dir = Directory.systemTemp.createTempSync('pure_live_room_tag_test');
    Hive.init(dir.path);
    await HivePrefUtil.init();
    container = ProviderContainer();
    SettingsService.to.init(container);
  });

  tearDownAll(() => container.dispose());

  testWidgets('a picked tag is saved on the room', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    expect(SettingsService.to.tag.addTag('游戏', ''), isTrue);
    final LiveRoom room = LiveRoom(roomId: 'r1', title: '房间', nick: '主播', platform: 'bilibili');

    await tester.pumpWidget(
      ProviderScope(
        child: ScreenUtilPlusInit(
          designSize: const Size(1920, 1080),
          autoRebuild: false,
          minTextAdapt: false,
          splitScreenMode: false,
          child: MaterialApp(
            theme: ThemeData(extensions: <ThemeExtension<dynamic>>[TvThemeExtension(theme: darkTvTheme)]),
            home: Scaffold(
              body: Center(
                child: Builder(
                  builder: (context) => TextButton(
                    onPressed: () => FavOperateUtil.showRoomTagDialog(context, room),
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    // The gap that used to dispose the notifier: the dialog is awaited, and
    // Riverpod's dispose scheduler runs while it is open.
    await tester.pumpAndSettle();

    await tester.tap(find.text('游戏'));
    await tester.pump();
    await tester.tap(find.text('done'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull, reason: 'confirming must not touch a disposed provider');
    expect(SettingsService.to.tag.getTagsForRoom(room), hasLength(1), reason: 'the picked tag is on the room now');

    // Let the zero-duration timer the settings read above scheduled run, or the
    // teardown reports a pending timer.
    await tester.pump(const Duration(milliseconds: 50));
  });
}
