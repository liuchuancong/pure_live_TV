import 'base_controller_state.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'base_paged_state.freezed.dart';

@freezed
abstract class BasePagedState<T> with _$BasePagedState<T> {
  const factory BasePagedState({
    required BaseControllerState controllerState,
    @Default([]) List<T> items,
    @Default([]) List<T> allLocalItems,
    @Default(1) int currentPage,
    @Default(20) int pageSize,
    @Default(false) bool canLoadMore,
    int? totalCount,
  }) = _BasePagedState<T>;
}
