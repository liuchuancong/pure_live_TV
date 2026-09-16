import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('probe: what does a ShellRoute builder see?', () async {
    final seen = <String, String>{};
    final router = GoRouter(
      initialLocation: '/settings',
      routes: [
        GoRoute(
          path: '/settings',
          builder: (context, state) => const Text('menu'),
          routes: [
            ShellRoute(
              builder: (context, state, child) {
                seen['nested:${state.uri.path}'] = state.matchedLocation;
                return child;
              },
              routes: [GoRoute(path: 'general', builder: (context, state) => const Text('general'))],
            ),
          ],
        ),
        ShellRoute(
          builder: (context, state, child) {
            seen['top:${state.uri.path}'] = state.matchedLocation;
            return child;
          },
          routes: [GoRoute(path: '/iptv', builder: (context, state) => const Text('iptv'))],
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    router.go('/settings/general');
    await tester.pumpAndSettle();
    router.go('/iptv');
    await tester.pumpAndSettle();

    // ignore: avoid_print
    print('PROBE: $seen');
  });
}
