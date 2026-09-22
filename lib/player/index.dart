// media_core-backed player layer.
//
// The heavy orchestration (watchdogs, line / engine fallback,
// backoff) lives in package:media_core. This barrel exports the
// facade, the engine adapters and the app-specific helpers the
// features consume.

export 'adapters/better_player_adapter.dart';
export 'adapters/flv_lzc_adapter.dart';
export 'adapters/media_kit_core_adapter.dart';
export 'core/live_room_volume_manager.dart';
export 'core/playback_proxy_policy.dart';
export 'global_player_service.dart';
export 'live_player_facade.dart';
export 'models/player_engine.dart';
export 'utils/fijk_helper.dart';
export 'utils/player_consts.dart';
