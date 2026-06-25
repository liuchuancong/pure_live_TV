import 'dart:async';
import 'dart:developer' as developer;
import 'package:pure_live/utils/event_bus.dart';
import 'package:pure_live/core/sites/sites.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pure_live/core/models/live_room/live_room.dart';
import 'package:pure_live/services/tag_management/live_tag.dart';
import 'package:pure_live/modules/favorite/model/favorite_state.dart';

part 'favorite_provider.g.dart';

@riverpod
class FavoriteNotifier extends _$FavoriteNotifier {
  StreamSubscription? _eventSubscription;
  Timer? _autoRefreshTimer;

  @override
  FavoriteState build() {
    ref.onDispose(() {
      _eventSubscription?.cancel();
      _autoRefreshTimer?.cancel();
    });

    _listenEventBus();
    _setupRefreshStrategy();

    return _syncAndFilter(const FavoriteState());
  }

  void _listenEventBus() {
    _eventSubscription = EventBus.instance.listen('refresh_favorite_rooms', (data) {
      refreshData();
    });
  }

  void _setupRefreshStrategy() {
    _autoRefreshTimer?.cancel();
    final refreshState = SettingsService.to.refreshState;
    final bool isEnabled = refreshState.autoRefreshFavorite;
    final int interval = refreshState.autoRefreshInterval;

    if (isEnabled && interval > 0) {
      _autoRefreshTimer = Timer.periodic(Duration(minutes: interval), (timer) {
        refreshData();
      });
    }
  }

  void changeOnlineTab(int index) {
    state = _syncAndFilter(state.copyWith(tabOnlineIndex: index));
  }

  void changeSiteTab(int index) {
    state = _syncAndFilter(state.copyWith(tabSiteIndex: index));
  }

  void changeSelectedTag(String tagId) {
    state = _syncAndFilter(state.copyWith(selectedTagId: tagId));
  }

  FavoriteState _syncAndFilter(FavoriteState currentState) {
    final favState = SettingsService.to.favState;
    final List<LiveRoom> roomsBase = List<LiveRoom>.from(favState.favoriteRooms);

    final onlineSrc = roomsBase.where((r) => r.liveStatus == LiveStatus.live && r.isRecord == false).toList();
    final offline = roomsBase.where((r) => r.liveStatus != LiveStatus.live).toList();
    final replaySrc = roomsBase.where((r) => r.liveStatus == LiveStatus.live && r.isRecord == true).toList();

    final List<LiveRoom> online = onlineSrc.map((room) {
      return room.copyWith(watching: int.tryParse(room.watching)?.toString() ?? '0');
    }).toList();

    final List<LiveRoom> replay = replaySrc.map((room) {
      return room.copyWith(watching: int.tryParse(room.watching)?.toString() ?? '0');
    }).toList();

    final tagState = SettingsService.to.tagState;
    final tagController = SettingsService.to.tag;

    int getRoomTagScore(LiveRoom room) {
      final List<String> ids = tagController.getTagsForRoom(room);
      if (ids.isEmpty) return 0;
      int highest = 0;
      const maxScore = 1000000;
      for (var id in ids) {
        final idx = tagState.tags.indexWhere((t) => id == t.id);
        if (idx != -1) {
          final tag = tagState.tags[idx];
          final score = maxScore - tag.order * 100;
          if (score > highest) highest = score;
        }
      }
      return highest;
    }

    int sortRooms(LiveRoom a, LiveRoom b) {
      final int watchA = int.tryParse(a.watching) ?? 0;
      final int watchB = int.tryParse(b.watching) ?? 0;

      if (currentState.selectedTagId == 'all') {
        return watchB.compareTo(watchA);
      }
      int sa = getRoomTagScore(a);
      int sb = getRoomTagScore(b);
      if (sa != sb) return sb.compareTo(sa);
      return watchB.compareTo(watchA);
    }

    online.sort(sortRooms);
    replay.sort(sortRooms);

    final currentAvailableSites = Sites().availableSites(containsAll: true);
    final List<LiveTag> visibleTagsList = [];

    if (currentState.tabSiteIndex >= 0 && currentState.tabSiteIndex < currentAvailableSites.length) {
      final activeSite = currentAvailableSites[currentState.tabSiteIndex];
      List<LiveRoom> target = switch (currentState.tabOnlineIndex) {
        0 => online,
        1 => replay,
        2 => offline,
        _ => online,
      };

      final Set<String> tagIds = {};
      for (var room in target) {
        if (activeSite.id == Sites.allSite || room.platform.toUpperCase() == activeSite.id.toUpperCase()) {
          final ids = tagController.getTagsForRoom(room);
          tagIds.addAll(ids);
        }
      }

      final tags = tagState.tags.where((t) => tagIds.contains(t.id)).toList();
      tags.sort((a, b) => a.order.compareTo(b.order));
      visibleTagsList.addAll(tags);
    }

    return currentState.copyWith(
      onlineRooms: online,
      offlineRooms: offline,
      replayRooms: replay,
      visibleTags: visibleTagsList,
    );
  }

  List<LiveRoom> getFilteredRooms() {
    List<LiveRoom> source = switch (state.tabOnlineIndex) {
      0 => state.onlineRooms,
      1 => state.replayRooms,
      2 => state.offlineRooms,
      _ => state.onlineRooms,
    };

    final currentAvailableSites = Sites().availableSites(containsAll: true);
    if (state.tabSiteIndex < 0 || state.tabSiteIndex >= currentAvailableSites.length) {
      return [];
    }

    final activeSite = currentAvailableSites[state.tabSiteIndex];
    if (activeSite.id != Sites.allSite) {
      source = source.where((room) => room.platform.toUpperCase() == activeSite.id.toUpperCase()).toList();
    }

    if (state.selectedTagId == 'all') {
      return source;
    }

    final tagController = SettingsService.to.tag;
    return source.where((room) {
      final List<String> ids = tagController.getTagsForRoom(room);
      return ids.contains(state.selectedTagId);
    }).toList();
  }

  Future<void> refreshData() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true);

    final favState = SettingsService.to.favState;
    final List<LiveRoom> source = List<LiveRoom>.from(favState.favoriteRooms);
    final currentAvailableSites = Sites().availableSites(containsAll: true);
    final refreshState = SettingsService.to.refreshState;

    List<LiveRoom> valid = source;
    if (state.tabSiteIndex >= 0 && state.tabSiteIndex < currentAvailableSites.length) {
      final activeSite = currentAvailableSites[state.tabSiteIndex];
      if (activeSite.id != Sites.allSite) {
        valid = source.where((r) => r.platform.toUpperCase() == activeSite.id.toUpperCase()).toList();
      }
    }

    final tagController = SettingsService.to.tag;
    if (state.selectedTagId != 'all') {
      valid = valid.where((room) {
        final List<String> ids = tagController.getTagsForRoom(room);
        return ids.contains(state.selectedTagId);
      }).toList();
    }

    final validRooms = valid.where((r) => r.platform.isNotEmpty).toList();
    if (validRooms.isEmpty) {
      state = _syncAndFilter(state.copyWith(isLoading: false));
      EventBus.instance.emit('refresh_favorite_finish', true);
      return;
    }

    final int batch = refreshState.maxConcurrentRefresh > 0 ? refreshState.maxConcurrentRefresh : 5;

    for (int i = 0; i < validRooms.length; i += batch) {
      final end = i + batch > validRooms.length ? validRooms.length : i + batch;
      final batchRooms = validRooms.sublist(i, end);

      try {
        final futures = batchRooms
            .map((room) => Sites.of(room.platform).liveSite.getRoomDetail(roomId: room.roomId, platform: room.platform))
            .toList();
        final results = await Future.wait(futures);

        for (var updated in results) {
          SettingsService.to.fav.updateRoom(updated);
        }
      } catch (e) {
        developer.log('Error refreshing room details in riverpod: $e');
      }
    }

    state = _syncAndFilter(state.copyWith(isLoading: false));
    EventBus.instance.emit('refresh_favorite_finish', true);
  }
}
