/// 应用代码统一出口（第三方 + core + 服务 + 组件 + 功能模块）。
///
/// 需要同时用到多层能力（例如播放页、设置页）时只 import 这一个文件；
/// 单一层的小文件请按需引用对应层的 export，避免无意扩大依赖面。
library;

export 'package_export.dart';
export 'models_export.dart';
export 'services_export.dart';
export 'providers_export.dart';
export 'widget_export.dart';
export 'feature_export.dart';
export 'app_export.dart';

export 'package:pure_live/core/index.dart';
