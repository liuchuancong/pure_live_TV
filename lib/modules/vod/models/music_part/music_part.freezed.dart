// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'music_part.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MusicPart {

 int get cid; int get page; String get title; int get duration;/// PGC episodes play through the pgc playurl endpoint instead; 0 = plain UGC.
 int get epId;
/// Create a copy of MusicPart
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MusicPartCopyWith<MusicPart> get copyWith => _$MusicPartCopyWithImpl<MusicPart>(this as MusicPart, _$identity);

  /// Serializes this MusicPart to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as MusicPart;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MusicPart&&(identical(other.cid, _this.cid) || other.cid == _this.cid)&&(identical(other.page, _this.page) || other.page == _this.page)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.duration, _this.duration) || other.duration == _this.duration)&&(identical(other.epId, _this.epId) || other.epId == _this.epId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as MusicPart;
  return Object.hash(runtimeType,_this.cid,_this.page,_this.title,_this.duration,_this.epId);
}

@override
String toString() {
  final _this = this as MusicPart;
  return 'MusicPart(cid: ${_this.cid}, page: ${_this.page}, title: ${_this.title}, duration: ${_this.duration}, epId: ${_this.epId})';
}


}

/// @nodoc
abstract mixin class $MusicPartCopyWith<$Res>  {
  factory $MusicPartCopyWith(MusicPart value, $Res Function(MusicPart) _then) = _$MusicPartCopyWithImpl;
@useResult
$Res call({
 int cid, int page, String title, int duration, int epId
});




}
/// @nodoc
class _$MusicPartCopyWithImpl<$Res>
    implements $MusicPartCopyWith<$Res> {
  _$MusicPartCopyWithImpl(this._self, this._then);

  final MusicPart _self;
  final $Res Function(MusicPart) _then;

/// Create a copy of MusicPart
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? cid = null,Object? page = null,Object? title = null,Object? duration = null,Object? epId = null,}) {
  return _then(MusicPart(
cid: null == cid ? _self.cid : cid // ignore: cast_nullable_to_non_nullable
as int,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as int,epId: null == epId ? _self.epId : epId // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [MusicPart].
extension MusicPartPatterns on MusicPart {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MusicPart value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MusicPart() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MusicPart value)  $default,){
final _that = this;
switch (_that) {
case _MusicPart():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MusicPart value)?  $default,){
final _that = this;
switch (_that) {
case _MusicPart() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int cid,  int page,  String title,  int duration,  int epId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MusicPart() when $default != null:
return $default(_that.cid,_that.page,_that.title,_that.duration,_that.epId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int cid,  int page,  String title,  int duration,  int epId)  $default,) {final _that = this;
switch (_that) {
case _MusicPart():
return $default(_that.cid,_that.page,_that.title,_that.duration,_that.epId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int cid,  int page,  String title,  int duration,  int epId)?  $default,) {final _that = this;
switch (_that) {
case _MusicPart() when $default != null:
return $default(_that.cid,_that.page,_that.title,_that.duration,_that.epId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MusicPart implements MusicPart {
  const _MusicPart({this.cid = 0, this.page = 1, this.title = '', this.duration = 0, this.epId = 0});
  factory _MusicPart.fromJson(Map<String, dynamic> json) => _$MusicPartFromJson(json);

@override@JsonKey() final  int cid;
@override@JsonKey() final  int page;
@override@JsonKey() final  String title;
@override@JsonKey() final  int duration;
/// PGC episodes play through the pgc playurl endpoint instead; 0 = plain UGC.
@override@JsonKey() final  int epId;

/// Create a copy of MusicPart
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MusicPartCopyWith<_MusicPart> get copyWith => __$MusicPartCopyWithImpl<_MusicPart>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MusicPartToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MusicPart&&(identical(other.cid, cid) || other.cid == cid)&&(identical(other.page, page) || other.page == page)&&(identical(other.title, title) || other.title == title)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.epId, epId) || other.epId == epId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,cid,page,title,duration,epId);
}

@override
String toString() {
    return 'MusicPart(cid: $cid, page: $page, title: $title, duration: $duration, epId: $epId)';
}


}

/// @nodoc
abstract mixin class _$MusicPartCopyWith<$Res> implements $MusicPartCopyWith<$Res> {
  factory _$MusicPartCopyWith(_MusicPart value, $Res Function(_MusicPart) _then) = __$MusicPartCopyWithImpl;
@override @useResult
$Res call({
 int cid, int page, String title, int duration, int epId
});




}
/// @nodoc
class __$MusicPartCopyWithImpl<$Res>
    implements _$MusicPartCopyWith<$Res> {
  __$MusicPartCopyWithImpl(this._self, this._then);

  final _MusicPart _self;
  final $Res Function(_MusicPart) _then;

/// Create a copy of MusicPart
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? cid = null,Object? page = null,Object? title = null,Object? duration = null,Object? epId = null,}) {
  return _then(_MusicPart(
cid: null == cid ? _self.cid : cid // ignore: cast_nullable_to_non_nullable
as int,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as int,epId: null == epId ? _self.epId : epId // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
