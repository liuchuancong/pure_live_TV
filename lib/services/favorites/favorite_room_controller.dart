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

  FavoriteSettingsModel _migrateSiteCatalog(FavoriteSettingsModel model) {
    final updated = List<String>.from(model.hotAreasList);
    var version = model.siteCatalogMigration;
    if (version < 2) {
      for (final site in Sites.supportSites) {
        if (!updated.contains(site.id)) updated.add(site.id);
      }
    }
    // Only append new platforms, so a release never resets platforms the user
    // deliberately hid.
    if (version < 4) {
      for (final site in Sites.supportSites) {
        if (!updated.contains(site.id)) updated.add(site.id);
      }
      return model.copyWith(hotAreasList: updated, siteCatalogMigration: 4);
    }
    if (version < 3) {
      version = 3;
      return model.copyWith(hotAreasList: updated, siteCatalogMigration: 3);
    }
    return model;
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
  /// the 在线 ordering never moved after a refresh.
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
  /// the user chose lands exactly there instead of being nudged step by step.
  void moveSiteTo(String siteId, int targetIndex) {
    final current = enabledSiteIds();
    final next = reorderIds(current, siteId.trim().toLowerCase(), targetIndex);
    if (listEquals(next, current)) return;
    setHotAreasList(next);
  }

  void changePreferPlatform(String name) {
    final normalized = name.trim().toLowerCase();
    if (Sites.supportSites.map((e) => e.id).contains(normalized)) {
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
    _update(FavoriteSettingsModel.fromJson(json));
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
