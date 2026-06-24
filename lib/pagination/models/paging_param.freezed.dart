// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'paging_param.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PagingParam<T> implements DiagnosticableTreeMixin {

 PagingMode get mode; int get pageSize; int get fixedServerSize; bool get keepAlive; FetchRemote<T>? get fetchRemote; FetchAllData<T>? get fetchAll; FetchFixedSize<T>? get fetchFixed; VoidCallback? get localRefresh;
/// Create a copy of PagingParam
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PagingParamCopyWith<T, PagingParam<T>> get copyWith => _$PagingParamCopyWithImpl<T, PagingParam<T>>(this as PagingParam<T>, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'PagingParam<$T>'))
    ..add(DiagnosticsProperty('mode', mode))..add(DiagnosticsProperty('pageSize', pageSize))..add(DiagnosticsProperty('fixedServerSize', fixedServerSize))..add(DiagnosticsProperty('keepAlive', keepAlive))..add(DiagnosticsProperty('fetchRemote', fetchRemote))..add(DiagnosticsProperty('fetchAll', fetchAll))..add(DiagnosticsProperty('fetchFixed', fetchFixed))..add(DiagnosticsProperty('localRefresh', localRefresh));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PagingParam<T>&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.pageSize, pageSize) || other.pageSize == pageSize)&&(identical(other.fixedServerSize, fixedServerSize) || other.fixedServerSize == fixedServerSize)&&(identical(other.keepAlive, keepAlive) || other.keepAlive == keepAlive)&&(identical(other.fetchRemote, fetchRemote) || other.fetchRemote == fetchRemote)&&(identical(other.fetchAll, fetchAll) || other.fetchAll == fetchAll)&&(identical(other.fetchFixed, fetchFixed) || other.fetchFixed == fetchFixed)&&(identical(other.localRefresh, localRefresh) || other.localRefresh == localRefresh));
}


@override
int get hashCode => Object.hash(runtimeType,mode,pageSize,fixedServerSize,keepAlive,fetchRemote,fetchAll,fetchFixed,localRefresh);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'PagingParam<$T>(mode: $mode, pageSize: $pageSize, fixedServerSize: $fixedServerSize, keepAlive: $keepAlive, fetchRemote: $fetchRemote, fetchAll: $fetchAll, fetchFixed: $fetchFixed, localRefresh: $localRefresh)';
}


}

/// @nodoc
abstract mixin class $PagingParamCopyWith<T,$Res>  {
  factory $PagingParamCopyWith(PagingParam<T> value, $Res Function(PagingParam<T>) _then) = _$PagingParamCopyWithImpl;
@useResult
$Res call({
 PagingMode mode, int pageSize, int fixedServerSize, bool keepAlive, FetchRemote<T>? fetchRemote, FetchAllData<T>? fetchAll, FetchFixedSize<T>? fetchFixed, VoidCallback? localRefresh
});




}
/// @nodoc
class _$PagingParamCopyWithImpl<T,$Res>
    implements $PagingParamCopyWith<T, $Res> {
  _$PagingParamCopyWithImpl(this._self, this._then);

  final PagingParam<T> _self;
  final $Res Function(PagingParam<T>) _then;

/// Create a copy of PagingParam
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? mode = null,Object? pageSize = null,Object? fixedServerSize = null,Object? keepAlive = null,Object? fetchRemote = freezed,Object? fetchAll = freezed,Object? fetchFixed = freezed,Object? localRefresh = freezed,}) {
  return _then(_self.copyWith(
mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as PagingMode,pageSize: null == pageSize ? _self.pageSize : pageSize // ignore: cast_nullable_to_non_nullable
as int,fixedServerSize: null == fixedServerSize ? _self.fixedServerSize : fixedServerSize // ignore: cast_nullable_to_non_nullable
as int,keepAlive: null == keepAlive ? _self.keepAlive : keepAlive // ignore: cast_nullable_to_non_nullable
as bool,fetchRemote: freezed == fetchRemote ? _self.fetchRemote : fetchRemote // ignore: cast_nullable_to_non_nullable
as FetchRemote<T>?,fetchAll: freezed == fetchAll ? _self.fetchAll : fetchAll // ignore: cast_nullable_to_non_nullable
as FetchAllData<T>?,fetchFixed: freezed == fetchFixed ? _self.fetchFixed : fetchFixed // ignore: cast_nullable_to_non_nullable
as FetchFixedSize<T>?,localRefresh: freezed == localRefresh ? _self.localRefresh : localRefresh // ignore: cast_nullable_to_non_nullable
as VoidCallback?,
  ));
}

}


/// Adds pattern-matching-related methods to [PagingParam].
extension PagingParamPatterns<T> on PagingParam<T> {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PagingParam<T> value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PagingParam() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PagingParam<T> value)  $default,){
final _that = this;
switch (_that) {
case _PagingParam():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PagingParam<T> value)?  $default,){
final _that = this;
switch (_that) {
case _PagingParam() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PagingMode mode,  int pageSize,  int fixedServerSize,  bool keepAlive,  FetchRemote<T>? fetchRemote,  FetchAllData<T>? fetchAll,  FetchFixedSize<T>? fetchFixed,  VoidCallback? localRefresh)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PagingParam() when $default != null:
return $default(_that.mode,_that.pageSize,_that.fixedServerSize,_that.keepAlive,_that.fetchRemote,_that.fetchAll,_that.fetchFixed,_that.localRefresh);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PagingMode mode,  int pageSize,  int fixedServerSize,  bool keepAlive,  FetchRemote<T>? fetchRemote,  FetchAllData<T>? fetchAll,  FetchFixedSize<T>? fetchFixed,  VoidCallback? localRefresh)  $default,) {final _that = this;
switch (_that) {
case _PagingParam():
return $default(_that.mode,_that.pageSize,_that.fixedServerSize,_that.keepAlive,_that.fetchRemote,_that.fetchAll,_that.fetchFixed,_that.localRefresh);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PagingMode mode,  int pageSize,  int fixedServerSize,  bool keepAlive,  FetchRemote<T>? fetchRemote,  FetchAllData<T>? fetchAll,  FetchFixedSize<T>? fetchFixed,  VoidCallback? localRefresh)?  $default,) {final _that = this;
switch (_that) {
case _PagingParam() when $default != null:
return $default(_that.mode,_that.pageSize,_that.fixedServerSize,_that.keepAlive,_that.fetchRemote,_that.fetchAll,_that.fetchFixed,_that.localRefresh);case _:
  return null;

}
}

}

/// @nodoc


class _PagingParam<T> with DiagnosticableTreeMixin implements PagingParam<T> {
  const _PagingParam({required this.mode, this.pageSize = 20, this.fixedServerSize = 20, this.keepAlive = false, this.fetchRemote, this.fetchAll, this.fetchFixed, this.localRefresh});
  

@override final  PagingMode mode;
@override@JsonKey() final  int pageSize;
@override@JsonKey() final  int fixedServerSize;
@override@JsonKey() final  bool keepAlive;
@override final  FetchRemote<T>? fetchRemote;
@override final  FetchAllData<T>? fetchAll;
@override final  FetchFixedSize<T>? fetchFixed;
@override final  VoidCallback? localRefresh;

/// Create a copy of PagingParam
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PagingParamCopyWith<T, _PagingParam<T>> get copyWith => __$PagingParamCopyWithImpl<T, _PagingParam<T>>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'PagingParam<$T>'))
    ..add(DiagnosticsProperty('mode', mode))..add(DiagnosticsProperty('pageSize', pageSize))..add(DiagnosticsProperty('fixedServerSize', fixedServerSize))..add(DiagnosticsProperty('keepAlive', keepAlive))..add(DiagnosticsProperty('fetchRemote', fetchRemote))..add(DiagnosticsProperty('fetchAll', fetchAll))..add(DiagnosticsProperty('fetchFixed', fetchFixed))..add(DiagnosticsProperty('localRefresh', localRefresh));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PagingParam<T>&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.pageSize, pageSize) || other.pageSize == pageSize)&&(identical(other.fixedServerSize, fixedServerSize) || other.fixedServerSize == fixedServerSize)&&(identical(other.keepAlive, keepAlive) || other.keepAlive == keepAlive)&&(identical(other.fetchRemote, fetchRemote) || other.fetchRemote == fetchRemote)&&(identical(other.fetchAll, fetchAll) || other.fetchAll == fetchAll)&&(identical(other.fetchFixed, fetchFixed) || other.fetchFixed == fetchFixed)&&(identical(other.localRefresh, localRefresh) || other.localRefresh == localRefresh));
}


@override
int get hashCode => Object.hash(runtimeType,mode,pageSize,fixedServerSize,keepAlive,fetchRemote,fetchAll,fetchFixed,localRefresh);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'PagingParam<$T>(mode: $mode, pageSize: $pageSize, fixedServerSize: $fixedServerSize, keepAlive: $keepAlive, fetchRemote: $fetchRemote, fetchAll: $fetchAll, fetchFixed: $fetchFixed, localRefresh: $localRefresh)';
}


}

/// @nodoc
abstract mixin class _$PagingParamCopyWith<T,$Res> implements $PagingParamCopyWith<T, $Res> {
  factory _$PagingParamCopyWith(_PagingParam<T> value, $Res Function(_PagingParam<T>) _then) = __$PagingParamCopyWithImpl;
@override @useResult
$Res call({
 PagingMode mode, int pageSize, int fixedServerSize, bool keepAlive, FetchRemote<T>? fetchRemote, FetchAllData<T>? fetchAll, FetchFixedSize<T>? fetchFixed, VoidCallback? localRefresh
});




}
/// @nodoc
class __$PagingParamCopyWithImpl<T,$Res>
    implements _$PagingParamCopyWith<T, $Res> {
  __$PagingParamCopyWithImpl(this._self, this._then);

  final _PagingParam<T> _self;
  final $Res Function(_PagingParam<T>) _then;

/// Create a copy of PagingParam
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? mode = null,Object? pageSize = null,Object? fixedServerSize = null,Object? keepAlive = null,Object? fetchRemote = freezed,Object? fetchAll = freezed,Object? fetchFixed = freezed,Object? localRefresh = freezed,}) {
  return _then(_PagingParam<T>(
mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as PagingMode,pageSize: null == pageSize ? _self.pageSize : pageSize // ignore: cast_nullable_to_non_nullable
as int,fixedServerSize: null == fixedServerSize ? _self.fixedServerSize : fixedServerSize // ignore: cast_nullable_to_non_nullable
as int,keepAlive: null == keepAlive ? _self.keepAlive : keepAlive // ignore: cast_nullable_to_non_nullable
as bool,fetchRemote: freezed == fetchRemote ? _self.fetchRemote : fetchRemote // ignore: cast_nullable_to_non_nullable
as FetchRemote<T>?,fetchAll: freezed == fetchAll ? _self.fetchAll : fetchAll // ignore: cast_nullable_to_non_nullable
as FetchAllData<T>?,fetchFixed: freezed == fetchFixed ? _self.fetchFixed : fetchFixed // ignore: cast_nullable_to_non_nullable
as FetchFixedSize<T>?,localRefresh: freezed == localRefresh ? _self.localRefresh : localRefresh // ignore: cast_nullable_to_non_nullable
as VoidCallback?,
  ));
}


}

// dart format on
