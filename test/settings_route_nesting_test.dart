import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Guards the go_router behaviour the settings route table depends on.
///
/// The table itself (`settingsPageRoutes` in `lib/app/router/app_router.dart`) is
/// one absolute-path map behind ONE shell; `test/settings_shell_title_test.dart`
/// asserts that shape. These tests keep the underlying rule executable: a
/// `ShellRoute` that owns no path contributes no prefix, so a *relative* child
/// can never match. That is why every settings page is registered with its full
/// path — the shape this file used to mirror (relative children nested inside
/// `/settings`, plus a second shell for the absolute ones) is exactly what two
/// layers of routing looked like.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final Widget blank = const SizedBox.shrink();

  test('a path-less top-level ShellRoute leaves relative children unmatchable', () {
    final router = GoRouter(
      routes: [
        ShellRoute(
          builder: (context, state, child) => child,
          routes: [GoRoute(path: 'general', builder: (context, state) => blank)],
        ),
      ],
    );

    // This is the shape the settings sections used to have: relative paths with
    // no parent path to resolve them against, so nothing matched and every one
    // of the 25 modules was unreachable.
    expect(router.configuration.findMatch(Uri.parse('/general')).isError, isTrue);
    expect(router.configuration.findMatch(Uri.parse('/settings/general')).isError, isTrue);
  });

  test('control: the same ShellRoute works with an absolute child path', () {
    final router = GoRouter(
      routes: [
        ShellRoute(
          builder: (context, state, child) => child,
          routes: [GoRoute(path: '/general', builder: (context, state) => blank)],
        ),
      ],
    );

    expect(router.configuration.findMatch(Uri.parse('/general')).isError, isFalse);
  });
}
