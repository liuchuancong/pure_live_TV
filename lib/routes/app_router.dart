import 'package:go_router/go_router.dart';
import 'package:pure_live/modules/home/home_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/modules/agreement/agreement_page.dart';
import 'package:pure_live/services/startUp/startup_controller.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final isFirstInApp = ref.watch(startupControllerProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final location = state.uri.path;

      if (isFirstInApp && location != '/agreement') {
        return '/agreement';
      }

      if (!isFirstInApp && location == '/agreement') {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomePage()),
      GoRoute(path: '/agreement', builder: (context, state) => const AgreementPage()),
    ],
  );
});
