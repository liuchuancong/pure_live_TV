// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'live_area.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LiveArea {

 String get platform; String get areaType; String get typeName; String get areaId; String get areaName; String get areaPic; String get shortName;
/// Create a copy of LiveArea
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LiveAreaCopyWith<LiveArea> get copyWith => _$LiveAreaCopyWithImpl<LiveArea>(this as LiveArea, _$identity);

  /// Serializes this LiveArea to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LiveArea&&(identical(other.platform, platform) || other.platform == platform)&&(identical(other.areaType, areaType) || other.areaType == areaType)&&(identical(other.typeName, typeName) || other.typeName == typeName)&&(identical(other.areaId, areaId) || other.areaId == areaId)&&(identical(other.areaName, areaName) || other.areaName == areaName)&&(identical(other.areaPic, areaPic) || other.areaPic == areaPic)&&(identical(other.shortName, shortName) || other.shortName == shortName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,platform,areaType,typeName,areaId,areaName,areaPic,shortName);

@override
String toString() {
  return 'LiveArea(platform: $platform, areaType: $areaType, typeName: $typeName, areaId: $areaId, areaName: $areaName, areaPic: $areaPic, shortName: $shortName)';
}


}

/// @nodoc
abstract mixin class $LiveAreaCopyWith<$Res>  {
  factory $LiveAreaCopyWith(LiveArea value, $Res Function(LiveArea) _then) = _$LiveAreaCopyWithImpl;
@useResult
$Res call({
 String platform, String areaType, String typeName, String areaId, String areaName, String areaPic, String shortName
});




}
/// @nodoc
class _$LiveAreaCopyWithImpl<$Res>
    implements $LiveAreaCopyWith<$Res> {
  _$LiveAreaCopyWithImpl(this._self, this._then);

  final LiveArea _self;
  final $Res Function(LiveArea) _then;

/// Create a copy of LiveArea
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? platform = null,Object? areaType = null,Object? typeName = null,Object? areaId = null,Object? areaName = null,Object? areaPic = null,Object? shortName = null,}) {
  return _then(_self.copyWith(
platform: null == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as String,areaType: null == areaType ? _self.areaType : areaType // ignore: cast_nullable_to_non_nullable
as String,typeName: null == typeName ? _self.typeName : typeName // ignore: cast_nullable_to_non_nullable
as String,areaId: null == areaId ? _self.areaId : areaId // ignore: cast_nullable_to_non_nullable
as String,areaName: null == areaName ? _self.areaName : areaName // ignore: cast_nullable_to_non_nullable
as String,areaPic: null == areaPic ? _self.areaPic : areaPic // ignore: cast_nullable_to_non_nullable
as String,shortName: null == shortName ? _self.shortName : shortName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [LiveArea].
extension LiveAreaPatterns on LiveArea {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LiveArea value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LiveArea() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LiveArea value)  $default,){
final _that = this;
switch (_that) {
case _LiveArea():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LiveArea value)?  $default,){
final _that = this;
switch (_that) {
case _LiveArea() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String platform,  String areaType,  String typeName,  String areaId,  String areaName,  String areaPic,  String shortName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LiveArea() when $default != null:
return $default(_that.platform,_that.areaType,_that.typeName,_that.areaId,_that.areaName,_that.areaPic,_that.shortName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String platform,  String areaType,  String typeName,  String areaId,  String areaName,  String areaPic,  String shortName)  $default,) {final _that = this;
switch (_that) {
case _LiveArea():
return $default(_that.platform,_that.areaType,_that.typeName,_that.areaId,_that.areaName,_that.areaPic,_that.shortName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String platform,  String areaType,  String typeName,  String areaId,  String areaName,  String areaPic,  String shortName)?  $default,) {final _that = this;
switch (_that) {
case _LiveArea() when $default != null:
return $default(_that.platform,_that.areaType,_that.typeName,_that.areaId,_that.areaName,_that.areaPic,_that.shortName);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LiveArea implements LiveArea {
  const _LiveArea({this.platform = '', this.areaType = '', this.typeName = '', this.areaId = '', this.areaName = '', this.areaPic = '', this.shortName = ''});
  factory _LiveArea.fromJson(Map<String, dynamic> json) => _$LiveAreaFromJson(json);

@override@JsonKey() final  String platform;
@override@JsonKey() final  String areaType;
@override@JsonKey() final  String typeName;
@override@JsonKey() final  String areaId;
@override@JsonKey() final  String areaName;
@override@JsonKey() final  String areaPic;
@override@JsonKey() final  String shortName;

/// Create a copy of LiveArea
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LiveAreaCopyWith<_LiveArea> get copyWith => __$LiveAreaCopyWithImpl<_LiveArea>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LiveAreaToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LiveArea&&(identical(other.platform, platform) || other.platform == platform)&&(identical(other.areaType, areaType) || other.areaType == areaType)&&(identical(other.typeName, typeName) || other.typeName == typeName)&&(identical(other.areaId, areaId) || other.areaId == areaId)&&(identical(other.areaName, areaName) || other.areaName == areaName)&&(identical(other.areaPic, areaPic) || other.areaPic == areaPic)&&(identical(other.shortName, shortName) || other.shortName == shortName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,platform,areaType,typeName,areaId,areaName,areaPic,shortName);

@override
String toString() {
  return 'LiveArea(platform: $platform, areaType: $areaType, typeName: $typeName, areaId: $areaId, areaName: $areaName, areaPic: $areaPic, shortName: $shortName)';
}


}

/// @nodoc
abstract mixin class _$LiveAreaCopyWith<$Res> implements $LiveAreaCopyWith<$Res> {
  factory _$LiveAreaCopyWith(_LiveArea value, $Res Function(_LiveArea) _then) = __$LiveAreaCopyWithImpl;
@override @useResult
$Res call({
 String platform, String areaType, String typeName, String areaId, String areaName, String areaPic, String shortName
});




}
/// @nodoc
class __$LiveAreaCopyWithImpl<$Res>
    implements _$LiveAreaCopyWith<$Res> {
  __$LiveAreaCopyWithImpl(this._self, this._then);

  final _LiveArea _self;
  final $Res Function(_LiveArea) _then;

/// Create a copy of LiveArea
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? platform = null,Object? areaType = null,Object? typeName = null,Object? areaId = null,Object? areaName = null,Object? areaPic = null,Object? shortName = null,}) {
  return _then(_LiveArea(
platform: null == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as String,areaType: null == areaType ? _self.areaType : areaType // ignore: cast_nullable_to_non_nullable
as String,typeName: null == typeName ? _self.typeName : typeName // ignore: cast_nullable_to_non_nullable
as String,areaId: null == areaId ? _self.areaId : areaId // ignore: cast_nullable_to_non_nullable
as String,areaName: null == areaName ? _self.areaName : areaName // ignore: cast_nullable_to_non_nullable
as String,areaPic: null == areaPic ? _self.areaPic : areaPic // ignore: cast_nullable_to_non_nullable
as String,shortName: null == shortName ? _self.shortName : shortName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
