/// The music module (bmsc feature set): the local library, synced playlists,
/// discovery (dynamics / cloud history / ranking / search) and the
/// full-screen lyric player. Depends only on modules/media and shared core.
///
/// Layout: section content hangs off `music_page.dart`; `pages/<domain>/`
/// holds the surfaces, `controllers/<domain>/` the state, `services/` the
/// lyric chain.
library;

export 'controllers/library/music_library_controller.dart';
export 'controllers/playlist/music_playlist_sync_controller.dart';
export 'controllers/playlist/music_playlist_sync_state.dart';
export 'music_page.dart';
export 'pages/discover/music_cloud_history_page.dart';
export 'pages/playback/music_archive_page.dart';
export 'pages/playback/music_player_page.dart';
export 'pages/playlist/music_fav_detail_page.dart';
export 'pages/playlist/music_fav_folders_page.dart';
export 'services/music_lyric_service.dart';
