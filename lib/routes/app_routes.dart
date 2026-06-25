import 'package:pure_live/core/sites/sites.dart';
import 'package:pure_live/core/models/live_area/live_area.dart';

abstract final class AppRoutes {
  /// 首页
  static const kInitial = "/home";

  /// 关注列表
  static const kFavorite = "/favorite";

  /// 热门推荐
  static const kPopular = "/popular";

  /// 分区分类列表
  static const kAreas = "/areas";

  /// 分区房间列表
  static const kAreaRooms = "/area_rooms";

  /// 直播播放页面
  static const kLivePlay = "/live_play";

  /// 搜索页面
  static const kSearch = "/search";

  /// 全局设置
  static const kSettings = "/settings";

  /// 联系我们
  static const kContact = "/contact";

  /// 备份与恢复
  static const kBackup = "/backup";

  /// 关于我们
  static const kAbout = "/about";

  /// 播放历史记录
  static const kHistory = "/history";

  /// 捐赠支持
  static const kDonate = "/donate";

  /// 个人中心
  static const kMine = "/mine";

  /// 用户登录
  static const kSignIn = "/sign_in";

  /// 用户管理
  static const kUserManage = "/user_manage";

  /// 修改密码
  static const kUpdatePassword = "/update_password";

  /// 弹幕屏蔽设置
  static const kSettingsDanmuShield = "/shield";

  /// 常用分区/热门分区设置
  static const kSettingsHotAreas = "/hot_areas";

  /// 账号绑定设置
  static const kSettingsAccount = "/settings_account";

  /// 哔哩哔哩扫码登录
  static const kBiliBiliQRLogin = "/bilibili_qr_login";

  /// 哔哩哔哩网页登录
  static const kBiliBiliWebLogin = "/bilibili_web_login";

  /// 内嵌网页浏览器
  static const kWebview = "/webview_all";

  /// 数据同步
  static const kSync = "/sync";

  /// 用户协议与隐私政策页面
  static const kAgreementPage = "/agreement_page";

  /// 关注的分区
  static const kFavoriteAreas = "/favorite_areas";

  /// 版本检查与更新
  static const kVersionPage = "/version_page";

  /// 工具箱
  static const kToolbox = "/tool_box";

  /// 抖音 Cookie 设置
  static const kDouyinCookie = "/douyin_cookie";

  /// 快手 Cookie 设置
  static const kKuaishouCookie = "/kuaishou_cookie";

  /// 壁纸/背景设置页面
  static const kWallpaperPage = "/wallpaper_page";
}

class AreaRoomsArgs {
  final Site site;

  final LiveArea subCategory;

  const AreaRoomsArgs({required this.site, required this.subCategory});
}
