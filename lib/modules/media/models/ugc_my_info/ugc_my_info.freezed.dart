// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ugc_my_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$UgcMyInfo {

 bool get isLogin; int get mid; String get uname; String get face; int get level; double get coin; bool get vip;
/// Create a copy of UgcMyInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UgcMyInfoCopyWith<UgcMyInfo> get copyWith => _$UgcMyInfoCopyWithImpl<UgcMyInfo>(this as UgcMyInfo, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as UgcMyInfo;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UgcMyInfo&&(identical(other.isLogin, _this.isLogin) || other.isLogin == _this.isLogin)&&(identical(other.mid, _this.mid) || other.mid == _this.mid)&&(identical(other.uname, _this.uname) || other.uname == _this.uname)&&(identical(other.face, _this.face) || other.face == _this.face)&&(identical(other.level, _this.level) || other.level == _this.level)&&(identical(other.coin, _this.coin) || other.coin == _this.coin)&&(identical(other.vip, _this.vip) || other.vip == _this.vip));
}


@override
int get hashCode {
  final _this = this as UgcMyInfo;
  return Object.hash(runtimeType,_this.isLogin,_this.mid,_this.uname,_this.face,_this.level,_this.coin,_this.vip);
}

@override
String toString() {
  final _this = this as UgcMyInfo;
  return 'UgcMyInfo(isLogin: ${_this.isLogin}, mid: ${_this.mid}, uname: ${_this.uname}, face: ${_this.face}, level: ${_this.level}, coin: ${_this.coin}, vip: ${_this.vip})';
}


}

/// @nodoc
abstract mixin class $UgcMyInfoCopyWith<$Res>  {
  factory $UgcMyInfoCopyWith(UgcMyInfo value, $Res Function(UgcMyInfo) _then) = _$UgcMyInfoCopyWithImpl;
@useResult
$Res call({
 bool isLogin, int mid, String uname, String face, int level, double coin, bool vip
});




}
/// @nodoc
class _$UgcMyInfoCopyWithImpl<$Res>
    implements $UgcMyInfoCopyWith<$Res> {
  _$UgcMyInfoCopyWithImpl(this._self, this._then);

  final UgcMyInfo _self;
  final $Res Function(UgcMyInfo) _then;

/// Create a copy of UgcMyInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isLogin = null,Object? mid = null,Object? uname = null,Object? face = null,Object? level = null,Object? coin = null,Object? vip = null,}) {
  return _then(UgcMyInfo(
isLogin: null == isLogin ? _self.isLogin : isLogin // ignore: cast_nullable_to_non_nullable
as bool,mid: null == mid ? _self.mid : mid // ignore: cast_nullable_to_non_nullable
as int,uname: null == uname ? _self.uname : uname // ignore: cast_nullable_to_non_nullable
as String,face: null == face ? _self.face : face // ignore: cast_nullable_to_non_nullable
as String,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int,coin: null == coin ? _self.coin : coin // ignore: cast_nullable_to_non_nullable
as double,vip: null == vip ? _self.vip : vip // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [UgcMyInfo].
extension UgcMyInfoPatterns on UgcMyInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UgcMyInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UgcMyInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UgcMyInfo value)  $default,){
final _that = this;
switch (_that) {
case _UgcMyInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UgcMyInfo value)?  $default,){
final _that = this;
switch (_that) {
case _UgcMyInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isLogin,  int mid,  String uname,  String face,  int level,  double coin,  bool vip)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UgcMyInfo() when $default != null:
return $default(_that.isLogin,_that.mid,_that.uname,_that.face,_that.level,_that.coin,_that.vip);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isLogin,  int mid,  String uname,  String face,  int level,  double coin,  bool vip)  $default,) {final _that = this;
switch (_that) {
case _UgcMyInfo():
return $default(_that.isLogin,_that.mid,_that.uname,_that.face,_that.level,_that.coin,_that.vip);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isLogin,  int mid,  String uname,  String face,  int level,  double coin,  bool vip)?  $default,) {final _that = this;
switch (_that) {
case _UgcMyInfo() when $default != null:
return $default(_that.isLogin,_that.mid,_that.uname,_that.face,_that.level,_that.coin,_that.vip);case _:
  return null;

}
}

}

/// @nodoc


class _UgcMyInfo implements UgcMyInfo {
  const _UgcMyInfo({required this.isLogin, this.mid = 0, this.uname = '', this.face = '', this.level = 0, this.coin = 0, this.vip = false});
  

@override final  bool isLogin;
@override@JsonKey() final  int mid;
@override@JsonKey() final  String uname;
@override@JsonKey() final  String face;
@override@JsonKey() final  int level;
@override@JsonKey() final  double coin;
@override@JsonKey() final  bool vip;

/// Create a copy of UgcMyInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UgcMyInfoCopyWith<_UgcMyInfo> get copyWith => __$UgcMyInfoCopyWithImpl<_UgcMyInfo>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _UgcMyInfo&&(identical(other.isLogin, isLogin) || other.isLogin == isLogin)&&(identical(other.mid, mid) || other.mid == mid)&&(identical(other.uname, uname) || other.uname == uname)&&(identical(other.face, face) || other.face == face)&&(identical(other.level, level) || other.level == level)&&(identical(other.coin, coin) || other.coin == coin)&&(identical(other.vip, vip) || other.vip == vip));
}


@override
int get hashCode {
    return Object.hash(runtimeType,isLogin,mid,uname,face,level,coin,vip);
}

@override
String toString() {
    return 'UgcMyInfo(isLogin: $isLogin, mid: $mid, uname: $uname, face: $face, level: $level, coin: $coin, vip: $vip)';
}


}

/// @nodoc
abstract mixin class _$UgcMyInfoCopyWith<$Res> implements $UgcMyInfoCopyWith<$Res> {
  factory _$UgcMyInfoCopyWith(_UgcMyInfo value, $Res Function(_UgcMyInfo) _then) = __$UgcMyInfoCopyWithImpl;
@override @useResult
$Res call({
 bool isLogin, int mid, String uname, String face, int level, double coin, bool vip
});




}
/// @nodoc
class __$UgcMyInfoCopyWithImpl<$Res>
    implements _$UgcMyInfoCopyWith<$Res> {
  __$UgcMyInfoCopyWithImpl(this._self, this._then);

  final _UgcMyInfo _self;
  final $Res Function(_UgcMyInfo) _then;

/// Create a copy of UgcMyInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isLogin = null,Object? mid = null,Object? uname = null,Object? face = null,Object? level = null,Object? coin = null,Object? vip = null,}) {
  return _then(_UgcMyInfo(
isLogin: null == isLogin ? _self.isLogin : isLogin // ignore: cast_nullable_to_non_nullable
as bool,mid: null == mid ? _self.mid : mid // ignore: cast_nullable_to_non_nullable
as int,uname: null == uname ? _self.uname : uname // ignore: cast_nullable_to_non_nullable
as String,face: null == face ? _self.face : face // ignore: cast_nullable_to_non_nullable
as String,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int,coin: null == coin ? _self.coin : coin // ignore: cast_nullable_to_non_nullable
as double,vip: null == vip ? _self.vip : vip // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
