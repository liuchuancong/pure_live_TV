import 'dart:async';
import 'dart:developer' as developer;
import 'package:pure_live/exports/common_export.dart';
import 'package:pure_live/services/index.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pure_live/features/favorite/model/favorite_state.dart';

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

    // A restore asks for one verification pass over the imported list; the event
    // above only reaches this provider when the page is already up (see
    // FavoriteRoomController.importFromJson).
    if (ref.read(favoriteRoomControllerProvider.notifier).consumeStatusRefreshRequest()) {
      Future<void>.microtask(refreshData);
    }

    final favState = ref.watch(favoriteRoomControllerProvider);
    // Rebuild when the audience display preference or the grid density change.
    final appState = ref.watch(appSettingsControllerProvider);
    return _syncAndFilter(const FavoriteState(), favState).copyWith(
      denseLayout: appState.enableDenseFavorites,
    );
  }

  void _listenEventBus() {
    _eventSubscription = EventBus.instance.listen('refresh_favorite_rooms', (data) {
      refreshData();
    });
  }

  void _setupRefreshStrategy() {
    _autoRefreshTimer?.cancel();
    final refreshState = ref.read(refreshConfigControllerProvider);
    final bool isEnabled = refreshState.autoRefreshFavorite;
    final int interval = refreshState.autoRefreshInterval;

    if (isEnabled && interval > 0) {
      _autoRefreshTimer = Timer.periodic(Duration(minutes: interval), (timer) {
        refreshData();
      });
    }
  }

  void changeOnlineTab(int index) {
    final favState = ref.read(favoriteRoomControllerProvider);
    state = _syncAndFilter(state.copyWith(tabOnlineIndex: index), favState);
  }

  void changeSiteTab(int index) {
    final favState = ref.read(favoriteRoomControllerProvider);
    state = _syncAndFilter(state.copyWith(tabSiteIndex: index), favState);
  }

  void changeSelectedTag(String tagId) {
    final favState = ref.read(favoriteRoomControllerProvider);
    state = _syncAndFilter(state.copyWith(selectedTagId: tagId), favState);
  }

  FavoriteState _syncAndFilter(FavoriteState currentState, FavoriteSettingsModel favState) {
    final appState = ref.read(appSettingsControllerProvider);
    final List<LiveRoom> roomsBase = List<LiveRoom>.from(favState.favoriteRooms);

    // The buckets follow the model's own predicates instead of comparing
    // `liveStatus == live` by hand:
    //
    // * a platform that has not answered yet persists `unknown` together with
    //   `status`, and `isLiveNow` is what treats that as 在线 — reading the enum
    //   directly filed such a followed room under 离线;
    // * a replay (`isRecord`, or a platform-reported `LiveStatus.replay` such as
    //   Huya's REPLAY and Weibo's replay state) belongs to 回放, not 离线;
    // * 离线 therefore only holds cards that are not playable at all, which is
    //   exactly the mobile reference's `!isPlayableNow` bucket.
    final onlineSrc = roomsBase.where((r) => r.isLiveNow && r.isRecord == false).toList();
    final replaySrc = roomsBase.where((r) => r.isRecord || r.effectiveLiveStatus == LiveStatus.replay).toList();
    final offline = roomsBase.where((r) => !r.isPlayableNow).toList();

    final List<LiveRoom> online = onlineSrc.map((room) {
      return room.copyWith(watching: int.tryParse(room.watching)?.toString() ?? '0');
    }).toList();

    final List<LiveRoom> replay = replaySrc.map((room) {
      return room.copyWith(watching: int.tryParse(room.watching)?.toString() ?? '0');
    }).toList();

    final tagState = ref.read(tagManagementControllerProvider);
    final tagController = ref.read(tagManagementControllerProvider.notifier);

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

    // Decorate-sort-undecorate: the comparators below used to recompute the
    // tag score and the audience rank key for both rooms on EVERY comparison
    // (n·log n × ~15 string parses + RegExp allocations per key); memoizing
    // per room turns the sort into plain integer/enum comparisons.
    final tagScoreMemo = <String, int>{};
    int tagScoreOf(LiveRoom room) => tagScoreMemo[room.identityKey] ??= getRoomTagScore(room);

    final audienceKeyMemo = <String, AudienceRankKey>{};
    AudienceRankKey audienceKeyOf(LiveRoom room) =>
        audienceKeyMemo[room.identityKey] ??=
        room.audienceRankKey(
          preferRealOnline: appState.preferRealOnlineCounts,
          // Capability-aware: a platform that only publishes heat must keep
          // ranking by that value even when concurrent mode is on.
          platformEnabled:
              LiveRoom.audienceCapabilityFor(room.normalizedPlatformId).supportsConcurrentOnline &&
              appState.realOnlinePlatforms.contains(room.normalizedPlatformId),
        );

    int byAudience(LiveRoom a, LiveRoom b) {
      final left = audienceKeyOf(a);
      final right = audienceKeyOf(b);
      final metricOrder = right.metricPriority.compareTo(left.metricPriority);
      if (metricOrder != 0) return metricOrder;
      final valueOrder = right.value.compareTo(left.value);
      if (valueOrder != 0) return valueOrder;
      return a.identityKey.compareTo(b.identityKey);
    }

    int sortRooms(LiveRoom a, LiveRoom b) {
      if (currentState.selectedTagId == 'all') {
        return byAudience(a, b);
      }
      final int sa = tagScoreOf(a);
      final int sb = tagScoreOf(b);
      if (sa != sb) return sb.compareTo(sa);
      return byAudience(a, b);
    }

    online.sort(sortRooms);
    replay.sort(sortRooms);

    final currentAvailableSites = Sites().availableSites(containsAll: true);
    final List<LiveTag> visibleTagsList = [];

    // Legacy builds stored tags by room number alone; move them onto
    // platform-scoped identities now that the followed rooms are known.
    tagController.migrateLegacyRoomTagKeys([...online, ...replay, ...offline]);

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
    final List<LiveRoom> source = switch (state.tabOnlineIndex) {
      0 => state.onlineRooms,
      1 => state.replayRooms,
      2 => state.offlineRooms,
      _ => state.onlineRooms,
    };

    return _inPageScope(source);
  }

  /// The followed rooms that are live right now, in the scope the page shows
  /// (platform tab and tag).
  ///
  /// This is what the player takes as its playlist: a room opened from this page
  /// is switched with up/down against the 已开播 list, so opening a replay or an
  /// offline card still moves between rooms that are actually live.
  List<LiveRoom> getLiveRooms() => _inPageScope(state.onlineRooms);

  /// Applies the page's platform tab and tag filter to [source].
  List<LiveRoom> _inPageScope(List<LiveRoom> source) {
    final currentAvailableSites = Sites().availableSites(containsAll: true);
    if (state.tabSiteIndex < 0 || state.tabSiteIndex >= currentAvailableSites.length) {
      return [];
    }

    List<LiveRoom> rooms = source;
    final activeSite = currentAvailableSites[state.tabSiteIndex];
    if (activeSite.id != Sites.allSite) {
      rooms = rooms.where((room) => room.platform.toUpperCase() == activeSite.id.toUpperCase()).toList();
    }

    if (state.selectedTagId == 'all') {
      return rooms;
    }

    final tagController = ref.read(tagManagementControllerProvider.notifier);
    return rooms.where((room) {
      final List<String> ids = tagController.getTagsForRoom(room);
      return ids.contains(state.selectedTagId);
    }).toList();
  }

  /// One card refresh may not hold a whole batch hostage.
  static const Duration _roomRefreshTimeout = Duration(seconds: 10);

  /// Refreshes one followed room, or returns `null` when the platform could not
  /// be asked.
  ///
  /// [fetchRoomDetailForRefresh] prefers the adapter's cheap metadata path and
  /// lets its failures propagate, which is what this guard needs: the
  /// presentation-oriented `LiveSite.getRoomDetail` answers an error with an
  /// offline-looking fallback room, so a single hiccup used to rewrite a live
  /// followed room as 离线. Returning `null` keeps the stored snapshot (status
  /// included) instead of publishing a guess.
  Future<LiveRoom?> _refreshRoom(LiveRoom room) async {
    try {
      final refreshed = await fetchRoomDetailForRefresh(
        site: Sites.of(room.platform).liveSite,
        roomId: room.roomId,
        platform: room.platform,
      ).timeout(_roomRefreshTimeout);

      // Some platforms answer with a different canonical id (Douyin reports the
      // web rid, for example). Re-binding keeps the identity that the merge
      // target and the local tags are keyed by.
      return refreshed.copyWith(roomId: room.roomId, platform: room.platform);
    } catch (e) {
      developer.log('Favorite room refresh failed for ${room.identityKey}: $e');
      return null;
    }
  }

  Future<void> refreshData() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true);

    final favState = ref.read(favoriteRoomControllerProvider);
    final List<LiveRoom> source = List<LiveRoom>.from(favState.favoriteRooms);
    final currentAvailableSites = Sites().availableSites(containsAll: true);
    final refreshState = ref.read(refreshConfigControllerProvider);

    List<LiveRoom> valid = source;
    if (state.tabSiteIndex >= 0 && state.tabSiteIndex < currentAvailableSites.length) {
      final activeSite = currentAvailableSites[state.tabSiteIndex];
      if (activeSite.id != Sites.allSite) {
        valid = source.where((r) => r.platform.toUpperCase() == activeSite.id.toUpperCase()).toList();
      }
    }

    final tagController = ref.read(tagManagementControllerProvider.notifier);
    if (state.selectedTagId != 'all') {
      valid = valid.where((room) {
        final List<String> ids = tagController.getTagsForRoom(room);
        return ids.contains(state.selectedTagId);
      }).toList();
    }

    final validRooms = valid.where((r) => r.platform.isNotEmpty).toList();
    if (validRooms.isEmpty) {
      state = _syncAndFilter(state.copyWith(isLoading: false), favState);
      EventBus.instance.emit('refresh_favorite_finish', true);
      return;
    }

    final int batch = refreshState.maxConcurrentRefresh > 0 ? refreshState.maxConcurrentRefresh : 5;

    for (int i = 0; i < validRooms.length; i += batch) {
      final end = i + batch > validRooms.length ? validRooms.length : i + batch;
      final batchRooms = validRooms.sublist(i, end);

      final futures = batchRooms.map(_refreshRoom).toList();
      final results = await Future.wait(futures);

      ref.read(favoriteRoomControllerProvider.notifier).updateRooms(
            results.whereType<LiveRoom>().toList(),
          );
    }

    final finalFavState = ref.read(favoriteRoomControllerProvider);
    state = _syncAndFilter(state.copyWith(isLoading: false), finalFavState);
    EventBus.instance.emit('refresh_favorite_finish', true);
  }
}
