// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'search_pgc_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SearchPgcItem {

@JsonKey(name: 'season_id', fromJson: lenientIntOf) int get seasonId;@JsonKey(fromJson: stripHtmlOf) String get title;@JsonKey(fromJson: httpsUrlOf) String get cover;@JsonKey(name: 'episodes', readValue: _readEpisodesCount) int get episodeCount;
/// Create a copy of SearchPgcItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchPgcItemCopyWith<SearchPgcItem> get copyWith => _$SearchPgcItemCopyWithImpl<SearchPgcItem>(this as SearchPgcItem, _$identity);

  /// Serializes this SearchPgcItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SearchPgcItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchPgcItem&&(identical(other.seasonId, _this.seasonId) || other.seasonId == _this.seasonId)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.cover, _this.cover) || other.cover == _this.cover)&&(identical(other.episodeCount, _this.episodeCount) || other.episodeCount == _this.episodeCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SearchPgcItem;
  return Object.hash(runtimeType,_this.seasonId,_this.title,_this.cover,_this.episodeCount);
}

@override
String toString() {
  final _this = this as SearchPgcItem;
  return 'SearchPgcItem(seasonId: ${_this.seasonId}, title: ${_this.title}, cover: ${_this.cover}, episodeCount: ${_this.episodeCount})';
}


}

/// @nodoc
abstract mixin class $SearchPgcItemCopyWith<$Res>  {
  factory $SearchPgcItemCopyWith(SearchPgcItem value, $Res Function(SearchPgcItem) _then) = _$SearchPgcItemCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'season_id', fromJson: lenientIntOf) int seasonId,@JsonKey(fromJson: stripHtmlOf) String title,@JsonKey(fromJson: httpsUrlOf) String cover,@JsonKey(name: 'episodes', readValue: _readEpisodesCount) int episodeCount
});




}
/// @nodoc
class _$SearchPgcItemCopyWithImpl<$Res>
    implements $SearchPgcItemCopyWith<$Res> {
  _$SearchPgcItemCopyWithImpl(this._self, this._then);

  final SearchPgcItem _self;
  final $Res Function(SearchPgcItem) _then;

/// Create a copy of SearchPgcItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? seasonId = null,Object? title = null,Object? cover = null,Object? episodeCount = null,}) {
  return _then(SearchPgcItem(
seasonId: null == seasonId ? _self.seasonId : seasonId // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,cover: null == cover ? _self.cover : cover // ignore: cast_nullable_to_non_nullable
as String,episodeCount: null == episodeCount ? _self.episodeCount : episodeCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [SearchPgcItem].
extension SearchPgcItemPatterns on SearchPgcItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SearchPgcItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SearchPgcItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SearchPgcItem value)  $default,){
final _that = this;
switch (_that) {
case _SearchPgcItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SearchPgcItem value)?  $default,){
final _that = this;
switch (_that) {
case _SearchPgcItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'season_id', fromJson: lenientIntOf)  int seasonId, @JsonKey(fromJson: stripHtmlOf)  String title, @JsonKey(fromJson: httpsUrlOf)  String cover, @JsonKey(name: 'episodes', readValue: _readEpisodesCount)  int episodeCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SearchPgcItem() when $default != null:
return $default(_that.seasonId,_that.title,_that.cover,_that.episodeCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'season_id', fromJson: lenientIntOf)  int seasonId, @JsonKey(fromJson: stripHtmlOf)  String title, @JsonKey(fromJson: httpsUrlOf)  String cover, @JsonKey(name: 'episodes', readValue: _readEpisodesCount)  int episodeCount)  $default,) {final _that = this;
switch (_that) {
case _SearchPgcItem():
return $default(_that.seasonId,_that.title,_that.cover,_that.episodeCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'season_id', fromJson: lenientIntOf)  int seasonId, @JsonKey(fromJson: stripHtmlOf)  String title, @JsonKey(fromJson: httpsUrlOf)  String cover, @JsonKey(name: 'episodes', readValue: _readEpisodesCount)  int episodeCount)?  $default,) {final _that = this;
switch (_that) {
case _SearchPgcItem() when $default != null:
return $default(_that.seasonId,_that.title,_that.cover,_that.episodeCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SearchPgcItem implements SearchPgcItem {
  const _SearchPgcItem({@JsonKey(name: 'season_id', fromJson: lenientIntOf) this.seasonId = 0, @JsonKey(fromJson: stripHtmlOf) this.title = '', @JsonKey(fromJson: httpsUrlOf) this.cover = '', @JsonKey(name: 'episodes', readValue: _readEpisodesCount) this.episodeCount = 0});
  factory _SearchPgcItem.fromJson(Map<String, dynamic> json) => _$SearchPgcItemFromJson(json);

@override@JsonKey(name: 'season_id', fromJson: lenientIntOf) final  int seasonId;
@override@JsonKey(fromJson: stripHtmlOf) final  String title;
@override@JsonKey(fromJson: httpsUrlOf) final  String cover;
@override@JsonKey(name: 'episodes', readValue: _readEpisodesCount) final  int episodeCount;

/// Create a copy of SearchPgcItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SearchPgcItemCopyWith<_SearchPgcItem> get copyWith => __$SearchPgcItemCopyWithImpl<_SearchPgcItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SearchPgcItemToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SearchPgcItem&&(identical(other.seasonId, seasonId) || other.seasonId == seasonId)&&(identical(other.title, title) || other.title == title)&&(identical(other.cover, cover) || other.cover == cover)&&(identical(other.episodeCount, episodeCount) || other.episodeCount == episodeCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,seasonId,title,cover,episodeCount);
}

@override
String toString() {
    return 'SearchPgcItem(seasonId: $seasonId, title: $title, cover: $cover, episodeCount: $episodeCount)';
}


}

/// @nodoc
abstract mixin class _$SearchPgcItemCopyWith<$Res> implements $SearchPgcItemCopyWith<$Res> {
  factory _$SearchPgcItemCopyWith(_SearchPgcItem value, $Res Function(_SearchPgcItem) _then) = __$SearchPgcItemCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'season_id', fromJson: lenientIntOf) int seasonId,@JsonKey(fromJson: stripHtmlOf) String title,@JsonKey(fromJson: httpsUrlOf) String cover,@JsonKey(name: 'episodes', readValue: _readEpisodesCount) int episodeCount
});




}
/// @nodoc
class __$SearchPgcItemCopyWithImpl<$Res>
    implements _$SearchPgcItemCopyWith<$Res> {
  __$SearchPgcItemCopyWithImpl(this._self, this._then);

  final _SearchPgcItem _self;
  final $Res Function(_SearchPgcItem) _then;

/// Create a copy of SearchPgcItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? seasonId = null,Object? title = null,Object? cover = null,Object? episodeCount = null,}) {
  return _then(_SearchPgcItem(
seasonId: null == seasonId ? _self.seasonId : seasonId // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,cover: null == cover ? _self.cover : cover // ignore: cast_nullable_to_non_nullable
as String,episodeCount: null == episodeCount ? _self.episodeCount : episodeCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
