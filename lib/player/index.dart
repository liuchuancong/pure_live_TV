// media_core-backed player layer.
//
// The heavy orchestration (watchdogs, line / engine fallback,
// backoff) lives in package:media_core. This barrel exports the
// facade, the engine adapters and the app-specific helpers the
// features consume.

export 'adapters/flv_lzc_adapter.dart';
export 'adapters/media_kit_core_adapter.dart';
export 'core/live_room_volume_manager.dart';
export 'core/playback_proxy_policy.dart';
export 'global_player_service.dart';
export 'live_player_facade.dart';
export 'models/player_engine.dart';
export 'models/player_error_type.dart';
export 'models/player_exception.dart';
export 'models/player_state.dart';
export 'utils/fijk_helper.dart';
export 'utils/player_consts.dart';
