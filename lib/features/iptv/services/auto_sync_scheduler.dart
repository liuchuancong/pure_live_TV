import 'dart:developer';

import 'package:pure_live/shared/platform/index.dart';
import 'package:pure_live/app/bootstrap/index.dart';
import 'package:pure_live/features/iptv/services/iptv_sync_engine.dart';
import 'package:pure_live/features/iptv/services/iptv_import_manager.dart';

import 'package:meta/meta.dart';
import 'package:pure_live/services/settings/settings.dart';
class AutoSyncScheduler {
  static final AutoSyncScheduler instance = AutoSyncScheduler._internal();
  AutoSyncScheduler._internal();

  final IptvResourceLoadGate _hotResourcesGate = IptvResourceLoadGate();

  Future<void> checkAndExecuteAutoSync() async {
    if (!SettingsService.to.iptv.isAutoSyncEnabled.v) return;

    final db = DbService.to.db;
    final int hoursInterval = SettingsService.to.iptv.normalizeCurrentAutoSyncHours();
    final Duration checkInterval = Duration(hours: hoursInterval);

    try {
      final expiredPlaylists = await db.getExpiredNetworkProviders(checkInterval);
      for (var playlist in expiredPlaylists) {
        await IptvSyncEngine.instance.syncPlaylist(playlist);
      }
    } catch (e) {
      log("Auto sync background task working failed: $e");
    }
  }

  Future<void> loadHotResources() => _hotResourcesGate.run(_loadHotResources);

  Future<void> _loadHotResources() async {
    // The hot list's subscription URL is user-manageable in settings -> IPTV; this
    // falls back to the built-in iptv-org default when no override is set.
    final iptvUrl = SettingsService.to.iptv.effectiveHotResourceUrl;
    await IptvImportManager().importFromNetworkUrl(
      iptvUrl,
      AppPathManager.iptvHotFile,
      forceUpdate: true,
      showTips: false,
      isHot: true,
    );
  }
}

/// Coalesces simultaneous feature-entry requests into one import without
/// caching a failure or a completed operation forever.
@visibleForTesting
class IptvResourceLoadGate {
  Future<void>? _inFlight;

  Future<void> run(Future<void> Function() operation) {
    final inFlight = _inFlight;
    if (inFlight != null) return inFlight;

    late final Future<void> tracked;
    tracked = Future<void>.sync(operation).whenComplete(() {
      if (identical(_inFlight, tracked)) _inFlight = null;
    });
    _inFlight = tracked;
    return tracked;
  }
}
