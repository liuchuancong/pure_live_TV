import 'package:freezed_annotation/freezed_annotation.dart';

part 'music_up.freezed.dart';
part 'music_up.g.dart';

/// so a follow survives the archive rows it was made from.
@freezed
abstract class MusicUp with _$MusicUp {
  const factory MusicUp({
    @Default(0) int mid,
    @Default('') String name,
    @Default('') String face,
  }) = _MusicUp;

  factory MusicUp.fromJson(Map<String, dynamic> json) => _$MusicUpFromJson(json);
}
