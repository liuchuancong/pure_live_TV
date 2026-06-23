// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'favorite_settings_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FavoriteSettingsModel {

 List<String> get shieldList; List<String> get hotAreasList; String get preferPlatform; List<LiveRoom> get favoriteRooms; List<LiveArea> get favoriteAreas;
/// Create a copy of FavoriteSettingsModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FavoriteSettingsModelCopyWith<FavoriteSettingsModel> get copyWith => _$FavoriteSettingsModelCopyWithImpl<FavoriteSettingsModel>(this as FavoriteSettingsModel, _$identity);

  /// Serializes this FavoriteSettingsModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FavoriteSettingsModel&&const DeepCollectionEquality().equals(other.shieldList, shieldList)&&const DeepCollectionEquality().equals(other.hotAreasList, hotAreasList)&&(identical(other.preferPlatform, preferPlatform) || other.preferPlatform == preferPlatform)&&const DeepCollectionEquality().equals(other.favoriteRooms, favoriteRooms)&&const DeepCollectionEquality().equals(other.favoriteAreas, favoriteAreas));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(shieldList),const DeepCollectionEquality().hash(hotAreasList),preferPlatform,const DeepCollectionEquality().hash(favoriteRooms),const DeepCollectionEquality().hash(favoriteAreas));

@override
String toString() {
  return 'FavoriteSettingsModel(shieldList: $shieldList, hotAreasList: $hotAreasList, preferPlatform: $preferPlatform, favoriteRooms: $favoriteRooms, favoriteAreas: $favoriteAreas)';
}


}

/// @nodoc
abstract mixin class $FavoriteSettingsModelCopyWith<$Res>  {
  factory $FavoriteSettingsModelCopyWith(FavoriteSettingsModel value, $Res Function(FavoriteSettingsModel) _then) = _$FavoriteSettingsModelCopyWithImpl;
@useResult
$Res call({
 List<String> shieldList, List<String> hotAreasList, String preferPlatform, List<LiveRoom> favoriteRooms, List<LiveArea> favoriteAreas
});




}
/// @nodoc
class _$FavoriteSettingsModelCopyWithImpl<$Res>
    implements $FavoriteSettingsModelCopyWith<$Res> {
  _$FavoriteSettingsModelCopyWithImpl(this._self, this._then);

  final FavoriteSettingsModel _self;
  final $Res Function(FavoriteSettingsModel) _then;

/// Create a copy of FavoriteSettingsModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? shieldList = null,Object? hotAreasList = null,Object? preferPlatform = null,Object? favoriteRooms = null,Object? favoriteAreas = null,}) {
  return _then(_self.copyWith(
shieldList: null == shieldList ? _self.shieldList : shieldList // ignore: cast_nullable_to_non_nullable
as List<String>,hotAreasList: null == hotAreasList ? _self.hotAreasList : hotAreasList // ignore: cast_nullable_to_non_nullable
as List<String>,preferPlatform: null == preferPlatform ? _self.preferPlatform : preferPlatform // ignore: cast_nullable_to_non_nullable
as String,favoriteRooms: null == favoriteRooms ? _self.favoriteRooms : favoriteRooms // ignore: cast_nullable_to_non_nullable
as List<LiveRoom>,favoriteAreas: null == favoriteAreas ? _self.favoriteAreas : favoriteAreas // ignore: cast_nullable_to_non_nullable
as List<LiveArea>,
  ));
}

}


/// Adds pattern-matching-related methods to [FavoriteSettingsModel].
extension FavoriteSettingsModelPatterns on FavoriteSettingsModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FavoriteSettingsModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FavoriteSettingsModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FavoriteSettingsModel value)  $default,){
final _that = this;
switch (_that) {
case _FavoriteSettingsModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FavoriteSettingsModel value)?  $default,){
final _that = this;
switch (_that) {
case _FavoriteSettingsModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<String> shieldList,  List<String> hotAreasList,  String preferPlatform,  List<LiveRoom> favoriteRooms,  List<LiveArea> favoriteAreas)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FavoriteSettingsModel() when $default != null:
return $default(_that.shieldList,_that.hotAreasList,_that.preferPlatform,_that.favoriteRooms,_that.favoriteAreas);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<String> shieldList,  List<String> hotAreasList,  String preferPlatform,  List<LiveRoom> favoriteRooms,  List<LiveArea> favoriteAreas)  $default,) {final _that = this;
switch (_that) {
case _FavoriteSettingsModel():
return $default(_that.shieldList,_that.hotAreasList,_that.preferPlatform,_that.favoriteRooms,_that.favoriteAreas);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<String> shieldList,  List<String> hotAreasList,  String preferPlatform,  List<LiveRoom> favoriteRooms,  List<LiveArea> favoriteAreas)?  $default,) {final _that = this;
switch (_that) {
case _FavoriteSettingsModel() when $default != null:
return $default(_that.shieldList,_that.hotAreasList,_that.preferPlatform,_that.favoriteRooms,_that.favoriteAreas);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FavoriteSettingsModel implements FavoriteSettingsModel {
  const _FavoriteSettingsModel({final  List<String> shieldList = const [], final  List<String> hotAreasList = const [], this.preferPlatform = '', final  List<LiveRoom> favoriteRooms = const [], final  List<LiveArea> favoriteAreas = const []}): _shieldList = shieldList,_hotAreasList = hotAreasList,_favoriteRooms = favoriteRooms,_favoriteAreas = favoriteAreas;
  factory _FavoriteSettingsModel.fromJson(Map<String, dynamic> json) => _$FavoriteSettingsModelFromJson(json);

 final  List<String> _shieldList;
@override@JsonKey() List<String> get shieldList {
  if (_shieldList is EqualUnmodifiableListView) return _shieldList;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_shieldList);
}

 final  List<String> _hotAreasList;
@override@JsonKey() List<String> get hotAreasList {
  if (_hotAreasList is EqualUnmodifiableListView) return _hotAreasList;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_hotAreasList);
}

@override@JsonKey() final  String preferPlatform;
 final  List<LiveRoom> _favoriteRooms;
@override@JsonKey() List<LiveRoom> get favoriteRooms {
  if (_favoriteRooms is EqualUnmodifiableListView) return _favoriteRooms;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_favoriteRooms);
}

 final  List<LiveArea> _favoriteAreas;
@override@JsonKey() List<LiveArea> get favoriteAreas {
  if (_favoriteAreas is EqualUnmodifiableListView) return _favoriteAreas;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_favoriteAreas);
}


/// Create a copy of FavoriteSettingsModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FavoriteSettingsModelCopyWith<_FavoriteSettingsModel> get copyWith => __$FavoriteSettingsModelCopyWithImpl<_FavoriteSettingsModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FavoriteSettingsModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FavoriteSettingsModel&&const DeepCollectionEquality().equals(other._shieldList, _shieldList)&&const DeepCollectionEquality().equals(other._hotAreasList, _hotAreasList)&&(identical(other.preferPlatform, preferPlatform) || other.preferPlatform == preferPlatform)&&const DeepCollectionEquality().equals(other._favoriteRooms, _favoriteRooms)&&const DeepCollectionEquality().equals(other._favoriteAreas, _favoriteAreas));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_shieldList),const DeepCollectionEquality().hash(_hotAreasList),preferPlatform,const DeepCollectionEquality().hash(_favoriteRooms),const DeepCollectionEquality().hash(_favoriteAreas));

@override
String toString() {
  return 'FavoriteSettingsModel(shieldList: $shieldList, hotAreasList: $hotAreasList, preferPlatform: $preferPlatform, favoriteRooms: $favoriteRooms, favoriteAreas: $favoriteAreas)';
}


}

/// @nodoc
abstract mixin class _$FavoriteSettingsModelCopyWith<$Res> implements $FavoriteSettingsModelCopyWith<$Res> {
  factory _$FavoriteSettingsModelCopyWith(_FavoriteSettingsModel value, $Res Function(_FavoriteSettingsModel) _then) = __$FavoriteSettingsModelCopyWithImpl;
@override @useResult
$Res call({
 List<String> shieldList, List<String> hotAreasList, String preferPlatform, List<LiveRoom> favoriteRooms, List<LiveArea> favoriteAreas
});




}
/// @nodoc
class __$FavoriteSettingsModelCopyWithImpl<$Res>
    implements _$FavoriteSettingsModelCopyWith<$Res> {
  __$FavoriteSettingsModelCopyWithImpl(this._self, this._then);

  final _FavoriteSettingsModel _self;
  final $Res Function(_FavoriteSettingsModel) _then;

/// Create a copy of FavoriteSettingsModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? shieldList = null,Object? hotAreasList = null,Object? preferPlatform = null,Object? favoriteRooms = null,Object? favoriteAreas = null,}) {
  return _then(_FavoriteSettingsModel(
shieldList: null == shieldList ? _self._shieldList : shieldList // ignore: cast_nullable_to_non_nullable
as List<String>,hotAreasList: null == hotAreasList ? _self._hotAreasList : hotAreasList // ignore: cast_nullable_to_non_nullable
as List<String>,preferPlatform: null == preferPlatform ? _self.preferPlatform : preferPlatform // ignore: cast_nullable_to_non_nullable
as String,favoriteRooms: null == favoriteRooms ? _self._favoriteRooms : favoriteRooms // ignore: cast_nullable_to_non_nullable
as List<LiveRoom>,favoriteAreas: null == favoriteAreas ? _self._favoriteAreas : favoriteAreas // ignore: cast_nullable_to_non_nullable
as List<LiveArea>,
  ));
}


}

// dart format on
