// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'music_track.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MusicTrack {

 MusicArchive get archive; MusicPart get part;
/// Create a copy of MusicTrack
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MusicTrackCopyWith<MusicTrack> get copyWith => _$MusicTrackCopyWithImpl<MusicTrack>(this as MusicTrack, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as MusicTrack;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MusicTrack&&(identical(other.archive, _this.archive) || other.archive == _this.archive)&&(identical(other.part, _this.part) || other.part == _this.part));
}


@override
int get hashCode {
  final _this = this as MusicTrack;
  return Object.hash(runtimeType,_this.archive,_this.part);
}

@override
String toString() {
  final _this = this as MusicTrack;
  return 'MusicTrack(archive: ${_this.archive}, part: ${_this.part})';
}


}

/// @nodoc
abstract mixin class $MusicTrackCopyWith<$Res>  {
  factory $MusicTrackCopyWith(MusicTrack value, $Res Function(MusicTrack) _then) = _$MusicTrackCopyWithImpl;
@useResult
$Res call({
 MusicArchive archive, MusicPart part
});


$MusicArchiveCopyWith<$Res> get archive;$MusicPartCopyWith<$Res> get part;

}
/// @nodoc
class _$MusicTrackCopyWithImpl<$Res>
    implements $MusicTrackCopyWith<$Res> {
  _$MusicTrackCopyWithImpl(this._self, this._then);

  final MusicTrack _self;
  final $Res Function(MusicTrack) _then;

/// Create a copy of MusicTrack
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? archive = null,Object? part = null,}) {
  return _then(MusicTrack(
archive: null == archive ? _self.archive : archive // ignore: cast_nullable_to_non_nullable
as MusicArchive,part: null == part ? _self.part : part // ignore: cast_nullable_to_non_nullable
as MusicPart,
  ));
}
/// Create a copy of MusicTrack
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MusicArchiveCopyWith<$Res> get archive {
  
  return $MusicArchiveCopyWith<$Res>(_self.archive, (value) {
    return _then(_self.copyWith(archive: value));
  });
}/// Create a copy of MusicTrack
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MusicPartCopyWith<$Res> get part {
  
  return $MusicPartCopyWith<$Res>(_self.part, (value) {
    return _then(_self.copyWith(part: value));
  });
}
}


/// Adds pattern-matching-related methods to [MusicTrack].
extension MusicTrackPatterns on MusicTrack {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MusicTrack value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MusicTrack() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MusicTrack value)  $default,){
final _that = this;
switch (_that) {
case _MusicTrack():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MusicTrack value)?  $default,){
final _that = this;
switch (_that) {
case _MusicTrack() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( MusicArchive archive,  MusicPart part)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MusicTrack() when $default != null:
return $default(_that.archive,_that.part);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( MusicArchive archive,  MusicPart part)  $default,) {final _that = this;
switch (_that) {
case _MusicTrack():
return $default(_that.archive,_that.part);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( MusicArchive archive,  MusicPart part)?  $default,) {final _that = this;
switch (_that) {
case _MusicTrack() when $default != null:
return $default(_that.archive,_that.part);case _:
  return null;

}
}

}

/// @nodoc


class _MusicTrack extends MusicTrack {
  const _MusicTrack({required this.archive, required this.part}): super._();
  

@override final  MusicArchive archive;
@override final  MusicPart part;

/// Create a copy of MusicTrack
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MusicTrackCopyWith<_MusicTrack> get copyWith => __$MusicTrackCopyWithImpl<_MusicTrack>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MusicTrack&&(identical(other.archive, archive) || other.archive == archive)&&(identical(other.part, part) || other.part == part));
}


@override
int get hashCode {
    return Object.hash(runtimeType,archive,part);
}

@override
String toString() {
    return 'MusicTrack(archive: $archive, part: $part)';
}


}

/// @nodoc
abstract mixin class _$MusicTrackCopyWith<$Res> implements $MusicTrackCopyWith<$Res> {
  factory _$MusicTrackCopyWith(_MusicTrack value, $Res Function(_MusicTrack) _then) = __$MusicTrackCopyWithImpl;
@override @useResult
$Res call({
 MusicArchive archive, MusicPart part
});


@override $MusicArchiveCopyWith<$Res> get archive;@override $MusicPartCopyWith<$Res> get part;

}
/// @nodoc
class __$MusicTrackCopyWithImpl<$Res>
    implements _$MusicTrackCopyWith<$Res> {
  __$MusicTrackCopyWithImpl(this._self, this._then);

  final _MusicTrack _self;
  final $Res Function(_MusicTrack) _then;

/// Create a copy of MusicTrack
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? archive = null,Object? part = null,}) {
  return _then(_MusicTrack(
archive: null == archive ? _self.archive : archive // ignore: cast_nullable_to_non_nullable
as MusicArchive,part: null == part ? _self.part : part // ignore: cast_nullable_to_non_nullable
as MusicPart,
  ));
}

/// Create a copy of MusicTrack
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MusicArchiveCopyWith<$Res> get archive {
  
  return $MusicArchiveCopyWith<$Res>(_self.archive, (value) {
    return _then(_self.copyWith(archive: value));
  });
}/// Create a copy of MusicTrack
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MusicPartCopyWith<$Res> get part {
  
  return $MusicPartCopyWith<$Res>(_self.part, (value) {
    return _then(_self.copyWith(part: value));
  });
}
}

// dart format on
