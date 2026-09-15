import 'package:pure_live/exports/common_export.dart';

abstract final class AppRoutes {
  /// Home
  static const kInitial = "/home";

  /// Followed rooms
  static const kFavorite = "/favorite";

  /// Popular picks
  static const kPopular = "/popular";

  /// Category list
  static const kAreas = "/areas";

  /// Rooms inside a category
  static const kAreaRooms = "/area_rooms";

  /// Live playback
  static const kLivePlay = "/live_play";

  /// Search
  static const kSearch = "/search";

  // Search results
  static const kSearchResult = "/search_result";

  /// Global settings
  static const kSettings = "/settings";

  /// Contact
  static const kContact = "/contact";

  /// Backup and restore
  static const kBackup = "/backup";

  /// About
  static const kAbout = "/about";

  /// Watch history
  static const kHistory = "/history";

  /// Donations
  static const kDonate = "/donate";

  /// Account
  static const kMine = "/mine";

  /// Sign in
  static const kSignIn = "/sign_in";

  /// User management
  static const kUserManage = "/user_manage";

  /// Change password
  static const kUpdatePassword = "/update_password";

  /// Danmaku blocklist
  static const kSettingsDanmuShield = "/shield";

  /// Preferred and popular categories
  static const kSettingsHotAreas = "/hot_areas";

  /// Account binding
  static const kSettingsAccount = "/settings_account";

  /// Bilibili QR sign-in
  static const kBiliBiliQRLogin = "/bilibili_qr_login";

  /// Bilibili web sign-in
  static const kBiliBiliWebLogin = "/bilibili_web_login";

  /// Embedded web browser
  static const kWebview = "/webview_all";

  /// Data sync
  static const kSync = "/sync";

  /// Terms of service and privacy policy
  static const kAgreementPage = "/agreement_page";

  /// Followed categories
  static const kFavoriteAreas = "/favorite_areas";

  /// Version check and updates
  static const kVersionPage = "/version_page";

  /// Toolbox
  static const kToolbox = "/tool_box";

  /// Douyin cookie settings
  static const kDouyinCookie = "/douyin_cookie";

  /// Kuaishou cookie settings
  static const kKuaishouCookie = "/kuaishou_cookie";

  /// Wallpaper and background settings
  static const kWallpaperPage = "/wallpaper_page";
}

class AreaRoomsArgs {
  final Site site;

  final LiveArea subCategory;

  const AreaRoomsArgs({required this.site, required this.subCategory});
}

class SearchResultArgs {
  final String keyword;
  final String site;
  final String searchType;

  const SearchResultArgs({required this.keyword, required this.site, required this.searchType});
}
