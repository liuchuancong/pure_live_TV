import 'dart:convert';
import 'dart:io';

import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:pure_live/features/home/home_page.dart';
import 'package:pure_live/features/home/home_provider.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/utils/hive_pref_util.dart';
import 'package:pure_live/shared/widgets/tv_icon_button.dart';

/// Pins the sidebar open, the way the expand button does at runtime.
class _ExpandedMenu extends IsMenuExpanded {
  @override
  bool build() => true;
}

/// The collapsed home sidebar names its destinations with two characters under
/// each icon.
///
/// The regression this pins: collapsed, the rail was a column of bare glyphs, so
/// the remote had to be aimed at an unlabelled icon to find 关注 / 热门 / 分区.
/// The labels are a caption line inside [TvIconButton]'s own surface, which now
/// grows downwards instead of staying square.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final Directory dir = Directory.systemTemp.createTempSync('pure_live_home_label_test');
    Hive.init(dir.path);
    await HivePrefUtil.init();
    // The sidebar's providers read preferences (menu order, icons, refresh
    // policy) and one of them persists its normalized copy on first build.
    SettingsService.to.init(ProviderContainer());
  });

  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(1920, 1080),
        autoRebuild: false,
        minTextAdapt: false,
        splitScreenMode: false,
        child: ProviderScope(
          child: MaterialApp(
            builder: Dpad.wrap(),
            theme: ThemeData(extensions: <ThemeExtension<dynamic>>[TvThemeExtension(theme: darkTvTheme)]),
            home: Scaffold(body: Center(child: child)),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('an icon button with a caption paints it under the icon', (tester) async {
    await pump(tester, TvIconButton(icon: const Icon(Icons.favorite_border), label: '关注'));

    expect(tester.takeException(), isNull);
    expect(find.text('关注'), findsOneWidget, reason: 'the collapsed rail names the destination');

    final Size captioned = tester.getSize(find.byType(DpadFocusable));
    expect(
      captioned.height,
      greaterThan(captioned.width),
      reason: 'the caption makes the tile a vertical pill instead of a square',
    );
  });

  testWidgets('an icon button without a caption stays the square icon-only control', (tester) async {
    await pump(tester, TvIconButton(icon: const Icon(Icons.favorite_border)));

    expect(tester.takeException(), isNull);
    expect(find.byType(Text), findsNothing);

    final Size plain = tester.getSize(find.byType(DpadFocusable));
    expect(plain.height, plain.width);
  });

  testWidgets('an empty caption is ignored rather than reserving a blank line', (tester) async {
    await pump(tester, TvIconButton(icon: const Icon(Icons.favorite_border), label: '  '));

    expect(find.byType(Text), findsNothing);
    final Size size = tester.getSize(find.byType(DpadFocusable));
    expect(size.height, size.width);
  });

  /// Mounts the real sidebar. [wrap] lets a case install provider overrides
  /// without naming riverpod's internal `Override` type, which the public
  /// barrel does not export.
  Future<void> pumpHome(WidgetTester tester, {Widget Function(Widget child)? wrap}) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final Widget home = ScreenUtilPlusInit(
      designSize: const Size(1920, 1080),
      autoRebuild: false,
      minTextAdapt: false,
      splitScreenMode: false,
      child: MaterialApp(
        builder: Dpad.wrap(),
        theme: ThemeData(extensions: <ThemeExtension<dynamic>>[TvThemeExtension(theme: darkTvTheme)]),
        home: const HomePage(),
      ),
    );

    await tester.pumpWidget(wrap == null ? ProviderScope(child: home) : wrap(home));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    // The home page schedules the update dialog 1.2s after the first frame; let
    // it fire (there is no new version in a test) so no timer outlives the test.
    await tester.pump(const Duration(milliseconds: 1500));
  }

  testWidgets('the collapsed rail labels every destination and fits its column', (tester) async {
    await pumpHome(tester);

    // A RenderFlex overflow in the rail reports through FlutterError, so this
    // also pins that the caption line still fits the 1080dp column.
    expect(tester.takeException(), isNull);

    // i18n resolves to the same string the rail asked for, whatever the locale
    // bundle does inside a widget test.
    for (final String key in const [
      'menu_short_following',
      'menu_short_backup',
      'menu_short_settings',
      'menu_short_expand',
    ]) {
      expect(find.text(i18n(key)), findsOneWidget, reason: '$key is not painted on the collapsed rail');
    }

    // Unmount so the clock's ticker does not outlive the test.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 50));
  });

  testWidgets('the expanded rail keeps the full names, without the captions', (tester) async {
    await pumpHome(
      tester,
      wrap: (child) => ProviderScope(
        overrides: [isMenuExpandedProvider.overrideWith(_ExpandedMenu.new)],
        child: child,
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text(i18n('ui_following')), findsOneWidget);
    expect(find.text(i18n('backup_manage')), findsOneWidget);
    expect(
      find.text(i18n('menu_short_backup')),
      findsNothing,
      reason: 'the caption is the collapsed state only',
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 50));
  });

  group('collapsed sidebar captions', () {
    /// Every entry the sidebar can show: the configurable destinations plus the
    /// fixed backup header, the settings entry and the expand toggle.
    const List<String> captionKeys = [
      'menu_short_following',
      'menu_short_hot',
      'menu_short_category',
      'menu_short_areas',
      'menu_short_link_playback',
      'menu_short_search',
      'menu_short_history',
      'menu_short_settings',
      'menu_short_backup',
      'menu_short_expand',
    ];

    Map<String, dynamic>? translations(String language) {
      final File file = File('assets/translations/$language.json');
      if (!file.existsSync()) {
        markTestSkipped('translations not found relative to ${Directory.current.path}');
        return null;
      }
      return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    }

    test('the Chinese captions are exactly two characters', () {
      final zh = translations('zh');
      if (zh == null) return;

      for (final String key in captionKeys) {
        final Object? value = zh[key];
        expect(value, isA<String>(), reason: '$key is missing from zh.json');
        expect(
          (value! as String).runes.length,
          2,
          reason: '$key must stay two characters wide for the 110dp rail, was "$value"',
        );
      }
    });

    test('the English captions exist and stay short enough for the rail', () {
      final en = translations('en');
      if (en == null) return;

      for (final String key in captionKeys) {
        final Object? value = en[key];
        expect(value, isA<String>(), reason: '$key is missing from en.json');
        final String text = (value! as String).trim();
        expect(text, isNotEmpty);
        expect(text.length, lessThanOrEqualTo(9), reason: '$key would ellipsize in the rail');
      }
    });
  });
}
