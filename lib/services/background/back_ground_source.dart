// lib/common/enums/background_source.dart
enum BackgroundSource {
  none,
  color,
  gradient,
  localImage,
  assetImage,
  networkImage,
  assetVideo,
  localVideo,
  networkVideo,
}

String bgSourceToString(BackgroundSource source) => source.name;

BackgroundSource bgSourceFromString(String str) {
  return BackgroundSource.values.firstWhere((item) => item.name == str, orElse: () => BackgroundSource.none);
}
