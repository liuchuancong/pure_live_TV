import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/shared/dialog/tv_dialog_utils.dart';
import 'package:pure_live/shared/dialog/tv_select_dialog.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/widgets/tv_button.dart';

/// A dialog that asks for a value must take the focus with it.
///
/// The regression: 观看历史 → 保留数量 → 自定义 opened the input dialog but left the
/// focus on the room card behind it, so the remote typed into nothing and the
/// dialog's field could not be reached without pressing Back first.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// A page whose own focusable item holds focus, like the history grid does.
  Future<void> pumpPageWithFocusable(WidgetTester tester, FocusNode pageFocus) async {
    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(1920, 1080),
        autoRebuild: false,
        minTextAdapt: true,
        splitScreenMode: false,
        child: MaterialApp(
          builder: Dpad.wrap(),
          theme: ThemeData(extensions: <ThemeExtension<dynamic>>[TvThemeExtension(theme: darkTvTheme)]),
          home: Scaffold(
            body: Center(
              child: TvButton(
                title: 'room card',
                focusNode: pageFocus,
                autofocus: true,
                onTap: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(pageFocus.hasPrimaryFocus, isTrue, reason: 'the page starts focused, as on a TV');
  }

  testWidgets('the input dialog takes focus off the page behind it', (WidgetTester tester) async {
    final FocusNode pageFocus = FocusNode(debugLabel: 'page');
    addTearDown(pageFocus.dispose);
    await pumpPageWithFocusable(tester, pageFocus);

    // Same path as 自定义 in the history page: TvDialogUtils.showInput.
    final BuildContext context = tester.element(find.byType(Scaffold));
    TvDialogUtils.showInput(context: context, title: 'custom', hintText: 'value');
    await tester.pumpAndSettle();

    expect(find.byType(EditableText), findsOneWidget, reason: 'the dialog must be up');

    final FocusNode fieldFocus = tester.widget<EditableText>(find.byType(EditableText)).focusNode;
    expect(
      fieldFocus.hasPrimaryFocus,
      isTrue,
      reason: 'the input dialog must hold the keyboard, not the page behind it',
    );
    expect(pageFocus.hasPrimaryFocus, isFalse, reason: 'the page behind must have given it up');
  });

  testWidgets('typing reaches the dialog field', (WidgetTester tester) async {
    final FocusNode pageFocus = FocusNode(debugLabel: 'page');
    addTearDown(pageFocus.dispose);
    await pumpPageWithFocusable(tester, pageFocus);

    final BuildContext context = tester.element(find.byType(Scaffold));
    TvDialogUtils.showInput(context: context, title: 'custom', hintText: 'value');
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(EditableText), '20');
    await tester.pumpAndSettle();

    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      '20',
      reason: 'the dialog field must be the one taking input',
    );
  });

  testWidgets('a page that grabs focus behind an open dialog does not keep it', (WidgetTester tester) async {
    // The real failure: the history grid rebuilds while the dialog is open, its
    // focused card dies, and the d-pad layer restores focus to a node of the page
    // behind — the dialog stayed up with its field unreachable.
    final FocusNode pageFocus = FocusNode(debugLabel: 'page');
    addTearDown(pageFocus.dispose);
    await pumpPageWithFocusable(tester, pageFocus);

    final BuildContext context = tester.element(find.byType(Scaffold));
    TvDialogUtils.showInput(context: context, title: 'custom', hintText: 'value');
    await tester.pumpAndSettle();

    final FocusNode fieldFocus = tester.widget<EditableText>(find.byType(EditableText)).focusNode;
    expect(fieldFocus.hasPrimaryFocus, isTrue);

    // Something on the page underneath asks for the keyboard.
    pageFocus.requestFocus();
    await tester.pump();
    await tester.pump();

    expect(
      fieldFocus.hasPrimaryFocus,
      isTrue,
      reason: 'the dialog must take the keyboard back from the page behind it',
    );
    expect(pageFocus.hasPrimaryFocus, isFalse);
  });

  testWidgets('a dialog opened from the remote takes the keyboard over', (WidgetTester tester) async {
    // The real path: 保留数量 (a select dialog) then 自定义 (the input dialog), both
    // driven by key presses, with no settling in between — which is how the remote
    // actually walks it.
    final FocusNode pageFocus = FocusNode(debugLabel: 'page');
    addTearDown(pageFocus.dispose);

    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(1920, 1080),
        autoRebuild: false,
        minTextAdapt: true,
        splitScreenMode: false,
        child: MaterialApp(
          builder: Dpad.wrap(),
          theme: ThemeData(extensions: <ThemeExtension<dynamic>>[TvThemeExtension(theme: darkTvTheme)]),
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: TvButton(
                  title: '保留数量',
                  focusNode: pageFocus,
                  autofocus: true,
                  onTap: () => _openLimitFlow(context),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(pageFocus.hasPrimaryFocus, isTrue);

    // OK on the toolbar button, then walk the select list onto 自定义 and confirm.
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(find.text('自定义'), findsOneWidget, reason: 'the select dialog is up');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    // No settle: the input dialog is pushed while the pop transition still runs.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(EditableText), findsOneWidget, reason: 'the input dialog must be up');
    final FocusNode fieldFocus = tester.widget<EditableText>(find.byType(EditableText)).focusNode;
    expect(
      fieldFocus.hasPrimaryFocus,
      isTrue,
      reason: 'the custom-input dialog must hold the keyboard, not the page behind it',
    );
  });
}

/// The history page's flow: pick a preset or 自定义, then ask for the value.
Future<void> _openLimitFlow(BuildContext context) async {
  final int? action = await TvDialogUtils.showSelect<int>(
    context: context,
    title: '保留数量',
    items: const <TvSelectItem<int>>[
      TvSelectItem<int>(title: '20', value: 20),
      TvSelectItem<int>(title: '自定义', value: -1),
    ],
  );
  if (action != -1 || !context.mounted) return;
  await TvDialogUtils.showInput(context: context, title: '自定义', hintText: '条数');
}
