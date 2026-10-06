/// 什么样的"视频轨"其实没有画面，应该显示房间封面而不是黑屏。
///
/// 判据是几何的：占位轨（1×1、16×16 之类）的短边小到任何真实档位都不会用。
/// 真画面最坏的守恒情况是低清竖屏，短边也在 100 上下。
bool isDummyVideoSize({required int width, required int height}) {
  if (width <= 0 || height <= 0) return false;
  final shortSide = width < height ? width : height;
  return shortSide <= dummyVideoShortSideLimit;
}

/// 短边上限（像素）。32 给 16×16 的占位轨留了一倍余量，同时离任何真实档位都还
/// 很远，所以这个阈值不需要按平台分表。
const int dummyVideoShortSideLimit = 32;

/// 语音直播平台：源里只有一路视频但其实没有真画面（背景图/纯色），和占位轨
/// 一样应该显示房间封面而不是黑屏。这些平台的流返回正常的 FLV/HLS 视频轨，
/// [isDummyVideoSize] 的短边判据不会命中，所以按平台名单兜底。
const Set<String> audioOnlyPlatforms = {'kilakila', 'missevan'};

/// 该平台是否为语音直播（即使流带视频轨也不含真画面）。
bool isAudioOnlyPlatform(String? platform) => platform != null && audioOnlyPlatforms.contains(platform);
