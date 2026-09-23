import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:pure_live/features/favorite/favorite_provider.dart';
import 'package:pure_live/platforms/sites.dart';
import 'package:pure_live/services/favorites/favorite_room_controller.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:pure_live/shared/contracts/live_site.dart';
import 'package:pure_live/shared/models/live_room/live_room.dart';
import 'package:pure_live/shared/utils/hive_pref_util.dart';

/// A platform adapter whose cheap refresh path fails the way a real adapter
/// propagates a transport error, while its UI-oriented detail path still answers
/// with the offline-looking fallback room.
class _FailingRefreshSite extends LiveSite implements LiveSiteRoomRefresher {
  int refreshCalls = 0;
  int detailCalls = 0;

  @override
  Future<LiveRoom> getRoomDetailForRefresh({required String roomId, required String platform}) async {
    refreshCalls++;
    throw Exception('transport failure');
  }

  @override
  Future<LiveRoom> getRoomDetail({required String roomId, required String platform}) async {
    detailCalls++;
    return LiveRoom(roomId: roomId, platform: platform).getLiveRoomWithError();
  }
}

/// An adapter that answers a card refresh with the platform's own state.
class _AnsweringRefreshSite extends LiveSite implements LiveSiteRoomRefresher {
  _AnsweringRefreshSite(this.answer);

  final LiveRoom Function(LiveRoom requested) answer;

  @override
  Future<LiveRoom> getRoomDetailForRefresh({required String roomId, required String platform}) async {
    return answer(LiveRoom(roomId: roomId, platform: platform));
  }

  @override
  Future<LiveRoom> getRoomDetail({required String roomId, required String platform}) {
    fail('a card refresh must use the refresher capability, not the UI detail call');
  }
}

LiveRoom _room(
  String id, {
  LiveStatus liveStatus = LiveStatus.live,
  bool status = true,
  bool isRecord = false,
  String watching = '100',
}) {
  return LiveRoom(
    roomId: id,
    title: 'room $id',
    nick: 'streamer $id',
    platform: Sites.bilibiliSite,
    liveStatus: liveStatus,
    status: status,
    isRecord: isRecord,
    watching: watching,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;

  setUpAll(() async {
    final Directory dir = Directory.systemTemp.createTempSync('pure_live_favorite_refresh_test');
    Hive.init(dir.path);
    await HivePrefUtil.init();
    // SettingsService keeps one container per process, so the whole suite shares
    // it; every test resets the followed rooms it depends on.
    container = ProviderContainer();
    SettingsService.to.init(container);
  });

  tearDownAll(() {
    container.dispose();
  });

  tearDown(() {
    Sites.siteLookupOverride = null;
  });

  FavoriteRoomController favorites() => container.read(favoriteRoomControllerProvider.notifier);

  /// The grid's notifier is auto-dispose, so the test holds a subscription the
  /// way the page does; otherwise the refresh would publish into a disposed
  /// notifier.
  FavoriteNotifier favoriteNotifier() {
    container.listen(favoriteProvider, (previous, next) {});
    return container.read(favoriteProvider.notifier);
  }

  void replaceFavorites(List<LiveRoom> rooms) {
    for (final room in [...container.read(favoriteRoomControllerProvider).favoriteRooms]) {
      favorites().removeRoom(room);
    }
    for (final room in rooms) {
      favorites().addRoom(room);
    }
  }

  test('a failed refresh keeps the followed room online instead of publishing the offline fallback', () async {
    final site = _FailingRefreshSite();
    Sites.siteLookupOverride = (id) => id == Sites.bilibiliSite ? site : null;

    replaceFavorites([_room('1')]);

    await favoriteNotifier().refreshData();

    expect(site.refreshCalls, 1, reason: 'a card refresh uses the cheap metadata capability');
    expect(site.detailCalls, 0, reason: 'the UI detail call fabricates an offline-looking room on failure');

    final state = container.read(favoriteProvider);
    expect(state.onlineRooms.map((room) => room.roomId), contains('1'));
    expect(state.offlineRooms, isEmpty, reason: 'one failed request must not report the followed room as 离线');
    expect(container.read(favoriteRoomControllerProvider).favoriteRooms.single.liveStatus, LiveStatus.live);
  });

  test('a refresh adopts the platform answer, audience count included', () async {
    final site = _AnsweringRefreshSite(
      (requested) => requested.copyWith(liveStatus: LiveStatus.offline, status: false, watching: '777'),
    );
    Sites.siteLookupOverride = (id) => id == Sites.bilibiliSite ? site : null;

    replaceFavorites([_room('1')]);

    await favoriteNotifier().refreshData();

    final stored = container.read(favoriteRoomControllerProvider).favoriteRooms.single;
    expect(stored.liveStatus, LiveStatus.offline);
    expect(stored.watching, '777', reason: 'the refreshed audience must not be discarded for the stored one');
    expect(container.read(favoriteProvider).offlineRooms.map((room) => room.roomId), contains('1'));
  });

  test('a pending room counts as online and a replay belongs to 回放, not 离线', () async {
    replaceFavorites([
      _room('pending', liveStatus: LiveStatus.unknown, status: true),
      _room('replay', liveStatus: LiveStatus.replay, status: false),
      _room('record', isRecord: true),
      _room('ended', liveStatus: LiveStatus.offline, status: false),
    ]);

    final state = container.read(favoriteProvider);

    expect(state.onlineRooms.map((room) => room.roomId), ['pending']);
    expect(state.replayRooms.map((room) => room.roomId), unorderedEquals(['replay', 'record']));
    expect(state.offlineRooms.map((room) => room.roomId), ['ended']);
  });

  group('关注 site 的显示逻辑', () {
    /// The notifier keeps its tab/tag selection across tests the way it does
    /// across page visits, so each test states where it starts: 全部平台 / 直播 /
    /// 全部标签.
    FavoriteNotifier resetSelection() {
      final notifier = favoriteNotifier();
      notifier.changeOnlineTab(0);
      notifier.changeSiteTab(0);
      notifier.changeSelectedTag('all');
      return notifier;
    }

    List<String> tabIds() => favoriteSitesForRooms(
      container.read(favoriteRoomControllerProvider).favoriteRooms,
    ).map((site) => site.id).toList();

    test('only the platforms that hold a followed room become tabs', () {
      replaceFavorites([_room('1'), _room('2').copyWith(platform: Sites.douyuSite)]);
      resetSelection();

      final ids = tabIds();

      expect(ids.first, Sites.allSite, reason: '全部 is always the first tab');
      expect(ids, containsAll(<String>[Sites.bilibiliSite, Sites.douyuSite]));
      expect(ids.length, 3, reason: 'the configured platforms nobody follows are left out');
    });

    test('a platform that loses its last room stops being a tab', () {
      replaceFavorites([_room('1')]);
      resetSelection();

      expect(tabIds(), <String>[Sites.allSite, Sites.bilibiliSite]);
    });

    test('the selection follows the platform id while the tab list changes', () {
      // Douyu sits at index 1 here …
      expect(
        resolveFavoriteSiteIndex(
          siteIds: <String>[Sites.allSite, Sites.douyuSite],
          selectedSiteId: Sites.douyuSite,
          fallback: 0,
        ),
        1,
      );
      // … and at index 2 once bilibili has a room again.
      expect(
        resolveFavoriteSiteIndex(
          siteIds: <String>[Sites.allSite, Sites.bilibiliSite, Sites.douyuSite],
          selectedSiteId: Sites.douyuSite,
          fallback: 0,
        ),
        2,
      );
      // Gone: the previous index, clamped — never out of range.
      expect(
        resolveFavoriteSiteIndex(
          siteIds: <String>[Sites.allSite, Sites.bilibiliSite],
          selectedSiteId: Sites.douyuSite,
          fallback: 2,
        ),
        1,
      );
    });

    test('picking a tab filters the grid to that platform', () {
      replaceFavorites([_room('1'), _room('2').copyWith(platform: Sites.douyuSite)]);
      final notifier = resetSelection();

      final ids = tabIds();
      notifier.changeSiteTab(ids.indexOf(Sites.douyuSite));

      expect(
        container.read(favoriteProvider).onlineRooms.length,
        2,
        reason: 'the provider keeps every followed room; the page scope does the filtering',
      );
      expect(notifier.getFilteredRooms().map((room) => room.roomId), ['2']);
    });
  });

  group('tag 在关注列表的显示逻辑', () {
    /// The notifier keeps its tab/tag selection across tests the way it does
    /// across page visits, so each test states where it starts: 全部平台 / 直播 /
    /// 全部标签.
    FavoriteNotifier resetSelection() {
      final notifier = favoriteNotifier();
      notifier.changeOnlineTab(0);
      notifier.changeSiteTab(0);
      notifier.changeSelectedTag('all');
      return notifier;
    }

    /// Assigns a tag to [room] the way the room-tag dialog does.
    String tagRoom(LiveRoom room, String name) {
      final tags = SettingsService.to.tag;
      tags.addTag(name, '');
      final String id = SettingsService.to.tagState.tags.firstWhere((tag) => tag.name == name).id;
      tags.setRoomTags(room, <String>[id]);
      return id;
    }

    test('the strip lists the tags in use on the shown list, in the user order', () {
      // Ids of their own: the tag map outlives a test, so reusing one the site
      // group already used would hand this room the previous test's tags.
      final LiveRoom live = _room('tag-a');
      final LiveRoom other = _room('tag-b').copyWith(platform: Sites.douyuSite);
      tagRoom(live, '游戏');
      tagRoom(other, '音乐');
      replaceFavorites(<LiveRoom>[live, other]);
      final notifier = resetSelection();

      expect(container.read(favoriteProvider).visibleTags.map((tag) => tag.name), <String>['游戏', '音乐']);

      // Scoped to the platform tab: douyu's tag is not offered under bilibili.
      notifier.changeSiteTab(1);
      expect(container.read(favoriteProvider).visibleTags.map((tag) => tag.name), <String>['游戏']);
    });

    test('the strip follows the status tab', () {
      final LiveRoom ended = _room('tag-c', liveStatus: LiveStatus.offline, status: false);
      tagRoom(ended, '游戏');
      replaceFavorites(<LiveRoom>[_room('tag-d'), ended]);
      final notifier = resetSelection();

      expect(container.read(favoriteProvider).visibleTags, isEmpty, reason: 'the 直播 list has no tagged room');

      notifier.changeOnlineTab(2);
      expect(container.read(favoriteProvider).visibleTags.map((tag) => tag.name), <String>['游戏']);
    });

    test('a deleted tag is dropped from the filter', () {
      final LiveRoom room = _room('tag-e');
      final String id = tagRoom(room, '游戏');
      replaceFavorites(<LiveRoom>[room]);
      final notifier = resetSelection();
      notifier.changeSelectedTag(id);
      expect(container.read(favoriteProvider).selectedTagId, id);

      SettingsService.to.tag.deleteTagById(id);
      notifier.changeOnlineTab(1);

      expect(container.read(favoriteProvider).selectedTagId, 'all', reason: 'the filter must not outlive its tag');
      expect(container.read(favoriteProvider).visibleTags, isEmpty);
    });
  });
}
