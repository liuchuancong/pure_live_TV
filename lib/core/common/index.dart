/// core/common 公共出口：网络、HLS、请求作用域与通用转换。
///
/// 日志/二进制/WebSocket 等工具已统一收敛到 `core/utils`，这里保留转发，
/// 让只 import 本文件的历史调用点继续可用（同一份实现，不产生二义性）。
library;

export 'android_native_http.dart';
export 'convert_helper.dart';
export 'fk_user_agent.dart';
export 'hls_master_selection.dart';
export 'hls_session_cookies.dart';
export 'hls_source_query_policy.dart';
export 'http_client.dart';
export 'http_header_policy.dart';
export 'iterum.dart';
export 'proxy_routing.dart';
export 'request_scope.dart';
export 'utils/color_util.dart';
export 'utils/list_util.dart';
export '../utils/text_util.dart';

// 已迁移至 core/utils 的工具（同源转发，避免调用点失效）
export '../utils/binary_writer.dart';
export '../utils/core_error.dart';
export '../utils/core_log.dart';
export '../utils/custom_interceptor.dart';
export '../utils/log.dart';
export '../utils/web_socket_util.dart';
