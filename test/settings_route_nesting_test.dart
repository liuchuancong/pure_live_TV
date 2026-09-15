import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Guards how the settings sections are nested in the route table.
///
/// A top-level `ShellRoute` has no path of its own, so its children are
/// resolved against the root (`/general`, `/theme`, ...). Nesting them under
/// `GoRoute(path: '/settings')` is what makes `/settings/<module>` match again.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final Widget blank = const SizedBox.shrink();

  GoRouter buildNestedRouter() => GoRouter(
    routes: [
      GoRoute(path: '/home', builder: (context, state) => blank),
      GoRoute(
        path: '/settings',
        redirect: (context, state) => state.uri.path == '/settings' ? '/settings/general' : null,
        routes: [
          ShellRoute(
            builder: (context, state, child) => child,
            routes: [
              GoRoute(path: 'general', builder: (context, state) => blank),
              GoRoute(path: 'font', builder: (context, state) => blank),
              GoRoute(path: 'fonts', builder: (context, state) => blank),
            ],
          ),
        ],
      ),
    ],
  );

  test('every settings section matches below /settings', () {
    final router = buildNestedRouter();

    for (final path in ['/settings/general', '/settings/font', '/settings/fonts']) {
      final match = router.configuration.findMatch(Uri.parse(path));
      expect(match.isError, isFalse, reason: '$path must resolve');
      expect(match.uri.path, path);
    }
  });

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
