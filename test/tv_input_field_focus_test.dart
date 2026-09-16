import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pure_live/shared/widgets/index.dart';

void main() {
  testWidgets('dpad down moves focus onto TvInputField', (tester) async {
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
                DpadFocusable(
                  autofocus: true,
                  onSelect: () {},
                  child: const Text('row above'),
                ),
                TvInputField(controller: controller, focusNode: fieldNode, hint: 'input'),
                DpadFocusable(
                  onSelect: () {},
                  child: const Text('row below'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(FocusManager.instance.primaryFocus, isNot(fieldNode));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();

    expect(
      FocusManager.instance.primaryFocus,
      fieldNode,
      reason: 'dpad down should land on the TvInputField text field',
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(
      FocusManager.instance.primaryFocus,
      isNot(fieldNode),
      reason: 'dpad down should leave the field to the row below',
    );
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
                DpadFocusable(
                  autofocus: true,
                  onSelect: () {},
                  child: const Text('row above'),
                ),
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
      FocusManager.instance.primaryFocus?.context?.findAncestorStateOfType<EditableTextState>() ?? null,
      isNotNull,
      reason: 'focus should be able to re-enter the input field',
    );
  });
}
