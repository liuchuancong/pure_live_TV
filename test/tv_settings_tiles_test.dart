import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pure_live/shared/dialog/tv_dialog.dart';
import 'package:pure_live/features/settings/tv_settings_page.dart';
import 'package:pure_live/shared/widgets/tv_settings_nav_tile.dart';
import 'package:pure_live/shared/widgets/tv_settings_row.dart';
import 'package:pure_live/shared/widgets/tv_settings_menu_tile.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/shared/widgets/tv_settings_option_tile.dart';
import 'package:pure_live/shared/widgets/tv_settings_slider_tile.dart';
import 'package:pure_live/shared/widgets/tv_settings_switch_tile.dart';

/// Mounts the TV components the way the app does.
///
/// These widgets build `DpadFocusable` instances whose contract is enforced by
/// runtime asserts — most importantly "provide either effects or builder, not
/// both". `flutter analyze` cannot see an assert inside a package constructor,
/// so without these tests a broken combination only shows up as a red screen on
/// the TV, which is exactly how the settings tiles shipped broken.
void main() {
  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(1920, 1080),
        autoRebuild: false,
        minTextAdapt: true,
        splitScreenMode: false,
        // The catalog reads providers (menu icons, i18n-adjacent state).
        child: ProviderScope(
          child: MaterialApp(
          // Same d-pad root the app installs.
          builder: Dpad.wrap(),
          home: Scaffold(body: Center(child: child)),
        ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  }

  testWidgets('TvSettingsSwitchTile renders', (tester) async {
    await pump(tester, TvSettingsSwitchTile(title: 'Follow theme', subtitle: 'sub', value: true, onChanged: (_) {}));
    expect(find.text('Follow theme'), findsOneWidget);
  });

  testWidgets('TvSettingsOptionTile renders', (tester) async {
    await pump(
      tester,
      TvSettingsOptionTile(title: 'Movie quality', subtitle: 'sub', options: const ['High', 'Low'], index: 0, onChanged: (_) {}),
    );
    expect(find.text('High'), findsOneWidget);
  });

  testWidgets('TvSettingsOptionTile tolerates an empty option list', (tester) async {
    await pump(tester, TvSettingsOptionTile(title: 'Empty', options: const [], index: 0, onChanged: (_) {}));
    expect(find.text('Empty'), findsOneWidget);
  });

  testWidgets('a single-option tile runs its action instead of opening a one-item list', (tester) async {
    // The regression: a single-option "action" row (导出配置, 清除缓存, 保存代理,
    // 检查更新, ...) opened a dialog showing its own value, the dialog reported
    // "nothing changed" and `onChanged` never ran, so every action row in the
    // settings was dead.
    int? fired;
    await pump(
      tester,
      TvSettingsOptionTile(title: 'Export config', options: const ['Export'], index: 0, onChanged: (i) => fired = i),
    );

    tester.widget<TvSettingsRow>(find.byType(TvSettingsRow)).onSelect!.call();
    await tester.pumpAndSettle();

    expect(fired, 0);
    expect(find.byType(TvDialog), findsNothing, reason: 'an action row must not open a selector');
    // The action label is the row title, so the row wears a chevron rather than
    // a value with a drop-down arrow.
    expect(find.text('Export'), findsNothing);
  });

  testWidgets('a choice row still shows its value, an action row does not', (tester) async {
    // The two must stay distinguishable: a choice row shows the current value
    // with a drop-down arrow, an action row wears a plain chevron.
    await pump(
      tester,
      TvSettingsOptionTile(title: 'Quality', options: const ['High', 'Low'], index: 0, onChanged: (_) {}),
    );
    expect(find.text('High'), findsOneWidget);
    expect(find.byIcon(Icons.expand_more_rounded), findsOneWidget);

    await pump(
      tester,
      TvSettingsOptionTile(title: 'Check update', options: const ['Check'], index: 0, onChanged: (_) {}),
    );
    expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
    expect(find.byIcon(Icons.expand_more_rounded), findsNothing);
  });

  testWidgets('TvSettingsMenuTile renders', (tester) async {
    await pump(
      tester,
      TvSettingsMenuTile<String>(
        title: 'Decoder',
        value: 'hardware',
        valueMap: const {'hardware': 'Hardware', 'software': 'Software'},
        onChanged: (_) {},
      ),
    );
    expect(find.text('Hardware'), findsOneWidget);
  });

  testWidgets('TvSettingsSliderTile renders', (tester) async {
    await pump(
      tester,
      TvSettingsSliderTile(
        title: 'Danmaku opacity',
        icon: Icons.opacity,
        value: 50,
        min: 0,
        max: 100,
        displayValue: '50%',
        onChanged: (_) {},
      ),
    );
    expect(find.text('50%'), findsOneWidget);
  });

  testWidgets('TvDialog renders its actions', (tester) async {
    await pump(
      tester,
      TvDialog(
        title: 'Clear cache',
        confirmText: 'Confirm',
        cancelText: 'Cancel',
        onConfirm: () {},
        onCancel: () {},
        child: const Text('body'),
      ),
    );
    expect(find.text('Confirm'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('every settings row renders through the shared shell', (tester) async {
    // One shell means one look: padding, palette colours and the bordered focus
    // treatment cannot drift apart between the switch, option, menu, slider and
    // navigation rows.
    final tiles = <Widget>[
      TvSettingsSwitchTile(title: 'Follow theme', value: true, onChanged: (_) {}),
      TvSettingsOptionTile(title: 'Quality', options: const ['High', 'Low'], index: 0, onChanged: (_) {}),
      TvSettingsMenuTile<String>(title: 'Decoder', value: 'a', valueMap: const {'a': 'A'}, onChanged: (_) {}),
      TvSettingsSliderTile(
        title: 'Opacity',
        icon: Icons.opacity,
        value: 50,
        min: 0,
        max: 100,
        displayValue: '50%',
        onChanged: (_) {},
      ),
      TvSettingsNavTile(title: 'Theme', icon: Icons.palette_outlined, onTap: () {}),
    ];

    for (final tile in tiles) {
      await pump(tester, tile);
      expect(find.byType(TvSettingsRow), findsOneWidget, reason: tile.runtimeType.toString());
    }
  });

  testWidgets('the settings catalog renders every group and row', (tester) async {
    // A tall viewport so the lazy ListView builds the whole catalog; i18n
    // falls back to the key when localizations are not loaded, which is what
    // the finders below match on.
    tester.view.physicalSize = const Size(1920, 4200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pump(tester, const SettingsCatalogView());

    final int expectedRows = settingsCatalog.fold(0, (sum, group) => sum + group.entries.length);
    expect(find.byType(TvSettingsGroupTitle), findsNWidgets(settingsCatalog.length));
    expect(find.byType(TvSettingsNavTile), findsNWidgets(expectedRows));

    for (final SettingsGroup group in settingsCatalog) {
      // A group heading may repeat a row title (the reference design does this
      // for IPTV and refresh), so presence is what matters here.
      expect(find.text(group.titleKey), findsAtLeastNWidgets(1), reason: 'group ${group.titleKey}');
      for (final SettingsEntry entry in group.entries) {
        expect(find.text(entry.titleKey), findsAtLeastNWidgets(1), reason: 'entry ${entry.path}');
      }
    }
  });
}
