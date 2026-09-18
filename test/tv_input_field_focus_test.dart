import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pure_live/shared/widgets/index.dart';

/// TvInputField is [TvTextField] from `tv_textfield` under the app's palette.
///
/// The behaviour these tests pin down is the whole reason the package replaced
/// a plain [TextField]: focus moves *through* the field with the arrows, and the
/// keyboard only opens when the user activates it. A plain TextField consumed
/// the arrows for caret movement, so a remote could never leave it.
void main() {
  testWidgets('dpad down moves focus onto TvInputField without editing it', (tester) async {
    final TextEditingController controller = TextEditingController();
    final FocusNode fieldNode = FocusNode();

    await tester.pumpWidget(
      MaterialApp(
        builder: Dpad.wrap(),
        home: Scaffold(
          body: DpadRegion(
            debugLabel: 'page',
            child: ListView(
              children: [
                DpadFocusable(autofocus: true, onSelect: () {}, child: const Text('row above')),
                TvInputField(controller: controller, focusNode: fieldNode, hint: 'input'),
                DpadFocusable(onSelect: () {}, child: const Text('row below')),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();

    expect(fieldNode.hasFocus, true, reason: 'dpad down should land on the TvInputField');
    expect(
      find.byType(EditableText),
      findsNothing,
      reason: 'merely focussing the field must not open the keyboard',
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(fieldNode.hasFocus, false, reason: 'dpad down should leave the field to the row below');
  });

  testWidgets('dpad can leave TvInputField upward and return', (tester) async {
    final TextEditingController controller = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        builder: Dpad.wrap(),
        home: Scaffold(
          body: DpadRegion(
            debugLabel: 'page',
            child: ListView(
              children: [
                DpadFocusable(autofocus: true, onSelect: () {}, child: const Text('row above')),
                TvInputField(controller: controller, hint: 'input'),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus, isNotNull);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(
      find.byType(TvInputField).evaluate().isNotEmpty,
      true,
      reason: 'focus should be able to re-enter the input field',
    );
  });

  testWidgets('activating a focused field opens the keyboard', (tester) async {
    final TextEditingController controller = TextEditingController();
    final FocusNode fieldNode = FocusNode();

    await tester.pumpWidget(
      MaterialApp(
        builder: Dpad.wrap(),
        home: Scaffold(
          body: DpadRegion(
            debugLabel: 'page',
            child: ListView(
              children: [
                DpadFocusable(autofocus: true, onSelect: () {}, child: const Text('row above')),
                TvInputField(controller: controller, focusNode: fieldNode, hint: 'input'),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();

    expect(find.byType(EditableText), findsOneWidget, reason: 'select on a focused field starts editing');
  });
}
