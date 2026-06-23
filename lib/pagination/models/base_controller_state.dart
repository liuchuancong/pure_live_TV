import 'package:freezed_annotation/freezed_annotation.dart';

part 'base_controller_state.freezed.dart';

@freezed
abstract class BaseControllerState with _$BaseControllerState {
  const factory BaseControllerState({
    @Default(false) bool pageLoading,
    @Default(false) bool loading,
    @Default(false) bool pageEmpty,
    @Default(false) bool pageError,
    @Default(false) bool notLogin,
    @Default("") String errorMsg,
  }) = _BaseControllerState;
}
