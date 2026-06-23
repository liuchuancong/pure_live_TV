import 'favorite_settings_model.dart';
import 'package:collection/collection.dart';
import 'package:pure_live/core/sites/sites.dart';
import 'package:pure_live/consts/app_consts.dart';
import 'package:pure_live/utils/hive_pref_util.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pure_live/core/models/live_room/live_room.dart';
import 'package:pure_live/core/models/live_area/live_area.dart';

part 'favorite_room_controller.g.dart';

@riverpod
class FavoriteRoomController extends _$FavoriteRoomController {
  static FavoriteRoomController get to => SettingsService.to.fav;
  @override
  FavoriteSettingsModel build() {
    return FavoriteSettingsModel(
      shieldList: HivePrefUtil.getStringList('shieldList') ?? [],
      hotAreasList: HivePrefUtil.getStringList('hotAreasList') ?? AppConsts.supportSites,
      preferPlatform: HivePrefUtil.getString('preferPlatform') ?? Sites.bilibiliSite,
      favoriteRooms: HivePrefUtil.getObjectList('favoriteRooms', LiveRoom.fromJson),
      favoriteAreas: HivePrefUtil.getObjectList('favoriteAreas', LiveArea.fromJson),
    );
  }

  bool isFavorite(LiveRoom room) => state.favoriteRooms.any((e) => e.roomId == room.roomId);
  bool isFavoriteArea(LiveArea area) => state.favoriteAreas.any((e) => e.areaId == area.areaId);

  void addRoom(LiveRoom room) {
    if (isFavorite(room)) return;
    state = state.copyWith(favoriteRooms: [...state.favoriteRooms, room]);
    HivePrefUtil.setObjectList('favoriteRooms', state.favoriteRooms, (room) => room.toJson());
  }

  void removeRoom(LiveRoom room) {
    state = state.copyWith(favoriteRooms: state.favoriteRooms.where((e) => e.roomId != room.roomId).toList());
    HivePrefUtil.setObjectList('favoriteRooms', state.favoriteRooms, (room) => room.toJson());
  }

  void updateRoom(LiveRoom room) {
    state = state.copyWith(favoriteRooms: state.favoriteRooms.map((e) => e.roomId == room.roomId ? room : e).toList());
    HivePrefUtil.setObjectList('favoriteRooms', state.favoriteRooms, (room) => room.toJson());
  }

  void addArea(LiveArea area) {
    if (isFavoriteArea(area)) return;
    state = state.copyWith(favoriteAreas: [...state.favoriteAreas, area]);
    HivePrefUtil.setObjectList('favoriteAreas', state.favoriteAreas, (room) => room.toJson());
  }

  void removeArea(LiveArea area) {
    state = state.copyWith(favoriteAreas: state.favoriteAreas.where((e) => e.areaId != area.areaId).toList());
    HivePrefUtil.setObjectList('favoriteAreas', state.favoriteAreas, (room) => room.toJson());
  }

  void addShieldList(String value) {
    state = state.copyWith(shieldList: [...state.shieldList, value]);
    HivePrefUtil.setStringList('shieldList', state.shieldList);
  }

  void removeShieldList(int idx) {
    state = state.copyWith(shieldList: List.from(state.shieldList)..removeAt(idx));
    HivePrefUtil.setStringList('shieldList', state.shieldList);
  }

  LiveRoom? getRoomById(String roomId, String platform) {
    return state.favoriteRooms.firstWhereOrNull((e) => e.roomId == roomId && e.platform == platform);
  }

  void changePreferPlatform(String name) {
    if (Sites.supportSites.map((e) => e.id).contains(name)) {
      state = state.copyWith(preferPlatform: name);
      HivePrefUtil.setString('preferPlatform', name);
    }
  }

  Map<String, dynamic> toJson() => state.toJson();

  void importFromJson(Map<String, dynamic> json) {
    state = FavoriteSettingsModel.fromJson(json);
    HivePrefUtil.setStringList('shieldList', state.shieldList);
    HivePrefUtil.setStringList('hotAreasList', state.hotAreasList);
    HivePrefUtil.setString('preferPlatform', state.preferPlatform);
    HivePrefUtil.setObjectList('favoriteRooms', state.favoriteRooms, (room) => room.toJson());
    HivePrefUtil.setObjectList('favoriteAreas', state.favoriteAreas, (room) => room.toJson());
  }
}
