import 'package:flutter/foundation.dart';
import 'package:pure_live/pagination/type_def/fun.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pure_live/pagination/models/paging_model.dart';

part 'paging_param.freezed.dart';

@freezed
abstract class PagingParam<T> with _$PagingParam<T> {
  const factory PagingParam({
    required PagingMode mode,
    @Default(20) int pageSize,
    @Default(20) int fixedServerSize,
    @Default(false) bool keepAlive,
    FetchRemote<T>? fetchRemote,
    FetchAllData<T>? fetchAll,
    FetchFixedSize<T>? fetchFixed,
    VoidCallback? localRefresh,
  }) = _PagingParam<T>;
}
