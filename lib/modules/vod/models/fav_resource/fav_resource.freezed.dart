// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'fav_resource.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FavResource {

 int get aid; String get bvid; String get title; String get cover; int get duration; int get playCount; int get barrageCount; String get upName; int get upMid; String get upFace; bool get invalid;
/// Create a copy of FavResource
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FavResourceCopyWith<FavResource> get copyWith => _$FavResourceCopyWithImpl<FavResource>(this as FavResource, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as FavResource;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FavResource&&(identical(other.aid, _this.aid) || other.aid == _this.aid)&&(identical(other.bvid, _this.bvid) || other.bvid == _this.bvid)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.cover, _this.cover) || other.cover == _this.cover)&&(identical(other.duration, _this.duration) || other.duration == _this.duration)&&(identical(other.playCount, _this.playCount) || other.playCount == _this.playCount)&&(identical(other.barrageCount, _this.barrageCount) || other.barrageCount == _this.barrageCount)&&(identical(other.upName, _this.upName) || other.upName == _this.upName)&&(identical(other.upMid, _this.upMid) || other.upMid == _this.upMid)&&(identical(other.upFace, _this.upFace) || other.upFace == _this.upFace)&&(identical(other.invalid, _this.invalid) || other.invalid == _this.invalid));
}


@override
int get hashCode {
  final _this = this as FavResource;
  return Object.hash(runtimeType,_this.aid,_this.bvid,_this.title,_this.cover,_this.duration,_this.playCount,_this.barrageCount,_this.upName,_this.upMid,_this.upFace,_this.invalid);
}

@override
String toString() {
  final _this = this as FavResource;
  return 'FavResource(aid: ${_this.aid}, bvid: ${_this.bvid}, title: ${_this.title}, cover: ${_this.cover}, duration: ${_this.duration}, playCount: ${_this.playCount}, barrageCount: ${_this.barrageCount}, upName: ${_this.upName}, upMid: ${_this.upMid}, upFace: ${_this.upFace}, invalid: ${_this.invalid})';
}


}

/// @nodoc
abstract mixin class $FavResourceCopyWith<$Res>  {
  factory $FavResourceCopyWith(FavResource value, $Res Function(FavResource) _then) = _$FavResourceCopyWithImpl;
@useResult
$Res call({
 int aid, String bvid, String title, String cover, int duration, int playCount, int barrageCount, String upName, int upMid, String upFace, bool invalid
});




}
/// @nodoc
class _$FavResourceCopyWithImpl<$Res>
    implements $FavResourceCopyWith<$Res> {
  _$FavResourceCopyWithImpl(this._self, this._then);

  final FavResource _self;
  final $Res Function(FavResource) _then;

/// Create a copy of FavResource
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? aid = null,Object? bvid = null,Object? title = null,Object? cover = null,Object? duration = null,Object? playCount = null,Object? barrageCount = null,Object? upName = null,Object? upMid = null,Object? upFace = null,Object? invalid = null,}) {
  return _then(FavResource(
aid: null == aid ? _self.aid : aid // ignore: cast_nullable_to_non_nullable
as int,bvid: null == bvid ? _self.bvid : bvid // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,cover: null == cover ? _self.cover : cover // ignore: cast_nullable_to_non_nullable
as String,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as int,playCount: null == playCount ? _self.playCount : playCount // ignore: cast_nullable_to_non_nullable
as int,barrageCount: null == barrageCount ? _self.barrageCount : barrageCount // ignore: cast_nullable_to_non_nullable
as int,upName: null == upName ? _self.upName : upName // ignore: cast_nullable_to_non_nullable
as String,upMid: null == upMid ? _self.upMid : upMid // ignore: cast_nullable_to_non_nullable
as int,upFace: null == upFace ? _self.upFace : upFace // ignore: cast_nullable_to_non_nullable
as String,invalid: null == invalid ? _self.invalid : invalid // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [FavResource].
extension FavResourcePatterns on FavResource {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FavResource value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FavResource() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FavResource value)  $default,){
final _that = this;
switch (_that) {
case _FavResource():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FavResource value)?  $default,){
final _that = this;
switch (_that) {
case _FavResource() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int aid,  String bvid,  String title,  String cover,  int duration,  int playCount,  int barrageCount,  String upName,  int upMid,  String upFace,  bool invalid)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FavResource() when $default != null:
return $default(_that.aid,_that.bvid,_that.title,_that.cover,_that.duration,_that.playCount,_that.barrageCount,_that.upName,_that.upMid,_that.upFace,_that.invalid);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int aid,  String bvid,  String title,  String cover,  int duration,  int playCount,  int barrageCount,  String upName,  int upMid,  String upFace,  bool invalid)  $default,) {final _that = this;
switch (_that) {
case _FavResource():
return $default(_that.aid,_that.bvid,_that.title,_that.cover,_that.duration,_that.playCount,_that.barrageCount,_that.upName,_that.upMid,_that.upFace,_that.invalid);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int aid,  String bvid,  String title,  String cover,  int duration,  int playCount,  int barrageCount,  String upName,  int upMid,  String upFace,  bool invalid)?  $default,) {final _that = this;
switch (_that) {
case _FavResource() when $default != null:
return $default(_that.aid,_that.bvid,_that.title,_that.cover,_that.duration,_that.playCount,_that.barrageCount,_that.upName,_that.upMid,_that.upFace,_that.invalid);case _:
  return null;

}
}

}

/// @nodoc


class _FavResource extends FavResource {
  const _FavResource({this.aid = 0, this.bvid = '', this.title = '', this.cover = '', this.duration = 0, this.playCount = 0, this.barrageCount = 0, this.upName = '', this.upMid = 0, this.upFace = '', this.invalid = false}): super._();
  

@override@JsonKey() final  int aid;
@override@JsonKey() final  String bvid;
@override@JsonKey() final  String title;
@override@JsonKey() final  String cover;
@override@JsonKey() final  int duration;
@override@JsonKey() final  int playCount;
@override@JsonKey() final  int barrageCount;
@override@JsonKey() final  String upName;
@override@JsonKey() final  int upMid;
@override@JsonKey() final  String upFace;
@override@JsonKey() final  bool invalid;

/// Create a copy of FavResource
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FavResourceCopyWith<_FavResource> get copyWith => __$FavResourceCopyWithImpl<_FavResource>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _FavResource&&(identical(other.aid, aid) || other.aid == aid)&&(identical(other.bvid, bvid) || other.bvid == bvid)&&(identical(other.title, title) || other.title == title)&&(identical(other.cover, cover) || other.cover == cover)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.playCount, playCount) || other.playCount == playCount)&&(identical(other.barrageCount, barrageCount) || other.barrageCount == barrageCount)&&(identical(other.upName, upName) || other.upName == upName)&&(identical(other.upMid, upMid) || other.upMid == upMid)&&(identical(other.upFace, upFace) || other.upFace == upFace)&&(identical(other.invalid, invalid) || other.invalid == invalid));
}


@override
int get hashCode {
    return Object.hash(runtimeType,aid,bvid,title,cover,duration,playCount,barrageCount,upName,upMid,upFace,invalid);
}

@override
String toString() {
    return 'FavResource(aid: $aid, bvid: $bvid, title: $title, cover: $cover, duration: $duration, playCount: $playCount, barrageCount: $barrageCount, upName: $upName, upMid: $upMid, upFace: $upFace, invalid: $invalid)';
}


}

/// @nodoc
abstract mixin class _$FavResourceCopyWith<$Res> implements $FavResourceCopyWith<$Res> {
  factory _$FavResourceCopyWith(_FavResource value, $Res Function(_FavResource) _then) = __$FavResourceCopyWithImpl;
@override @useResult
$Res call({
 int aid, String bvid, String title, String cover, int duration, int playCount, int barrageCount, String upName, int upMid, String upFace, bool invalid
});




}
/// @nodoc
class __$FavResourceCopyWithImpl<$Res>
    implements _$FavResourceCopyWith<$Res> {
  __$FavResourceCopyWithImpl(this._self, this._then);

  final _FavResource _self;
  final $Res Function(_FavResource) _then;

/// Create a copy of FavResource
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? aid = null,Object? bvid = null,Object? title = null,Object? cover = null,Object? duration = null,Object? playCount = null,Object? barrageCount = null,Object? upName = null,Object? upMid = null,Object? upFace = null,Object? invalid = null,}) {
  return _then(_FavResource(
aid: null == aid ? _self.aid : aid // ignore: cast_nullable_to_non_nullable
as int,bvid: null == bvid ? _self.bvid : bvid // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,cover: null == cover ? _self.cover : cover // ignore: cast_nullable_to_non_nullable
as String,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as int,playCount: null == playCount ? _self.playCount : playCount // ignore: cast_nullable_to_non_nullable
as int,barrageCount: null == barrageCount ? _self.barrageCount : barrageCount // ignore: cast_nullable_to_non_nullable
as int,upName: null == upName ? _self.upName : upName // ignore: cast_nullable_to_non_nullable
as String,upMid: null == upMid ? _self.upMid : upMid // ignore: cast_nullable_to_non_nullable
as int,upFace: null == upFace ? _self.upFace : upFace // ignore: cast_nullable_to_non_nullable
as String,invalid: null == invalid ? _self.invalid : invalid // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
