import 'dart:io';
import 'dart:ui' as ui;

import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:pure_live/features/home/home_page.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/utils/hive_pref_util.dart';
import 'package:pure_live/shared/widgets/index.dart';

/// The controls have to follow the app's font-size setting, not just the labels.
///
/// A label is a `.sp` style the inherited scaler multiplies again, while every
/// control around it — button box, icon, rail, tab pill — was measured in panel
/// units alone. The result: the user enlarged the font and only the text moved;
/// the buttons stayed their design size and eventually clipped the labels they
/// were holding. These tests pin the control geometry to the same scale as the
/// text, and pin that nothing clips at the extremes.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final Directory dir = Directory.systemTemp.createTempSync('pure_live_control_scale');
    Hive.init(dir.path);
    await HivePrefUtil.init();
    SettingsService.to.init(ProviderContainer());
  });

  /// Mounts [child] under the same text-scale plumbing `App` installs.
  Future<void> pumpAt(
    WidgetTester tester,
    Widget child, {
    required double scale,
    Size panel = const Size(1920, 1080),
  }) async {
    tester.view.physicalSize = panel;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: TvTextScale.designSize,
        autoRebuild: false,
        child: ProviderScope(
          child: MaterialApp(
            builder: (context, child) => Dpad.wrap()(
              context,
              MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TvTextScale.scalerFor(context, userScale: scale)),
                child: child!,
              ),
            ),
            theme: ThemeData(
              extensions: <ThemeExtension<dynamic>>[TvThemeExtension(theme: darkTvTheme)],
            ),
            home: child,
          ),
        ),
      ),
    );
    await tester.pump();
    // The home page schedules its update dialog 1.2s after the first frame.
    await tester.pump(const Duration(milliseconds: 1500));
  }

  /// The text of a control has to fit the box that control drew for it.
  List<String> labelsOutgrowingTheirControl(WidgetTester tester) {
    final List<String> reports = <String>[];
    for (final Element element in find.byType(Text).evaluate()) {
      final RenderParagraph paragraph = element.renderObject! as RenderParagraph;
      final double needed = paragraph.getMaxIntrinsicHeight(paragraph.size.width);
      if (needed - paragraph.size.height > 0.5) {
        reports.add(
          '"${(element.widget as Text).data}" needs ${needed.toStringAsFixed(1)}px '
          'but its box is ${paragraph.size.height.toStringAsFixed(1)}px',
        );
      }
    }
    return reports;
  }

  testWidgets('the home sidebar keeps its labels and its buttons together', (
    WidgetTester tester,
  ) async {
    final List<double> railWidths = <double>[];
    final List<double> itemSizes = <double>[];

    for (final double scale in <double>[1.0, 1.6]) {
      await pumpAt(
        tester,
        RepaintBoundary(key: const Key('home-shot'), child: const HomePage()),
        scale: scale,
      );
      expect(tester.takeException(), isNull, reason: 'home page renders at $scale');

      // A still of the rail per scale, for eyeballing the buttons next to the
      // text they belong to.
      await tester.runAsync(() async {
        final RenderRepaintBoundary boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const Key('home-shot')),
        );
        final ui.Image image = await boundary.toImage();
        final ByteData? data = await image.toByteData(format: ui.ImageByteFormat.png);
        File('test/goldens/text_scale_home_${(scale * 100).round()}.png').writeAsBytesSync(
          data!.buffer.asUint8List(),
        );
      });

      // The rail carries the width the page computed from the text scale.
      railWidths.add(tester.getSize(find.byKey(const Key('home-sidebar'))).width);

      final Finder item = find.byType(TvIconButton);
      itemSizes.add(tester.getSize(item.first).width);

      final List<String> clipped = labelsOutgrowingTheirControl(tester);
      expect(clipped, isEmpty, reason: 'sidebar labels fit their controls at $scale');

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(
      railWidths[1],
      greaterThan(railWidths[0] * 1.4),
      reason: 'the rail grows with the font setting, otherwise its names are cut',
    );
    expect(
      itemSizes[1],
      greaterThan(itemSizes[0] * 1.4),
      reason: 'the collapsed rail tiles grow with the font setting too',
    );
  });

  testWidgets('a button grows with the font setting and still holds its label', (
    WidgetTester tester,
  ) async {
    final List<double> heights = <double>[];

    for (final double scale in <double>[1.0, 1.6, 2.0]) {
      await pumpAt(
        tester,
        Scaffold(
          body: Center(
            child: TvButton(
              title: '开始播放',
              icon: const Icon(Icons.play_arrow_rounded),
              onTap: () {},
            ),
          ),
        ),
        scale: scale,
      );
      expect(tester.takeException(), isNull, reason: 'button renders at $scale');

      final Element button = find.byType(TvButton).evaluate().single;
      heights.add((button.renderObject! as RenderBox).size.height);
      expect(
        labelsOutgrowingTheirControl(tester),
        isEmpty,
        reason: 'the button label fits at $scale',
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(heights[1] / heights[0], closeTo(1.6, 0.05));
    expect(heights[2] / heights[0], closeTo(2.0, 0.05));
  });

  testWidgets('the app bar grows with the font setting', (WidgetTester tester) async {
    final List<double> barHeights = <double>[];

    for (final double scale in <double>[1.0, 1.6]) {
      await pumpAt(
        tester,
        Navigator(
          onGenerateRoute: (settings) => MaterialPageRoute<void>(
            builder: (_) => Scaffold(
              body: Builder(builder: (context) => TvAppBar(title: '设置', showBackButton: false)),
            ),
          ),
        ),
        scale: scale,
      );
      expect(tester.takeException(), isNull, reason: 'app bar renders at $scale');

      barHeights.add(tester.getSize(find.byType(TvAppBar).first).height);
      expect(labelsOutgrowingTheirControl(tester), isEmpty, reason: 'app bar labels fit at $scale');

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(barHeights[1] / barHeights[0], closeTo(1.6, 0.05));
  });

  testWidgets('the tab bar pill grows with the font setting', (WidgetTester tester) async {
    final List<double> pillHeights = <double>[];

    for (final double scale in <double>[1.0, 1.6]) {
      await pumpAt(
        tester,
        Scaffold(
          body: Center(
            child: TvTabBar(
              tabs: const <TvTabItemData>[
                TvTabItemData(id: 'live', title: '正在直播'),
                TvTabItemData(id: 'replay', title: '正在重播'),
              ],
              currentIndex: 0,
              onTabChange: (_) {},
            ),
          ),
        ),
        scale: scale,
      );
      expect(tester.takeException(), isNull, reason: 'tab bar renders at $scale');

      pillHeights.add(tester.getSize(find.byType(TvTabBar).first).height);
      expect(labelsOutgrowingTheirControl(tester), isEmpty, reason: 'tab labels fit at $scale');

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(pillHeights[1] / pillHeights[0], closeTo(1.6, 0.05));
  });

  testWidgets('the home page holds up at 160% on a 720p panel', (WidgetTester tester) async {
    // The panel correction (1080/720) and the user's own scale multiply, so the
    // labels are drawn at 2.4x their design size inside a panel that is also
    // 2/3 the size — the worst case the app can produce.
    await pumpAt(tester, const HomePage(), scale: 1.6, panel: const Size(1280, 720));
    expect(tester.takeException(), isNull);
    expect(tester.takeException(), isNull, reason: 'no overflow in the rail or the page chrome');
  });
}
