// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'video_progress_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$VideoProgressEntry {

 int get cid; int get position; int get duration; double get percent; int get updatedAt; MusicArchive? get archive;
/// Create a copy of VideoProgressEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VideoProgressEntryCopyWith<VideoProgressEntry> get copyWith => _$VideoProgressEntryCopyWithImpl<VideoProgressEntry>(this as VideoProgressEntry, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as VideoProgressEntry;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VideoProgressEntry&&(identical(other.cid, _this.cid) || other.cid == _this.cid)&&(identical(other.position, _this.position) || other.position == _this.position)&&(identical(other.duration, _this.duration) || other.duration == _this.duration)&&(identical(other.percent, _this.percent) || other.percent == _this.percent)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt)&&(identical(other.archive, _this.archive) || other.archive == _this.archive));
}


@override
int get hashCode {
  final _this = this as VideoProgressEntry;
  return Object.hash(runtimeType,_this.cid,_this.position,_this.duration,_this.percent,_this.updatedAt,_this.archive);
}

@override
String toString() {
  final _this = this as VideoProgressEntry;
  return 'VideoProgressEntry(cid: ${_this.cid}, position: ${_this.position}, duration: ${_this.duration}, percent: ${_this.percent}, updatedAt: ${_this.updatedAt}, archive: ${_this.archive})';
}


}

/// @nodoc
abstract mixin class $VideoProgressEntryCopyWith<$Res>  {
  factory $VideoProgressEntryCopyWith(VideoProgressEntry value, $Res Function(VideoProgressEntry) _then) = _$VideoProgressEntryCopyWithImpl;
@useResult
$Res call({
 int cid, int position, int duration, double percent, int updatedAt, MusicArchive? archive
});


$MusicArchiveCopyWith<$Res>? get archive;

}
/// @nodoc
class _$VideoProgressEntryCopyWithImpl<$Res>
    implements $VideoProgressEntryCopyWith<$Res> {
  _$VideoProgressEntryCopyWithImpl(this._self, this._then);

  final VideoProgressEntry _self;
  final $Res Function(VideoProgressEntry) _then;

/// Create a copy of VideoProgressEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? cid = null,Object? position = null,Object? duration = null,Object? percent = null,Object? updatedAt = null,Object? archive = freezed,}) {
  return _then(VideoProgressEntry(
cid: null == cid ? _self.cid : cid // ignore: cast_nullable_to_non_nullable
as int,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as int,percent: null == percent ? _self.percent : percent // ignore: cast_nullable_to_non_nullable
as double,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as int,archive: freezed == archive ? _self.archive : archive // ignore: cast_nullable_to_non_nullable
as MusicArchive?,
  ));
}
/// Create a copy of VideoProgressEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MusicArchiveCopyWith<$Res>? get archive {
    if (_self.archive == null) {
    return null;
  }

  return $MusicArchiveCopyWith<$Res>(_self.archive!, (value) {
    return _then(_self.copyWith(archive: value));
  });
}
}


/// Adds pattern-matching-related methods to [VideoProgressEntry].
extension VideoProgressEntryPatterns on VideoProgressEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VideoProgressEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VideoProgressEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VideoProgressEntry value)  $default,){
final _that = this;
switch (_that) {
case _VideoProgressEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VideoProgressEntry value)?  $default,){
final _that = this;
switch (_that) {
case _VideoProgressEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int cid,  int position,  int duration,  double percent,  int updatedAt,  MusicArchive? archive)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VideoProgressEntry() when $default != null:
return $default(_that.cid,_that.position,_that.duration,_that.percent,_that.updatedAt,_that.archive);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int cid,  int position,  int duration,  double percent,  int updatedAt,  MusicArchive? archive)  $default,) {final _that = this;
switch (_that) {
case _VideoProgressEntry():
return $default(_that.cid,_that.position,_that.duration,_that.percent,_that.updatedAt,_that.archive);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int cid,  int position,  int duration,  double percent,  int updatedAt,  MusicArchive? archive)?  $default,) {final _that = this;
switch (_that) {
case _VideoProgressEntry() when $default != null:
return $default(_that.cid,_that.position,_that.duration,_that.percent,_that.updatedAt,_that.archive);case _:
  return null;

}
}

}

/// @nodoc


class _VideoProgressEntry implements VideoProgressEntry {
  const _VideoProgressEntry({this.cid = 0, this.position = 0, this.duration = 0, this.percent = 0, this.updatedAt = 0, this.archive});
  

@override@JsonKey() final  int cid;
@override@JsonKey() final  int position;
@override@JsonKey() final  int duration;
@override@JsonKey() final  double percent;
@override@JsonKey() final  int updatedAt;
@override final  MusicArchive? archive;

/// Create a copy of VideoProgressEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VideoProgressEntryCopyWith<_VideoProgressEntry> get copyWith => __$VideoProgressEntryCopyWithImpl<_VideoProgressEntry>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _VideoProgressEntry&&(identical(other.cid, cid) || other.cid == cid)&&(identical(other.position, position) || other.position == position)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.percent, percent) || other.percent == percent)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.archive, archive) || other.archive == archive));
}


@override
int get hashCode {
    return Object.hash(runtimeType,cid,position,duration,percent,updatedAt,archive);
}

@override
String toString() {
    return 'VideoProgressEntry(cid: $cid, position: $position, duration: $duration, percent: $percent, updatedAt: $updatedAt, archive: $archive)';
}


}

/// @nodoc
abstract mixin class _$VideoProgressEntryCopyWith<$Res> implements $VideoProgressEntryCopyWith<$Res> {
  factory _$VideoProgressEntryCopyWith(_VideoProgressEntry value, $Res Function(_VideoProgressEntry) _then) = __$VideoProgressEntryCopyWithImpl;
@override @useResult
$Res call({
 int cid, int position, int duration, double percent, int updatedAt, MusicArchive? archive
});


@override $MusicArchiveCopyWith<$Res>? get archive;

}
/// @nodoc
class __$VideoProgressEntryCopyWithImpl<$Res>
    implements _$VideoProgressEntryCopyWith<$Res> {
  __$VideoProgressEntryCopyWithImpl(this._self, this._then);

  final _VideoProgressEntry _self;
  final $Res Function(_VideoProgressEntry) _then;

/// Create a copy of VideoProgressEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? cid = null,Object? position = null,Object? duration = null,Object? percent = null,Object? updatedAt = null,Object? archive = freezed,}) {
  return _then(_VideoProgressEntry(
cid: null == cid ? _self.cid : cid // ignore: cast_nullable_to_non_nullable
as int,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as int,percent: null == percent ? _self.percent : percent // ignore: cast_nullable_to_non_nullable
as double,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as int,archive: freezed == archive ? _self.archive : archive // ignore: cast_nullable_to_non_nullable
as MusicArchive?,
  ));
}

/// Create a copy of VideoProgressEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MusicArchiveCopyWith<$Res>? get archive {
    if (_self.archive == null) {
    return null;
  }

  return $MusicArchiveCopyWith<$Res>(_self.archive!, (value) {
    return _then(_self.copyWith(archive: value));
  });
}
}

/// @nodoc
mixin _$VideoProgressState {

 Map<String, VideoProgressEntry> get entries;
/// Create a copy of VideoProgressState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VideoProgressStateCopyWith<VideoProgressState> get copyWith => _$VideoProgressStateCopyWithImpl<VideoProgressState>(this as VideoProgressState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as VideoProgressState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VideoProgressState&&const DeepCollectionEquality().equals(other.entries, _this.entries));
}


@override
int get hashCode {
  final _this = this as VideoProgressState;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.entries));
}

@override
String toString() {
  final _this = this as VideoProgressState;
  return 'VideoProgressState(entries: ${_this.entries})';
}


}

/// @nodoc
abstract mixin class $VideoProgressStateCopyWith<$Res>  {
  factory $VideoProgressStateCopyWith(VideoProgressState value, $Res Function(VideoProgressState) _then) = _$VideoProgressStateCopyWithImpl;
@useResult
$Res call({
 Map<String, VideoProgressEntry> entries
});




}
/// @nodoc
class _$VideoProgressStateCopyWithImpl<$Res>
    implements $VideoProgressStateCopyWith<$Res> {
  _$VideoProgressStateCopyWithImpl(this._self, this._then);

  final VideoProgressState _self;
  final $Res Function(VideoProgressState) _then;

/// Create a copy of VideoProgressState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? entries = null,}) {
  return _then(VideoProgressState(
entries: null == entries ? _self.entries : entries // ignore: cast_nullable_to_non_nullable
as Map<String, VideoProgressEntry>,
  ));
}

}


/// Adds pattern-matching-related methods to [VideoProgressState].
extension VideoProgressStatePatterns on VideoProgressState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VideoProgressState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VideoProgressState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VideoProgressState value)  $default,){
final _that = this;
switch (_that) {
case _VideoProgressState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VideoProgressState value)?  $default,){
final _that = this;
switch (_that) {
case _VideoProgressState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Map<String, VideoProgressEntry> entries)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VideoProgressState() when $default != null:
return $default(_that.entries);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Map<String, VideoProgressEntry> entries)  $default,) {final _that = this;
switch (_that) {
case _VideoProgressState():
return $default(_that.entries);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Map<String, VideoProgressEntry> entries)?  $default,) {final _that = this;
switch (_that) {
case _VideoProgressState() when $default != null:
return $default(_that.entries);case _:
  return null;

}
}

}

/// @nodoc


class _VideoProgressState implements VideoProgressState {
  const _VideoProgressState({ Map<String, VideoProgressEntry> entries = const {}}): _entries = entries;
  

 final  Map<String, VideoProgressEntry> _entries;
@override@JsonKey() Map<String, VideoProgressEntry> get entries {
  if (_entries is EqualUnmodifiableMapView) return _entries;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_entries);
}


/// Create a copy of VideoProgressState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VideoProgressStateCopyWith<_VideoProgressState> get copyWith => __$VideoProgressStateCopyWithImpl<_VideoProgressState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _VideoProgressState&&const DeepCollectionEquality().equals(other.entries, _entries));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_entries));
}

@override
String toString() {
    return 'VideoProgressState(entries: $entries)';
}


}

/// @nodoc
abstract mixin class _$VideoProgressStateCopyWith<$Res> implements $VideoProgressStateCopyWith<$Res> {
  factory _$VideoProgressStateCopyWith(_VideoProgressState value, $Res Function(_VideoProgressState) _then) = __$VideoProgressStateCopyWithImpl;
@override @useResult
$Res call({
 Map<String, VideoProgressEntry> entries
});




}
/// @nodoc
class __$VideoProgressStateCopyWithImpl<$Res>
    implements _$VideoProgressStateCopyWith<$Res> {
  __$VideoProgressStateCopyWithImpl(this._self, this._then);

  final _VideoProgressState _self;
  final $Res Function(_VideoProgressState) _then;

/// Create a copy of VideoProgressState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? entries = null,}) {
  return _then(_VideoProgressState(
entries: null == entries ? _self._entries : entries // ignore: cast_nullable_to_non_nullable
as Map<String, VideoProgressEntry>,
  ));
}


}

// dart format on
