import 'package:freezed_annotation/freezed_annotation.dart';

part 'live_tag.freezed.dart';
part 'live_tag.g.dart';

@freezed
abstract class LiveTag with _$LiveTag {
  const factory LiveTag({
    required String id,
    @Default('') String name,
    @Default('') String description,
    @Default(0) int order,
  }) = _LiveTag;

  factory LiveTag.fromJson(Map<String, dynamic> json) => _$LiveTagFromJson(json);
}
