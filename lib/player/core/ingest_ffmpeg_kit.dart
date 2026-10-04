import 'dart:async';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_session.dart';
import 'package:media_core_ingest/media_core_ingest.dart';

/// [IngestFfmpegStarter] backed by `ffmpeg_kit_flutter_new`.
///
/// media_core_ingest deliberately ships no FFmpeg binary — the host injects
/// one. This is the TV app's injection: it wraps an [FFmpegSession] in the
/// [IngestFfmpegProcess] contract the relay expects.
///
/// The session runs asynchronously (`executeWithArguments` returns once the
/// native side has accepted the command); the relay waits for the first
/// playlist file, which is the real readiness signal. A session that dies
/// before publishing a playlist surfaces through
/// [IngestFfmpegProcess.exitCode], and the relay's startup wait throws.
Future<IngestFfmpegProcess> startIngestFfmpeg(List<String> arguments) async {
  final session = await FFmpegKit.executeWithArguments(arguments);
  return _FfmpegKitProcess(session);
}

final class _FfmpegKitProcess implements IngestFfmpegProcess {
  _FfmpegKitProcess(this._session);

  final FFmpegSession _session;
  bool _stopped = false;

  @override
  Future<int> get exitCode async {
    final returnCode = await _session.getReturnCode();
    // FFmpegKit maps a cancelled session to 255; the relay treats any non-zero
    // exit before the first playlist as a startup failure.
    return returnCode?.getValue() ?? 255;
  }

  @override
  Future<void> stop() async {
    if (_stopped) return;
    _stopped = true;
    await FFmpegKit.cancel(_session.getSessionId());
  }
}
