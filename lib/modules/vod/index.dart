/// Shared VOD core for the music and video modules: the bilibili web
/// endpoints, the playback engine and the surfaces both modes mount.
///
/// Boundary rules: `modules/music` and `modules/video` may import from here,
/// never from each other; the live domain (features/, platforms/) must not
/// import anything under modules/ except through the app shell (home page's
/// mode switch and the router). Music-only endpoints (third-party playlist
/// providers, lyrics) live under `modules/music/api/` instead.
///
/// Layout: `api/` the bilibili web endpoints, `models/` the response models
/// (one folder per model behind `models/models.dart`), `controllers/` the
/// shared VOD player engine, `widgets/` shared cards and the login gate,
/// `pages/` surfaces both modules mount (comments, user space, dynamics).
library;

export 'api/bilibili_api_client.dart';
export 'api/bilibili_danmaku_api.dart';
export 'api/bilibili_lyric_api.dart';
export 'api/bilibili_music_api.dart';
export 'api/bilibili_pgc_api.dart';
export 'api/bilibili_ugc_api.dart';
export 'controllers/music_player_controller.dart';
export 'controllers/video_player_controller.dart';
export 'controllers/vod_playback_core.dart';
export 'models/models.dart';
export 'pages/ugc_comments_page.dart';
export 'pages/ugc_dynamics_page.dart';
export 'pages/ugc_user_space_page.dart';
export 'widgets/bilibili_login_gate.dart';
export 'widgets/handle_video_surface.dart';
