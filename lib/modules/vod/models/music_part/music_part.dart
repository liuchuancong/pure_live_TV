import 'package:freezed_annotation/freezed_annotation.dart';

part 'music_part.freezed.dart';
part 'music_part.g.dart';

/// One part (P) of an archive — the unit the queue plays.
@freezed
abstract class MusicPart with _$MusicPart {
  const factory MusicPart({
    @Default(0) int cid,
    @Default(1) int page,
    @Default('') String title,
    @Default(0) int duration,

    /// PGC episodes play through the pgc playurl endpoint instead; 0 = plain UGC.
    @Default(0) int epId,
  }) = _MusicPart;

  factory MusicPart.fromJson(Map<String, dynamic> json) => _$MusicPartFromJson(json);
}
