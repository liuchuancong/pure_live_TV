import 'package:get/get.dart';
import 'package:pure_live/common/index.dart';

class GetXRouterObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    // 进入页面 route.settings.name
    final SettingsService settingsService = Get.find<SettingsService>();
    settingsService.routeChangeType.value = RouteChangeType.push;
    settingsService.currentRouteName.value = route.settings.name!;
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) async {
    super.didPop(route, previousRoute);
    final SettingsService settingsService = Get.find<SettingsService>();
    settingsService.routeChangeType.value = RouteChangeType.pop;
    // 离开页面 previousRoute.settings.name
    settingsService.currentRouteName.value = previousRoute!.settings.name!;
  }
}
