// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pgc_season.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PgcSeason {

@JsonKey(name: 'season_id', fromJson: lenientIntOf) int get seasonId; String get title;@JsonKey(name: 'cover', fromJson: httpsUrlOf) String get cover; String get evaluate; List<PgcEpisode> get episodes; String get badge;@JsonKey(fromJson: lenientDoubleOf) double get rating; List<String> get styles; String get pubTime;
/// Create a copy of PgcSeason
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PgcSeasonCopyWith<PgcSeason> get copyWith => _$PgcSeasonCopyWithImpl<PgcSeason>(this as PgcSeason, _$identity);

  /// Serializes this PgcSeason to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PgcSeason;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PgcSeason&&(identical(other.seasonId, _this.seasonId) || other.seasonId == _this.seasonId)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.cover, _this.cover) || other.cover == _this.cover)&&(identical(other.evaluate, _this.evaluate) || other.evaluate == _this.evaluate)&&const DeepCollectionEquality().equals(other.episodes, _this.episodes)&&(identical(other.badge, _this.badge) || other.badge == _this.badge)&&(identical(other.rating, _this.rating) || other.rating == _this.rating)&&const DeepCollectionEquality().equals(other.styles, _this.styles)&&(identical(other.pubTime, _this.pubTime) || other.pubTime == _this.pubTime));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PgcSeason;
  return Object.hash(runtimeType,_this.seasonId,_this.title,_this.cover,_this.evaluate,const DeepCollectionEquality().hash(_this.episodes),_this.badge,_this.rating,const DeepCollectionEquality().hash(_this.styles),_this.pubTime);
}

@override
String toString() {
  final _this = this as PgcSeason;
  return 'PgcSeason(seasonId: ${_this.seasonId}, title: ${_this.title}, cover: ${_this.cover}, evaluate: ${_this.evaluate}, episodes: ${_this.episodes}, badge: ${_this.badge}, rating: ${_this.rating}, styles: ${_this.styles}, pubTime: ${_this.pubTime})';
}


}

/// @nodoc
abstract mixin class $PgcSeasonCopyWith<$Res>  {
  factory $PgcSeasonCopyWith(PgcSeason value, $Res Function(PgcSeason) _then) = _$PgcSeasonCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'season_id', fromJson: lenientIntOf) int seasonId, String title,@JsonKey(name: 'cover', fromJson: httpsUrlOf) String cover, String evaluate, List<PgcEpisode> episodes, String badge,@JsonKey(fromJson: lenientDoubleOf) double rating, List<String> styles, String pubTime
});




}
/// @nodoc
class _$PgcSeasonCopyWithImpl<$Res>
    implements $PgcSeasonCopyWith<$Res> {
  _$PgcSeasonCopyWithImpl(this._self, this._then);

  final PgcSeason _self;
  final $Res Function(PgcSeason) _then;

/// Create a copy of PgcSeason
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? seasonId = null,Object? title = null,Object? cover = null,Object? evaluate = null,Object? episodes = null,Object? badge = null,Object? rating = null,Object? styles = null,Object? pubTime = null,}) {
  return _then(PgcSeason(
seasonId: null == seasonId ? _self.seasonId : seasonId // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,cover: null == cover ? _self.cover : cover // ignore: cast_nullable_to_non_nullable
as String,evaluate: null == evaluate ? _self.evaluate : evaluate // ignore: cast_nullable_to_non_nullable
as String,episodes: null == episodes ? _self.episodes : episodes // ignore: cast_nullable_to_non_nullable
as List<PgcEpisode>,badge: null == badge ? _self.badge : badge // ignore: cast_nullable_to_non_nullable
as String,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double,styles: null == styles ? _self.styles : styles // ignore: cast_nullable_to_non_nullable
as List<String>,pubTime: null == pubTime ? _self.pubTime : pubTime // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PgcSeason].
extension PgcSeasonPatterns on PgcSeason {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PgcSeason value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PgcSeason() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PgcSeason value)  $default,){
final _that = this;
switch (_that) {
case _PgcSeason():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PgcSeason value)?  $default,){
final _that = this;
switch (_that) {
case _PgcSeason() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'season_id', fromJson: lenientIntOf)  int seasonId,  String title, @JsonKey(name: 'cover', fromJson: httpsUrlOf)  String cover,  String evaluate,  List<PgcEpisode> episodes,  String badge, @JsonKey(fromJson: lenientDoubleOf)  double rating,  List<String> styles,  String pubTime)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PgcSeason() when $default != null:
return $default(_that.seasonId,_that.title,_that.cover,_that.evaluate,_that.episodes,_that.badge,_that.rating,_that.styles,_that.pubTime);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'season_id', fromJson: lenientIntOf)  int seasonId,  String title, @JsonKey(name: 'cover', fromJson: httpsUrlOf)  String cover,  String evaluate,  List<PgcEpisode> episodes,  String badge, @JsonKey(fromJson: lenientDoubleOf)  double rating,  List<String> styles,  String pubTime)  $default,) {final _that = this;
switch (_that) {
case _PgcSeason():
return $default(_that.seasonId,_that.title,_that.cover,_that.evaluate,_that.episodes,_that.badge,_that.rating,_that.styles,_that.pubTime);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'season_id', fromJson: lenientIntOf)  int seasonId,  String title, @JsonKey(name: 'cover', fromJson: httpsUrlOf)  String cover,  String evaluate,  List<PgcEpisode> episodes,  String badge, @JsonKey(fromJson: lenientDoubleOf)  double rating,  List<String> styles,  String pubTime)?  $default,) {final _that = this;
switch (_that) {
case _PgcSeason() when $default != null:
return $default(_that.seasonId,_that.title,_that.cover,_that.evaluate,_that.episodes,_that.badge,_that.rating,_that.styles,_that.pubTime);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PgcSeason implements PgcSeason {
  const _PgcSeason({@JsonKey(name: 'season_id', fromJson: lenientIntOf) this.seasonId = 0, this.title = '', @JsonKey(name: 'cover', fromJson: httpsUrlOf) this.cover = '', this.evaluate = '',  List<PgcEpisode> episodes = const [], this.badge = '', @JsonKey(fromJson: lenientDoubleOf) this.rating = 0,  List<String> styles = const [], this.pubTime = ''}): _episodes = episodes,_styles = styles;
  factory _PgcSeason.fromJson(Map<String, dynamic> json) => _$PgcSeasonFromJson(json);

@override@JsonKey(name: 'season_id', fromJson: lenientIntOf) final  int seasonId;
@override@JsonKey() final  String title;
@override@JsonKey(name: 'cover', fromJson: httpsUrlOf) final  String cover;
@override@JsonKey() final  String evaluate;
 final  List<PgcEpisode> _episodes;
@override@JsonKey() List<PgcEpisode> get episodes {
  if (_episodes is EqualUnmodifiableListView) return _episodes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_episodes);
}

@override@JsonKey() final  String badge;
@override@JsonKey(fromJson: lenientDoubleOf) final  double rating;
 final  List<String> _styles;
@override@JsonKey() List<String> get styles {
  if (_styles is EqualUnmodifiableListView) return _styles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_styles);
}

@override@JsonKey() final  String pubTime;

/// Create a copy of PgcSeason
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PgcSeasonCopyWith<_PgcSeason> get copyWith => __$PgcSeasonCopyWithImpl<_PgcSeason>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PgcSeasonToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PgcSeason&&(identical(other.seasonId, seasonId) || other.seasonId == seasonId)&&(identical(other.title, title) || other.title == title)&&(identical(other.cover, cover) || other.cover == cover)&&(identical(other.evaluate, evaluate) || other.evaluate == evaluate)&&const DeepCollectionEquality().equals(other.episodes, _episodes)&&(identical(other.badge, badge) || other.badge == badge)&&(identical(other.rating, rating) || other.rating == rating)&&const DeepCollectionEquality().equals(other.styles, _styles)&&(identical(other.pubTime, pubTime) || other.pubTime == pubTime));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,seasonId,title,cover,evaluate,const DeepCollectionEquality().hash(_episodes),badge,rating,const DeepCollectionEquality().hash(_styles),pubTime);
}

@override
String toString() {
    return 'PgcSeason(seasonId: $seasonId, title: $title, cover: $cover, evaluate: $evaluate, episodes: $episodes, badge: $badge, rating: $rating, styles: $styles, pubTime: $pubTime)';
}


}

/// @nodoc
abstract mixin class _$PgcSeasonCopyWith<$Res> implements $PgcSeasonCopyWith<$Res> {
  factory _$PgcSeasonCopyWith(_PgcSeason value, $Res Function(_PgcSeason) _then) = __$PgcSeasonCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'season_id', fromJson: lenientIntOf) int seasonId, String title,@JsonKey(name: 'cover', fromJson: httpsUrlOf) String cover, String evaluate, List<PgcEpisode> episodes, String badge,@JsonKey(fromJson: lenientDoubleOf) double rating, List<String> styles, String pubTime
});




}
/// @nodoc
class __$PgcSeasonCopyWithImpl<$Res>
    implements _$PgcSeasonCopyWith<$Res> {
  __$PgcSeasonCopyWithImpl(this._self, this._then);

  final _PgcSeason _self;
  final $Res Function(_PgcSeason) _then;

/// Create a copy of PgcSeason
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? seasonId = null,Object? title = null,Object? cover = null,Object? evaluate = null,Object? episodes = null,Object? badge = null,Object? rating = null,Object? styles = null,Object? pubTime = null,}) {
  return _then(_PgcSeason(
seasonId: null == seasonId ? _self.seasonId : seasonId // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,cover: null == cover ? _self.cover : cover // ignore: cast_nullable_to_non_nullable
as String,evaluate: null == evaluate ? _self.evaluate : evaluate // ignore: cast_nullable_to_non_nullable
as String,episodes: null == episodes ? _self._episodes : episodes // ignore: cast_nullable_to_non_nullable
as List<PgcEpisode>,badge: null == badge ? _self.badge : badge // ignore: cast_nullable_to_non_nullable
as String,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double,styles: null == styles ? _self._styles : styles // ignore: cast_nullable_to_non_nullable
as List<String>,pubTime: null == pubTime ? _self.pubTime : pubTime // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
