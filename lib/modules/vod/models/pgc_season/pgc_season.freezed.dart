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

@JsonKey(name: 'season_id', fromJson: lenientIntOf) int get seasonId; String get title;@JsonKey(name: 'cover', fromJson: httpsUrlOf) String get cover; String get evaluate; List<PgcEpisode> get episodes; String get badge;@JsonKey(fromJson: lenientDoubleOf) double get rating; List<String> get styles; String get pubTime;/// `user_status.follow` — the 追番 toggle's initial state.
@JsonKey(fromJson: lenientIntOf) int get follow;/// `new_ep.desc` — the "更新至第 X 话" line under the title.
 String get newEpDesc;/// `user_status.progress` — where the user last stopped watching.
@JsonKey(name: 'lastEpId', fromJson: lenientIntOf) int get lastEpId;@JsonKey(name: 'lastEpIndex') String get lastEpIndex;/// The `section[]` blocks (番外/PV/SP), empty ones already dropped.
 List<PgcSection> get sections;/// `seasons[]` — the sibling seasons of the same series; the switcher
/// chips only appear when this has more than the current season.
 List<PgcItem> get altSeasons;
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PgcSeason&&(identical(other.seasonId, _this.seasonId) || other.seasonId == _this.seasonId)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.cover, _this.cover) || other.cover == _this.cover)&&(identical(other.evaluate, _this.evaluate) || other.evaluate == _this.evaluate)&&const DeepCollectionEquality().equals(other.episodes, _this.episodes)&&(identical(other.badge, _this.badge) || other.badge == _this.badge)&&(identical(other.rating, _this.rating) || other.rating == _this.rating)&&const DeepCollectionEquality().equals(other.styles, _this.styles)&&(identical(other.pubTime, _this.pubTime) || other.pubTime == _this.pubTime)&&(identical(other.follow, _this.follow) || other.follow == _this.follow)&&(identical(other.newEpDesc, _this.newEpDesc) || other.newEpDesc == _this.newEpDesc)&&(identical(other.lastEpId, _this.lastEpId) || other.lastEpId == _this.lastEpId)&&(identical(other.lastEpIndex, _this.lastEpIndex) || other.lastEpIndex == _this.lastEpIndex)&&const DeepCollectionEquality().equals(other.sections, _this.sections)&&const DeepCollectionEquality().equals(other.altSeasons, _this.altSeasons));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PgcSeason;
  return Object.hash(runtimeType,_this.seasonId,_this.title,_this.cover,_this.evaluate,const DeepCollectionEquality().hash(_this.episodes),_this.badge,_this.rating,const DeepCollectionEquality().hash(_this.styles),_this.pubTime,_this.follow,_this.newEpDesc,_this.lastEpId,_this.lastEpIndex,const DeepCollectionEquality().hash(_this.sections),const DeepCollectionEquality().hash(_this.altSeasons));
}

@override
String toString() {
  final _this = this as PgcSeason;
  return 'PgcSeason(seasonId: ${_this.seasonId}, title: ${_this.title}, cover: ${_this.cover}, evaluate: ${_this.evaluate}, episodes: ${_this.episodes}, badge: ${_this.badge}, rating: ${_this.rating}, styles: ${_this.styles}, pubTime: ${_this.pubTime}, follow: ${_this.follow}, newEpDesc: ${_this.newEpDesc}, lastEpId: ${_this.lastEpId}, lastEpIndex: ${_this.lastEpIndex}, sections: ${_this.sections}, altSeasons: ${_this.altSeasons})';
}


}

/// @nodoc
abstract mixin class $PgcSeasonCopyWith<$Res>  {
  factory $PgcSeasonCopyWith(PgcSeason value, $Res Function(PgcSeason) _then) = _$PgcSeasonCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'season_id', fromJson: lenientIntOf) int seasonId, String title,@JsonKey(name: 'cover', fromJson: httpsUrlOf) String cover, String evaluate, List<PgcEpisode> episodes, String badge,@JsonKey(fromJson: lenientDoubleOf) double rating, List<String> styles, String pubTime,@JsonKey(fromJson: lenientIntOf) int follow, String newEpDesc,@JsonKey(name: 'lastEpId', fromJson: lenientIntOf) int lastEpId,@JsonKey(name: 'lastEpIndex') String lastEpIndex, List<PgcSection> sections, List<PgcItem> altSeasons
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
@pragma('vm:prefer-inline') @override $Res call({Object? seasonId = null,Object? title = null,Object? cover = null,Object? evaluate = null,Object? episodes = null,Object? badge = null,Object? rating = null,Object? styles = null,Object? pubTime = null,Object? follow = null,Object? newEpDesc = null,Object? lastEpId = null,Object? lastEpIndex = null,Object? sections = null,Object? altSeasons = null,}) {
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
as String,follow: null == follow ? _self.follow : follow // ignore: cast_nullable_to_non_nullable
as int,newEpDesc: null == newEpDesc ? _self.newEpDesc : newEpDesc // ignore: cast_nullable_to_non_nullable
as String,lastEpId: null == lastEpId ? _self.lastEpId : lastEpId // ignore: cast_nullable_to_non_nullable
as int,lastEpIndex: null == lastEpIndex ? _self.lastEpIndex : lastEpIndex // ignore: cast_nullable_to_non_nullable
as String,sections: null == sections ? _self.sections : sections // ignore: cast_nullable_to_non_nullable
as List<PgcSection>,altSeasons: null == altSeasons ? _self.altSeasons : altSeasons // ignore: cast_nullable_to_non_nullable
as List<PgcItem>,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'season_id', fromJson: lenientIntOf)  int seasonId,  String title, @JsonKey(name: 'cover', fromJson: httpsUrlOf)  String cover,  String evaluate,  List<PgcEpisode> episodes,  String badge, @JsonKey(fromJson: lenientDoubleOf)  double rating,  List<String> styles,  String pubTime, @JsonKey(fromJson: lenientIntOf)  int follow,  String newEpDesc, @JsonKey(name: 'lastEpId', fromJson: lenientIntOf)  int lastEpId, @JsonKey(name: 'lastEpIndex')  String lastEpIndex,  List<PgcSection> sections,  List<PgcItem> altSeasons)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PgcSeason() when $default != null:
return $default(_that.seasonId,_that.title,_that.cover,_that.evaluate,_that.episodes,_that.badge,_that.rating,_that.styles,_that.pubTime,_that.follow,_that.newEpDesc,_that.lastEpId,_that.lastEpIndex,_that.sections,_that.altSeasons);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'season_id', fromJson: lenientIntOf)  int seasonId,  String title, @JsonKey(name: 'cover', fromJson: httpsUrlOf)  String cover,  String evaluate,  List<PgcEpisode> episodes,  String badge, @JsonKey(fromJson: lenientDoubleOf)  double rating,  List<String> styles,  String pubTime, @JsonKey(fromJson: lenientIntOf)  int follow,  String newEpDesc, @JsonKey(name: 'lastEpId', fromJson: lenientIntOf)  int lastEpId, @JsonKey(name: 'lastEpIndex')  String lastEpIndex,  List<PgcSection> sections,  List<PgcItem> altSeasons)  $default,) {final _that = this;
switch (_that) {
case _PgcSeason():
return $default(_that.seasonId,_that.title,_that.cover,_that.evaluate,_that.episodes,_that.badge,_that.rating,_that.styles,_that.pubTime,_that.follow,_that.newEpDesc,_that.lastEpId,_that.lastEpIndex,_that.sections,_that.altSeasons);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'season_id', fromJson: lenientIntOf)  int seasonId,  String title, @JsonKey(name: 'cover', fromJson: httpsUrlOf)  String cover,  String evaluate,  List<PgcEpisode> episodes,  String badge, @JsonKey(fromJson: lenientDoubleOf)  double rating,  List<String> styles,  String pubTime, @JsonKey(fromJson: lenientIntOf)  int follow,  String newEpDesc, @JsonKey(name: 'lastEpId', fromJson: lenientIntOf)  int lastEpId, @JsonKey(name: 'lastEpIndex')  String lastEpIndex,  List<PgcSection> sections,  List<PgcItem> altSeasons)?  $default,) {final _that = this;
switch (_that) {
case _PgcSeason() when $default != null:
return $default(_that.seasonId,_that.title,_that.cover,_that.evaluate,_that.episodes,_that.badge,_that.rating,_that.styles,_that.pubTime,_that.follow,_that.newEpDesc,_that.lastEpId,_that.lastEpIndex,_that.sections,_that.altSeasons);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PgcSeason implements PgcSeason {
  const _PgcSeason({@JsonKey(name: 'season_id', fromJson: lenientIntOf) this.seasonId = 0, this.title = '', @JsonKey(name: 'cover', fromJson: httpsUrlOf) this.cover = '', this.evaluate = '',  List<PgcEpisode> episodes = const [], this.badge = '', @JsonKey(fromJson: lenientDoubleOf) this.rating = 0,  List<String> styles = const [], this.pubTime = '', @JsonKey(fromJson: lenientIntOf) this.follow = 0, this.newEpDesc = '', @JsonKey(name: 'lastEpId', fromJson: lenientIntOf) this.lastEpId = 0, @JsonKey(name: 'lastEpIndex') this.lastEpIndex = '',  List<PgcSection> sections = const [],  List<PgcItem> altSeasons = const []}): _episodes = episodes,_styles = styles,_sections = sections,_altSeasons = altSeasons;
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
/// `user_status.follow` — the 追番 toggle's initial state.
@override@JsonKey(fromJson: lenientIntOf) final  int follow;
/// `new_ep.desc` — the "更新至第 X 话" line under the title.
@override@JsonKey() final  String newEpDesc;
/// `user_status.progress` — where the user last stopped watching.
@override@JsonKey(name: 'lastEpId', fromJson: lenientIntOf) final  int lastEpId;
@override@JsonKey(name: 'lastEpIndex') final  String lastEpIndex;
/// The `section[]` blocks (番外/PV/SP), empty ones already dropped.
 final  List<PgcSection> _sections;
/// The `section[]` blocks (番外/PV/SP), empty ones already dropped.
@override@JsonKey() List<PgcSection> get sections {
  if (_sections is EqualUnmodifiableListView) return _sections;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sections);
}

/// `seasons[]` — the sibling seasons of the same series; the switcher
/// chips only appear when this has more than the current season.
 final  List<PgcItem> _altSeasons;
/// `seasons[]` — the sibling seasons of the same series; the switcher
/// chips only appear when this has more than the current season.
@override@JsonKey() List<PgcItem> get altSeasons {
  if (_altSeasons is EqualUnmodifiableListView) return _altSeasons;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_altSeasons);
}


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
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PgcSeason&&(identical(other.seasonId, seasonId) || other.seasonId == seasonId)&&(identical(other.title, title) || other.title == title)&&(identical(other.cover, cover) || other.cover == cover)&&(identical(other.evaluate, evaluate) || other.evaluate == evaluate)&&const DeepCollectionEquality().equals(other.episodes, _episodes)&&(identical(other.badge, badge) || other.badge == badge)&&(identical(other.rating, rating) || other.rating == rating)&&const DeepCollectionEquality().equals(other.styles, _styles)&&(identical(other.pubTime, pubTime) || other.pubTime == pubTime)&&(identical(other.follow, follow) || other.follow == follow)&&(identical(other.newEpDesc, newEpDesc) || other.newEpDesc == newEpDesc)&&(identical(other.lastEpId, lastEpId) || other.lastEpId == lastEpId)&&(identical(other.lastEpIndex, lastEpIndex) || other.lastEpIndex == lastEpIndex)&&const DeepCollectionEquality().equals(other.sections, _sections)&&const DeepCollectionEquality().equals(other.altSeasons, _altSeasons));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,seasonId,title,cover,evaluate,const DeepCollectionEquality().hash(_episodes),badge,rating,const DeepCollectionEquality().hash(_styles),pubTime,follow,newEpDesc,lastEpId,lastEpIndex,const DeepCollectionEquality().hash(_sections),const DeepCollectionEquality().hash(_altSeasons));
}

@override
String toString() {
    return 'PgcSeason(seasonId: $seasonId, title: $title, cover: $cover, evaluate: $evaluate, episodes: $episodes, badge: $badge, rating: $rating, styles: $styles, pubTime: $pubTime, follow: $follow, newEpDesc: $newEpDesc, lastEpId: $lastEpId, lastEpIndex: $lastEpIndex, sections: $sections, altSeasons: $altSeasons)';
}


}

/// @nodoc
abstract mixin class _$PgcSeasonCopyWith<$Res> implements $PgcSeasonCopyWith<$Res> {
  factory _$PgcSeasonCopyWith(_PgcSeason value, $Res Function(_PgcSeason) _then) = __$PgcSeasonCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'season_id', fromJson: lenientIntOf) int seasonId, String title,@JsonKey(name: 'cover', fromJson: httpsUrlOf) String cover, String evaluate, List<PgcEpisode> episodes, String badge,@JsonKey(fromJson: lenientDoubleOf) double rating, List<String> styles, String pubTime,@JsonKey(fromJson: lenientIntOf) int follow, String newEpDesc,@JsonKey(name: 'lastEpId', fromJson: lenientIntOf) int lastEpId,@JsonKey(name: 'lastEpIndex') String lastEpIndex, List<PgcSection> sections, List<PgcItem> altSeasons
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
@override @pragma('vm:prefer-inline') $Res call({Object? seasonId = null,Object? title = null,Object? cover = null,Object? evaluate = null,Object? episodes = null,Object? badge = null,Object? rating = null,Object? styles = null,Object? pubTime = null,Object? follow = null,Object? newEpDesc = null,Object? lastEpId = null,Object? lastEpIndex = null,Object? sections = null,Object? altSeasons = null,}) {
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
as String,follow: null == follow ? _self.follow : follow // ignore: cast_nullable_to_non_nullable
as int,newEpDesc: null == newEpDesc ? _self.newEpDesc : newEpDesc // ignore: cast_nullable_to_non_nullable
as String,lastEpId: null == lastEpId ? _self.lastEpId : lastEpId // ignore: cast_nullable_to_non_nullable
as int,lastEpIndex: null == lastEpIndex ? _self.lastEpIndex : lastEpIndex // ignore: cast_nullable_to_non_nullable
as String,sections: null == sections ? _self._sections : sections // ignore: cast_nullable_to_non_nullable
as List<PgcSection>,altSeasons: null == altSeasons ? _self._altSeasons : altSeasons // ignore: cast_nullable_to_non_nullable
as List<PgcItem>,
  ));
}


}


/// @nodoc
mixin _$PgcSection {

 String get title; List<PgcEpisode> get episodes;
/// Create a copy of PgcSection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PgcSectionCopyWith<PgcSection> get copyWith => _$PgcSectionCopyWithImpl<PgcSection>(this as PgcSection, _$identity);

  /// Serializes this PgcSection to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PgcSection;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PgcSection&&(identical(other.title, _this.title) || other.title == _this.title)&&const DeepCollectionEquality().equals(other.episodes, _this.episodes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PgcSection;
  return Object.hash(runtimeType,_this.title,const DeepCollectionEquality().hash(_this.episodes));
}

@override
String toString() {
  final _this = this as PgcSection;
  return 'PgcSection(title: ${_this.title}, episodes: ${_this.episodes})';
}


}

/// @nodoc
abstract mixin class $PgcSectionCopyWith<$Res>  {
  factory $PgcSectionCopyWith(PgcSection value, $Res Function(PgcSection) _then) = _$PgcSectionCopyWithImpl;
@useResult
$Res call({
 String title, List<PgcEpisode> episodes
});




}
/// @nodoc
class _$PgcSectionCopyWithImpl<$Res>
    implements $PgcSectionCopyWith<$Res> {
  _$PgcSectionCopyWithImpl(this._self, this._then);

  final PgcSection _self;
  final $Res Function(PgcSection) _then;

/// Create a copy of PgcSection
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? episodes = null,}) {
  return _then(PgcSection(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,episodes: null == episodes ? _self.episodes : episodes // ignore: cast_nullable_to_non_nullable
as List<PgcEpisode>,
  ));
}

}


/// Adds pattern-matching-related methods to [PgcSection].
extension PgcSectionPatterns on PgcSection {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PgcSection value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PgcSection() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PgcSection value)  $default,){
final _that = this;
switch (_that) {
case _PgcSection():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PgcSection value)?  $default,){
final _that = this;
switch (_that) {
case _PgcSection() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  List<PgcEpisode> episodes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PgcSection() when $default != null:
return $default(_that.title,_that.episodes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  List<PgcEpisode> episodes)  $default,) {final _that = this;
switch (_that) {
case _PgcSection():
return $default(_that.title,_that.episodes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  List<PgcEpisode> episodes)?  $default,) {final _that = this;
switch (_that) {
case _PgcSection() when $default != null:
return $default(_that.title,_that.episodes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PgcSection implements PgcSection {
  const _PgcSection({this.title = '',  List<PgcEpisode> episodes = const []}): _episodes = episodes;
  factory _PgcSection.fromJson(Map<String, dynamic> json) => _$PgcSectionFromJson(json);

@override@JsonKey() final  String title;
 final  List<PgcEpisode> _episodes;
@override@JsonKey() List<PgcEpisode> get episodes {
  if (_episodes is EqualUnmodifiableListView) return _episodes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_episodes);
}


/// Create a copy of PgcSection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PgcSectionCopyWith<_PgcSection> get copyWith => __$PgcSectionCopyWithImpl<_PgcSection>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PgcSectionToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PgcSection&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other.episodes, _episodes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,title,const DeepCollectionEquality().hash(_episodes));
}

@override
String toString() {
    return 'PgcSection(title: $title, episodes: $episodes)';
}


}

/// @nodoc
abstract mixin class _$PgcSectionCopyWith<$Res> implements $PgcSectionCopyWith<$Res> {
  factory _$PgcSectionCopyWith(_PgcSection value, $Res Function(_PgcSection) _then) = __$PgcSectionCopyWithImpl;
@override @useResult
$Res call({
 String title, List<PgcEpisode> episodes
});




}
/// @nodoc
class __$PgcSectionCopyWithImpl<$Res>
    implements _$PgcSectionCopyWith<$Res> {
  __$PgcSectionCopyWithImpl(this._self, this._then);

  final _PgcSection _self;
  final $Res Function(_PgcSection) _then;

/// Create a copy of PgcSection
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? episodes = null,}) {
  return _then(_PgcSection(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,episodes: null == episodes ? _self._episodes : episodes // ignore: cast_nullable_to_non_nullable
as List<PgcEpisode>,
  ));
}


}

// dart format on
