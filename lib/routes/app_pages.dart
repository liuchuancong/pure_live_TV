import 'route_path.dart';
import 'package:get/get.dart';
import 'package:pure_live/modules/sync/sync_page.dart';
import 'package:pure_live/modules/home/home_page.dart';
import 'package:pure_live/modules/areas/areas_page.dart';
import 'package:pure_live/modules/sync/sync_binding.dart';
import 'package:pure_live/modules/home/home_binding.dart';
import 'package:pure_live/modules/search/search_page.dart';
import 'package:pure_live/modules/areas/areas_binding.dart';
import 'package:pure_live/modules/version/version_page.dart';
import 'package:pure_live/modules/account/account_bing.dart';
import 'package:pure_live/modules/account/account_page.dart';
import 'package:pure_live/modules/popular/popular_page.dart';
import 'package:pure_live/modules/history/history_page.dart';
import 'package:pure_live/modules/search/search_binding.dart';
import 'package:pure_live/modules/favorite/favorite_page.dart';
import 'package:pure_live/modules/settings/settings_page.dart';
import 'package:pure_live/modules/version/version_binding.dart';
import 'package:pure_live/modules/popular/popular_binding.dart';
import 'package:pure_live/modules/agreement/agreement_page.dart';
import 'package:pure_live/modules/hot_areas/hot_areas_page.dart';
import 'package:pure_live/modules/live_play/live_play_page.dart';
import 'package:pure_live/modules/shield/danmu_shield_page.dart';
import 'package:pure_live/modules/areas/favorite_areas_page.dart';
import 'package:pure_live/modules/favorite/favorite_binding.dart';
import 'package:pure_live/modules/settings/settings_binding.dart';
import 'package:pure_live/modules/area_rooms/area_rooms_page.dart';
import 'package:pure_live/modules/hot_areas/hot_areas_binding.dart';
import 'package:pure_live/modules/live_play/live_play_binding.dart';
import 'package:pure_live/modules/shield/danmu_shield_binding.dart';
import 'package:pure_live/modules/history/history_rooms_binding.dart';
import 'package:pure_live/modules/area_rooms/area_rooms_binding.dart';
import 'package:pure_live/modules/account/bilibili/qr_login_page.dart';
import 'package:pure_live/modules/account/bilibili/bilibili_bings.dart';
import 'package:pure_live/modules/agreement/agreement_page_binding.dart';


// auth

class AppPages {
  AppPages._();

  static final routes = [
    GetPage(
      name: RoutePath.kInitial,
      page: HomePage.new,
      bindings: [HomeBinding()],
    ),
    GetPage(
      name: RoutePath.kFavorite,
      page: FavoritePage.new,
      bindings: [FavoriteBinding()],
    ),
    GetPage(
      name: RoutePath.kPopular,
      page: PopularPage.new,
      bindings: [PoPopularBinding()],
    ),
    GetPage(
      name: RoutePath.kAreas,
      page: AreasPage.new,
      bindings: [AreasBinding()],
    ),
    GetPage(
      name: RoutePath.kSettings,
      page: SettingsPage.new,
      bindings: [SettingsBinding()],
    ),
    GetPage(
      name: RoutePath.kHistory,
      page: HistoryPage.new,
      bindings: [HistoryPageBinding()],
    ),
    GetPage(
      name: RoutePath.kSearch,
      page: SearchRoomPage.new,
      bindings: [SearchBinding()],
    ),
    GetPage(
      name: RoutePath.kAreaRooms,
      page: AreasRoomPage.new,
      bindings: [AreaRoomsBinding()],
    ),
    GetPage(
      name: RoutePath.kLivePlay,
      page: () => LivePlayPage(),
      preventDuplicates: true,
      bindings: [LivePlayBinding()],
    ),
    //账号设置
    GetPage(
      name: RoutePath.kSettingsAccount,
      page: () => const AccountPage(),
      bindings: [AccountBinding()],
    ),
    //哔哩哔哩Web登录
    //哔哩哔哩二维码登录
    GetPage(
      name: RoutePath.kBiliBiliQRLogin,
      page: () => const BiliBiliQRLoginPage(),
      bindings: [
        BilibiliQrLoginBinding(),
      ],
    ),
    GetPage(
      name: RoutePath.kSettingsDanmuShield,
      page: () => const DanmuShieldPage(),
      bindings: [
        DanmuShieldBinding(),
      ],
    ),
    GetPage(
      name: RoutePath.kSettingsHotAreas,
      page: () => const HotAreasPage(),
      bindings: [
        HotAreasBinding(),
      ],
    ),
    GetPage(
      name: RoutePath.kSync,
      page: () => const SyncPage(),
      bindings: [
        SyncBinding(),
      ],
    ),

    GetPage(name: RoutePath.kAgreementPage, page: () => const AgreementPage(), bindings: [
      AgreementPageBinding(),
    ]),
    // 喜爱分区
    GetPage(name: RoutePath.kFavoriteAreas, page: () => const FavoriteAreasPage()),

    // VersionPage
    GetPage(name: RoutePath.kVersionPage, page: () => const VersionPage(), bindings: [
      VersionBinding(),
    ]),
  ];
}
