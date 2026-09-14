import 'package:pure_live/shared/data/db_service.dart';
import 'package:pure_live/shared/utils/event_bus.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:pure_live/features/iptv/services/epg_sync_engine.dart';
import 'package:pure_live/services/background_task/background_task_model.dart';
import 'package:pure_live/services/background_task/background_task_service.dart';
import 'package:pure_live/features/iptv/services/auto_sync_scheduler.dart';

/// 内置后台任务的执行体登记表。
///
/// 这是「调度框架」和「业务实现」之间的唯一接缝：框架不认识 IPTV、EPG、壁纸，
/// 只认识 [BackgroundTaskExecutor]；业务侧也不用知道心跳、退避、去重怎么做的。
///
/// 对应扩展 `background.js` 末尾那一串 `chrome.alarms.onAlarm.addListener` 的
/// 分支：按 alarm 名分发到各自的处理函数。
class BackgroundTaskRegistry {
  BackgroundTaskRegistry._();

  /// 把全部内置任务注册进调度器。
  static void registerDefaults() {
    BackgroundTaskService.instance.registerAll(<BackgroundTaskKind, BackgroundTaskExecutor>{
      BackgroundTaskKind.iptvAutoSync: _syncIptv,
      BackgroundTaskKind.epgAutoSync: _syncEpg,
      BackgroundTaskKind.iptvHotResource: _loadHotResource,
      BackgroundTaskKind.epgDefaultResource: _loadDefaultEpg,
      BackgroundTaskKind.favoriteRefresh: _refreshFavorites,
      BackgroundTaskKind.wallpaperRotate: _rotateWallpaper,
    });
  }

  // ---------------------------------------------------------------------------
  // IPTV / EPG
  // ---------------------------------------------------------------------------

  /// IPTV 播放列表同步。
  ///
  /// 复用 [AutoSyncScheduler.checkAndExecuteAutoSync]，它自己会看「自动同步」开关和
  /// 用户在 IPTV 设置里选的间隔；这里只是把它从「打开 IPTV 页才可能被调用一次」
  /// 变成「应用在跑就按周期检查」。没有任何过期源时返回 true（无事可做不算失败）。
  static Future<bool> _syncIptv() async {
    final settings = SettingsService.to.iptv;
    if (!settings.isAutoSyncEnabled.v) return true;

    final db = DbService.to.db;
    final checkInterval = Duration(hours: settings.normalizeCurrentAutoSyncHours());
    final expiredProviders = await db.getExpiredNetworkProviders(checkInterval);
    final expiredEpgs = await db.getExpiredEpgSources(checkInterval);
    if (expiredProviders.isEmpty && expiredEpgs.isEmpty) return true;

    await AutoSyncScheduler.instance.checkAndExecuteAutoSync();
    return true;
  }

  /// EPG 节目单同步：只跑过期的那几个源。
  static Future<bool> _syncEpg() async {
    final settings = SettingsService.to.iptv;
    if (!settings.isAutoSyncEnabled.v) return true;

    final db = DbService.to.db;
    final checkInterval = Duration(hours: settings.normalizeCurrentAutoSyncHours());
    final expired = await db.getExpiredEpgSources(checkInterval);
    if (expired.isEmpty) return true;

    var allOk = true;
    for (final epg in expired) {
      final ok = await EpgSyncEngine.instance.updateEpgCache(epg, forceUpdate: true, showTips: false);
      // 单个源失败不打断其余源，但整体上报为失败以便退避重试。
      if (!ok) allOk = false;
    }
    return allOk;
  }

  // ---------------------------------------------------------------------------
  // 资源更新
  // ---------------------------------------------------------------------------

  static Future<bool> _loadHotResource() {
    return _runResourceUpdate(() => AutoSyncScheduler.instance.loadHotResources());
  }

  static Future<bool> _loadDefaultEpg() {
    return _runResourceUpdate(() => AutoSyncScheduler.instance.loadDefaultEpgResources());
  }

  /// [IptvResourceLoadGate] 会把并发请求合并成一个，失败也不缓存；
  /// 这里只需要把「抛异常」翻译成 false。
  static Future<bool> _runResourceUpdate(Future<void> Function() operation) async {
    try {
      await operation();
      return true;
    } catch (_) {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // 关注列表
  // ---------------------------------------------------------------------------

  /// 关注列表刷新。
  ///
  /// 只发事件：真正持有房间数据的是关注页的 Riverpod 通知器，任务层不做数据搬运，
  /// 界面没打开时这条事件没有订阅者，等于什么也不做（也就不会产生无谓的请求）。
  static Future<bool> _refreshFavorites() async {
    if (!SettingsService.to.refresh.autoRefreshFavoriteValue.v) return true;
    EventBus.instance.emit('refresh_favorite_rooms', true);
    return true;
  }

  // ---------------------------------------------------------------------------
  // 壁纸
  // ---------------------------------------------------------------------------

  /// 在线壁纸轮换：复用 `BackgroundController.rotateWallpaperIfNeeded`，
  /// 由它自己判断「自动换壁纸」开关和间隔。
  static Future<bool> _rotateWallpaper() {
    return SettingsService.to.bg.rotateWallpaperIfNeeded();
  }
}
