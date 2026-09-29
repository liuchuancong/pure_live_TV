/// The live-mode domains, module siblings of music/ and video/: the play
/// session (playback/), the channel sources (hot/ areas/ favorite/
/// favorite_areas/ history/), IPTV, the movie playback surface and the TV
/// search. Device sync moved to domains/device/. Each keeps its own index;
/// this barrel is the app shell's single entry.
library;

export 'areas/index.dart';
export 'favorite/index.dart';
export 'favorite_areas/index.dart';
export 'history/index.dart';
export 'hot/index.dart';
export 'iptv/index.dart';
export 'movie_playback/index.dart';
export 'playback/index.dart';
export 'search/index.dart';
