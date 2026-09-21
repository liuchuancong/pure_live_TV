import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pure_live/shared/widgets/tv_input_field.dart';
import 'package:pure_live/shared/theme/tv_theme_extension.dart';
import 'package:pure_live/shared/theme/themes/cyber_theme.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

/// The TV input contract with the tv_textfield dependency gone: a focused field
/// shows text without stealing the arrows, OK starts editing, Escape stops.
void main() {
  testWidgets('tv input field: display -> edit -> submit', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final FocusNode node = FocusNode();
    final TextEditingController controller = TextEditingController();
    addTearDown(() {
      node.dispose();
      controller.dispose();
    });
    String? submitted;
    final FocusNode other = FocusNode();
    addTearDown(other.dispose);

    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(1920, 1080),
        autoRebuild: false,
        child: MaterialApp(
          builder: Dpad.wrap(),
          theme: ThemeData(
            useMaterial3: true,
            extensions: <ThemeExtension<dynamic>>[TvThemeExtension(theme: cyberTvTheme)],
          ),
          home: Scaffold(
            body: Column(
              children: [
                TvInputField(
                  controller: controller,
                  focusNode: node,
                  hint: 'hint',
                  onSubmitted: (value) => submitted = value,
                ),
                Focus(focusNode: other, child: const SizedBox(width: 40, height: 40)),
              ],
            ),
          ),
        ),
      ),
    );

    // Display state: no TextField yet, nothing has stolen the arrows.
    expect(find.byType(TextField), findsNothing);

    node.requestFocus();
    await tester.pump();
    expect(find.byType(TextField), findsNothing);

    // OK starts editing; the real TextField takes over.
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'abc');
    await tester.pump();
    expect(controller.text, 'abc');

    // Escape leaves editing, back to the display line, focus still on the field.
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    expect(find.text('abc'), findsOneWidget);
    expect(node.hasFocus, isTrue);

    // Submitted text still reaches the caller.
    expect(submitted, isNull);
  });
}
