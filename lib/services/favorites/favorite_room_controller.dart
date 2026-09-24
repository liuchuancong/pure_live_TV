import 'favorite_settings_model.dart';
import 'package:flutter/foundation.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pure_live/services/settings/settings_value.dart';

part 'favorite_room_controller.g.dart';

/// Favorites, blocked words, blocked danmaku users and directory migration,
/// with identity-based de-duplication.
@riverpod
class FavoriteRoomController extends _$FavoriteRoomController {
  static FavoriteRoomController get to => SettingsService.to.fav;
  static const int maxShieldKeywordLength = 40;

  // Exposed as a reactive value for non-widget code such as the player core.
  SettingsValue<List<LiveRoom>> get favoriteRooms => SettingsValue(() => state.favoriteRooms);
  SettingsValue<List<String>> get hotAreasList => SettingsValue(() => state.hotAreasList);

  @override
  FavoriteSettingsModel build() {
    final initial = FavoriteSettingsModel(
      shieldList: HivePrefUtil.getStringList('shieldList') ?? [],
      siteCatalogMigration: HivePrefUtil.getInt('siteCatalogMigration') ?? 0,
      hotAreasList: HivePrefUtil.getStringList('hotAreasList') ?? AppConsts.supportSites,
      preferPlatform: HivePrefUtil.getString('preferPlatform') ?? Sites.bilibiliSite,
      favoriteRooms: HivePrefUtil.getObjectList('favoriteRooms', LiveRoom.fromJson),
      favoriteAreas: HivePrefUtil.getObjectList('favoriteAreas', LiveArea.fromJson),
    );
    // Normalize stored entries once at build time.
    var normalized = _normalizeDanmakuBlocks(initial);
    normalized = _normalizeSiteCatalogIds(normalized);
    normalized = _normalizeFavoriteRoomIdentities(normalized);
    normalized = _migrateSiteCatalog(normalized);
    normalized = _normalizePreferredPlatform(normalized);
    if (normalized != initial) _persist(normalized);
    return normalized;
  }

  // ------------------------------------------------------------------
  // identity helpers (LiveRoom / LiveArea)
  // ------------------------------------------------------------------

  static LiveRoom _normalizedIdentityCopy(LiveRoom room) {
    return room.copyWith(platform: room.normalizedPlatformId, roomId: room.normalizedRoomId);
  }

  static bool _isValidFavoriteRoom(LiveRoom room) {
    final platform = room.normalizedPlatformId.trim();
    final roomId = room.normalizedRoomId.trim().toLowerCase();

    if (platform.isEmpty || roomId.isEmpty) return false;

    switch (roomId) {
      case '0':
      case 'null':
      case 'undefined':
      case 'nan':
      case 'none':
        return false;
    }
    return true;
  }

  static bool isValidFavoriteRoomStatic(LiveRoom room) => _isValidFavoriteRoom(room);

  static String _areaKey(LiveArea area) => '${area.platform.trim().toLowerCase()}:${area.areaId.trim()}';

  static bool _sameStrings(List<String> left, List<String> right) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }

  static bool _sameFavoriteRoomSnapshot(List<LiveRoom> left, List<LiveRoom> right) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (left[index].identityKey != right[index].identityKey) return false;
    }
    return true;
  }

  static List<String> _normalizeDanmakuBlockValues(Iterable<String> values) {
    final seen = <String>{};
    final normalized = <String>[];
    for (final rawValue in values) {
      final value = rawValue.trim();
      if (value.isNotEmpty && seen.add(value.toLowerCase())) normalized.add(value);
    }
    return normalized;
  }

  // ------------------------------------------------------------------
  // Build-time normalization.
  // ------------------------------------------------------------------

  FavoriteSettingsModel _normalizeDanmakuBlocks(FavoriteSettingsModel model) {
    final keywords = _normalizeDanmakuBlockValues(model.shieldList);
    if (_sameStrings(model.shieldList, keywords)) return model;
    return model.copyWith(shieldList: keywords);
  }

  FavoriteSettingsModel _normalizeSiteCatalogIds(FavoriteSettingsModel model) {
    final supported = Sites.supportSites.map((e) => e.id).toSet();
    final seen = <String>{};
    final normalized = <String>[];

    for (final rawId in model.hotAreasList) {
      final id = rawId.trim().toLowerCase();
      if (supported.contains(id) && seen.add(id)) normalized.add(id);
    }

    final preferred = model.preferPlatform.trim().toLowerCase();
    final nextPrefer = supported.contains(preferred) ? preferred : Sites.bilibiliSite;

    if (_sameStrings(model.hotAreasList, normalized) && nextPrefer == model.preferPlatform) return model;
    return model.copyWith(hotAreasList: normalized, preferPlatform: nextPrefer);
  }

  /// The preferred platform must stay inside the visible tab selection: a
  /// hidden platform can never be the tab the app opens on.
  FavoriteSettingsModel _normalizePreferredPlatform(FavoriteSettingsModel model) {
    if (model.hotAreasList.isNotEmpty && !model.hotAreasList.contains(model.preferPlatform)) {
      return model.copyWith(preferPlatform: model.hotAreasList.first);
    }
    return model;
  }

  FavoriteSettingsModel _normalizeFavoriteRoomIdentities(FavoriteSettingsModel model) {
    if (model.favoriteRooms.isEmpty) return model;

    final normalized = <LiveRoom>[];
    final identities = <String>{};
    for (final room in model.favoriteRooms) {
      final next = _normalizedIdentityCopy(room);
      if (!_isValidFavoriteRoom(next)) continue;
      if (!identities.add(next.identityKey)) continue;
      normalized.add(next);
    }
    if (_sameFavoriteRoomSnapshot(model.favoriteRooms, normalized)) return model;
    return model.copyWith(favoriteRooms: normalized);
  }

  /// Platforms appended to [Sites.supportSites] after the version-3 catalog,
  /// in the order they were released. Each release appends only what it
  /// introduced: re-enabling the whole catalog would silently un-hide every
  /// platform the user removed from the home tabs.
  static const List<String> _catalogAdditions = [
    Sites.liveMeSite, // v4
    Sites.tiktokSite, // v5
    Sites.youtubeSite, // v6
    Sites.bigoSite, // v7
    Sites.pandaLiveSite, // v8
    Sites.popkonSite, // v9
    Sites.shopeeLiveSite, // v10
    Sites.vkVideoLiveSite, // v11
    Sites.nimoTvSite, // v12
    Sites.dailymotionSite, // v13
    Sites.rumbleSite, // v14
    Sites.goodgameSite, // v15
    Sites.fc2LiveSite, // v16
    Sites.steamBroadcastSite, // v17
    Sites.jdLiveSite, // v18
    Sites.taobaoLiveSite, // v19
    Sites.kugouLiveSite, // v20
    Sites.baiduLiveSite, // v21
    Sites.sixRoomSite, // v22
    Sites.lookLiveSite, // v23
    Sites.seventeenLiveSite, // v24
  ];

  /// Version 3 was the catalog before [_catalogAdditions] started, so the
  /// current version is `3 + _catalogAdditions.length`.
  static const int _siteCatalogVersion = 24;

  FavoriteSettingsModel _migrateSiteCatalog(FavoriteSettingsModel model) {
    assert(_siteCatalogVersion == 3 + _catalogAdditions.length);
    if (model.siteCatalogMigration >= _siteCatalogVersion) return model;
    final updated = List<String>.from(model.hotAreasList);
    final seen = updated.toSet();
    if (model.siteCatalogMigration < 2) {
      for (final site in Sites.supportSites) {
        if (seen.add(site.id)) updated.add(site.id);
      }
    }
    final granted = model.siteCatalogMigration < 3 ? 0 : model.siteCatalogMigration - 3;
    for (final id in _catalogAdditions.skip(granted.clamp(0, _catalogAdditions.length))) {
      if (seen.add(id)) updated.add(id);
    }
    return model.copyWith(hotAreasList: updated, siteCatalogMigration: _siteCatalogVersion);
  }

  // ------------------------------------------------------------------
  // queries
  // ------------------------------------------------------------------

  bool isFavorite(LiveRoom room) => state.favoriteRooms.any((e) => e.hasSameIdentity(room));
  bool isFavoriteArea(LiveArea area) => state.favoriteAreas.any((e) => _areaKey(e) == _areaKey(area));

  LiveRoom? getRoomById(String roomId, String platform) {
    final identity = '${platform.trim().toLowerCase()}:${roomId.trim()}';
    for (final room in state.favoriteRooms) {
      if (room.identityKey == identity) return room;
    }
    return null;
  }

  /// Drops favorite rooms with an invalid or duplicated identity.
  bool removeInvalidFavoriteRooms() {
    if (state.favoriteRooms.isEmpty) return false;
    final validRooms = <LiveRoom>[];
    final identities = <String>{};
    for (final room in state.favoriteRooms) {
      final normalized = _normalizedIdentityCopy(room);
      if (!_isValidFavoriteRoom(normalized)) continue;
      if (!identities.add(normalized.identityKey)) continue;
      validRooms.add(normalized);
    }
    if (_sameFavoriteRoomSnapshot(state.favoriteRooms, validRooms)) return false;
    _update(state.copyWith(favoriteRooms: validRooms));
    return true;
  }

  // ------------------------------------------------------------------
  // favorite room management
  // ------------------------------------------------------------------

  bool addRoom(LiveRoom room) {
    final normalized = _normalizedIdentityCopy(room);
    if (!_isValidFavoriteRoom(normalized)) return false;
    if (isFavorite(normalized)) return false;
    _update(state.copyWith(favoriteRooms: [...state.favoriteRooms, normalized]));
    return true;
  }

  bool removeRoom(LiveRoom room) {
    final index = state.favoriteRooms.indexWhere((e) => e.hasSameIdentity(room));
    if (index < 0) return false;
    final updated = List<LiveRoom>.from(state.favoriteRooms)..removeAt(index);
    _update(state.copyWith(favoriteRooms: updated));
    return true;
  }

  /// Applies one refresh snapshot on top of the stored favourite entry.
  ///
  /// Server-owned fields (status, title, cover, audience…) come from [refreshed];
  /// everything a refresh payload does not carry (tags, the record flag, the
  /// local identity) stays as the user's entry had it.
  ///
  /// The audience values need the merge direction spelled out: the stored entry
  /// used to be the base of [LiveRoom.withAudienceFallbackFrom], which only
  /// fills *empty* fields, so every refreshed viewer count was discarded as soon
  /// as the stored card already had one. A card therefore kept a stale count and
  /// the live ordering never moved after a refresh.
  static LiveRoom mergeRefreshedRoom(LiveRoom stored, LiveRoom refreshed) {
    final fresh = refreshed.withAudienceFallbackFrom(stored);

    return stored.copyWith(
      title: fresh.title,
      nick: fresh.nick,
      avatar: fresh.avatar,
      cover: fresh.cover,
      area: fresh.area,
      introduction: fresh.introduction,
      status: fresh.status,
      liveStatus: fresh.liveStatus,
      watching: fresh.watching,
      popularity: fresh.popularity,
      onlineViewers: fresh.onlineViewers,
      totalViewers: fresh.totalViewers,
      audienceMetricType: fresh.audienceMetricType,
    );
  }

  /// Applies a whole refresh batch with ONE state write and ONE persist:
  /// updateRoom per room re-encoded the entire favourite list to JSON on the
  /// main isolate per room (N × O(N) = O(N²)) and emitted N provider updates.
  void updateRooms(List<LiveRoom> rooms) {
    if (rooms.isEmpty) return;
    var current = state.favoriteRooms;
    var changed = false;
    for (final room in rooms) {
      final normalized = _normalizedIdentityCopy(room);
      if (!_isValidFavoriteRoom(normalized)) continue;
      final index = current.indexWhere((e) => e.hasSameIdentity(normalized));
      if (index < 0) continue;
      current = List<LiveRoom>.from(current);
      current[index] = mergeRefreshedRoom(current[index], normalized);
      changed = true;
    }
    if (changed) _update(state.copyWith(favoriteRooms: current));
  }

  bool updateRoom(LiveRoom room) {
    final normalized = _normalizedIdentityCopy(room);
    if (!_isValidFavoriteRoom(normalized)) return false;
    final index = state.favoriteRooms.indexWhere((e) => e.hasSameIdentity(normalized));
    if (index < 0) return false;
    final updated = List<LiveRoom>.from(state.favoriteRooms);
    // Locate by identity key, then overwrite with the refresh snapshot. Keeping
    // the favourite refresh metadata in step is the caller's responsibility.
    updated[index] = mergeRefreshedRoom(updated[index], normalized);
    _update(state.copyWith(favoriteRooms: updated));
    return true;
  }

  bool addArea(LiveArea area) {
    if (area.areaId.isEmpty || isFavoriteArea(area)) return false;
    _update(state.copyWith(favoriteAreas: [...state.favoriteAreas, area]));
    return true;
  }

  bool removeArea(LiveArea area) {
    final updated = state.favoriteAreas.where((e) => _areaKey(e) != _areaKey(area)).toList();
    if (updated.length == state.favoriteAreas.length) return false;
    _update(state.copyWith(favoriteAreas: updated));
    return true;
  }

  // ------------------------------------------------------------------
  // shield list / blocked danmaku users
  // ------------------------------------------------------------------

  bool addShieldList(String value) {
    final text = value.trim();
    if (text.isEmpty || text.length > maxShieldKeywordLength) return false;
    if (state.shieldList.any((item) => item.trim().toLowerCase() == text.toLowerCase())) return false;
    _update(state.copyWith(shieldList: [...state.shieldList, text]));
    return true;
  }

  bool removeShieldList(int index) {
    if (index < 0 || index >= state.shieldList.length) return false;
    final updated = List<String>.from(state.shieldList)..removeAt(index);
    _update(state.copyWith(shieldList: updated));
    return true;
  }

  // ------------------------------------------------------------------
  // hot areas / site catalog
  // ------------------------------------------------------------------

  void setHotAreasList(List<String> sites) {
    _update(state.copyWith(hotAreasList: _normalizeDanmakuBlockValues(sites)));
  }

  bool toggleSiteEnabled(String siteId, bool enabled) {
    final id = siteId.trim().toLowerCase();
    final current = List<String>.from(state.hotAreasList);
    if (enabled) {
      if (current.contains(id)) return false;
      current.add(id);
    } else {
      if (!current.remove(id)) return false;
    }
    _update(state.copyWith(hotAreasList: current));
    return true;
  }

  /// The visible platform ids, normalized and de-duplicated, in display order.
  ///
  /// `availableSites()` reads the stored list in order, so this *is* the order of
  /// the platform tabs on hot / categories.
  List<String> enabledSiteIds() {
    final seen = <String>{};
    return <String>[
      for (final raw in state.hotAreasList)
        if (seen.add(raw.trim().toLowerCase())) raw.trim().toLowerCase(),
    ];
  }

  /// Moves [siteId] by [delta] positions in the platform display order.
  void moveSite(String siteId, int delta) {
    final current = enabledSiteIds();
    final index = current.indexOf(siteId.trim().toLowerCase());
    final target = index + delta;
    if (index < 0 || target < 0 || target >= current.length) return;
    setHotAreasList(reorderIds(current, current[index], target));
  }

  /// Puts [siteId] at [targetIndex] of the platform display order.
  ///
  /// The platform order page's "pick a platform, then name its position" move: the one
  /// the user chose lands there instead of being nudged step by step.
  void moveSiteTo(String siteId, int targetIndex) {
    final current = enabledSiteIds();
    final next = reorderIds(current, siteId.trim().toLowerCase(), targetIndex);
    if (listEquals(next, current)) return;
    setHotAreasList(next);
  }

  void changePreferPlatform(String name) {
    final normalized = name.trim().toLowerCase();
    // Only a platform that is actually visible can become the opening tab.
    if (state.hotAreasList.contains(normalized)) {
      _update(state.copyWith(preferPlatform: normalized));
    }
  }

  // ------------------------------------------------------------------
  // persistence / backup
  // ------------------------------------------------------------------

  void _update(FavoriteSettingsModel next) {
    state = next;
    _persist(next);
  }

  void _persist(FavoriteSettingsModel model) {
    HivePrefUtil.setStringList('shieldList', model.shieldList);
    HivePrefUtil.setInt('siteCatalogMigration', model.siteCatalogMigration);
    HivePrefUtil.setStringList('hotAreasList', model.hotAreasList);
    HivePrefUtil.setString('preferPlatform', model.preferPlatform);
    HivePrefUtil.setObjectList('favoriteRooms', model.favoriteRooms, (room) => room.toJson());
    HivePrefUtil.setObjectList('favoriteAreas', model.favoriteAreas, (area) => area.toJson());
  }

  Map<String, dynamic> toJson() => state.toJson();

  void importFromJson(Map<String, dynamic> json) {
    // An imported document is normalized exactly like a stored one, which is what
    // the reference's `fromJson` does before publishing the lists: identities are
    // canonicalised, then rooms with an invalid identity and duplicate identities
    // are dropped. An import is the one place a foreign document can smuggle in a
    // room whose id is a placeholder ("0"/"null"/…) or the same room twice, and
    // the pass is what deletes them instead of leaving cards that can never play.
    final imported = _normalizePreferredPlatform(
      _normalizeFavoriteRoomIdentities(
        _normalizeSiteCatalogIds(_normalizeDanmakuBlocks(FavoriteSettingsModel.fromJson(json))),
      ),
    );

    _update(imported);

    if (state.favoriteRooms.isEmpty) return;

    // A restored follow list arrives with the statuses it was exported with —
    // hours, days or weeks old — so the imported rooms would sit in whichever
    // bucket the backup remembered. Ask for one verification pass: the event
    // reaches a favourites page that is already mounted, and a page that opens
    // later takes the flag instead. (The reference does the same after its account
    // download: restore the settings, then refresh the followed rooms.)
    _statusRefreshRequested = true;
    EventBus.instance.emit('refresh_favorite_rooms', true);
  }

  /// Whether an import left the followed list asking to be verified.
  bool _statusRefreshRequested = false;

  /// Takes the pending verification request, if any.
  ///
  /// The favourites page calls this when it builds. The flag exists because an
  /// import is driven from the settings side, where the favourites page (and its
  /// listener on the event above) may not be alive yet.
  bool consumeStatusRefreshRequest() {
    if (!_statusRefreshRequested) return false;

    _statusRefreshRequested = false;
    return true;
  }

  /// Parses the favorites section with validation and normalization, without persisting.
  static Map<String, dynamic> parseConfig(Map<String, dynamic> json) {
    final model = FavoriteSettingsModel.fromJson(json);
    final parsed = _normalizeDanmakuBlocksStatic(model);
    return parsed.toJson();
  }

  static FavoriteSettingsModel _normalizeDanmakuBlockValuesModel(FavoriteSettingsModel model) {
    return model.copyWith(shieldList: _normalizeDanmakuBlockValues(model.shieldList));
  }

  static FavoriteSettingsModel _normalizeDanmakuBlocksStatic(FavoriteSettingsModel model) {
    return _normalizeDanmakuBlockValuesModel(model);
  }

  /// Extracts the favorites section from a backup root document.
  static Map<String, dynamic> extractConfig(Map<String, dynamic>? rootConfig) {
    final favorite = rootConfig?['favorite'] as Map<String, dynamic>? ?? {};
    return parseConfig(favorite);
  }

  static Map<String, dynamic> mergeConfig(Map<String, dynamic> rootConfig, Map<String, dynamic> updateFields) {
    final favorite = Map<String, dynamic>.from(rootConfig['favorite'] ?? {});
    updateFields.forEach((key, value) {
      favorite[key] = value;
    });
    rootConfig['favorite'] = favorite;
    return rootConfig;
  }
}
