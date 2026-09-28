import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:pure_live/exports/common_export.dart';
import 'package:pure_live/modules/media/models/bilibili_music_models.dart';
import 'package:pure_live/modules/video/controllers/playback/video_progress_state.dart';

part 'video_progress_controller.g.dart';

/// The video module's local watch-progress store, newBV's 已播进度条: every
/// part that opens reports its position, cards render the progress bar, and a
/// reopened archive resumes from where it stopped.
///
/// Persisted in the video-module Hive key `videoWatchProgress` — music keeps
/// its own keys and the two libraries never touch.
@Riverpod(keepAlive: true)
class VideoProgressController extends _$VideoProgressController {
  static const String _key = 'videoWatchProgress';

  @override
  VideoProgressState build() {
    return VideoProgressState(entries: _load());
  }

  double percentOf(String bvid) => state.entries[bvid]?.percent ?? 0;

  VideoProgressEntry? entryFor(String bvid) => state.entries[bvid];

  /// Reports one playback tick (called from the player page on a timer, so it
  /// must be cheap and persist only on meaningful movement).
  void record(
    String bvid, {
    required int cid,
    required int position,
    required int duration,
    MusicArchive? archive,
  }) {
    if (bvid.isEmpty || duration <= 0) return;
    final percent = (position / duration).clamp(0.0, 1.0);
    if (percent >= 0.995) return; // finished rows drop off the resume bar
    final entry = VideoProgressEntry(
      cid: cid,
      position: position,
      duration: duration,
      percent: percent,
      updatedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      archive: archive,
    );
    final existing = state.entries[bvid];
    if (existing != null &&
        existing.cid == cid &&
        (position - existing.position).abs() < 15 &&
        existing.archive != null) {
      return; // same part, moved under 15s: not worth a Hive write
    }
    state = state.copyWith(entries: {...state.entries, bvid: entry});
    _persist();
  }

  /// Finished parts are removed so their bars disappear.
  void clear(String bvid) {
    state = state.copyWith(entries: {...state.entries}..remove(bvid));
    _persist();
  }

  Map<String, VideoProgressEntry> _load() {
    try {
      final raw = HivePrefUtil.getString(_key);
      if (raw == null || raw.isEmpty) return {};
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      return {
        for (final entry in decoded.entries)
          entry.key.toString(): VideoProgressEntry(
            cid: int.tryParse(entry.value?['cid']?.toString() ?? '') ?? 0,
            position: int.tryParse(entry.value?['position']?.toString() ?? '') ?? 0,
            duration: int.tryParse(entry.value?['duration']?.toString() ?? '') ?? 0,
            percent: double.tryParse(entry.value?['percent']?.toString() ?? '') ?? 0,
            updatedAt: int.tryParse(entry.value?['updatedAt']?.toString() ?? '') ?? 0,
            archive: entry.value?['archive'] is Map<String, dynamic>
                ? MusicArchive.fromJson(entry.value['archive'] as Map<String, dynamic>)
                : null,
          ),
      };
    } catch (_) {
      return {};
    }
  }

  void _persist() {
    HivePrefUtil.setString(
      _key,
      jsonEncode({
        for (final entry in state.entries.entries)
          entry.key: {
            'cid': entry.value.cid,
            'position': entry.value.position,
            'duration': entry.value.duration,
            'percent': entry.value.percent,
            'updatedAt': entry.value.updatedAt,
            if (entry.value.archive != null) 'archive': entry.value.archive!.toJson(),
          },
      }),
    );
  }
}
