import 'package:freezed_annotation/freezed_annotation.dart';

part 'fav_folder.freezed.dart';
part 'fav_folder.g.dart';

///
/// [fromJson]/[toJson] are the Hive round-trip shape; [fromListJson] maps the
/// web API row, whose cover arrives either as a url string or as an avatar
/// object carrying its own `url`.
@freezed
abstract class FavFolder with _$FavFolder {
  const factory FavFolder({
    @Default(0) int id,
    @Default('') String title,
    @Default(0) int mediaCount,
    @Default('') String cover,
    @Default(true) bool isPublic,
  }) = _FavFolder;

  factory FavFolder.fromJson(Map<String, dynamic> json) => _$FavFolderFromJson(json);

  /// One row of `x/v3/fav/folder/created/list-all` / `collected/list`;
  /// `privacy` is a flag int (0 = public).
  factory FavFolder.fromListJson(Map<dynamic, dynamic> json) {
    final cover = json['cover'];
    return FavFolder(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      title: json['title']?.toString() ?? '',
      mediaCount: int.tryParse(json['media_count']?.toString() ?? '') ?? 0,
      cover: cover is Map ? cover['url']?.toString() ?? '' : cover?.toString() ?? '',
      isPublic: (int.tryParse(json['privacy']?.toString() ?? '') ?? 0) == 0,
    );
  }
}
