/// Shared bilibili-UGC core for the music and video modules.
///
/// Boundary rules: `modules/music` and `modules/video` may import from here,
/// never from each other; the live domain (features/, platforms/) must not
/// import anything under modules/ except through the app shell (home page's
/// mode switch and the router).
library;

export 'bilibili_login_gate.dart';
export 'bilibili_music_api.dart';
export 'bilibili_music_models.dart';
export 'music_player_controller.dart';
export 'music_video_card.dart';
