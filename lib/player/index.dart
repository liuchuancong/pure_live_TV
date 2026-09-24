// media_core-backed player layer.
//
// The heavy orchestration (watchdogs, line / engine fallback,
// backoff) lives in package:media_core, and the engine adapters come
// from the media_core adapter packages (media_core_media_kit /
// media_core_ijk_player / media_core_better_player). This barrel only
// exports the app-facing surface: the facade, the kernel-registration
// service and the app-specific helpers the features consume.

export 'core/live_room_volume_manager.dart';
export 'core/playback_proxy_policy.dart';
export 'global_player_service.dart';
export 'live_player_facade.dart';
export 'models/player_engine.dart';
export 'utils/player_consts.dart';
