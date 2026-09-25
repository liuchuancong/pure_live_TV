import 'dart:async';
import 'dart:developer' as developer;
import 'package:pure_live/services/index.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pure_live/features/favorite/model/favorite_state.dart';

part 'favorite_provider.g.dart';

/// The platform tabs a follower sees: "All" plus the platforms that actually hold
/// a followed room, in the configured platform order.
///
/// The mobile reference's `favoriteSitesForRooms` rule. A platform nobody
/// follows is not a tab: listing every available platform buried the one or two
/// the user follows among empty tabs, and an empty tab has no rooms — and so no
/// tags — to show or filter by.
List<Site> favoriteSitesForRooms(Iterable<LiveRoom> rooms) {
  final List<Site> available = Sites().availableSites(containsAll: true);
  final Set<String> followed = <String>{
    for (final LiveRoom room in rooms)
      if (room.normalizedPlatformId.isNotEmpty) room.normalizedPlatformId,
  };
  return <Site>[
    for (final Site site in available)
      if (site.id == Sites.allSite || followed.contains(site.id.trim().toLowerCase())) site,
  ];
}

/// The tab index to show for [selectedSiteId]: where that platform sits in
/// [siteIds], or [fallback] clamped into range once it is gone (its last room was
/// unfollowed, so it is not a tab any more).
int resolveFavoriteSiteIndex({required List<String> siteIds, required String selectedSiteId, required int fallback}) {
  if (siteIds.isEmpty) return 0;
  final int selected = siteIds.indexOf(selectedSiteId);
  return selected >= 0 ? selected : fallback.clamp(0, siteIds.length - 1);
}

@riverpod
class FavoriteNotifier extends _$FavoriteNotifier {
  StreamSubscription? _eventSubscription;
  Timer? _autoRefreshTimer;

  /// The platform whose tab the page shows, by id.
  ///
  /// The tab list grows and shrinks with the followed rooms, so the selection is
  /// remembered as an id and re-resolved on every rebuild: an index alone pointed
  /// at whatever platform slid into the position of one that just lost its last
  /// room.
  String _selectedSiteId = Sites.allSite;

  /// The status tab (0 live, 1 replay, 2 offline) the page shows.
  ///
  /// Held as a field for the same reason as [_selectedSiteId], and that matters
  /// more here: this notifier rebuilds on every favourite change - a room being
  /// followed, a player write-back - and starting each rebuild from a blank state
  /// dropped the viewer back onto the live tab. Under a covered page that also
  /// switched the grid out from under them, so returning from the player landed
  /// on a tab whose core had never been re-sliced.
  int _tabOnlineIndex = 0;

  /// The tag the page filters by, held for the same reason as [_tabOnlineIndex].
  String _selectedTagId = 'all';

  /// The platform tab the page shows, for callers that key their own state by it.
  String get activeSiteId => _selectedSiteId;

  /// The status tab the page shows.
  int get activeTabIndex => _tabOnlineIndex;

  /// The platform tabs the page draws. See [favoriteSitesForRooms].
  List<Site> get siteTabs => favoriteSitesForRooms(ref.read(favoriteRoomControllerProvider).favoriteRooms);

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
      Future<void>.microtask(() => refreshData(scopeAll: true));
    }

    final favState = ref.watch(favoriteRoomControllerProvider);
    // Rebuild when the audience display preference or the grid density change.
    final appState = ref.watch(appSettingsControllerProvider);
    return _syncAndFilter(const FavoriteState(), favState).copyWith(denseLayout: appState.enableDenseFavorites);
  }

  void _listenEventBus() {
    _eventSubscription = EventBus.instance.listen('refresh_favorite_rooms', (data) {
      // data == true marks the import/restore verification pass: verify every
      // followed room, not just the slice the page is showing.
      refreshData(scopeAll: data == true);
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
    _tabOnlineIndex = index;
    final favState = ref.read(favoriteRoomControllerProvider);
    state = _syncAndFilter(state, favState);
  }

  void changeSiteTab(int index) {
    final List<Site> sites = siteTabs;
    if (index >= 0 && index < sites.length) _selectedSiteId = sites[index].id;
    final favState = ref.read(favoriteRoomControllerProvider);
    state = _syncAndFilter(state.copyWith(tabSiteIndex: index), favState);
  }

  void changeSelectedTag(String tagId) {
    _selectedTagId = tagId;
    final favState = ref.read(favoriteRoomControllerProvider);
    state = _syncAndFilter(state, favState);
  }

  FavoriteState _syncAndFilter(FavoriteState currentState, FavoriteSettingsModel favState) {
    final appState = ref.read(appSettingsControllerProvider);
    final List<LiveRoom> roomsBase = List<LiveRoom>.from(favState.favoriteRooms);

    // The buckets follow the model's own predicates instead of comparing
    // `liveStatus == live` by hand:
    //
    // * a platform that has not answered yet persists `unknown` together with
    //   `status`, and `isLiveNow` is what treats that as live - reading the enum
    //   directly filed such a followed room under offline;
    // * a replay (`isRecord`, or a platform-reported `LiveStatus.replay` such as
    //   Huya's REPLAY and Weibo's replay state) belongs to replay, not offline;
    // * offline therefore only holds cards that are not playable at all, which is
    //   the same as the mobile reference's `!isPlayableNow` bucket.
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

    // The platform tabs, and the one actually shown. Resolving by id keeps the
    // selection on the same platform while the tab list grows and shrinks.
    final List<Site> sites = favoriteSitesForRooms(roomsBase);
    final int siteIndex = resolveFavoriteSiteIndex(
      siteIds: <String>[for (final Site site in sites) site.id],
      selectedSiteId: _selectedSiteId,
      fallback: currentState.tabSiteIndex,
    );
    final Site? activeSite = sites.isEmpty ? null : sites[siteIndex];
    _selectedSiteId = activeSite?.id ?? Sites.allSite;

    // A tag deleted while it was the active filter must not keep filtering
    // invisibly: the reference drops the same selection. The surviving selection
    // is written back to the field, so the reset survives a rebuild too.
    _selectedTagId = _selectedTagId == 'all' || tagState.tags.any((tag) => tag.id == _selectedTagId)
        ? _selectedTagId
        : 'all';

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
    AudienceRankKey audienceKeyOf(LiveRoom room) => audienceKeyMemo[room.identityKey] ??= room.audienceRankKey(
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
      if (_selectedTagId == 'all') {
        return byAudience(a, b);
      }
      final int sa = tagScoreOf(a);
      final int sb = tagScoreOf(b);
      if (sa != sb) return sb.compareTo(sa);
      return byAudience(a, b);
    }

    online.sort(sortRooms);
    replay.sort(sortRooms);

    final List<LiveTag> visibleTagsList = [];

    // Legacy builds stored tags by room number alone; move them onto
    // platform-scoped identities now that the followed rooms are known.
    tagController.migrateLegacyRoomTagKeys([...online, ...replay, ...offline]);

    // The tag strip: the tags of the rooms the page is showing — the selected
    // status list, on the selected platform — in the user's own tag order. Tags
    // no room on screen carries would filter to an empty grid.
    if (activeSite != null) {
      final List<LiveRoom> target = switch (_tabOnlineIndex) {
        0 => online,
        1 => replay,
        2 => offline,
        _ => online,
      };

      final Set<String> tagIds = {};
      for (final LiveRoom room in target) {
        if (activeSite.id == Sites.allSite || room.normalizedPlatformId == activeSite.id.trim().toLowerCase()) {
          tagIds.addAll(tagController.getTagsForRoom(room));
        }
      }

      final List<LiveTag> tags = tagState.tags.where((tag) => tagIds.contains(tag.id)).toList();
      tags.sort((a, b) => a.order.compareTo(b.order));
      visibleTagsList.addAll(tags);
    }

    // A tag the shown list does not use must not keep filtering invisibly: the
    // selection is re-resolved against the tags actually on screen, so a stale
    // one (its chips are gone from the strip) cannot leave the grid showing a
    // single room with nothing on screen explaining why.
    if (_selectedTagId != 'all' && !visibleTagsList.any((tag) => tag.id == _selectedTagId)) {
      _selectedTagId = 'all';
    }

    return currentState.copyWith(
      tabSiteIndex: siteIndex,
      tabOnlineIndex: _tabOnlineIndex,
      selectedTagId: _selectedTagId,
      onlineRooms: online,
      offlineRooms: offline,
      replayRooms: replay,
      visibleTags: visibleTagsList,
    );
  }

  /// The rooms of one status tab, scoped to a platform tab and a tag.
  ///
  /// The page's grids live in their own paging cores, one per tab/platform/tag
  /// combination, and each of them asks for its slice here. Asking for "the" slice
  /// instead - the one the page happens to be showing - left every other core with
  /// the pool it was last given, so a card that changed status stayed in its old
  /// group until the page was reopened.
  List<LiveRoom> roomsFor({required int tabIndex, required String siteId, required String tagId}) {
    final List<LiveRoom> source = switch (tabIndex) {
      1 => state.replayRooms,
      2 => state.offlineRooms,
      _ => state.onlineRooms,
    };

    return _scoped(source, siteId: siteId, tagId: tagId);
  }

  List<LiveRoom> getFilteredRooms() =>
      roomsFor(tabIndex: _tabOnlineIndex, siteId: _selectedSiteId, tagId: _selectedTagId);

  /// The followed rooms that are live right now, in the scope the page shows
  /// (platform tab and tag).
  List<LiveRoom> getLiveRooms() => _inPageScope(state.onlineRooms);

  /// The page's full room list in display order — live, then replay, then
  /// offline — scoped to the platform tab the page shows.
  ///
  /// This is what the player takes as its playlist: the playlist mirrors the
  /// source the room was opened from, so switching walks the same three status
  /// groups the page shows instead of only the live slice. A room opened from
  /// the replay or offline tab therefore moves through its own group first.
  List<LiveRoom> getPlaylistRooms() {
    LiveRoom normalizeAudience(LiveRoom room) =>
        room.copyWith(watching: int.tryParse(room.watching)?.toString() ?? '0');
    return [
      ..._inPageScope(state.onlineRooms).map(normalizeAudience),
      ..._inPageScope(state.replayRooms).map(normalizeAudience),
      ..._inPageScope(state.offlineRooms).map(normalizeAudience),
    ];
  }

  /// Applies the page's platform tab and tag filter to [source].
  List<LiveRoom> _inPageScope(List<LiveRoom> source) => _scoped(source, siteId: _selectedSiteId, tagId: _selectedTagId);

  List<LiveRoom> _scoped(List<LiveRoom> source, {required String siteId, required String tagId}) {
    List<LiveRoom> rooms = source;
    final String normalizedSite = siteId.trim().toLowerCase();

    if (normalizedSite.isNotEmpty && normalizedSite != Sites.allSite) {
      rooms = rooms.where((room) => room.normalizedPlatformId == normalizedSite).toList();
    }

    if (tagId == 'all') {
      return rooms;
    }

    final tagController = ref.read(tagManagementControllerProvider.notifier);
    return rooms.where((room) {
      final List<String> ids = tagController.getTagsForRoom(room);
      return ids.contains(tagId);
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
  /// followed room as offline. Returning `null` keeps the stored snapshot (status
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

  ///
  /// [scopeAll] widens the pass beyond the visible platform tab and tag: a
  /// synced follow list arrives with the statuses its backup remembered, so
  /// stale cards sit in buckets they no longer belong to - verifying only the
  /// visible slice leaves the other buckets wrong until the user happens to
  /// visit each one. The import-triggered verification pass therefore passes
  /// true; a manual pull-refresh stays scoped (and fast).
  Future<void> refreshData({bool scopeAll = false}) async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true);

    final favState = ref.read(favoriteRoomControllerProvider);
    final List<LiveRoom> source = List<LiveRoom>.from(favState.favoriteRooms);
    final List<Site> sites = favoriteSitesForRooms(source);
    final refreshState = ref.read(refreshConfigControllerProvider);

    List<LiveRoom> valid = source;
    if (!scopeAll) {
      if (state.tabSiteIndex >= 0 && state.tabSiteIndex < sites.length) {
        final activeSite = sites[state.tabSiteIndex];
        if (activeSite.id != Sites.allSite) {
          final String siteId = activeSite.id.trim().toLowerCase();
          valid = source.where((r) => r.normalizedPlatformId == siteId).toList();
        }
      }

      final tagController = ref.read(tagManagementControllerProvider.notifier);
      if (state.selectedTagId != 'all') {
        valid = valid.where((room) {
          final List<String> ids = tagController.getTagsForRoom(room);
          return ids.contains(state.selectedTagId);
        }).toList();
      }
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

      ref.read(favoriteRoomControllerProvider.notifier).updateRooms(results.whereType<LiveRoom>().toList());
    }

    final finalFavState = ref.read(favoriteRoomControllerProvider);
    state = _syncAndFilter(state.copyWith(isLoading: false), finalFavState);
    EventBus.instance.emit('refresh_favorite_finish', true);
  }
}
