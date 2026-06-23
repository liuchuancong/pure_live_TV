import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/global/app_path_manager.dart';
import 'package:pure_live/services/db_service/db_controller.dart';
import 'package:pure_live/core/sites/iptv/services/epg_sync_engine.dart';
import 'package:pure_live/core/sites/iptv/services/iptv_sync_engine.dart';
import 'package:pure_live/core/sites/iptv/services/epg_import_manager.dart';
import 'package:pure_live/core/sites/iptv/services/iptv_import_manager.dart';

class AutoSyncScheduler {
  final Ref ref;
  AutoSyncScheduler(this.ref);

  Future<void> checkAndExecuteAutoSync() async {
    final settings = 
    if (!settings.isAutoSyncEnabled) return;

    final db = ref.read(dbServiceProvider).db;
    final Duration checkInterval = Duration(hours: settings.autoSyncHoursInterval);

    try {
      final expiredPlaylists = await db.getExpiredNetworkProviders(checkInterval);
      for (var playlist in expiredPlaylists) {
        await IptvSyncEngine.instance.syncPlaylist(playlist);
      }
      final expiredEpgs = await db.getExpiredEpgSources(checkInterval);
      for (var epg in expiredEpgs) {
        await EpgSyncEngine.instance.updateEpgCache(epg, forceUpdate: true, showTips: false);
      }
    } catch (e) {
      log("Auto sync background task working failed: $e");
    }
  }

  Future<void> loadHotResources() async {
    const iptvUrl = 'https://iptv-org.github.io/iptv/countries/cn.m3u';
    await IptvImportManager().importFromNetworkUrl(
      iptvUrl,
      AppPathManager.iptvHotFile,
      forceUpdate: true,
      showTips: false,
      isHot: true,
    );
  }

  Future<void> loadDefaultEpgResources() async {
    const epgSource = 'https://epg.zsdc.eu.org/t.xml.gz';
    await EpgImportManager().importFromNetworkUrl(
      epgSource,
      AppPathManager.iptvHotFile,
      forceUpdate: true,
      showTips: false,
    );

    final settingsNotifier = ref.read(iptvSettingsProvider.notifier);
    if (settingsNotifier.state.selectedSourceId.isEmpty) {
      final db = ref.read(dbServiceProvider).db;
      final epgSources = await db.getAllEpgSources();
      if (epgSources.isNotEmpty) {
        final activeSource = epgSources.first;
        // 假设通过 Notifier 更新设置
        settingsNotifier.updateSelectedSource(activeSource.id, activeSource.name);
      }
    }
  }
}

final autoSyncSchedulerProvider = Provider<AutoSyncScheduler>((ref) {
  return AutoSyncScheduler(ref);
});
