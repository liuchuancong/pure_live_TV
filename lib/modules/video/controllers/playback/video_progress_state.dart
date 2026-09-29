import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pure_live/modules/media/models/models.dart';

part 'video_progress_state.freezed.dart';

/// One archive's local watch progress — what the card progress bars and the
/// resume-on-reopen read. PGC episodes ride the same store keyed by the
/// season's pseudo-bvid.
@freezed
abstract class VideoProgressEntry with _$VideoProgressEntry {
  const factory VideoProgressEntry({
    @Default(0) int cid,
    @Default(0) int position,
    @Default(0) int duration,
    @Default(0) double percent,
    @Default(0) int updatedAt,
    MusicArchive? archive,
  }) = _VideoProgressEntry;
}

@freezed
abstract class VideoProgressState with _$VideoProgressState {
  const factory VideoProgressState({@Default({}) Map<String, VideoProgressEntry> entries}) = _VideoProgressState;
}
