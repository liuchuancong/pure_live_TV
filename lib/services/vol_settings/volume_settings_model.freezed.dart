// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'volume_settings_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$VolumeSettingsModel {

 double get defaultMobileVolume; double get defaultDesktopVolume; bool get globalVolumeMute; Map<String, double> get roomVolumes;
/// Create a copy of VolumeSettingsModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VolumeSettingsModelCopyWith<VolumeSettingsModel> get copyWith => _$VolumeSettingsModelCopyWithImpl<VolumeSettingsModel>(this as VolumeSettingsModel, _$identity);

  /// Serializes this VolumeSettingsModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VolumeSettingsModel&&(identical(other.defaultMobileVolume, defaultMobileVolume) || other.defaultMobileVolume == defaultMobileVolume)&&(identical(other.defaultDesktopVolume, defaultDesktopVolume) || other.defaultDesktopVolume == defaultDesktopVolume)&&(identical(other.globalVolumeMute, globalVolumeMute) || other.globalVolumeMute == globalVolumeMute)&&const DeepCollectionEquality().equals(other.roomVolumes, roomVolumes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,defaultMobileVolume,defaultDesktopVolume,globalVolumeMute,const DeepCollectionEquality().hash(roomVolumes));

@override
String toString() {
  return 'VolumeSettingsModel(defaultMobileVolume: $defaultMobileVolume, defaultDesktopVolume: $defaultDesktopVolume, globalVolumeMute: $globalVolumeMute, roomVolumes: $roomVolumes)';
}


}

/// @nodoc
abstract mixin class $VolumeSettingsModelCopyWith<$Res>  {
  factory $VolumeSettingsModelCopyWith(VolumeSettingsModel value, $Res Function(VolumeSettingsModel) _then) = _$VolumeSettingsModelCopyWithImpl;
@useResult
$Res call({
 double defaultMobileVolume, double defaultDesktopVolume, bool globalVolumeMute, Map<String, double> roomVolumes
});




}
/// @nodoc
class _$VolumeSettingsModelCopyWithImpl<$Res>
    implements $VolumeSettingsModelCopyWith<$Res> {
  _$VolumeSettingsModelCopyWithImpl(this._self, this._then);

  final VolumeSettingsModel _self;
  final $Res Function(VolumeSettingsModel) _then;

/// Create a copy of VolumeSettingsModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? defaultMobileVolume = null,Object? defaultDesktopVolume = null,Object? globalVolumeMute = null,Object? roomVolumes = null,}) {
  return _then(_self.copyWith(
defaultMobileVolume: null == defaultMobileVolume ? _self.defaultMobileVolume : defaultMobileVolume // ignore: cast_nullable_to_non_nullable
as double,defaultDesktopVolume: null == defaultDesktopVolume ? _self.defaultDesktopVolume : defaultDesktopVolume // ignore: cast_nullable_to_non_nullable
as double,globalVolumeMute: null == globalVolumeMute ? _self.globalVolumeMute : globalVolumeMute // ignore: cast_nullable_to_non_nullable
as bool,roomVolumes: null == roomVolumes ? _self.roomVolumes : roomVolumes // ignore: cast_nullable_to_non_nullable
as Map<String, double>,
  ));
}

}


/// Adds pattern-matching-related methods to [VolumeSettingsModel].
extension VolumeSettingsModelPatterns on VolumeSettingsModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VolumeSettingsModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VolumeSettingsModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VolumeSettingsModel value)  $default,){
final _that = this;
switch (_that) {
case _VolumeSettingsModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VolumeSettingsModel value)?  $default,){
final _that = this;
switch (_that) {
case _VolumeSettingsModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double defaultMobileVolume,  double defaultDesktopVolume,  bool globalVolumeMute,  Map<String, double> roomVolumes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VolumeSettingsModel() when $default != null:
return $default(_that.defaultMobileVolume,_that.defaultDesktopVolume,_that.globalVolumeMute,_that.roomVolumes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double defaultMobileVolume,  double defaultDesktopVolume,  bool globalVolumeMute,  Map<String, double> roomVolumes)  $default,) {final _that = this;
switch (_that) {
case _VolumeSettingsModel():
return $default(_that.defaultMobileVolume,_that.defaultDesktopVolume,_that.globalVolumeMute,_that.roomVolumes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double defaultMobileVolume,  double defaultDesktopVolume,  bool globalVolumeMute,  Map<String, double> roomVolumes)?  $default,) {final _that = this;
switch (_that) {
case _VolumeSettingsModel() when $default != null:
return $default(_that.defaultMobileVolume,_that.defaultDesktopVolume,_that.globalVolumeMute,_that.roomVolumes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VolumeSettingsModel implements VolumeSettingsModel {
  const _VolumeSettingsModel({this.defaultMobileVolume = 0.5, this.defaultDesktopVolume = 1.0, this.globalVolumeMute = false, final  Map<String, double> roomVolumes = const {}}): _roomVolumes = roomVolumes;
  factory _VolumeSettingsModel.fromJson(Map<String, dynamic> json) => _$VolumeSettingsModelFromJson(json);

@override@JsonKey() final  double defaultMobileVolume;
@override@JsonKey() final  double defaultDesktopVolume;
@override@JsonKey() final  bool globalVolumeMute;
 final  Map<String, double> _roomVolumes;
@override@JsonKey() Map<String, double> get roomVolumes {
  if (_roomVolumes is EqualUnmodifiableMapView) return _roomVolumes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_roomVolumes);
}


/// Create a copy of VolumeSettingsModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VolumeSettingsModelCopyWith<_VolumeSettingsModel> get copyWith => __$VolumeSettingsModelCopyWithImpl<_VolumeSettingsModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VolumeSettingsModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VolumeSettingsModel&&(identical(other.defaultMobileVolume, defaultMobileVolume) || other.defaultMobileVolume == defaultMobileVolume)&&(identical(other.defaultDesktopVolume, defaultDesktopVolume) || other.defaultDesktopVolume == defaultDesktopVolume)&&(identical(other.globalVolumeMute, globalVolumeMute) || other.globalVolumeMute == globalVolumeMute)&&const DeepCollectionEquality().equals(other._roomVolumes, _roomVolumes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,defaultMobileVolume,defaultDesktopVolume,globalVolumeMute,const DeepCollectionEquality().hash(_roomVolumes));

@override
String toString() {
  return 'VolumeSettingsModel(defaultMobileVolume: $defaultMobileVolume, defaultDesktopVolume: $defaultDesktopVolume, globalVolumeMute: $globalVolumeMute, roomVolumes: $roomVolumes)';
}


}

/// @nodoc
abstract mixin class _$VolumeSettingsModelCopyWith<$Res> implements $VolumeSettingsModelCopyWith<$Res> {
  factory _$VolumeSettingsModelCopyWith(_VolumeSettingsModel value, $Res Function(_VolumeSettingsModel) _then) = __$VolumeSettingsModelCopyWithImpl;
@override @useResult
$Res call({
 double defaultMobileVolume, double defaultDesktopVolume, bool globalVolumeMute, Map<String, double> roomVolumes
});




}
/// @nodoc
class __$VolumeSettingsModelCopyWithImpl<$Res>
    implements _$VolumeSettingsModelCopyWith<$Res> {
  __$VolumeSettingsModelCopyWithImpl(this._self, this._then);

  final _VolumeSettingsModel _self;
  final $Res Function(_VolumeSettingsModel) _then;

/// Create a copy of VolumeSettingsModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? defaultMobileVolume = null,Object? defaultDesktopVolume = null,Object? globalVolumeMute = null,Object? roomVolumes = null,}) {
  return _then(_VolumeSettingsModel(
defaultMobileVolume: null == defaultMobileVolume ? _self.defaultMobileVolume : defaultMobileVolume // ignore: cast_nullable_to_non_nullable
as double,defaultDesktopVolume: null == defaultDesktopVolume ? _self.defaultDesktopVolume : defaultDesktopVolume // ignore: cast_nullable_to_non_nullable
as double,globalVolumeMute: null == globalVolumeMute ? _self.globalVolumeMute : globalVolumeMute // ignore: cast_nullable_to_non_nullable
as bool,roomVolumes: null == roomVolumes ? _self._roomVolumes : roomVolumes // ignore: cast_nullable_to_non_nullable
as Map<String, double>,
  ));
}


}

// dart format on
