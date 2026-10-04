import 'dart:async';

import 'package:media_core_ingest/media_core_ingest.dart';
import 'package:media_core_recording_ffmpeg/media_core_recording_ffmpeg.dart';

/// [IngestFfmpegStarter] backed by media_core's own [FfmpegKitExecutor].
///
/// media_core_ingest deliberately ships no FFmpeg binary — the host injects
/// one. media_core_recording_ffmpeg already wraps `ffmpeg_kit_extended_flutter`
/// behind [FfmpegExecutor]; this file adapts that interface to the
/// [IngestFfmpegProcess] contract the relay expects.
///
/// The executor is lazily initialized on first use and lives for the app
/// session (FFmpegKit's native load is expensive; one instance serves every
/// relay start).
final FfmpegKitExecutor _executor = FfmpegKitExecutor();
bool _initialized = false;

Future<IngestFfmpegProcess> startIngestFfmpeg(List<String> arguments) async {
  if (!_initialized) {
    await _executor.initialize();
    _initialized = true;
  }
  final execution = await _executor.start(arguments: arguments);
  return _ExecutionAdapter(execution);
}

/// Thin adapter: [FfmpegExecution] → [IngestFfmpegProcess].
///
/// The two interfaces carry the same two members the relay needs (exitCode,
/// stop); this just bridges the type gap without duplicating lifecycle logic.
final class _ExecutionAdapter implements IngestFfmpegProcess {
  _ExecutionAdapter(this._inner);

  final FfmpegExecution _inner;

  @override
  Future<int> get exitCode => _inner.exitCode;

  @override
  Future<void> stop() => _inner.stop();
}
