import 'package:freezed_annotation/freezed_annotation.dart';

part 'server_state.freezed.dart';
part 'server_state.g.dart';

@freezed
abstract class ServerState with _$ServerState {
  const factory ServerState({required bool isRunning, required String serverUrl, required int port, String? error}) =
      _ServerState;

  factory ServerState.fromJson(Map<String, dynamic> json) => _$ServerStateFromJson(json);
}
