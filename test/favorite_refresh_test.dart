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
}
