import 'history_model.dart';
import 'package:pure_live/utils/hive_pref_util.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pure_live/core/models/live_room/live_room.dart';

part 'history_controller.g.dart';

@riverpod
class HistoryController extends _$HistoryController {
  static HistoryController get to => SettingsService.to.history;
  @override
  HistoryModel build() {
    final list = HivePrefUtil.getObjectList('historyRooms', LiveRoom.fromJson);
    return HistoryModel(historyRooms: list);
  }

  void addRoomToHistory(LiveRoom room) {
    final newList = state.historyRooms.where((e) => e.roomId != room.roomId).toList();
    newList.insert(0, room);

    final trimmedList = newList.take(50).toList();

    state = state.copyWith(historyRooms: trimmedList);
    _persist();
  }

  void removeHistory(LiveRoom room) {
    final newList = state.historyRooms.where((e) => e.roomId != room.roomId || e.platform != room.platform).toList();
    state = state.copyWith(historyRooms: newList);
    _persist();
  }

  void clearHistory() {
    state = state.copyWith(historyRooms: []);
    _persist();
  }

  void _persist() {
    HivePrefUtil.setObjectList('historyRooms', state.historyRooms, (r) => r.toJson());
  }

  void importFromJson(Map<String, dynamic> json) {
    state = HistoryModel.fromJson(json);
    _persist();
  }

  Map<String, dynamic> toJson() => state.toJson();
}
