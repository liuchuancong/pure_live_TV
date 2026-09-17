import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pure_live/shared/widgets/index.dart';

Widget scaffoldPage(String title, {required List<Widget> rows}) {
  void onContentEdge(TraversalDirection direction) {
    // The back-button handoff this file was diagnosing now lives in the real
    // scaffold; `tv_scaffold_focus_test.dart` covers it.
  }
  return Scaffold(
    body: DpadRegion(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TvAppBar(title: title),
            Expanded(
              child: DpadRegion(
                verticalEdge: DpadEdgeBehavior.stop,
                onEdge: onContentEdge,
                child: TvFocusRestorer(
                  child: SingleChildScrollView(child: Column(children: rows)),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> pumpRoot(WidgetTester tester) async {
  await tester.pumpWidget(
    ScreenUtilPlusInit(
      designSize: const Size(1920, 1080),
      autoRebuild: false,
      minTextAdapt: true,
      splitScreenMode: false,
      child: MaterialApp(
        builder: Dpad.wrap(),
        home: const Scaffold(body: SizedBox.shrink()),
      ),
    ),
  );
}

void main() {
  testWidgets('debug focus state on level-3 page', (tester) async {
    await pumpRoot(tester);
    final BuildContext rootContext = tester.element(find.byType(Scaffold).first);
    Navigator.of(rootContext).push(MaterialPageRoute<void>(builder: (_) => scaffoldPage('level 2', rows: [
      TvSettingsSwitchTile(title: 'a', value: false, onChanged: (_) {}),
    ])));
    await tester.pumpAndSettle();
    Navigator.of(rootContext).push(MaterialPageRoute<void>(builder: (_) => scaffoldPage('level 3', rows: [
      TvSettingsSwitchTile(title: 'b', value: false, onChanged: (_) {}),
    ])));
    await tester.pumpAndSettle();

    final FocusNode? primary = FocusManager.instance.primaryFocus;
    // ignore: avoid_print
    print('PRIMARY: ${primary?.debugLabel} canRequestFocus=${primary?.canRequestFocus} skipping=${primary?.skipTraversal}');
    final scope = primary!.nearestScope;
    // ignore: avoid_print
    print('SCOPE: ${scope?.debugLabel}');
    // ignore: avoid_print
    print('DESCENDANTS: ${scope?.traversalDescendants.length ?? 0}');
    for (final n in scope?.traversalDescendants ?? const <FocusNode>[]) {
      // ignore: avoid_print
      print('  node ${n.debugLabel} attached=${n.parent != null} canRequest=${n.canRequestFocus} skip=${n.skipTraversal} context=${n.context}');
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    // ignore: avoid_print
    print('AFTER DOWN primary: ${FocusManager.instance.primaryFocus?.debugLabel}');
  });
}
