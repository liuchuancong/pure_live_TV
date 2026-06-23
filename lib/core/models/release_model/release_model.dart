import 'package:freezed_annotation/freezed_annotation.dart';

part 'release_model.freezed.dart';
part 'release_model.g.dart';

@freezed
abstract class ReleaseModel with _$ReleaseModel {
  const factory ReleaseModel({
    @Default('') String version,
    @Default('') String title,
    @Default('') String date,
    @Default('') String github,
    required AuthorModel author,
    @Default('') String changeLog,
    @Default([]) List<ReleaseFileModel> files,
  }) = _ReleaseModel;

  factory ReleaseModel.fromJson(Map<String, dynamic> json) => _$ReleaseModelFromJson(json);
}

@freezed
abstract class AuthorModel with _$AuthorModel {
  const factory AuthorModel({@Default('') String name, @Default('') String avatar, @Default('') String profile}) =
      _AuthorModel;

  factory AuthorModel.fromJson(Map<String, dynamic> json) => _$AuthorModelFromJson(json);
}

@freezed
abstract class ReleaseFileModel with _$ReleaseFileModel {
  const factory ReleaseFileModel({
    @Default('') String name,
    @Default('') String size,
    @Default(0) int downloads,
    @Default('') String url,
  }) = _ReleaseFileModel;

  factory ReleaseFileModel.fromJson(Map<String, dynamic> json) => _$ReleaseFileModelFromJson(json);
}
