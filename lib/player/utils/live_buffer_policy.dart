/// Bounded buffer budget for non-seekable live streams.
///
/// Forward media is bounded by both bytes and time, rather than inheriting
/// media_kit's disk cache (where byte limits only bound packet metadata).
/// This is a demux buffer budget, not a bound on decoder/GPU/process memory.
///
/// The sizes used to chase low latency (2s readahead, 6s cache) — on a TV box
/// a single network hiccup or a bitrate spike drained the forward buffer
/// faster than it refilled, and the visible result was constant stutter.
/// The budget now trades a few seconds of latency for headroom: readahead
/// keeps ~8s of media, the demuxer may prefetch ~30s ahead, and `cache-pause`
/// refills a *drained* buffer to 4s before resuming instead of resuming into
/// an immediately-empty one (the classic stutter loop).
abstract final class LiveBufferPolicy {
  static const int forwardBytes = 96 * 1024 * 1024;
  static const int backBytes = 8 * 1024 * 1024;
  static const int readaheadSeconds = 8;
  static const int cacheSeconds = 30;

  /// When the buffer runs dry, resume only after this much media is back.
  static const int cachePauseWaitSeconds = 4;

  static Future<void> apply(Future<void> Function(String name, String value) setProperty) async {
    // Network cache-secs takes precedence over the smaller base readahead.
    // Set the whole contract before opening media, including inherited values.
    await setProperty('cache', 'yes');
    await setProperty('cache-on-disk', 'no');
    await setProperty('cache-secs', cacheSeconds.toString());
    await setProperty('demuxer-max-bytes', forwardBytes.toString());
    await setProperty('demuxer-max-back-bytes', backBytes.toString());
    // Past media must not borrow the unused forward reserve. Otherwise low
    // bitrate live streams keep accumulating minutes of unwanted back cache.
    await setProperty('demuxer-donate-buffer', 'no');
    await setProperty('demuxer-readahead-secs', readaheadSeconds.toString());
    // Refill-then-resume: after a stall, wait for a healthy buffer instead of
    // restarting playback into an empty one.
    await setProperty('cache-pause', 'yes');
    await setProperty('cache-pause-wait', cachePauseWaitSeconds.toString());
    // Let the demuxer thread read while the decoder drains, so a slow fill
    // never serializes with decoding.
    await setProperty('demuxer-thread', 'yes');
    // Drop late frames rather than stacking them: on a stalled fill a frame
    // backlog turns into seconds of accumulated lag and visible stutter.
    await setProperty('framedrop', 'decoder+vo');
  }
}
