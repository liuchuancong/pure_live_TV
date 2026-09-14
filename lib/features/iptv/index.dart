/// IPTV feature exports.
///
/// `data/database.dart` and `data/tables.dart` are not exported: their drift row
/// types (Channel/EpgChannel/EpgMapping/Provider) clash with site models and the
/// riverpod Provider; import the source file directly when needed.
library;

export 'iptv_repository.dart';
export 'support/fuzzy_match.dart';
export 'models/channel.dart';
export 'models/show.dart';
export 'parsers/json_epg_parser.dart';
export 'parsers/m3u_parser.dart';
export 'parsers/playlist_parse_result.dart';
export 'parsers/txt_parser.dart';
export 'parsers/xmltv_parser.dart';
export 'platform/iptv_site.dart';
export 'services/auto_sync_scheduler.dart';
export 'services/channel_detail_controller.dart';
export 'services/epg_auto_mapper.dart';
export 'services/epg_import_manager.dart';
export 'services/epg_sync_engine.dart';
export 'services/iptv_import_manager.dart';
export 'services/iptv_sync_engine.dart';
export 'services/playlist_channel_reconciler.dart';
export 'storage/playlist_storage.dart';