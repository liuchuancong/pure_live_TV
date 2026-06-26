import 'package:go_router/go_router.dart';
import 'package:pure_live/routes/app_routes.dart';
import 'package:pure_live/modules/home/home_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/modules/agreement/agreement_page.dart';
import 'package:pure_live/modules/area_rooms/area_rooms_page.dart';
import 'package:pure_live/services/startUp/startup_controller.dart';
import 'package:pure_live/modules/search/tv_search_result_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final isFirstInApp = ref.watch(startupControllerProvider);

  return GoRouter(
    initialLocation: AppRoutes.kInitial,
    redirect: (context, state) {
      final location = state.uri.path;

      if (isFirstInApp && location != AppRoutes.kAgreementPage) {
        return AppRoutes.kAgreementPage;
      }

      if (!isFirstInApp && location == AppRoutes.kAgreementPage) {
        return AppRoutes.kInitial;
      }

      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.kInitial, builder: (context, state) => const HomePage()),
      GoRoute(path: AppRoutes.kAgreementPage, builder: (context, state) => const AgreementPage()),
      GoRoute(
        path: AppRoutes.kAreaRooms,
        builder: (context, state) {
          final args = state.extra as AreaRoomsArgs;
          return AreaRoomsPage(site: args.site, subCategory: args.subCategory);
        },
      ),
      GoRoute(
        path: AppRoutes.kSearchResult,
        builder: (context, state) {
          final args = state.extra as SearchResultArgs;
          return TvSearchResultPage(keyword: args.keyword, site: args.site, searchType: args.searchType);
        },
      ),
    ],
  );
});
