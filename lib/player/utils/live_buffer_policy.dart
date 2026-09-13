/// Bounded low-latency buffer budget for non-seekable live streams.
///
/// Forward media is bounded by both bytes and time, rather than inheriting
/// media_kit's disk cache (where byte limits only bound packet metadata).
/// This is a demux buffer budget, not a bound on decoder/GPU/process memory.
abstract final class LiveBufferPolicy {
  static const int forwardBytes = 32 * 1024 * 1024;
  static const int backBytes = 4 * 1024 * 1024;
  static const int readaheadSeconds = 2;
  static const int cacheSeconds = 6;

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
  }
}
