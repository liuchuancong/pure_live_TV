import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pure_live/core/models/live_area/live_area.dart';

part 'live_category.freezed.dart';
part 'live_category.g.dart';

@freezed
abstract class LiveCategory with _$LiveCategory {
  const factory LiveCategory({required String id, required String name, @Default([]) List<LiveArea> children}) =
      _LiveCategory;

  factory LiveCategory.fromJson(Map<String, dynamic> json) => _$LiveCategoryFromJson(json);
}
