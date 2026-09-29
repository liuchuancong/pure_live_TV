import 'package:freezed_annotation/freezed_annotation.dart';

part 'font_model.freezed.dart';
part 'font_model.g.dart';

@freezed
abstract class FontModel with _$FontModel {
  const factory FontModel({
    @Default('') String id,
    @Default('') String name,
    @Default([]) List<String> files,
    @Default('') String desc,
    @Default('') String official,
    @Default({}) Map<String, dynamic> license,
  }) = _FontModel;

  factory FontModel.fromJson(Map<String, dynamic> json) => _$FontModelFromJson(json);
}
