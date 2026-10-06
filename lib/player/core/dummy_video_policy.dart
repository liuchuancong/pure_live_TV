/// Whether a reported video size can carry a picture at all.
///
/// Purely geometric: a placeholder track (1x1, 16x16) has a short side no real
/// rendition would use; the worst real case, low-quality vertical, sits around
/// 100.
bool isDummyVideoSize({required int width, required int height}) {
  if (width <= 0 || height <= 0) return false;
  final shortSide = width < height ? width : height;
  return shortSide <= dummyVideoShortSideLimit;
}

/// Short-side ceiling in pixels. 32 is a full order of magnitude above a 16x16
/// placeholder and far below any real rendition, so no per-platform table.
const int dummyVideoShortSideLimit = 32;

/// Audio-live platforms: a real-sized video track that is just a backdrop
/// image, so the geometric check never fires and the cover shows instead.
const Set<String> audioOnlyPlatforms = {'kilakila', 'missevan'};

/// Whether [platform] ships no real picture even with a video track.
bool isAudioOnlyPlatform(String? platform) => platform != null && audioOnlyPlatforms.contains(platform);
