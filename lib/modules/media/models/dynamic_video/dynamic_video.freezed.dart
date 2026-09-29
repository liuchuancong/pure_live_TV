// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'dynamic_video.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DynamicVideo {

 MusicArchive get archive; String get pubTime;
/// Create a copy of DynamicVideo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DynamicVideoCopyWith<DynamicVideo> get copyWith => _$DynamicVideoCopyWithImpl<DynamicVideo>(this as DynamicVideo, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as DynamicVideo;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DynamicVideo&&(identical(other.archive, _this.archive) || other.archive == _this.archive)&&(identical(other.pubTime, _this.pubTime) || other.pubTime == _this.pubTime));
}


@override
int get hashCode {
  final _this = this as DynamicVideo;
  return Object.hash(runtimeType,_this.archive,_this.pubTime);
}

@override
String toString() {
  final _this = this as DynamicVideo;
  return 'DynamicVideo(archive: ${_this.archive}, pubTime: ${_this.pubTime})';
}


}

/// @nodoc
abstract mixin class $DynamicVideoCopyWith<$Res>  {
  factory $DynamicVideoCopyWith(DynamicVideo value, $Res Function(DynamicVideo) _then) = _$DynamicVideoCopyWithImpl;
@useResult
$Res call({
 MusicArchive archive, String pubTime
});


$MusicArchiveCopyWith<$Res> get archive;

}
/// @nodoc
class _$DynamicVideoCopyWithImpl<$Res>
    implements $DynamicVideoCopyWith<$Res> {
  _$DynamicVideoCopyWithImpl(this._self, this._then);

  final DynamicVideo _self;
  final $Res Function(DynamicVideo) _then;

/// Create a copy of DynamicVideo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? archive = null,Object? pubTime = null,}) {
  return _then(DynamicVideo(
archive: null == archive ? _self.archive : archive // ignore: cast_nullable_to_non_nullable
as MusicArchive,pubTime: null == pubTime ? _self.pubTime : pubTime // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of DynamicVideo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MusicArchiveCopyWith<$Res> get archive {
  
  return $MusicArchiveCopyWith<$Res>(_self.archive, (value) {
    return _then(_self.copyWith(archive: value));
  });
}
}


/// Adds pattern-matching-related methods to [DynamicVideo].
extension DynamicVideoPatterns on DynamicVideo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DynamicVideo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DynamicVideo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DynamicVideo value)  $default,){
final _that = this;
switch (_that) {
case _DynamicVideo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DynamicVideo value)?  $default,){
final _that = this;
switch (_that) {
case _DynamicVideo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( MusicArchive archive,  String pubTime)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DynamicVideo() when $default != null:
return $default(_that.archive,_that.pubTime);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( MusicArchive archive,  String pubTime)  $default,) {final _that = this;
switch (_that) {
case _DynamicVideo():
return $default(_that.archive,_that.pubTime);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( MusicArchive archive,  String pubTime)?  $default,) {final _that = this;
switch (_that) {
case _DynamicVideo() when $default != null:
return $default(_that.archive,_that.pubTime);case _:
  return null;

}
}

}

/// @nodoc


class _DynamicVideo extends DynamicVideo {
  const _DynamicVideo({required this.archive, this.pubTime = ''}): super._();
  

@override final  MusicArchive archive;
@override@JsonKey() final  String pubTime;

/// Create a copy of DynamicVideo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DynamicVideoCopyWith<_DynamicVideo> get copyWith => __$DynamicVideoCopyWithImpl<_DynamicVideo>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DynamicVideo&&(identical(other.archive, archive) || other.archive == archive)&&(identical(other.pubTime, pubTime) || other.pubTime == pubTime));
}


@override
int get hashCode {
    return Object.hash(runtimeType,archive,pubTime);
}

@override
String toString() {
    return 'DynamicVideo(archive: $archive, pubTime: $pubTime)';
}


}

/// @nodoc
abstract mixin class _$DynamicVideoCopyWith<$Res> implements $DynamicVideoCopyWith<$Res> {
  factory _$DynamicVideoCopyWith(_DynamicVideo value, $Res Function(_DynamicVideo) _then) = __$DynamicVideoCopyWithImpl;
@override @useResult
$Res call({
 MusicArchive archive, String pubTime
});


@override $MusicArchiveCopyWith<$Res> get archive;

}
/// @nodoc
class __$DynamicVideoCopyWithImpl<$Res>
    implements _$DynamicVideoCopyWith<$Res> {
  __$DynamicVideoCopyWithImpl(this._self, this._then);

  final _DynamicVideo _self;
  final $Res Function(_DynamicVideo) _then;

/// Create a copy of DynamicVideo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? archive = null,Object? pubTime = null,}) {
  return _then(_DynamicVideo(
archive: null == archive ? _self.archive : archive // ignore: cast_nullable_to_non_nullable
as MusicArchive,pubTime: null == pubTime ? _self.pubTime : pubTime // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of DynamicVideo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MusicArchiveCopyWith<$Res> get archive {
  
  return $MusicArchiveCopyWith<$Res>(_self.archive, (value) {
    return _then(_self.copyWith(archive: value));
  });
}
}

// dart format on
