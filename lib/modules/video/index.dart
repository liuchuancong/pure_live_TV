/// The video module (newBV feature set): recommend / popular / ranking /
/// region / PGC / dynamics / search / personal sections, the archive detail,
/// the full-screen player with progress store, and the PGC api. Depends only
/// on modules/media and shared core.
///
/// Layout: section content hangs off `video_home_page.dart`; `pages/<domain>/`
/// the surfaces, `controllers/<domain>/` the state, `api/`+`models/` the PGC
/// layer, `widgets/` the shared card.
library;

export 'api/video_pgc_api.dart';
export 'controllers/playback/video_progress_controller.dart';
export 'controllers/playback/video_progress_state.dart';
export 'models/video_pgc_models.dart';
export 'pages/archive/video_detail_page.dart';
export 'pages/discover/video_pgc_page.dart';
export 'pages/discover/video_region_page.dart';
export 'pages/discover/video_search_page.dart';
export 'pages/discover/video_season_page.dart';
export 'pages/personal/video_personal_page.dart';
export 'pages/playback/video_player_page.dart';
export 'video_home_page.dart';
export 'widgets/video_card.dart';
