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
import 'package:pure_live/services/settings/settings.dart';
import 'package:pure_live/services/theme_settings/theme_settings_controller.dart';
import 'package:pure_live/shared/models/live_area/live_area.dart';
import 'package:pure_live/shared/models/live_room/live_room.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/utils/hive_pref_util.dart';
import 'package:pure_live/shared/widgets/index.dart';

/// The grid cards have to survive the app's font-size setting.
///
/// The setting multiplies every label through `MediaQuery.textScaler`, while the
/// cell a card is handed stays whatever the grid delegate computed. Anything in
/// the card sized from `.sp` alone therefore kept its design size while the text
/// grew: the title was clipped inside its own line box, the platform chip ate the
/// row and squeezed the title to a couple of glyphs, and the area label was cut
/// at its second line. These tests pin the two properties that make the cards
/// work at any scale — no label is taller than the box it was given, and no
/// label paints outside its card — across the setting's range and the layout
/// densities the app offers.
/// The bundled font when it is present, otherwise any CJK face on the host. The
/// test shell otherwise draws every label as a solid block, which hides both the
/// clipping and the proportions this file exists to look at.
Uint8List? _fontBytes() {
  for (final String path in <String>[
    'assets/MiSans-Regular.ttf',
    r'C:\Windows\Fonts\Deng.ttf',
    r'C:\Windows\Fonts\simhei.ttf',
    '/System/Library/Fonts/PingFang.ttc',
    '/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc',
  ]) {
    final File file = File(path);
    if (file.existsSync()) return file.readAsBytesSync();
  }
  return null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final Directory dir = Directory.systemTemp.createTempSync('pure_live_text_scale');
    Hive.init(dir.path);
    await HivePrefUtil.init();
    SettingsService.to.init(ProviderContainer());
    // The cards embed cached network images; without a temp dir the cache
    // manager throws a MissingPluginException that would drown the layout
    // results this file is about.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall call) async => Directory.systemTemp.createTempSync('pure_live_cache').path,
    );
  });

  /// The home content column: a 1920 panel minus the expanded sidebar.
  const double contentWidth = 1720;

  LiveRoom room(int index) => LiveRoom(
    roomId: '$index',
    title: '房间标题 $index',
    nick: '主播名字 $index',
    platform: 'bilibili',
    liveStatus: LiveStatus.live,
    status: true,
    watching: '12.3万',
  );

  /// Long enough to wrap onto its second line in an 8-column cell.
  LiveArea area(int index) => LiveArea(areaName: '分类名称 $index 很长的分类名', areaPic: '');

  Widget cards({required int roomColumns, required int areaColumns}) {
    return ProviderScope(
      child: ColoredBox(
        color: const Color(0xFF101010),
        child: Center(
          child: SizedBox(
            width: contentWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 360,
                  child: GridView.builder(
                    padding: EdgeInsets.all(16.sp),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: roomColumns,
                      mainAxisSpacing: 32.sp,
                      crossAxisSpacing: 32.sp,
                      childAspectRatio: ThemeSettingsController.roomCardAspectRatio(roomColumns),
                    ),
                    itemCount: 6,
                    itemBuilder: (context, index) => TvRoomCard(room: room(index)),
                  ),
                ),
                SizedBox(
                  height: 300,
                  child: GridView.builder(
                    padding: EdgeInsets.all(16.sp),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: areaColumns,
                      mainAxisSpacing: 32.sp,
                      crossAxisSpacing: 32.sp,
                      childAspectRatio: 1.3,
                    ),
                    itemCount: 8,
                    itemBuilder: (context, index) =>
                        TvAreaCard(area: area(index), onTap: () {}, onLongPress: () {}),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<String> drainErrors(WidgetTester tester) {
    final List<String> messages = <String>[];
    Object? error = tester.takeException();
    while (error != null) {
      messages.add(error is FlutterError ? error.message.split('\n').first : error.toString());
      error = tester.takeException();
    }
    return messages.where((String message) => !message.contains('MissingPluginException')).toList();
  }

  /// Labels whose glyphs need more height than the box they were handed: the
  /// text scaler grew the font, the box did not follow, and the overflow is
  /// painted over whatever sits below it (or cut off).
  List<String> textsTallerThanTheirBox(WidgetTester tester, Type cardType) {
    final List<String> reports = <String>[];
    final Finder texts = find.descendant(of: find.byType(cardType), matching: find.byType(Text));
    for (final Element element in texts.evaluate()) {
      final RenderParagraph paragraph = element.renderObject! as RenderParagraph;
      final double needed = paragraph.getMaxIntrinsicHeight(paragraph.size.width);
      if (needed - paragraph.size.height > 0.5) {
        final String label = (element.widget as Text).data ?? '';
        reports.add(
          '"$label" needs ${needed.toStringAsFixed(1)}px but its box is ${paragraph.size.height.toStringAsFixed(1)}px',
        );
      }
    }
    return reports;
  }

  Future<void> render(
    WidgetTester tester, {
    required double scale,
    required int roomColumns,
    required int areaColumns,
    Size panel = const Size(1920, 1080),
    bool snap = false,
  }) async {
    tester.view.physicalSize = panel;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // App.build does this in the app; without it every widget that installs an
    // AppTextStyles as a DefaultTextStyle (TvButton, …) falls back to the shell's
    // block font and the previews stop resembling the app.
    AppTextStyles.fontFamily = 'MiSans';

    final Uint8List? fontBytes = _fontBytes();
    if (fontBytes != null) {
      for (final String family in <String>['MiSans', 'Roboto']) {
        final FontLoader loader = FontLoader(family)
          ..addFont(Future<ByteData>.value(ByteData.view(fontBytes.buffer)));
        await loader.load();
      }
    }

    final String tag =
        '${(scale * 100).round()}%/rooms=$roomColumns/areas=$areaColumns/${panel.height.toInt()}p';

    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: TvTextScale.designSize,
        autoRebuild: false,
        child: MaterialApp(
          builder: (context, child) => Dpad.wrap()(
            context,
            MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale * TvTextScale.legibilityLift(context))),
              child: child!,
            ),
          ),
          theme: ThemeData(
            fontFamily: 'MiSans',
            extensions: <ThemeExtension<dynamic>>[TvThemeExtension(theme: darkTvTheme)],
          ),
          home: Scaffold(
            backgroundColor: darkTvTheme.backgroundColor,
            body: cards(roomColumns: roomColumns, areaColumns: areaColumns),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    if (snap) {
      final Directory out = Directory('test/goldens');
      if (!out.existsSync()) out.createSync(recursive: true);
      final String file =
          'test/goldens/text_scale_cards_${(scale * 100).round()}_${roomColumns}_${panel.height.toInt()}p'
          '.png';
      await tester.runAsync(() async {
        final RenderRepaintBoundary boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byType(RepaintBoundary).first,
        );
        final ui.Image image = await boundary.toImage();
        final ByteData? data = await image.toByteData(format: ui.ImageByteFormat.png);
        File(file).writeAsBytesSync(data!.buffer.asUint8List());
      });
    }

    final List<String> errors = drainErrors(tester);
    final List<String> roomClipped = textsTallerThanTheirBox(tester, TvRoomCard);
    final List<String> areaClipped = textsTallerThanTheirBox(tester, TvAreaCard);
    for (final String report in <String>[...roomClipped, ...areaClipped]) {
      debugPrint('[$tag] CLIPPED $report');
    }

    expect(errors, isEmpty, reason: 'render errors at $tag');
    expect(roomClipped, isEmpty, reason: 'room card labels outgrew their boxes at $tag');
    expect(areaClipped, isEmpty, reason: 'area card labels outgrew their boxes at $tag');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('the focused title line keeps its height at any text scale', (
    WidgetTester tester,
  ) async {
    // The card swaps the plain label for the marquee when it takes focus. Both
    // have to occupy the same line box at the current font scale — the box used
    // to be `fontSize * 1.3` from the design size, which was already 8% short at
    // 100% and clipped the title once the font was enlarged.
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final Uint8List? fontBytes = _fontBytes();
    if (fontBytes != null) {
      final FontLoader loader = FontLoader('MiSans')
        ..addFont(Future<ByteData>.value(ByteData.view(fontBytes.buffer)));
      await loader.load();
    }
    AppTextStyles.fontFamily = 'MiSans';

    final List<double> lineHeights = <double>[];
    for (final double scale in <double>[1.0, 1.6, 2.0]) {
      await tester.pumpWidget(
        ScreenUtilPlusInit(
          designSize: TvTextScale.designSize,
          autoRebuild: false,
          child: MaterialApp(
            home: Builder(
              builder: (context) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale * TvTextScale.legibilityLift(context))),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    TvMarqueeText(
                      text: '房间标题很长很长很长',
                      style: TextStyle(fontSize: 22),
                      isFocused: false,
                    ),
                    TvMarqueeText(
                      text: '房间标题很长很长很长',
                      style: TextStyle(fontSize: 22),
                      isFocused: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      final List<double> heights = <double>[
        for (final Element element in find.byType(TvMarqueeText).evaluate())
          (element.renderObject! as RenderBox).size.height,
      ];
      debugPrint('[marquee ${(scale * 100).round()}%] line heights: $heights');
      expect(heights.first, heights.last, reason: 'focus must not resize the title line');
      for (final Element element in find.byType(Text).evaluate()) {
        final RenderParagraph paragraph = element.renderObject! as RenderParagraph;
        final double needed = paragraph.getMaxIntrinsicHeight(paragraph.size.width);
        expect(
          paragraph.size.height,
          greaterThanOrEqualTo(needed - 0.5),
          reason: 'a title line is taller than its box at ${(scale * 100).round()}%',
        );
      }
      lineHeights.add(heights.first);
    }
    // The line grows with the setting instead of staying at its design height.
    expect(lineHeights[1], greaterThan(lineHeights[0] * 1.4));
    expect(lineHeights[2], greaterThan(lineHeights[1] * 1.1));
  });

  // The setting's own range is 0.8-1.6; 2.0 is what the app clamps to.
  for (final double scale in <double>[1.0, 1.3, 1.6, 2.0]) {
    testWidgets('cards at ${(scale * 100).round()}% text scale', (WidgetTester tester) async {
      await render(tester, scale: scale, roomColumns: 4, areaColumns: 8, snap: true);
    });
  }

  testWidgets('cards at 160% text scale in the dense 5-column layout', (WidgetTester tester) async {
    await render(tester, scale: 1.6, roomColumns: 5, areaColumns: 8);
  });

  testWidgets('cards in small cells at 100% text scale', (WidgetTester tester) async {
    // Far below any real cell: the compact branch has to hold up on its own.
    await render(tester, scale: 1.0, roomColumns: 10, areaColumns: 16);
  });

  testWidgets('cards on a 720p panel at 160% text scale', (WidgetTester tester) async {
    // The worst case the app can produce: the panel correction (1080/720) and
    // the user's own scale multiply, so the labels are drawn ~2.4x their design
    // size inside cells that also shrank with the panel.
    await render(
      tester,
      scale: 1.6,
      roomColumns: 4,
      areaColumns: 8,
      panel: const Size(1280, 720),
      snap: true,
    );
  });
}
