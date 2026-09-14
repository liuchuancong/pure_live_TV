/// IPTV 能力公共出口。
///
/// 不导出 `local/database.dart`、`provider/provider.dart` 以及 `models/channel.dart`、
/// `models/epg.dart`：drift 生成的行类型（Channel/EpgChannel/EpgMapping/Provider）
/// 与站点模型、riverpod 的 `Provider` 同名。需要它们的文件请直接引用源文件。
library;

export 'iptv_repository.dart';
export 'core/fuzzy_match.dart';

// 展示用模型
export 'models/show.dart';

// 解析器
export 'parsers/json_epg_parser.dart';
export 'parsers/m3u_parser.dart';
export 'parsers/playlist_parse_result.dart';
export 'parsers/txt_parser.dart';
export 'parsers/xmltv_parser.dart';

// 业务服务
export 'services/auto_sync_scheduler.dart';
export 'services/channel_detail_controller.dart';
export 'services/epg_auto_mapper.dart';
export 'services/epg_import_manager.dart';
export 'services/epg_sync_engine.dart';
export 'services/iptv_import_manager.dart';
export 'services/iptv_sync_engine.dart';
export 'services/playlist_channel_reconciler.dart';
export 'storage/playlist_storage.dart';
