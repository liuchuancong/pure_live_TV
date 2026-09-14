import 'package:flutter/material.dart';

/// 应用级导航入口。
///
/// 服务层（IPTV/EPG 导入等）需要在没有 `BuildContext` 的位置弹确认框；
/// GetX 移除后统一使用这个 key，而不是让每个服务各自持有 Navigator。
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

/// 当前可用导航上下文；应用尚未挂载或已销毁时为 null。
BuildContext? get appNavigatorContext {
  final context = appNavigatorKey.currentContext;
  if (context == null || !context.mounted) return null;
  return context;
}
