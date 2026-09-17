import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/widgets/index.dart';

/// `/settings` — the settings menu — builds its own app bar
/// (`appBar: TvAppBar(title: i18n('settings_title'))`) instead of letting
/// `TvPageScaffold` build one from a title.
///
/// The regression: passing a ready-made `TvAppBar` skipped the focus node the shell
/// needs. The 返回 button was drawn, but nothing handed focus Up to it and the opening
/// highlight never landed on it, so on that one page the remote could not select 返回
/// and it never showed the focused look every other page's 返回 shows.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpMenu(WidgetTester tester) async {
    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(1920, 1080),
        autoRebuild: false,
        minTextAdapt: true,
        splitScreenMode: false,
        child: MaterialApp(
          // The d-pad root and snap-scroll theme the app installs.
          builder: Dpad.wrap(theme: const DpadThemeData(scrollDuration: Duration.zero)),
          theme: ThemeData(extensions: <ThemeExtension<dynamic>>[TvThemeExtension(theme: darkTvTheme)]),
          navigatorObservers: <NavigatorObserver>[tvRouteObserver],
          home: const Scaffold(body: SizedBox.shrink()),
        ),
      ),
    );

    // The menu is pushed, so it can pop and therefore shows 返回.
    final BuildContext context = tester.element(find.byType(Scaffold).first);
    Navigator.of(context).push<void>(MaterialPageRoute<void>(builder: (_) => const _SettingsMenuPage()));
    await tester.pumpAndSettle();
  }

  bool focusOnBackButton() {
    final BuildContext? context = FocusManager.instance.primaryFocus?.context;
    return context?.findAncestorWidgetOfExactType<TvButton>() != null;
  }

  bool focusOnRow() {
    final BuildContext? context = FocusManager.instance.primaryFocus?.context;
    return context?.findAncestorWidgetOfExactType<TvSettingsSwitchTile>() != null;
  }

  testWidgets('the settings menu opens on 返回', (WidgetTester tester) async {
    await pumpMenu(tester);
    expect(find.text('ui_back'), findsOneWidget, reason: 'the menu is pushed, so it has a 返回 button');
    expect(focusOnBackButton(), isTrue, reason: 'the highlight opens on 返回, like every other page');
  });

  testWidgets('返回 stays selectable: down into the rows, up onto 返回 again', (WidgetTester tester) async {
    await pumpMenu(tester);

    for (int cycle = 0; cycle < 3; cycle++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(focusOnRow(), isTrue, reason: 'cycle $cycle: down from 返回 reaches the menu rows');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      expect(
        focusOnBackButton(),
        isTrue,
        reason: 'cycle $cycle: up from the first row must return to 返回 — without a wired node '
            'the bar had nothing to hand focus to and the remote was stuck on the row',
      );
    }
  });

  testWidgets('a page-supplied 返回 node inside the custom bar is used, not replaced', (WidgetTester tester) async {
    final FocusNode node = FocusNode(debugLabel: 'settings_menu_back');
    addTearDown(node.dispose);

    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(1920, 1080),
        autoRebuild: false,
        minTextAdapt: true,
        splitScreenMode: false,
        child: MaterialApp(
          builder: Dpad.wrap(theme: const DpadThemeData(scrollDuration: Duration.zero)),
          theme: ThemeData(extensions: <ThemeExtension<dynamic>>[TvThemeExtension(theme: darkTvTheme)]),
          navigatorObservers: <NavigatorObserver>[tvRouteObserver],
          home: const Scaffold(body: SizedBox.shrink()),
        ),
      ),
    );
    final BuildContext context = tester.element(find.byType(Scaffold).first);
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => TvPageScaffold(appBar: TvAppBar(title: 'mine', backFocusNode: node), child: const SizedBox.shrink()),
      ),
    );
    await tester.pumpAndSettle();

    expect(node.hasFocus, isTrue, reason: 'the node passed inside the custom bar is the one the shell opens on');
  });
}

/// The settings menu's shape: its own app bar, its own rows.
class _SettingsMenuPage extends StatelessWidget {
  const _SettingsMenuPage();

  @override
  Widget build(BuildContext context) {
    return TvPageScaffold(
      appBar: TvAppBar(title: 'settings_title'),
      child: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            for (int row = 1; row <= 3; row++)
              TvSettingsSwitchTile(title: 'menu row $row', value: false, onChanged: (_) {}),
          ],
        ),
      ),
    );
  }
}
