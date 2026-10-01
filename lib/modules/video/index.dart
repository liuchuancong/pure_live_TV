/// The video module (newBV feature set): recommend / popular / ranking /
/// region / PGC / dynamics / search / personal sections, the archive detail
/// and the full-screen player with progress store. Depends only on
/// modules/vod and shared core — the PGC endpoints and models live in the
/// shared vod layer.
///
/// Layout: section content hangs off `video_home_page.dart`; `pages/<domain>/`
/// the surfaces, `controllers/<domain>/` the state, `widgets/` the shared
/// card.
library;

export 'controllers/playback/video_progress_controller.dart';
export 'controllers/playback/video_progress_state.dart';
export 'pages/archive/video_detail_page.dart';
export 'pages/discover/video_pgc_page.dart';
export 'pages/discover/video_region_page.dart';
export 'pages/discover/video_search_page.dart';
export 'pages/discover/video_tag_search_page.dart';
export 'pages/discover/video_season_page.dart';
export 'pages/personal/video_personal_section.dart';
export 'video_section.dart';
export 'video_section_view.dart';
export 'pages/playback/video_player_page.dart';
export 'pages/home/video_home_page.dart';
export 'widgets/video_card.dart';
