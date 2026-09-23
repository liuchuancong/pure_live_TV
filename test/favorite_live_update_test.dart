import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dpad/dpad.dart';
import 'package:hive_ce/hive.dart';
import 'package:pure_live/features/favorite/favorite_page.dart';
import 'package:pure_live/services/favorites/favorite_room_controller.dart';
import 'package:pure_live/services/favorites/favorite_settings_model.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:pure_live/shared/models/live_room/live_room.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/utils/hive_pref_util.dart';
import 'package:pure_live/shared/widgets/tv_button.dart';

/// Following a room while the favourite grid is alive must show up in the
/// grid.
///
/// The regression this pins: the grid's data lives in a PagingCore, and the
/// view's identity is deliberately only the tab/tag selection (so following a
/// room no longer resets the focus and the scroll position). Nothing told the
/// core that the list had changed, so a room followed in the player only
/// appeared after switching tabs or restarting the app.
class _FakeFavoriteController extends FavoriteRoomController {
  _FakeFavoriteController(this.initial);

  final FavoriteSettingsModel initial;

  @override
  FavoriteSettingsModel build() => initial;
}

LiveRoom _room(String id, String title) {
  return LiveRoom(
    roomId: id,
    title: title,
    nick: 'streamer $id',
    platform: 'bilibili',
    liveStatus: LiveStatus.live,
    status: true,
    watching: '100',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final Directory dir = Directory.systemTemp.createTempSync('pure_live_favorite_test');
    Hive.init(dir.path);
    await HivePrefUtil.init();
    SettingsService.to.init(ProviderContainer());
  });

  testWidgets('a room followed while the page is open shows up in the grid', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final fake = _FakeFavoriteController(
      FavoriteSettingsModel(favoriteRooms: <LiveRoom>[_room('1', '原本关注的房间')]),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [favoriteRoomControllerProvider.overrideWith(() => fake)],
        child: ScreenUtilPlusInit(
          designSize: const Size(1920, 1080),
          autoRebuild: false,
          minTextAdapt: false,
          splitScreenMode: false,
          child: MaterialApp(
            builder: Dpad.wrap(),
            theme: ThemeData(extensions: <ThemeExtension<dynamic>>[TvThemeExtension(theme: darkTvTheme)]),
            home: const FavoritePage(),
          ),
        ),
      ),
    );
    // The grid loads through a microtask + a fake async frame.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('原本关注的房间'), findsOneWidget, reason: 'the followed room is on screen');

    // The player's follow action writes the same controller.
    fake.addRoom(_room('2', '刚关注的房间'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('刚关注的房间'), findsOneWidget, reason: 'the new room must appear without a tab switch or a restart');

    // Unmount and let riverpod's deferred dispose task (a zero-delay timer)
    // run: the harness asserts no timer is pending when the test ends.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 50));
  });

  /// The tag strip's active chip carries the accent until the filter moves on.
  ///
  /// Regression: the strip only passed `isSecondary`, so the tag that filtered
  /// the grid had no highlight of its own — the chip looked highlighted only
  /// while the remote was on it, and choosing another tag read as "the highlight
  /// disappeared".
  testWidgets('the tag strip keeps the accent on the tag that is filtering', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // Two tags, one room each, so the strip offers 全部 plus both of them.
    final tags = SettingsService.to.tag;
    tags.addTag('游戏', '');
    tags.addTag('音乐', '');
    final tagState = SettingsService.to.tagState;
    final game = tagState.tags.firstWhere((tag) => tag.name == '游戏');
    final music = tagState.tags.firstWhere((tag) => tag.name == '音乐');
    tags.setRoomTags(_room('1', '房间一'), <String>[game.id]);
    tags.setRoomTags(_room('2', '房间二'), <String>[music.id]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          favoriteRoomControllerProvider.overrideWith(
            () => _FakeFavoriteController(
              FavoriteSettingsModel(favoriteRooms: <LiveRoom>[_room('1', '房间一'), _room('2', '房间二')]),
            ),
          ),
        ],
        child: ScreenUtilPlusInit(
          designSize: const Size(1920, 1080),
          autoRebuild: false,
          minTextAdapt: false,
          splitScreenMode: false,
          child: MaterialApp(
            builder: Dpad.wrap(),
            theme: ThemeData(extensions: <ThemeExtension<dynamic>>[TvThemeExtension(theme: darkTvTheme)]),
            home: const FavoritePage(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    TvButton chip(String label) =>
        tester.widget<TvButton>(find.ancestor(of: find.text(label), matching: find.byType(TvButton)));

    expect(chip('recorder_tab_all').selected, isTrue, reason: 'the page opens on 全部');

    await tester.tap(find.text('游戏'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(chip('游戏').selected, isTrue, reason: 'the filtering tag keeps the accent');
    expect(chip('recorder_tab_all').selected, isFalse);

    await tester.tap(find.text('音乐'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(chip('音乐').selected, isTrue, reason: 'the highlight moves to the new tag instead of vanishing');
    expect(chip('游戏').selected, isFalse);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 50));
  });
}
