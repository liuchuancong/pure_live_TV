// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pgc_episode.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PgcEpisode {

@JsonKey(name: 'id', fromJson: lenientIntOf) int get epId;@JsonKey(fromJson: lenientIntOf) int get cid; String get title;@JsonKey(name: 'long_title') String get longTitle;@JsonKey(name: 'cover', fromJson: httpsUrlOf) String get cover;@JsonKey(name: 'duration', fromJson: lenientIntOf) int get durationMs; String get badge;
/// Create a copy of PgcEpisode
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PgcEpisodeCopyWith<PgcEpisode> get copyWith => _$PgcEpisodeCopyWithImpl<PgcEpisode>(this as PgcEpisode, _$identity);

  /// Serializes this PgcEpisode to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PgcEpisode;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PgcEpisode&&(identical(other.epId, _this.epId) || other.epId == _this.epId)&&(identical(other.cid, _this.cid) || other.cid == _this.cid)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.longTitle, _this.longTitle) || other.longTitle == _this.longTitle)&&(identical(other.cover, _this.cover) || other.cover == _this.cover)&&(identical(other.durationMs, _this.durationMs) || other.durationMs == _this.durationMs)&&(identical(other.badge, _this.badge) || other.badge == _this.badge));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PgcEpisode;
  return Object.hash(runtimeType,_this.epId,_this.cid,_this.title,_this.longTitle,_this.cover,_this.durationMs,_this.badge);
}

@override
String toString() {
  final _this = this as PgcEpisode;
  return 'PgcEpisode(epId: ${_this.epId}, cid: ${_this.cid}, title: ${_this.title}, longTitle: ${_this.longTitle}, cover: ${_this.cover}, durationMs: ${_this.durationMs}, badge: ${_this.badge})';
}


}

/// @nodoc
abstract mixin class $PgcEpisodeCopyWith<$Res>  {
  factory $PgcEpisodeCopyWith(PgcEpisode value, $Res Function(PgcEpisode) _then) = _$PgcEpisodeCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'id', fromJson: lenientIntOf) int epId,@JsonKey(fromJson: lenientIntOf) int cid, String title,@JsonKey(name: 'long_title') String longTitle,@JsonKey(name: 'cover', fromJson: httpsUrlOf) String cover,@JsonKey(name: 'duration', fromJson: lenientIntOf) int durationMs, String badge
});




}
/// @nodoc
class _$PgcEpisodeCopyWithImpl<$Res>
    implements $PgcEpisodeCopyWith<$Res> {
  _$PgcEpisodeCopyWithImpl(this._self, this._then);

  final PgcEpisode _self;
  final $Res Function(PgcEpisode) _then;

/// Create a copy of PgcEpisode
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? epId = null,Object? cid = null,Object? title = null,Object? longTitle = null,Object? cover = null,Object? durationMs = null,Object? badge = null,}) {
  return _then(PgcEpisode(
epId: null == epId ? _self.epId : epId // ignore: cast_nullable_to_non_nullable
as int,cid: null == cid ? _self.cid : cid // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,longTitle: null == longTitle ? _self.longTitle : longTitle // ignore: cast_nullable_to_non_nullable
as String,cover: null == cover ? _self.cover : cover // ignore: cast_nullable_to_non_nullable
as String,durationMs: null == durationMs ? _self.durationMs : durationMs // ignore: cast_nullable_to_non_nullable
as int,badge: null == badge ? _self.badge : badge // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PgcEpisode].
extension PgcEpisodePatterns on PgcEpisode {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PgcEpisode value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PgcEpisode() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PgcEpisode value)  $default,){
final _that = this;
switch (_that) {
case _PgcEpisode():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PgcEpisode value)?  $default,){
final _that = this;
switch (_that) {
case _PgcEpisode() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'id', fromJson: lenientIntOf)  int epId, @JsonKey(fromJson: lenientIntOf)  int cid,  String title, @JsonKey(name: 'long_title')  String longTitle, @JsonKey(name: 'cover', fromJson: httpsUrlOf)  String cover, @JsonKey(name: 'duration', fromJson: lenientIntOf)  int durationMs,  String badge)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PgcEpisode() when $default != null:
return $default(_that.epId,_that.cid,_that.title,_that.longTitle,_that.cover,_that.durationMs,_that.badge);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'id', fromJson: lenientIntOf)  int epId, @JsonKey(fromJson: lenientIntOf)  int cid,  String title, @JsonKey(name: 'long_title')  String longTitle, @JsonKey(name: 'cover', fromJson: httpsUrlOf)  String cover, @JsonKey(name: 'duration', fromJson: lenientIntOf)  int durationMs,  String badge)  $default,) {final _that = this;
switch (_that) {
case _PgcEpisode():
return $default(_that.epId,_that.cid,_that.title,_that.longTitle,_that.cover,_that.durationMs,_that.badge);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'id', fromJson: lenientIntOf)  int epId, @JsonKey(fromJson: lenientIntOf)  int cid,  String title, @JsonKey(name: 'long_title')  String longTitle, @JsonKey(name: 'cover', fromJson: httpsUrlOf)  String cover, @JsonKey(name: 'duration', fromJson: lenientIntOf)  int durationMs,  String badge)?  $default,) {final _that = this;
switch (_that) {
case _PgcEpisode() when $default != null:
return $default(_that.epId,_that.cid,_that.title,_that.longTitle,_that.cover,_that.durationMs,_that.badge);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PgcEpisode implements PgcEpisode {
  const _PgcEpisode({@JsonKey(name: 'id', fromJson: lenientIntOf) this.epId = 0, @JsonKey(fromJson: lenientIntOf) this.cid = 0, this.title = '', @JsonKey(name: 'long_title') this.longTitle = '', @JsonKey(name: 'cover', fromJson: httpsUrlOf) this.cover = '', @JsonKey(name: 'duration', fromJson: lenientIntOf) this.durationMs = 0, this.badge = ''});
  factory _PgcEpisode.fromJson(Map<String, dynamic> json) => _$PgcEpisodeFromJson(json);

@override@JsonKey(name: 'id', fromJson: lenientIntOf) final  int epId;
@override@JsonKey(fromJson: lenientIntOf) final  int cid;
@override@JsonKey() final  String title;
@override@JsonKey(name: 'long_title') final  String longTitle;
@override@JsonKey(name: 'cover', fromJson: httpsUrlOf) final  String cover;
@override@JsonKey(name: 'duration', fromJson: lenientIntOf) final  int durationMs;
@override@JsonKey() final  String badge;

/// Create a copy of PgcEpisode
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PgcEpisodeCopyWith<_PgcEpisode> get copyWith => __$PgcEpisodeCopyWithImpl<_PgcEpisode>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PgcEpisodeToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PgcEpisode&&(identical(other.epId, epId) || other.epId == epId)&&(identical(other.cid, cid) || other.cid == cid)&&(identical(other.title, title) || other.title == title)&&(identical(other.longTitle, longTitle) || other.longTitle == longTitle)&&(identical(other.cover, cover) || other.cover == cover)&&(identical(other.durationMs, durationMs) || other.durationMs == durationMs)&&(identical(other.badge, badge) || other.badge == badge));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,epId,cid,title,longTitle,cover,durationMs,badge);
}

@override
String toString() {
    return 'PgcEpisode(epId: $epId, cid: $cid, title: $title, longTitle: $longTitle, cover: $cover, durationMs: $durationMs, badge: $badge)';
}


}

/// @nodoc
abstract mixin class _$PgcEpisodeCopyWith<$Res> implements $PgcEpisodeCopyWith<$Res> {
  factory _$PgcEpisodeCopyWith(_PgcEpisode value, $Res Function(_PgcEpisode) _then) = __$PgcEpisodeCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'id', fromJson: lenientIntOf) int epId,@JsonKey(fromJson: lenientIntOf) int cid, String title,@JsonKey(name: 'long_title') String longTitle,@JsonKey(name: 'cover', fromJson: httpsUrlOf) String cover,@JsonKey(name: 'duration', fromJson: lenientIntOf) int durationMs, String badge
});




}
/// @nodoc
class __$PgcEpisodeCopyWithImpl<$Res>
    implements _$PgcEpisodeCopyWith<$Res> {
  __$PgcEpisodeCopyWithImpl(this._self, this._then);

  final _PgcEpisode _self;
  final $Res Function(_PgcEpisode) _then;

/// Create a copy of PgcEpisode
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? epId = null,Object? cid = null,Object? title = null,Object? longTitle = null,Object? cover = null,Object? durationMs = null,Object? badge = null,}) {
  return _then(_PgcEpisode(
epId: null == epId ? _self.epId : epId // ignore: cast_nullable_to_non_nullable
as int,cid: null == cid ? _self.cid : cid // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,longTitle: null == longTitle ? _self.longTitle : longTitle // ignore: cast_nullable_to_non_nullable
as String,cover: null == cover ? _self.cover : cover // ignore: cast_nullable_to_non_nullable
as String,durationMs: null == durationMs ? _self.durationMs : durationMs // ignore: cast_nullable_to_non_nullable
as int,badge: null == badge ? _self.badge : badge // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
