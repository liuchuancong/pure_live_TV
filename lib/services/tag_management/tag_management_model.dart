import 'live_tag.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'tag_management_model.freezed.dart';
part 'tag_management_model.g.dart';

@freezed
abstract class TagManagementModel with _$TagManagementModel {
  const factory TagManagementModel({
    @Default([]) List<LiveTag> tags,
    @Default({}) Map<String, List<String>> roomTagsMap,
  }) = _TagManagementModel;

  factory TagManagementModel.fromJson(Map<String, dynamic> json) => _$TagManagementModelFromJson(json);
}
