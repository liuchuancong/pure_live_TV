// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'base_controller_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BaseControllerState {

 bool get pageLoading; bool get loading; bool get pageEmpty; bool get pageError; bool get notLogin; String get errorMsg;
/// Create a copy of BaseControllerState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BaseControllerStateCopyWith<BaseControllerState> get copyWith => _$BaseControllerStateCopyWithImpl<BaseControllerState>(this as BaseControllerState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BaseControllerState&&(identical(other.pageLoading, pageLoading) || other.pageLoading == pageLoading)&&(identical(other.loading, loading) || other.loading == loading)&&(identical(other.pageEmpty, pageEmpty) || other.pageEmpty == pageEmpty)&&(identical(other.pageError, pageError) || other.pageError == pageError)&&(identical(other.notLogin, notLogin) || other.notLogin == notLogin)&&(identical(other.errorMsg, errorMsg) || other.errorMsg == errorMsg));
}


@override
int get hashCode => Object.hash(runtimeType,pageLoading,loading,pageEmpty,pageError,notLogin,errorMsg);

@override
String toString() {
  return 'BaseControllerState(pageLoading: $pageLoading, loading: $loading, pageEmpty: $pageEmpty, pageError: $pageError, notLogin: $notLogin, errorMsg: $errorMsg)';
}


}

/// @nodoc
abstract mixin class $BaseControllerStateCopyWith<$Res>  {
  factory $BaseControllerStateCopyWith(BaseControllerState value, $Res Function(BaseControllerState) _then) = _$BaseControllerStateCopyWithImpl;
@useResult
$Res call({
 bool pageLoading, bool loading, bool pageEmpty, bool pageError, bool notLogin, String errorMsg
});




}
/// @nodoc
class _$BaseControllerStateCopyWithImpl<$Res>
    implements $BaseControllerStateCopyWith<$Res> {
  _$BaseControllerStateCopyWithImpl(this._self, this._then);

  final BaseControllerState _self;
  final $Res Function(BaseControllerState) _then;

/// Create a copy of BaseControllerState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? pageLoading = null,Object? loading = null,Object? pageEmpty = null,Object? pageError = null,Object? notLogin = null,Object? errorMsg = null,}) {
  return _then(_self.copyWith(
pageLoading: null == pageLoading ? _self.pageLoading : pageLoading // ignore: cast_nullable_to_non_nullable
as bool,loading: null == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as bool,pageEmpty: null == pageEmpty ? _self.pageEmpty : pageEmpty // ignore: cast_nullable_to_non_nullable
as bool,pageError: null == pageError ? _self.pageError : pageError // ignore: cast_nullable_to_non_nullable
as bool,notLogin: null == notLogin ? _self.notLogin : notLogin // ignore: cast_nullable_to_non_nullable
as bool,errorMsg: null == errorMsg ? _self.errorMsg : errorMsg // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [BaseControllerState].
extension BaseControllerStatePatterns on BaseControllerState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BaseControllerState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BaseControllerState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BaseControllerState value)  $default,){
final _that = this;
switch (_that) {
case _BaseControllerState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BaseControllerState value)?  $default,){
final _that = this;
switch (_that) {
case _BaseControllerState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool pageLoading,  bool loading,  bool pageEmpty,  bool pageError,  bool notLogin,  String errorMsg)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BaseControllerState() when $default != null:
return $default(_that.pageLoading,_that.loading,_that.pageEmpty,_that.pageError,_that.notLogin,_that.errorMsg);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool pageLoading,  bool loading,  bool pageEmpty,  bool pageError,  bool notLogin,  String errorMsg)  $default,) {final _that = this;
switch (_that) {
case _BaseControllerState():
return $default(_that.pageLoading,_that.loading,_that.pageEmpty,_that.pageError,_that.notLogin,_that.errorMsg);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool pageLoading,  bool loading,  bool pageEmpty,  bool pageError,  bool notLogin,  String errorMsg)?  $default,) {final _that = this;
switch (_that) {
case _BaseControllerState() when $default != null:
return $default(_that.pageLoading,_that.loading,_that.pageEmpty,_that.pageError,_that.notLogin,_that.errorMsg);case _:
  return null;

}
}

}

/// @nodoc


class _BaseControllerState implements BaseControllerState {
  const _BaseControllerState({this.pageLoading = false, this.loading = false, this.pageEmpty = false, this.pageError = false, this.notLogin = false, this.errorMsg = ""});
  

@override@JsonKey() final  bool pageLoading;
@override@JsonKey() final  bool loading;
@override@JsonKey() final  bool pageEmpty;
@override@JsonKey() final  bool pageError;
@override@JsonKey() final  bool notLogin;
@override@JsonKey() final  String errorMsg;

/// Create a copy of BaseControllerState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BaseControllerStateCopyWith<_BaseControllerState> get copyWith => __$BaseControllerStateCopyWithImpl<_BaseControllerState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BaseControllerState&&(identical(other.pageLoading, pageLoading) || other.pageLoading == pageLoading)&&(identical(other.loading, loading) || other.loading == loading)&&(identical(other.pageEmpty, pageEmpty) || other.pageEmpty == pageEmpty)&&(identical(other.pageError, pageError) || other.pageError == pageError)&&(identical(other.notLogin, notLogin) || other.notLogin == notLogin)&&(identical(other.errorMsg, errorMsg) || other.errorMsg == errorMsg));
}


@override
int get hashCode => Object.hash(runtimeType,pageLoading,loading,pageEmpty,pageError,notLogin,errorMsg);

@override
String toString() {
  return 'BaseControllerState(pageLoading: $pageLoading, loading: $loading, pageEmpty: $pageEmpty, pageError: $pageError, notLogin: $notLogin, errorMsg: $errorMsg)';
}


}

/// @nodoc
abstract mixin class _$BaseControllerStateCopyWith<$Res> implements $BaseControllerStateCopyWith<$Res> {
  factory _$BaseControllerStateCopyWith(_BaseControllerState value, $Res Function(_BaseControllerState) _then) = __$BaseControllerStateCopyWithImpl;
@override @useResult
$Res call({
 bool pageLoading, bool loading, bool pageEmpty, bool pageError, bool notLogin, String errorMsg
});




}
/// @nodoc
class __$BaseControllerStateCopyWithImpl<$Res>
    implements _$BaseControllerStateCopyWith<$Res> {
  __$BaseControllerStateCopyWithImpl(this._self, this._then);

  final _BaseControllerState _self;
  final $Res Function(_BaseControllerState) _then;

/// Create a copy of BaseControllerState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? pageLoading = null,Object? loading = null,Object? pageEmpty = null,Object? pageError = null,Object? notLogin = null,Object? errorMsg = null,}) {
  return _then(_BaseControllerState(
pageLoading: null == pageLoading ? _self.pageLoading : pageLoading // ignore: cast_nullable_to_non_nullable
as bool,loading: null == loading ? _self.loading : loading // ignore: cast_nullable_to_non_nullable
as bool,pageEmpty: null == pageEmpty ? _self.pageEmpty : pageEmpty // ignore: cast_nullable_to_non_nullable
as bool,pageError: null == pageError ? _self.pageError : pageError // ignore: cast_nullable_to_non_nullable
as bool,notLogin: null == notLogin ? _self.notLogin : notLogin // ignore: cast_nullable_to_non_nullable
as bool,errorMsg: null == errorMsg ? _self.errorMsg : errorMsg // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
