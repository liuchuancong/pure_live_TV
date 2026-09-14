/// core 层公共出口。
///
/// 业务代码优先 `import 'package:pure_live/core/index.dart';`，
/// 而不是逐个 import core 下的具体文件；需要 show/hide 的场景再直接引用源文件。
library;

// 站点注册表（Sites.of / supportSites）
export 'sites.dart';

// 基础能力
export 'common/index.dart';
export 'consts/index.dart';
export 'plugins/index.dart';
export 'utils/index.dart';

// 直播业务
export 'danmaku/index.dart';
export 'emoji/index.dart';
export 'interface/index.dart';
export 'iptv/index.dart';
export 'models/index.dart';
export 'site/index.dart';
export 'tars/index.dart' hide BinaryWriter, WriteBuffer, ReadBuffer;
