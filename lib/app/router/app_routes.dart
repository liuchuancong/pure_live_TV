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

  /// The two platform display sub-pages: which platforms are listed, and in which order.
  static const kSettingsHotAreasVisibility = "/hot_areas/visibility";
  static const kSettingsHotAreasOrder = "/hot_areas/order";

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

  /// Picture sources of the remote wallpaper library.
  static const kWallpaperLibrary = "/wallpaper_library";

  /// The random-wallpaper API list.
  static const kWallpaperApi = "/wallpaper_api";

  /// The sources belonging to one API group.
  static const kWallpaperApiGroup = "/wallpaper_api_group";

  /// One wallpaper-library source: category list or straight to the grid.
  static const kWallpaperGallery = "/wallpaper_gallery";

  /// One wallpaper-library category: the thumbnail grid.
  static const kWallpaperItems = "/wallpaper_items";

  /// Fullscreen wallpaper preview (library shard walk or random-API image).
  static const kWallpaperPreview = "/wallpaper_preview";

  /// IPTV playlists and EPG sources (desktop app path).
  static const kIptv = "/iptv";

  /// IPTV sub-pages: import, auto-sync and request headers, each its own
  /// screen instead of one long scroll.
  static const kIptvResources = "/iptv/resources";
  static const kIptvImport = "/iptv/import";
  static const kIptvSync = "/iptv/sync";
  static const kIptvHeaders = "/iptv/headers";

  /// Tag management (desktop app path).
  static const kSettingsTags = "/settingTags";

  /// Settings sub-pages that the desktop app pushes without a named route.
  static const kSettingsTheme = "/settings/theme";
  static const kSettingsThemePicker = "/settings/theme_picker";
  static const kSettingsGridSpacing = "/settings/grid_spacing";
  static const kSettingsRefresh = "/settings/refresh";
  static const kSettingsVideo = "/settings/video";
  static const kSettingsPipDanmaku = "/settings/pip_danmaku";
  static const kSettingsPlayerKernel = "/settings/player_kernel";
  static const kSettingsProxy = "/settings/proxy";
  static const kSettingsLocalInteraction = "/settings/local_interaction";
  static const kSettingsGeneral = "/settings/general";
  static const kSettingsNavigation = "/settings/navigation";

  /// The three navigation & display sub-pages: which entries the side menu shows, in
  /// which order, and with which icon.
  static const kSettingsNavVisibility = "/settings/nav_visibility";
  static const kSettingsNavOrder = "/settings/nav_order";
  static const kSettingsNavIcons = "/settings/nav_icons";

  static const kSettingsPlatform = "/settings/platform";
  static const kSettingsCache = "/settings/cache";
  static const kSettingsConfigPreview = "/settings/config_preview";

  /// Icon picker, opened with the current icon as `extra`.
  static const kSettingsIconPicker = "/settings/icon_picker";

  /// Loading animation picker (grid of live previews).
  static const kSettingsLoadingStyle = "/settings/loading_style";

  /// Colour picker (grid of colours), opened with the current colour as `extra`.
  static const kSettingsColorPicker = "/settings/color_picker";

  /// Sub-pages opened from inside a settings page.
  static const kSettingsDecoder = "/settings/decoder";
  static const kSettingsRenderer = "/settings/renderer";
  static const kSettingsAudioOutput = "/settings/audio_output";
  static const kSettingsDanmaku = "/settings/danmaku";
  static const kSettingsFont = "/settings/font";
  static const kSettingsFontFamily = "/settings/fonts";
  static const kSettingsFontFamilyDanmaku = "/settingsFontFamilyDanmaku";
  static const kAppUpdate = "/app_update";
  static const kAppDownload = "/app_update/download";
  static const kUpdateHistory = "/update_history";
  static const kSettingsPage = "/settings/page";
  static const kSettingsAudience = "/settings/audience";
  static const kSettingsLocalBackup = "/settings/backups";

  /// Device sync (the TV end of the phone's device sync row)
  static const kSettingsDeviceSync = "/settings/device_sync";

  /// Per-platform cookie pages: every platform gets its own page, with both a
  /// QR (phone page or device sign-in) and manual input.
  static const kSettingsAccountBilibili = "/settings_account/bilibili";
  static const kSettingsAccountHuya = "/settings_account/huya";
  static const kSettingsAccountDouyu = "/settings_account/douyu";
  static const kSettingsAccountYy = "/settings_account/yy";
  static const kSettingsAccountDouyin = "/settings_account/douyin";
  static const kSettingsAccountKuaishou = "/settings_account/kuaishou";
  static const kSettingsAccountTwitch = "/settings_account/twitch";
  static const kSettingsAccountSoop = "/settings_account/soop";
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
