/// 生成 HttpClient.findProxy 使用的代理指令。
String buildProxyDirective({required bool enabled, required String host, required int port}) {
  if (!enabled || host.trim().isEmpty || port <= 0) return 'DIRECT';
  return 'PROXY ${host.trim()}:$port';
}
