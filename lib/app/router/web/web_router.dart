class WebRemoteRouter {
  WebRemoteRouter._();

  /// Dashboard
  static const String dashboard = '/#/';

  /// Video link resolver
  static const String movie = '/#/movie';

  /// Live room search
  static const String search = '/#/search';

  /// Danmaku keyword filter settings
  static const String danmakuFilter = '/#/danmaku';

  /// Tag management
  static const String tags = '/#/tags';

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
