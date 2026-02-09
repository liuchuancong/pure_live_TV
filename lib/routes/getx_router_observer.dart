import 'dart:developer';
import 'package:get/get.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/modules/home/home_controller.dart';
import 'package:pure_live/player/switchable_global_player.dart';
import 'package:pure_live/modules/live_play/live_play_controller.dart';

class GetXRouterObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    // 进入页面 route.settings.name
    final SettingsService settingsService = Get.find<SettingsService>();
    settingsService.routeChangeType.value = RouteChangeType.push;
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) async {
    super.didPop(route, previousRoute);
    final SettingsService settingsService = Get.find<SettingsService>();
    settingsService.routeChangeType.value = RouteChangeType.pop;
  }
}

class BackButtonObserver extends RouteObserver<PageRoute<dynamic>> {
  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    if (route.settings.name == RoutePath.kInitial) {
      try {
        final controller = Get.find<HomeController>();
        controller.refreshData();
      } catch (e) {
        log("BackButtonObserver Error: ${e.toString()}");
      }
    } else if (route.settings.name == RoutePath.kLivePlay) {
      Get.find<LivePlayController>().onDelete();
      SwitchableGlobalPlayer().stop();
    }
  }
}
