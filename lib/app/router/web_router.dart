class WebRemoteRouter {
  WebRemoteRouter._();

  /// Dashboard
  static const String dashboard = '/#/';

  /// Video link resolver
  static const String movie = '/#/movie';

  /// Live room search
  static const String search = '/#/search';

  /// Cookie management parent, holds the per-platform children
  static const String cookieRoot = '/#/cookie';

  /// Bilibili cookie
  static const String cookieBilibili = '/#/cookie/bilibili';

  /// Douyu cookie
  static const String cookieDouyu = '/#/cookie/douyu';

  /// Huya cookie
  static const String cookieHuya = '/#/cookie/huya';

  /// Douyin cookie
  static const String cookieDouyin = '/#/cookie/douyin';

  /// Kuaishou cookie
  static const String cookieKuaishou = '/#/cookie/kuaishou';

  /// NetEase CC cookie
  static const String cookieCc = '/#/cookie/cc';

  /// Danmaku keyword filter settings
  static const String danmakuFilter = '/#/danmaku';

  /// Import, export and backup sync
  static const String sync = '/#/sync';

  /// Log viewer and download
  static const String log = '/#/log';

  /// About
  static const String about = '/#/about';

  /// Donations
  static const String donate = '/#/donate';

  /// Fallback target for unknown paths
  static const String fallback404 = '/#/';
}
