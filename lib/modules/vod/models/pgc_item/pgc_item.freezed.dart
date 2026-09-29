// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pgc_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PgcItem {

@JsonKey(name: 'season_id', fromJson: lenientIntOf) int get seasonId;@JsonKey(fromJson: stripHtmlOf) String get title;@JsonKey(name: 'cover', fromJson: httpsUrlOf) String get cover;@JsonKey(fromJson: stripHtmlOf) String get subtitle; String get badge;@JsonKey(fromJson: lenientDoubleOf) double get rating;@JsonKey(fromJson: lenientIntOf) int get episodeCount;
/// Create a copy of PgcItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PgcItemCopyWith<PgcItem> get copyWith => _$PgcItemCopyWithImpl<PgcItem>(this as PgcItem, _$identity);

  /// Serializes this PgcItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PgcItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PgcItem&&(identical(other.seasonId, _this.seasonId) || other.seasonId == _this.seasonId)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.cover, _this.cover) || other.cover == _this.cover)&&(identical(other.subtitle, _this.subtitle) || other.subtitle == _this.subtitle)&&(identical(other.badge, _this.badge) || other.badge == _this.badge)&&(identical(other.rating, _this.rating) || other.rating == _this.rating)&&(identical(other.episodeCount, _this.episodeCount) || other.episodeCount == _this.episodeCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PgcItem;
  return Object.hash(runtimeType,_this.seasonId,_this.title,_this.cover,_this.subtitle,_this.badge,_this.rating,_this.episodeCount);
}

@override
String toString() {
  final _this = this as PgcItem;
  return 'PgcItem(seasonId: ${_this.seasonId}, title: ${_this.title}, cover: ${_this.cover}, subtitle: ${_this.subtitle}, badge: ${_this.badge}, rating: ${_this.rating}, episodeCount: ${_this.episodeCount})';
}


}

/// @nodoc
abstract mixin class $PgcItemCopyWith<$Res>  {
  factory $PgcItemCopyWith(PgcItem value, $Res Function(PgcItem) _then) = _$PgcItemCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'season_id', fromJson: lenientIntOf) int seasonId,@JsonKey(fromJson: stripHtmlOf) String title,@JsonKey(name: 'cover', fromJson: httpsUrlOf) String cover,@JsonKey(fromJson: stripHtmlOf) String subtitle, String badge,@JsonKey(fromJson: lenientDoubleOf) double rating,@JsonKey(fromJson: lenientIntOf) int episodeCount
});




}
/// @nodoc
class _$PgcItemCopyWithImpl<$Res>
    implements $PgcItemCopyWith<$Res> {
  _$PgcItemCopyWithImpl(this._self, this._then);

  final PgcItem _self;
  final $Res Function(PgcItem) _then;

/// Create a copy of PgcItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? seasonId = null,Object? title = null,Object? cover = null,Object? subtitle = null,Object? badge = null,Object? rating = null,Object? episodeCount = null,}) {
  return _then(PgcItem(
seasonId: null == seasonId ? _self.seasonId : seasonId // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,cover: null == cover ? _self.cover : cover // ignore: cast_nullable_to_non_nullable
as String,subtitle: null == subtitle ? _self.subtitle : subtitle // ignore: cast_nullable_to_non_nullable
as String,badge: null == badge ? _self.badge : badge // ignore: cast_nullable_to_non_nullable
as String,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double,episodeCount: null == episodeCount ? _self.episodeCount : episodeCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [PgcItem].
extension PgcItemPatterns on PgcItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PgcItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PgcItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PgcItem value)  $default,){
final _that = this;
switch (_that) {
case _PgcItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PgcItem value)?  $default,){
final _that = this;
switch (_that) {
case _PgcItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'season_id', fromJson: lenientIntOf)  int seasonId, @JsonKey(fromJson: stripHtmlOf)  String title, @JsonKey(name: 'cover', fromJson: httpsUrlOf)  String cover, @JsonKey(fromJson: stripHtmlOf)  String subtitle,  String badge, @JsonKey(fromJson: lenientDoubleOf)  double rating, @JsonKey(fromJson: lenientIntOf)  int episodeCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PgcItem() when $default != null:
return $default(_that.seasonId,_that.title,_that.cover,_that.subtitle,_that.badge,_that.rating,_that.episodeCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'season_id', fromJson: lenientIntOf)  int seasonId, @JsonKey(fromJson: stripHtmlOf)  String title, @JsonKey(name: 'cover', fromJson: httpsUrlOf)  String cover, @JsonKey(fromJson: stripHtmlOf)  String subtitle,  String badge, @JsonKey(fromJson: lenientDoubleOf)  double rating, @JsonKey(fromJson: lenientIntOf)  int episodeCount)  $default,) {final _that = this;
switch (_that) {
case _PgcItem():
return $default(_that.seasonId,_that.title,_that.cover,_that.subtitle,_that.badge,_that.rating,_that.episodeCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'season_id', fromJson: lenientIntOf)  int seasonId, @JsonKey(fromJson: stripHtmlOf)  String title, @JsonKey(name: 'cover', fromJson: httpsUrlOf)  String cover, @JsonKey(fromJson: stripHtmlOf)  String subtitle,  String badge, @JsonKey(fromJson: lenientDoubleOf)  double rating, @JsonKey(fromJson: lenientIntOf)  int episodeCount)?  $default,) {final _that = this;
switch (_that) {
case _PgcItem() when $default != null:
return $default(_that.seasonId,_that.title,_that.cover,_that.subtitle,_that.badge,_that.rating,_that.episodeCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PgcItem implements PgcItem {
  const _PgcItem({@JsonKey(name: 'season_id', fromJson: lenientIntOf) this.seasonId = 0, @JsonKey(fromJson: stripHtmlOf) this.title = '', @JsonKey(name: 'cover', fromJson: httpsUrlOf) this.cover = '', @JsonKey(fromJson: stripHtmlOf) this.subtitle = '', this.badge = '', @JsonKey(fromJson: lenientDoubleOf) this.rating = 0, @JsonKey(fromJson: lenientIntOf) this.episodeCount = 0});
  factory _PgcItem.fromJson(Map<String, dynamic> json) => _$PgcItemFromJson(json);

@override@JsonKey(name: 'season_id', fromJson: lenientIntOf) final  int seasonId;
@override@JsonKey(fromJson: stripHtmlOf) final  String title;
@override@JsonKey(name: 'cover', fromJson: httpsUrlOf) final  String cover;
@override@JsonKey(fromJson: stripHtmlOf) final  String subtitle;
@override@JsonKey() final  String badge;
@override@JsonKey(fromJson: lenientDoubleOf) final  double rating;
@override@JsonKey(fromJson: lenientIntOf) final  int episodeCount;

/// Create a copy of PgcItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PgcItemCopyWith<_PgcItem> get copyWith => __$PgcItemCopyWithImpl<_PgcItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PgcItemToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PgcItem&&(identical(other.seasonId, seasonId) || other.seasonId == seasonId)&&(identical(other.title, title) || other.title == title)&&(identical(other.cover, cover) || other.cover == cover)&&(identical(other.subtitle, subtitle) || other.subtitle == subtitle)&&(identical(other.badge, badge) || other.badge == badge)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.episodeCount, episodeCount) || other.episodeCount == episodeCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,seasonId,title,cover,subtitle,badge,rating,episodeCount);
}

@override
String toString() {
    return 'PgcItem(seasonId: $seasonId, title: $title, cover: $cover, subtitle: $subtitle, badge: $badge, rating: $rating, episodeCount: $episodeCount)';
}


}

/// @nodoc
abstract mixin class _$PgcItemCopyWith<$Res> implements $PgcItemCopyWith<$Res> {
  factory _$PgcItemCopyWith(_PgcItem value, $Res Function(_PgcItem) _then) = __$PgcItemCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'season_id', fromJson: lenientIntOf) int seasonId,@JsonKey(fromJson: stripHtmlOf) String title,@JsonKey(name: 'cover', fromJson: httpsUrlOf) String cover,@JsonKey(fromJson: stripHtmlOf) String subtitle, String badge,@JsonKey(fromJson: lenientDoubleOf) double rating,@JsonKey(fromJson: lenientIntOf) int episodeCount
});




}
/// @nodoc
class __$PgcItemCopyWithImpl<$Res>
    implements _$PgcItemCopyWith<$Res> {
  __$PgcItemCopyWithImpl(this._self, this._then);

  final _PgcItem _self;
  final $Res Function(_PgcItem) _then;

/// Create a copy of PgcItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? seasonId = null,Object? title = null,Object? cover = null,Object? subtitle = null,Object? badge = null,Object? rating = null,Object? episodeCount = null,}) {
  return _then(_PgcItem(
seasonId: null == seasonId ? _self.seasonId : seasonId // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,cover: null == cover ? _self.cover : cover // ignore: cast_nullable_to_non_nullable
as String,subtitle: null == subtitle ? _self.subtitle : subtitle // ignore: cast_nullable_to_non_nullable
as String,badge: null == badge ? _self.badge : badge // ignore: cast_nullable_to_non_nullable
as String,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as double,episodeCount: null == episodeCount ? _self.episodeCount : episodeCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
