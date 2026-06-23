// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'live_play_quality.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LivePlayQuality {

 String get quality; dynamic get data; int get sort;
/// Create a copy of LivePlayQuality
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LivePlayQualityCopyWith<LivePlayQuality> get copyWith => _$LivePlayQualityCopyWithImpl<LivePlayQuality>(this as LivePlayQuality, _$identity);

  /// Serializes this LivePlayQuality to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LivePlayQuality&&(identical(other.quality, quality) || other.quality == quality)&&const DeepCollectionEquality().equals(other.data, data)&&(identical(other.sort, sort) || other.sort == sort));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,quality,const DeepCollectionEquality().hash(data),sort);

@override
String toString() {
  return 'LivePlayQuality(quality: $quality, data: $data, sort: $sort)';
}


}

/// @nodoc
abstract mixin class $LivePlayQualityCopyWith<$Res>  {
  factory $LivePlayQualityCopyWith(LivePlayQuality value, $Res Function(LivePlayQuality) _then) = _$LivePlayQualityCopyWithImpl;
@useResult
$Res call({
 String quality, dynamic data, int sort
});




}
/// @nodoc
class _$LivePlayQualityCopyWithImpl<$Res>
    implements $LivePlayQualityCopyWith<$Res> {
  _$LivePlayQualityCopyWithImpl(this._self, this._then);

  final LivePlayQuality _self;
  final $Res Function(LivePlayQuality) _then;

/// Create a copy of LivePlayQuality
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? quality = null,Object? data = freezed,Object? sort = null,}) {
  return _then(_self.copyWith(
quality: null == quality ? _self.quality : quality // ignore: cast_nullable_to_non_nullable
as String,data: freezed == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as dynamic,sort: null == sort ? _self.sort : sort // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [LivePlayQuality].
extension LivePlayQualityPatterns on LivePlayQuality {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LivePlayQuality value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LivePlayQuality() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LivePlayQuality value)  $default,){
final _that = this;
switch (_that) {
case _LivePlayQuality():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LivePlayQuality value)?  $default,){
final _that = this;
switch (_that) {
case _LivePlayQuality() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String quality,  dynamic data,  int sort)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LivePlayQuality() when $default != null:
return $default(_that.quality,_that.data,_that.sort);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String quality,  dynamic data,  int sort)  $default,) {final _that = this;
switch (_that) {
case _LivePlayQuality():
return $default(_that.quality,_that.data,_that.sort);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String quality,  dynamic data,  int sort)?  $default,) {final _that = this;
switch (_that) {
case _LivePlayQuality() when $default != null:
return $default(_that.quality,_that.data,_that.sort);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LivePlayQuality implements LivePlayQuality {
  const _LivePlayQuality({required this.quality, this.data, this.sort = 0});
  factory _LivePlayQuality.fromJson(Map<String, dynamic> json) => _$LivePlayQualityFromJson(json);

@override final  String quality;
@override final  dynamic data;
@override@JsonKey() final  int sort;

/// Create a copy of LivePlayQuality
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LivePlayQualityCopyWith<_LivePlayQuality> get copyWith => __$LivePlayQualityCopyWithImpl<_LivePlayQuality>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LivePlayQualityToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LivePlayQuality&&(identical(other.quality, quality) || other.quality == quality)&&const DeepCollectionEquality().equals(other.data, data)&&(identical(other.sort, sort) || other.sort == sort));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,quality,const DeepCollectionEquality().hash(data),sort);

@override
String toString() {
  return 'LivePlayQuality(quality: $quality, data: $data, sort: $sort)';
}


}

/// @nodoc
abstract mixin class _$LivePlayQualityCopyWith<$Res> implements $LivePlayQualityCopyWith<$Res> {
  factory _$LivePlayQualityCopyWith(_LivePlayQuality value, $Res Function(_LivePlayQuality) _then) = __$LivePlayQualityCopyWithImpl;
@override @useResult
$Res call({
 String quality, dynamic data, int sort
});




}
/// @nodoc
class __$LivePlayQualityCopyWithImpl<$Res>
    implements _$LivePlayQualityCopyWith<$Res> {
  __$LivePlayQualityCopyWithImpl(this._self, this._then);

  final _LivePlayQuality _self;
  final $Res Function(_LivePlayQuality) _then;

/// Create a copy of LivePlayQuality
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? quality = null,Object? data = freezed,Object? sort = null,}) {
  return _then(_LivePlayQuality(
quality: null == quality ? _self.quality : quality // ignore: cast_nullable_to_non_nullable
as String,data: freezed == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as dynamic,sort: null == sort ? _self.sort : sort // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
