import 'live_tag.dart';
import 'tag_management_model.dart';
import 'package:pure_live/utils/hive_pref_util.dart';
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
    final newList = List<LiveTag>.from(state.tags)..removeAt(index);
    state = state.copyWith(tags: _refreshOrders(newList));
    _persist();
  }

  void setRoomTags(String roomId, List<String> tagIds) {
    final newMap = Map<String, List<String>>.from(state.roomTagsMap);
    if (tagIds.isEmpty) {
      newMap.remove(roomId);
    } else {
      newMap[roomId] = tagIds;
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
