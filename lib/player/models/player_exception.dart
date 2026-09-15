import 'player_error_type.dart';

class PlayerException implements Exception {
  final String message;

  /// Stable machine-readable diagnostic code for recovery strategies. The UI
  /// should only display [message] and must not parse this field.
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
