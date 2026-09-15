import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pure_live/features/settings/tv_settings_option_tile.dart';
import 'package:pure_live/shared/dialog/tv_dialog.dart';
import 'package:pure_live/shared/widgets/tv_settings_menu_tile.dart';
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
        child: MaterialApp(
          // Same d-pad root the app installs.
          builder: Dpad.wrap(),
          home: Scaffold(body: Center(child: child)),
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
}
