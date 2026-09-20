import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show ByteData;
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/widgets/index.dart';

/// Renders two scene empty states (favorite, favorite-areas) to one PNG so the
/// icon/scene alignment can be reviewed without a device.
///
/// Run: flutter test test/empty_scene_preview_test.dart
void main() {
  testWidgets('render empty scene previews', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(1920, 1080),
        autoRebuild: false,
        minTextAdapt: false,
        child: MaterialApp(
          theme: ThemeData(extensions: <ThemeExtension<dynamic>>[TvThemeExtension(theme: blueTvTheme)]),
          home: RepaintBoundary(
            key: const Key('empties'),
            child: Scaffold(
              backgroundColor: blueTvTheme.backgroundColor,
              body: Row(
                children: [
                  Expanded(
                    child: Builder(
                      builder: (context) => sceneEmptyView(
                        context,
                        scene: EmptyScene.favorite,
                        onRetry: () {},
                        onGoSearch: () {},
                      ),
                    ),
                  ),
                  Expanded(
                    child: Builder(
                      builder: (context) => sceneEmptyView(
                        context,
                        scene: EmptyScene.favoriteAreas,
                        onRetry: () {},
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.runAsync(() async {
      final RenderRepaintBoundary boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const Key('empties')),
      );
      final ui.Image image = await boundary.toImage();
      final ByteData? data = await image.toByteData(format: ui.ImageByteFormat.png);
      Directory('test/goldens').createSync(recursive: true);
      File('test/goldens/empty_scenes.png').writeAsBytesSync(data!.buffer.asUint8List());
    });
  });
}
