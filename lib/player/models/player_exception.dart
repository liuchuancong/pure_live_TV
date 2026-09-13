import 'player_error_type.dart';

class PlayerException implements Exception {
  final String message;

  /// 稳定的机器可读诊断码，供恢复策略使用；UI 只展示 [message]，不要解析该字段
  final String? code;

  final Object? error;

  final StackTrace? stackTrace;

  final PlayerErrorType type;

  PlayerException({required this.message, required this.type, this.code, this.error, this.stackTrace});

  @override
  String toString() {
    return '[${type.name}] $message';
  }
}
