// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_space_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$UserSpaceInfo {

 int get mid; String get name; String get face; String get sign; int get followers; int get following; int get videoCount; bool get isFollowed; int get level;
/// Create a copy of UserSpaceInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserSpaceInfoCopyWith<UserSpaceInfo> get copyWith => _$UserSpaceInfoCopyWithImpl<UserSpaceInfo>(this as UserSpaceInfo, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as UserSpaceInfo;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserSpaceInfo&&(identical(other.mid, _this.mid) || other.mid == _this.mid)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.face, _this.face) || other.face == _this.face)&&(identical(other.sign, _this.sign) || other.sign == _this.sign)&&(identical(other.followers, _this.followers) || other.followers == _this.followers)&&(identical(other.following, _this.following) || other.following == _this.following)&&(identical(other.videoCount, _this.videoCount) || other.videoCount == _this.videoCount)&&(identical(other.isFollowed, _this.isFollowed) || other.isFollowed == _this.isFollowed)&&(identical(other.level, _this.level) || other.level == _this.level));
}


@override
int get hashCode {
  final _this = this as UserSpaceInfo;
  return Object.hash(runtimeType,_this.mid,_this.name,_this.face,_this.sign,_this.followers,_this.following,_this.videoCount,_this.isFollowed,_this.level);
}

@override
String toString() {
  final _this = this as UserSpaceInfo;
  return 'UserSpaceInfo(mid: ${_this.mid}, name: ${_this.name}, face: ${_this.face}, sign: ${_this.sign}, followers: ${_this.followers}, following: ${_this.following}, videoCount: ${_this.videoCount}, isFollowed: ${_this.isFollowed}, level: ${_this.level})';
}


}

/// @nodoc
abstract mixin class $UserSpaceInfoCopyWith<$Res>  {
  factory $UserSpaceInfoCopyWith(UserSpaceInfo value, $Res Function(UserSpaceInfo) _then) = _$UserSpaceInfoCopyWithImpl;
@useResult
$Res call({
 int mid, String name, String face, String sign, int followers, int following, int videoCount, bool isFollowed, int level
});




}
/// @nodoc
class _$UserSpaceInfoCopyWithImpl<$Res>
    implements $UserSpaceInfoCopyWith<$Res> {
  _$UserSpaceInfoCopyWithImpl(this._self, this._then);

  final UserSpaceInfo _self;
  final $Res Function(UserSpaceInfo) _then;

/// Create a copy of UserSpaceInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? mid = null,Object? name = null,Object? face = null,Object? sign = null,Object? followers = null,Object? following = null,Object? videoCount = null,Object? isFollowed = null,Object? level = null,}) {
  return _then(UserSpaceInfo(
mid: null == mid ? _self.mid : mid // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,face: null == face ? _self.face : face // ignore: cast_nullable_to_non_nullable
as String,sign: null == sign ? _self.sign : sign // ignore: cast_nullable_to_non_nullable
as String,followers: null == followers ? _self.followers : followers // ignore: cast_nullable_to_non_nullable
as int,following: null == following ? _self.following : following // ignore: cast_nullable_to_non_nullable
as int,videoCount: null == videoCount ? _self.videoCount : videoCount // ignore: cast_nullable_to_non_nullable
as int,isFollowed: null == isFollowed ? _self.isFollowed : isFollowed // ignore: cast_nullable_to_non_nullable
as bool,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [UserSpaceInfo].
extension UserSpaceInfoPatterns on UserSpaceInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserSpaceInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserSpaceInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserSpaceInfo value)  $default,){
final _that = this;
switch (_that) {
case _UserSpaceInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserSpaceInfo value)?  $default,){
final _that = this;
switch (_that) {
case _UserSpaceInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int mid,  String name,  String face,  String sign,  int followers,  int following,  int videoCount,  bool isFollowed,  int level)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserSpaceInfo() when $default != null:
return $default(_that.mid,_that.name,_that.face,_that.sign,_that.followers,_that.following,_that.videoCount,_that.isFollowed,_that.level);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int mid,  String name,  String face,  String sign,  int followers,  int following,  int videoCount,  bool isFollowed,  int level)  $default,) {final _that = this;
switch (_that) {
case _UserSpaceInfo():
return $default(_that.mid,_that.name,_that.face,_that.sign,_that.followers,_that.following,_that.videoCount,_that.isFollowed,_that.level);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int mid,  String name,  String face,  String sign,  int followers,  int following,  int videoCount,  bool isFollowed,  int level)?  $default,) {final _that = this;
switch (_that) {
case _UserSpaceInfo() when $default != null:
return $default(_that.mid,_that.name,_that.face,_that.sign,_that.followers,_that.following,_that.videoCount,_that.isFollowed,_that.level);case _:
  return null;

}
}

}

/// @nodoc


class _UserSpaceInfo implements UserSpaceInfo {
  const _UserSpaceInfo({this.mid = 0, this.name = '', this.face = '', this.sign = '', this.followers = 0, this.following = 0, this.videoCount = 0, this.isFollowed = false, this.level = 0});
  

@override@JsonKey() final  int mid;
@override@JsonKey() final  String name;
@override@JsonKey() final  String face;
@override@JsonKey() final  String sign;
@override@JsonKey() final  int followers;
@override@JsonKey() final  int following;
@override@JsonKey() final  int videoCount;
@override@JsonKey() final  bool isFollowed;
@override@JsonKey() final  int level;

/// Create a copy of UserSpaceInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserSpaceInfoCopyWith<_UserSpaceInfo> get copyWith => __$UserSpaceInfoCopyWithImpl<_UserSpaceInfo>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserSpaceInfo&&(identical(other.mid, mid) || other.mid == mid)&&(identical(other.name, name) || other.name == name)&&(identical(other.face, face) || other.face == face)&&(identical(other.sign, sign) || other.sign == sign)&&(identical(other.followers, followers) || other.followers == followers)&&(identical(other.following, following) || other.following == following)&&(identical(other.videoCount, videoCount) || other.videoCount == videoCount)&&(identical(other.isFollowed, isFollowed) || other.isFollowed == isFollowed)&&(identical(other.level, level) || other.level == level));
}


@override
int get hashCode {
    return Object.hash(runtimeType,mid,name,face,sign,followers,following,videoCount,isFollowed,level);
}

@override
String toString() {
    return 'UserSpaceInfo(mid: $mid, name: $name, face: $face, sign: $sign, followers: $followers, following: $following, videoCount: $videoCount, isFollowed: $isFollowed, level: $level)';
}


}

/// @nodoc
abstract mixin class _$UserSpaceInfoCopyWith<$Res> implements $UserSpaceInfoCopyWith<$Res> {
  factory _$UserSpaceInfoCopyWith(_UserSpaceInfo value, $Res Function(_UserSpaceInfo) _then) = __$UserSpaceInfoCopyWithImpl;
@override @useResult
$Res call({
 int mid, String name, String face, String sign, int followers, int following, int videoCount, bool isFollowed, int level
});




}
/// @nodoc
class __$UserSpaceInfoCopyWithImpl<$Res>
    implements _$UserSpaceInfoCopyWith<$Res> {
  __$UserSpaceInfoCopyWithImpl(this._self, this._then);

  final _UserSpaceInfo _self;
  final $Res Function(_UserSpaceInfo) _then;

/// Create a copy of UserSpaceInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? mid = null,Object? name = null,Object? face = null,Object? sign = null,Object? followers = null,Object? following = null,Object? videoCount = null,Object? isFollowed = null,Object? level = null,}) {
  return _then(_UserSpaceInfo(
mid: null == mid ? _self.mid : mid // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,face: null == face ? _self.face : face // ignore: cast_nullable_to_non_nullable
as String,sign: null == sign ? _self.sign : sign // ignore: cast_nullable_to_non_nullable
as String,followers: null == followers ? _self.followers : followers // ignore: cast_nullable_to_non_nullable
as int,following: null == following ? _self.following : following // ignore: cast_nullable_to_non_nullable
as int,videoCount: null == videoCount ? _self.videoCount : videoCount // ignore: cast_nullable_to_non_nullable
as int,isFollowed: null == isFollowed ? _self.isFollowed : isFollowed // ignore: cast_nullable_to_non_nullable
as bool,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
