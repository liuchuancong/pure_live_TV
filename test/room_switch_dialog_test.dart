import 'dart:io';
import 'package:hive_ce/hive.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:pure_live/shared/utils/hive_pref_util.dart';
import 'package:pure_live/shared/models/live_room/live_room.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/services/history_settings/history_model.dart';
import 'package:pure_live/services/favorites/favorite_settings_model.dart';
import 'package:pure_live/services/favorites/favorite_room_controller.dart';
import 'package:pure_live/services/history_settings/history_controller.dart';
import 'package:pure_live/features/live_play/dialogs/room_switch_dialog.dart';

/// The room switcher is steered by **selected index**, like the player's own
/// control bar and side panels: Left/Right walk the tabs, Down enters the list,
/// Up from the first row leaves it, OK takes the highlighted room.
///
/// What this pins: the dialog used to be a focus-traversal UI (TvTabBar +
/// DpadFocusable rows + a TabBarView), and a tab change handed the keyboard to a
/// row of the page that was still on its way out — the list showed one tab while
/// the highlight sat on another. Nothing about which room OK takes may depend on
/// where a geometric focus search lands.
class _FakeFavoriteController extends FavoriteRoomController {
  _FakeFavoriteController(this.initial);

  final FavoriteSettingsModel initial;

  @override
  FavoriteSettingsModel build() => initial;
}

class _FakeHistoryController extends HistoryController {
  _FakeHistoryController(this.initial);

  final HistoryModel initial;

  @override
  HistoryModel build() => initial;
}

/// A live room with no avatar, so nothing in the dialog reaches for the network.
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

  /// The room lists come from SettingsService, so the fakes go into the container
  /// the service is initialized with. `_container` is `late final` inside the
  /// service: it takes one initialization per process, which is why this happens
  /// once for the whole file.
  late ProviderContainer container;

  setUpAll(() async {
    final Directory dir = Directory.systemTemp.createTempSync('pure_live_room_switch_test');
    Hive.init(dir.path);
    await HivePrefUtil.init();

    container = ProviderContainer(
      overrides: [
        favoriteRoomControllerProvider.overrideWith(
          () => _FakeFavoriteController(FavoriteSettingsModel(favoriteRooms: <LiveRoom>[_room('live-1', '直播中的房间')])),
        ),
        historyControllerProvider.overrideWith(
          () => _FakeHistoryController(
            HistoryModel(historyRooms: <LiveRoom>[_room('h-1', '历史一号'), _room('h-2', '历史二号')]),
          ),
        ),
      ],
    );
    SettingsService.to.init(container);
  });

  tearDownAll(() => container.dispose());

  /// Opens the dialog from a route; the returned getter reads what it handed
  /// back.
  Future<LiveRoom? Function()> pumpDialog(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    LiveRoom? picked;
    await tester.pumpWidget(
      ProviderScope(
        child: ScreenUtilPlusInit(
          designSize: const Size(1920, 1080),
          autoRebuild: false,
          minTextAdapt: false,
          splitScreenMode: false,
          child: MaterialApp(
            theme: ThemeData(extensions: <ThemeExtension<dynamic>>[TvThemeExtension(theme: darkTvTheme)]),
            // Without loaded localizations the labels are the i18n *keys*
            // (`watch_history (2)`), which are far longer than any shipped
            // translation — and the tab strip is deliberately sized to its own
            // content. Rendering the harness at a smaller text scale measures the
            // strip the way a localized build would.
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(0.7)),
              child: child!,
            ),
            home: Scaffold(
              body: Center(
                child: Builder(
                  builder: (context) => TextButton(
                    onPressed: () async {
                      picked = await showRoomSwitchDialog(context, current: _room('now', '当前房间'));
                    },
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return () => picked;
  }

  /// Ends an interaction the way a real remote does — with the frame settled and
  /// the zero-duration timers Riverpod schedules on a settings read already run,
  /// since a pending one fails the test's own teardown.
  Future<void> settle(WidgetTester tester) async {
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('left/right walk the tabs, down enters the list, OK takes the room', (WidgetTester tester) async {
    final LiveRoom? Function() result = await pumpDialog(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // Opens on the tab strip, so the first tab's list is already on screen.
    expect(find.text('直播中的房间'), findsOneWidget);

    // Right walks the strip: the third tab's list replaces the first's.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(find.text('历史一号'), findsOneWidget);
    expect(find.text('直播中的房间'), findsNothing, reason: 'the list follows the tab index');

    // Down enters the list, the next press walks it, OK takes what is highlighted.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await settle(tester);

    expect(result()?.title, '历史二号');
  });

  testWidgets('up from the first row is the way back to the tabs', (WidgetTester tester) async {
    await pumpDialog(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // Into the list, then straight back out of it.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();

    // Left now belongs to the strip — it walks the tabs instead of merely
    // leaving the list, which is the difference between the two zones.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await settle(tester);

    expect(find.text('历史一号'), findsOneWidget, reason: 'wrapped from the first tab to the last');
  });

  testWidgets('an empty tab keeps the keyboard on the strip', (WidgetTester tester) async {
    final LiveRoom? Function() result = await pumpDialog(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // The middle tab has no followed room that is replaying.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(find.text('no_followed_room_live'), findsOneWidget, reason: 'an unlocalized build shows the key');

    // Down and OK must not walk into the empty list: nothing is picked and the
    // dialog stays open.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await settle(tester);
    expect(result(), isNull, reason: 'an empty list has no row to take');
    expect(find.text('switch_live_room'), findsOneWidget, reason: 'the dialog title is still up');
  });

  testWidgets('escape closes the dialog without picking anything', (WidgetTester tester) async {
    final LiveRoom? Function() result = await pumpDialog(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await settle(tester);

    expect(result(), isNull);
    expect(find.text('switch_live_room'), findsNothing, reason: 'the dialog is gone');
  });
}
