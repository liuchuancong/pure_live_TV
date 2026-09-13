import 'history_model.dart';
import 'package:pure_live/utils/hive_pref_util.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pure_live/core/models/live_room/live_room.dart';

part 'history_controller.g.dart';

/// 同步自 pure_live HistoryController 的历史记录上限常量与工具函数。
const int defaultHistoryLimit = 50;
const int unlimitedHistoryLimit = 0;

int normalizeHistoryLimit(Object? value) {
  final parsed = value is num ? value.toInt() : int.tryParse(value?.toString() ?? '');
  if (parsed == null || parsed < 0) return defaultHistoryLimit;
  return parsed;
}

List<T> applyHistoryLimit<T>(Iterable<T> values, int limit) {
  final normalized = normalizeHistoryLimit(limit);
  return normalized == unlimitedHistoryLimit
      ? List<T>.of(values, growable: true)
      : values.take(normalized).toList(growable: true);
}

/// 以稳定身份（平台:房间ID）去重插入历史记录。
List<LiveRoom> upsertHistoryRoom(List<LiveRoom> current, LiveRoom room, {int limit = defaultHistoryLimit}) {
  final maxLength = normalizeHistoryLimit(limit);
  final next = List<LiveRoom>.from(current)..removeWhere((entry) => entry.hasSameIdentity(room));
  next.insert(0, room.copyWith(platform: room.normalizedPlatformId, roomId: room.normalizedRoomId));
  if (maxLength != unlimitedHistoryLimit && next.length > maxLength) {
    next.removeRange(maxLength, next.length);
  }
  return next;
}

/// 刷新后合并房间快照，保留历史条目的展示上下文。
LiveRoom preserveHistoryMetadata(LiveRoom refreshed, LiveRoom previous) {
  return refreshed.withAudienceFallbackFrom(previous);
}

@riverpod
class HistoryController extends _$HistoryController {
  static HistoryController get to => SettingsService.to.history;

  static const String historyLimitKey = 'historyLimit';

  @override
  HistoryModel build() {
    final list = HivePrefUtil.getObjectList('historyRooms', LiveRoom.fromJson);
    final limit = normalizeHistoryLimit(HivePrefUtil.getInt(historyLimitKey) ?? defaultHistoryLimit);
    final model = HistoryModel(
      historyRooms: applyHistoryLimit(list, limit),
      historyLimit: limit,
    );
    if (list.length != model.historyRooms.length) _persist(model);
    return model;
  }

  void setHistoryLimit(int value) {
    final normalized = normalizeHistoryLimit(value);
    var rooms = state.historyRooms;
    if (normalized != unlimitedHistoryLimit && rooms.length > normalized) {
      rooms = rooms.take(normalized).toList(growable: true);
    }
    _update(state.copyWith(historyLimit: normalized, historyRooms: rooms));
  }

  void addRoomToHistory(LiveRoom room) {
    _update(
      state.copyWith(
        historyRooms: upsertHistoryRoom(state.historyRooms, room, limit: state.historyLimit),
      ),
    );
  }

  void removeRoomFromHistory(LiveRoom room) {
    _update(
      state.copyWith(
        historyRooms: state.historyRooms.where((entry) => !entry.hasSameIdentity(room)).toList(),
      ),
    );
  }

  void removeRoomFromHistoryAt(int index) {
    if (index < 0 || index >= state.historyRooms.length) return;
    final updated = List<LiveRoom>.from(state.historyRooms)..removeAt(index);
    _update(state.copyWith(historyRooms: updated));
  }

  /// 兼容旧调用名（同 removeRoomFromHistory）。
  void removeHistory(LiveRoom room) => removeRoomFromHistory(room);

  void clearHistory() {
    _update(state.copyWith(historyRooms: <LiveRoom>[]));
  }

  /// 同步自 pure_live：用刷新快照替换历史中对应条目（仅替换仍属于本次刷新的项）。
  void applyRefreshedRooms(List<LiveRoom> snapshot, List<LiveRoom?> refreshed) {
    if (snapshot.length != refreshed.length) return;
    LiveRoom? replacementFor(LiveRoom room) {
      for (var i = 0; i < snapshot.length; i++) {
        if (identical(snapshot[i], room) || snapshot[i].identityKey == room.identityKey) {
          return refreshed[i];
        }
      }
      return null;
    }

    final mapped = state.historyRooms.map((room) => replacementFor(room) ?? room).toList();
    _update(state.copyWith(historyRooms: applyHistoryLimit(mapped, state.historyLimit)));
  }

  void _update(HistoryModel next) {
    state = next;
    _persist(next);
  }

  void _persist(HistoryModel model) {
    HivePrefUtil.setObjectList('historyRooms', model.historyRooms, (r) => r.toJson());
    HivePrefUtil.setInt(historyLimitKey, model.historyLimit);
  }

  Map<String, dynamic> toJson() => state.toJson();

  void importFromJson(Map<String, dynamic> json) {
    _update(HistoryModel.fromJson(json));
  }

  /// 同步自 pure_live：解析历史分区（归一化上限并裁剪列表），不触发持久化。
  static Map<String, dynamic> parseConfig(Map<String, dynamic> json) {
    final limit = normalizeHistoryLimit(json[historyLimitKey]);
    final rooms = (json['historyRooms'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((e) => LiveRoom.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    return {'historyRooms': applyHistoryLimit(rooms, limit), historyLimitKey: limit};
  }

  /// 同步自 pure_live：从备份根配置中提取 history 分区。
  static Map<String, dynamic> extractConfig(Map<String, dynamic>? rootConfig) {
    final history = rootConfig?['history'] as Map<String, dynamic>? ?? {};
    return parseConfig(history);
  }

  static Map<String, dynamic> mergeConfig(Map<String, dynamic> rootConfig, Map<String, dynamic> updateFields) {
    final history = Map<String, dynamic>.from(rootConfig['history'] ?? {});
    updateFields.forEach((k, v) => history[k] = v);
    rootConfig['history'] = history;
    return rootConfig;
  }
}
