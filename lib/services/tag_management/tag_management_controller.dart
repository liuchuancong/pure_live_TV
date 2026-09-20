import 'live_tag.dart';
import 'tag_management_model.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tag_management_controller.g.dart';

@riverpod
class TagManagementController extends _$TagManagementController {
  static TagManagementController get to => SettingsService.to.tag;
  @override
  TagManagementModel build() {
    final tags =
        HivePrefUtil.getObject(
          'user_custom_tags_v5',
          (json) => (json as List).map((e) => LiveTag.fromJson(e)).toList(),
        ) ??
        [];
    final mapping =
        HivePrefUtil.getObject(
          'room_to_tags_mapping_v1',
          (json) => (json as Map).map((k, v) => MapEntry(k.toString(), (v as List).cast<String>())),
        ) ??
        {};

    return TagManagementModel(tags: tags..sort((a, b) => a.order.compareTo(b.order)), roomTagsMap: mapping);
  }

  void addTag(String name, String description) {
    if (name.trim().isEmpty || state.tags.any((t) => t.name.toLowerCase() == name.trim().toLowerCase())) return;

    final newTag = LiveTag(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.trim(),
      description: description.trim(),
      order: state.tags.length,
    );
    state = state.copyWith(tags: [...state.tags, newTag]);
    _persist();
  }

  void deleteTag(int index) {
    if (index < 0 || index >= state.tags.length) return;
    final removedId = state.tags[index].id;
    final newList = List<LiveTag>.from(state.tags)..removeAt(index);

    // Drop the deleted tag from every room mapping, otherwise the filter row
    // keeps matching rooms through an id that no longer exists.
    final newMap = <String, List<String>>{};
    for (final entry in state.roomTagsMap.entries) {
      final remaining = entry.value.where((id) => id != removedId).toList(growable: false);
      if (remaining.isNotEmpty) newMap[entry.key] = remaining;
    }

    state = state.copyWith(tags: _refreshOrders(newList), roomTagsMap: newMap);
    _persist();
  }

  /// Replaces the tags of [room].
  ///
  /// Rooms are keyed by platform and room id, so the same numeric room id on
  /// two platforms keeps separate tags. Unknown ids are dropped and the legacy
  /// room-id-only entry is removed once the room has a scoped entry.
  void setRoomTags(LiveRoom room, List<String> tagIds) {
    final roomKey = room.identityKey;
    if (roomKey.isEmpty) return;

    final knownIds = state.tags.map((tag) => tag.id).toSet();
    final normalized = tagIds.where(knownIds.contains).toSet().toList(growable: false);
    final legacyKey = room.normalizedRoomId;

    final newMap = Map<String, List<String>>.from(state.roomTagsMap);
    if (legacyKey.isNotEmpty && legacyKey != roomKey) newMap.remove(legacyKey);
    if (normalized.isEmpty) {
      newMap.remove(roomKey);
    } else {
      newMap[roomKey] = normalized;
    }

    state = state.copyWith(roomTagsMap: newMap);
    _persist();
  }

  /// Adds or removes one tag without replacing the room's other tags.
  void toggleRoomTag(LiveRoom room, String tagId, bool enabled) {
    final current = getTagsForRoom(room);
    final next = List<String>.from(current);
    if (enabled) {
      if (!next.contains(tagId)) next.add(tagId);
    } else {
      next.remove(tagId);
    }
    setRoomTags(room, next);
  }

  List<String> getTagsForRoom(LiveRoom room) {
    final roomKey = room.identityKey;
    final scoped = state.roomTagsMap[roomKey];
    if (scoped != null) return scoped;
    // Legacy entries were keyed by room id only.
    return state.roomTagsMap[room.normalizedRoomId] ?? const <String>[];
  }

  /// Moves legacy room-id-only mappings onto platform-scoped identities.
  ///
  /// A legacy tag is copied to every matching platform room before the old key
  /// is removed, so existing assignments survive while later edits diverge.
  /// One pass per session: this ran inside every favourite _syncAndFilter
  /// (per tab switch, per tag change, N times per auto-refresh) although it
  /// is a one-time data migration.
  bool _legacyMigrationDone = false;

  void migrateLegacyRoomTagKeys(Iterable<LiveRoom> rooms) {
    if (_legacyMigrationDone) return;
    _legacyMigrationDone = true;
    final newMap = Map<String, List<String>>.from(state.roomTagsMap);
    final migratedLegacyKeys = <String>{};
    var changed = false;

    for (final room in rooms) {
      final legacyKey = room.normalizedRoomId;
      if (legacyKey.isEmpty || room.normalizedPlatformId.isEmpty) continue;
      final legacyTags = newMap[legacyKey];
      if (legacyTags == null) continue;
      newMap.putIfAbsent(room.identityKey, () => List<String>.from(legacyTags));
      migratedLegacyKeys.add(legacyKey);
      changed = true;
    }

    if (!changed) return;
    for (final key in migratedLegacyKeys) {
      newMap.remove(key);
    }
    state = state.copyWith(roomTagsMap: newMap);
    _persist();
  }

  List<LiveTag> _refreshOrders(List<LiveTag> list) {
    return list.asMap().entries.map((e) => e.value.copyWith(order: e.key)).toList();
  }

  void _persist() {
    HivePrefUtil.setObject('user_custom_tags_v5', state.tags.map((e) => e.toJson()).toList());
    HivePrefUtil.setObject('room_to_tags_mapping_v1', state.roomTagsMap);
  }

  void importFromJson(Map<String, dynamic> json) {
    state = TagManagementModel.fromJson(json);
    _persist();
  }

  Map<String, dynamic> toJson() => state.toJson();
}
