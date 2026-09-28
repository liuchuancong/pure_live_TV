/// Shared bilibili-UGC core for the music and video modules.
///
/// Boundary rules: `modules/music` and `modules/video` may import from here,
/// never from each other; the live domain (features/, platforms/) must not
/// import anything under modules/ except through the app shell (home page's
/// mode switch and the router).
///
/// Layout: `api/` the bilibili web endpoints, `models/` the response models,
/// `controllers/` the shared VOD player engine, `widgets/` shared cards and
/// the login gate, `pages/` surfaces both modules mount (comments, user
/// space, dynamics).
library;

export 'api/bilibili_music_api.dart';
export 'api/bilibili_ugc_api.dart';
export 'controllers/music_player_controller.dart';
export 'models/bilibili_music_models.dart';
export 'models/bilibili_ugc_models.dart';
export 'pages/ugc_comments_page.dart';
export 'pages/ugc_dynamics_page.dart';
export 'pages/ugc_user_space_page.dart';
export 'widgets/bilibili_login_gate.dart';
export 'widgets/music_video_card.dart';
