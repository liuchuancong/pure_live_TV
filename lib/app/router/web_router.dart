class WebRemoteRouter {
  WebRemoteRouter._();

  /// 首页仪表盘
  static const String dashboard = '/#/';

  /// 视频链接解析页面
  static const String movie = '/#/movie';

  /// 直播间搜索页面
  static const String search = '/#/search';

  /// Cookie 管理父页面（包含子路由）
  static const String cookieRoot = '/#/cookie';

  /// B站 Cookie 子页面
  static const String cookieBilibili = '/#/cookie/bilibili';

  /// 斗鱼 Cookie 子页面
  static const String cookieDouyu = '/#/cookie/douyu';

  /// 虎牙 Cookie 子页面
  static const String cookieHuya = '/#/cookie/huya';

  /// 抖音 Cookie 子页面
  static const String cookieDouyin = '/#/cookie/douyin';

  /// 快手 Cookie 子页面
  static const String cookieKuaishou = '/#/cookie/kuaishou';

  /// 网易CC Cookie 子页面
  static const String cookieCc = '/#/cookie/cc';

  /// WebDAV 配置页面
  static const String webdavSettings = '/#/webdav_settings';

  /// WebDAV 使用帮助页面
  static const String webdavHelp = '/#/webdav-help';

  /// 弹幕过滤关键词设置页
  static const String danmakuFilter = '/#/danmaku';

  /// 数据导入导出/备份同步页面
  static const String sync = '/#/sync';

  /// 系统日志查看、下载页面
  static const String log = '/#/log';

  /// 关于程序页面
  static const String about = '/#/about';

  /// 捐赠支持页面
  static const String donate = '/#/donate';

  /// 404 兜底重定向地址
  static const String fallback404 = '/#/';
}
