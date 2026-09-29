import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pure_live/modules/media/models/music_archive/music_archive.dart';
import 'package:pure_live/modules/media/models/music_part/music_part.dart';

part 'music_track.freezed.dart';

/// A queue entry: which part of which archive.
@freezed
abstract class MusicTrack with _$MusicTrack {
  const factory MusicTrack({
    required MusicArchive archive,
    required MusicPart part,
  }) = _MusicTrack;

  const MusicTrack._();

  String get id => '${archive.bvid}_p${part.page}_${part.cid}';

  /// Display name: the part title; the archive title already is the part
  /// title for single-part uploads.
  String get title => part.title;
}
