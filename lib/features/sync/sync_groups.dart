/// 同步分组。
///
/// 分组是面向用户的，落库时映射到 [BackupController.knownSections] 的分区名，
/// 这样收发两端都用同一套备份快照，不需要另写序列化。
enum SyncGroup {
  /// 关注列表 + 弹幕屏蔽词。
  ///
  /// 两者在 `FavoriteSettingsModel` 里是同一份数据（`favoriteRooms` /
  /// `shieldList` 同属一个 freezed 模型），无法拆成两个分区，所以合成一组。
  account,

  /// 主题模式、加载动画样式、TV 配色板。
  theme,

  /// 背景/壁纸。
  background,

  /// 弹幕外观（字号/速度/区域/透明度/描边…）。
  danmaku,

  /// 播放器内核、画面、页面、刷新等其余设置。
  player,

  /// 观看历史。
  history,

  /// Cookie / WebDAV 凭据（敏感，默认不选）。
  sensitive,
}

/// 分组定义与分区映射。
class SyncGroups {
  SyncGroups._();

  static const Map<SyncGroup, List<String>> sections = <SyncGroup, List<String>>{
    SyncGroup.account: <String>['favorite'],
    SyncGroup.theme: <String>['theme', 'tvTheme'],
    SyncGroup.background: <String>['background'],
    SyncGroup.danmaku: <String>['danmaku'],
    SyncGroup.player: <String>[
      'app',
      'player',
      'volume',
      'font',
      'page',
      'refresh',
      'proxy',
      'iptv',
      'exit',
      'startup',
      'log',
      'tags',
    ],
    SyncGroup.history: <String>['history'],
    SyncGroup.sensitive: <String>['cookie', 'webdav'],
  };

  /// 默认勾选：除敏感凭据外全选（凭据要走 https 或在可信网络里手动打开）。
  static const Set<SyncGroup> defaultSelection = <SyncGroup>{
    SyncGroup.account,
    SyncGroup.theme,
    SyncGroup.background,
    SyncGroup.danmaku,
    SyncGroup.player,
    SyncGroup.history,
  };

  static const List<SyncGroup> displayOrder = <SyncGroup>[
    SyncGroup.account,
    SyncGroup.theme,
    SyncGroup.background,
    SyncGroup.danmaku,
    SyncGroup.player,
    SyncGroup.history,
    SyncGroup.sensitive,
  ];

  static List<String> sectionsOf(Iterable<SyncGroup> groups) {
    final result = <String>[];
    for (final group in groups) {
      for (final section in sections[group] ?? const <String>[]) {
        if (!result.contains(section)) result.add(section);
      }
    }
    return result;
  }
}
