// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'player_settings_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PlayerSettingsModel {

 int get videoFitIndex; String get videoPlayerKey; String get preferResolution; String get preferResolutionCellular; bool get enableCodec; bool get playerCompatMode; bool get customPlayerOutput; String get videoOutputDriver; String get audioOutputDriver; String get videoHardwareDecoder; bool get floatPlay; bool get audioOnly; bool get useHardStopOnExit;
/// Create a copy of PlayerSettingsModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlayerSettingsModelCopyWith<PlayerSettingsModel> get copyWith => _$PlayerSettingsModelCopyWithImpl<PlayerSettingsModel>(this as PlayerSettingsModel, _$identity);

  /// Serializes this PlayerSettingsModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlayerSettingsModel&&(identical(other.videoFitIndex, videoFitIndex) || other.videoFitIndex == videoFitIndex)&&(identical(other.videoPlayerKey, videoPlayerKey) || other.videoPlayerKey == videoPlayerKey)&&(identical(other.preferResolution, preferResolution) || other.preferResolution == preferResolution)&&(identical(other.preferResolutionCellular, preferResolutionCellular) || other.preferResolutionCellular == preferResolutionCellular)&&(identical(other.enableCodec, enableCodec) || other.enableCodec == enableCodec)&&(identical(other.playerCompatMode, playerCompatMode) || other.playerCompatMode == playerCompatMode)&&(identical(other.customPlayerOutput, customPlayerOutput) || other.customPlayerOutput == customPlayerOutput)&&(identical(other.videoOutputDriver, videoOutputDriver) || other.videoOutputDriver == videoOutputDriver)&&(identical(other.audioOutputDriver, audioOutputDriver) || other.audioOutputDriver == audioOutputDriver)&&(identical(other.videoHardwareDecoder, videoHardwareDecoder) || other.videoHardwareDecoder == videoHardwareDecoder)&&(identical(other.floatPlay, floatPlay) || other.floatPlay == floatPlay)&&(identical(other.audioOnly, audioOnly) || other.audioOnly == audioOnly)&&(identical(other.useHardStopOnExit, useHardStopOnExit) || other.useHardStopOnExit == useHardStopOnExit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,videoFitIndex,videoPlayerKey,preferResolution,preferResolutionCellular,enableCodec,playerCompatMode,customPlayerOutput,videoOutputDriver,audioOutputDriver,videoHardwareDecoder,floatPlay,audioOnly,useHardStopOnExit);

@override
String toString() {
  return 'PlayerSettingsModel(videoFitIndex: $videoFitIndex, videoPlayerKey: $videoPlayerKey, preferResolution: $preferResolution, preferResolutionCellular: $preferResolutionCellular, enableCodec: $enableCodec, playerCompatMode: $playerCompatMode, customPlayerOutput: $customPlayerOutput, videoOutputDriver: $videoOutputDriver, audioOutputDriver: $audioOutputDriver, videoHardwareDecoder: $videoHardwareDecoder, floatPlay: $floatPlay, audioOnly: $audioOnly, useHardStopOnExit: $useHardStopOnExit)';
}


}

/// @nodoc
abstract mixin class $PlayerSettingsModelCopyWith<$Res>  {
  factory $PlayerSettingsModelCopyWith(PlayerSettingsModel value, $Res Function(PlayerSettingsModel) _then) = _$PlayerSettingsModelCopyWithImpl;
@useResult
$Res call({
 int videoFitIndex, String videoPlayerKey, String preferResolution, String preferResolutionCellular, bool enableCodec, bool playerCompatMode, bool customPlayerOutput, String videoOutputDriver, String audioOutputDriver, String videoHardwareDecoder, bool floatPlay, bool audioOnly, bool useHardStopOnExit
});




}
/// @nodoc
class _$PlayerSettingsModelCopyWithImpl<$Res>
    implements $PlayerSettingsModelCopyWith<$Res> {
  _$PlayerSettingsModelCopyWithImpl(this._self, this._then);

  final PlayerSettingsModel _self;
  final $Res Function(PlayerSettingsModel) _then;

/// Create a copy of PlayerSettingsModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? videoFitIndex = null,Object? videoPlayerKey = null,Object? preferResolution = null,Object? preferResolutionCellular = null,Object? enableCodec = null,Object? playerCompatMode = null,Object? customPlayerOutput = null,Object? videoOutputDriver = null,Object? audioOutputDriver = null,Object? videoHardwareDecoder = null,Object? floatPlay = null,Object? audioOnly = null,Object? useHardStopOnExit = null,}) {
  return _then(_self.copyWith(
videoFitIndex: null == videoFitIndex ? _self.videoFitIndex : videoFitIndex // ignore: cast_nullable_to_non_nullable
as int,videoPlayerKey: null == videoPlayerKey ? _self.videoPlayerKey : videoPlayerKey // ignore: cast_nullable_to_non_nullable
as String,preferResolution: null == preferResolution ? _self.preferResolution : preferResolution // ignore: cast_nullable_to_non_nullable
as String,preferResolutionCellular: null == preferResolutionCellular ? _self.preferResolutionCellular : preferResolutionCellular // ignore: cast_nullable_to_non_nullable
as String,enableCodec: null == enableCodec ? _self.enableCodec : enableCodec // ignore: cast_nullable_to_non_nullable
as bool,playerCompatMode: null == playerCompatMode ? _self.playerCompatMode : playerCompatMode // ignore: cast_nullable_to_non_nullable
as bool,customPlayerOutput: null == customPlayerOutput ? _self.customPlayerOutput : customPlayerOutput // ignore: cast_nullable_to_non_nullable
as bool,videoOutputDriver: null == videoOutputDriver ? _self.videoOutputDriver : videoOutputDriver // ignore: cast_nullable_to_non_nullable
as String,audioOutputDriver: null == audioOutputDriver ? _self.audioOutputDriver : audioOutputDriver // ignore: cast_nullable_to_non_nullable
as String,videoHardwareDecoder: null == videoHardwareDecoder ? _self.videoHardwareDecoder : videoHardwareDecoder // ignore: cast_nullable_to_non_nullable
as String,floatPlay: null == floatPlay ? _self.floatPlay : floatPlay // ignore: cast_nullable_to_non_nullable
as bool,audioOnly: null == audioOnly ? _self.audioOnly : audioOnly // ignore: cast_nullable_to_non_nullable
as bool,useHardStopOnExit: null == useHardStopOnExit ? _self.useHardStopOnExit : useHardStopOnExit // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [PlayerSettingsModel].
extension PlayerSettingsModelPatterns on PlayerSettingsModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlayerSettingsModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlayerSettingsModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlayerSettingsModel value)  $default,){
final _that = this;
switch (_that) {
case _PlayerSettingsModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlayerSettingsModel value)?  $default,){
final _that = this;
switch (_that) {
case _PlayerSettingsModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int videoFitIndex,  String videoPlayerKey,  String preferResolution,  String preferResolutionCellular,  bool enableCodec,  bool playerCompatMode,  bool customPlayerOutput,  String videoOutputDriver,  String audioOutputDriver,  String videoHardwareDecoder,  bool floatPlay,  bool audioOnly,  bool useHardStopOnExit)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlayerSettingsModel() when $default != null:
return $default(_that.videoFitIndex,_that.videoPlayerKey,_that.preferResolution,_that.preferResolutionCellular,_that.enableCodec,_that.playerCompatMode,_that.customPlayerOutput,_that.videoOutputDriver,_that.audioOutputDriver,_that.videoHardwareDecoder,_that.floatPlay,_that.audioOnly,_that.useHardStopOnExit);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int videoFitIndex,  String videoPlayerKey,  String preferResolution,  String preferResolutionCellular,  bool enableCodec,  bool playerCompatMode,  bool customPlayerOutput,  String videoOutputDriver,  String audioOutputDriver,  String videoHardwareDecoder,  bool floatPlay,  bool audioOnly,  bool useHardStopOnExit)  $default,) {final _that = this;
switch (_that) {
case _PlayerSettingsModel():
return $default(_that.videoFitIndex,_that.videoPlayerKey,_that.preferResolution,_that.preferResolutionCellular,_that.enableCodec,_that.playerCompatMode,_that.customPlayerOutput,_that.videoOutputDriver,_that.audioOutputDriver,_that.videoHardwareDecoder,_that.floatPlay,_that.audioOnly,_that.useHardStopOnExit);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int videoFitIndex,  String videoPlayerKey,  String preferResolution,  String preferResolutionCellular,  bool enableCodec,  bool playerCompatMode,  bool customPlayerOutput,  String videoOutputDriver,  String audioOutputDriver,  String videoHardwareDecoder,  bool floatPlay,  bool audioOnly,  bool useHardStopOnExit)?  $default,) {final _that = this;
switch (_that) {
case _PlayerSettingsModel() when $default != null:
return $default(_that.videoFitIndex,_that.videoPlayerKey,_that.preferResolution,_that.preferResolutionCellular,_that.enableCodec,_that.playerCompatMode,_that.customPlayerOutput,_that.videoOutputDriver,_that.audioOutputDriver,_that.videoHardwareDecoder,_that.floatPlay,_that.audioOnly,_that.useHardStopOnExit);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlayerSettingsModel implements PlayerSettingsModel {
  const _PlayerSettingsModel({this.videoFitIndex = 0, this.videoPlayerKey = 'mpv', this.preferResolution = '', this.preferResolutionCellular = '', this.enableCodec = true, this.playerCompatMode = false, this.customPlayerOutput = false, this.videoOutputDriver = 'gpu', this.audioOutputDriver = 'auto', this.videoHardwareDecoder = 'auto', this.floatPlay = false, this.audioOnly = false, this.useHardStopOnExit = false});
  factory _PlayerSettingsModel.fromJson(Map<String, dynamic> json) => _$PlayerSettingsModelFromJson(json);

@override@JsonKey() final  int videoFitIndex;
@override@JsonKey() final  String videoPlayerKey;
@override@JsonKey() final  String preferResolution;
@override@JsonKey() final  String preferResolutionCellular;
@override@JsonKey() final  bool enableCodec;
@override@JsonKey() final  bool playerCompatMode;
@override@JsonKey() final  bool customPlayerOutput;
@override@JsonKey() final  String videoOutputDriver;
@override@JsonKey() final  String audioOutputDriver;
@override@JsonKey() final  String videoHardwareDecoder;
@override@JsonKey() final  bool floatPlay;
@override@JsonKey() final  bool audioOnly;
@override@JsonKey() final  bool useHardStopOnExit;

/// Create a copy of PlayerSettingsModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlayerSettingsModelCopyWith<_PlayerSettingsModel> get copyWith => __$PlayerSettingsModelCopyWithImpl<_PlayerSettingsModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlayerSettingsModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlayerSettingsModel&&(identical(other.videoFitIndex, videoFitIndex) || other.videoFitIndex == videoFitIndex)&&(identical(other.videoPlayerKey, videoPlayerKey) || other.videoPlayerKey == videoPlayerKey)&&(identical(other.preferResolution, preferResolution) || other.preferResolution == preferResolution)&&(identical(other.preferResolutionCellular, preferResolutionCellular) || other.preferResolutionCellular == preferResolutionCellular)&&(identical(other.enableCodec, enableCodec) || other.enableCodec == enableCodec)&&(identical(other.playerCompatMode, playerCompatMode) || other.playerCompatMode == playerCompatMode)&&(identical(other.customPlayerOutput, customPlayerOutput) || other.customPlayerOutput == customPlayerOutput)&&(identical(other.videoOutputDriver, videoOutputDriver) || other.videoOutputDriver == videoOutputDriver)&&(identical(other.audioOutputDriver, audioOutputDriver) || other.audioOutputDriver == audioOutputDriver)&&(identical(other.videoHardwareDecoder, videoHardwareDecoder) || other.videoHardwareDecoder == videoHardwareDecoder)&&(identical(other.floatPlay, floatPlay) || other.floatPlay == floatPlay)&&(identical(other.audioOnly, audioOnly) || other.audioOnly == audioOnly)&&(identical(other.useHardStopOnExit, useHardStopOnExit) || other.useHardStopOnExit == useHardStopOnExit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,videoFitIndex,videoPlayerKey,preferResolution,preferResolutionCellular,enableCodec,playerCompatMode,customPlayerOutput,videoOutputDriver,audioOutputDriver,videoHardwareDecoder,floatPlay,audioOnly,useHardStopOnExit);

@override
String toString() {
  return 'PlayerSettingsModel(videoFitIndex: $videoFitIndex, videoPlayerKey: $videoPlayerKey, preferResolution: $preferResolution, preferResolutionCellular: $preferResolutionCellular, enableCodec: $enableCodec, playerCompatMode: $playerCompatMode, customPlayerOutput: $customPlayerOutput, videoOutputDriver: $videoOutputDriver, audioOutputDriver: $audioOutputDriver, videoHardwareDecoder: $videoHardwareDecoder, floatPlay: $floatPlay, audioOnly: $audioOnly, useHardStopOnExit: $useHardStopOnExit)';
}


}

/// @nodoc
abstract mixin class _$PlayerSettingsModelCopyWith<$Res> implements $PlayerSettingsModelCopyWith<$Res> {
  factory _$PlayerSettingsModelCopyWith(_PlayerSettingsModel value, $Res Function(_PlayerSettingsModel) _then) = __$PlayerSettingsModelCopyWithImpl;
@override @useResult
$Res call({
 int videoFitIndex, String videoPlayerKey, String preferResolution, String preferResolutionCellular, bool enableCodec, bool playerCompatMode, bool customPlayerOutput, String videoOutputDriver, String audioOutputDriver, String videoHardwareDecoder, bool floatPlay, bool audioOnly, bool useHardStopOnExit
});




}
/// @nodoc
class __$PlayerSettingsModelCopyWithImpl<$Res>
    implements _$PlayerSettingsModelCopyWith<$Res> {
  __$PlayerSettingsModelCopyWithImpl(this._self, this._then);

  final _PlayerSettingsModel _self;
  final $Res Function(_PlayerSettingsModel) _then;

/// Create a copy of PlayerSettingsModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? videoFitIndex = null,Object? videoPlayerKey = null,Object? preferResolution = null,Object? preferResolutionCellular = null,Object? enableCodec = null,Object? playerCompatMode = null,Object? customPlayerOutput = null,Object? videoOutputDriver = null,Object? audioOutputDriver = null,Object? videoHardwareDecoder = null,Object? floatPlay = null,Object? audioOnly = null,Object? useHardStopOnExit = null,}) {
  return _then(_PlayerSettingsModel(
videoFitIndex: null == videoFitIndex ? _self.videoFitIndex : videoFitIndex // ignore: cast_nullable_to_non_nullable
as int,videoPlayerKey: null == videoPlayerKey ? _self.videoPlayerKey : videoPlayerKey // ignore: cast_nullable_to_non_nullable
as String,preferResolution: null == preferResolution ? _self.preferResolution : preferResolution // ignore: cast_nullable_to_non_nullable
as String,preferResolutionCellular: null == preferResolutionCellular ? _self.preferResolutionCellular : preferResolutionCellular // ignore: cast_nullable_to_non_nullable
as String,enableCodec: null == enableCodec ? _self.enableCodec : enableCodec // ignore: cast_nullable_to_non_nullable
as bool,playerCompatMode: null == playerCompatMode ? _self.playerCompatMode : playerCompatMode // ignore: cast_nullable_to_non_nullable
as bool,customPlayerOutput: null == customPlayerOutput ? _self.customPlayerOutput : customPlayerOutput // ignore: cast_nullable_to_non_nullable
as bool,videoOutputDriver: null == videoOutputDriver ? _self.videoOutputDriver : videoOutputDriver // ignore: cast_nullable_to_non_nullable
as String,audioOutputDriver: null == audioOutputDriver ? _self.audioOutputDriver : audioOutputDriver // ignore: cast_nullable_to_non_nullable
as String,videoHardwareDecoder: null == videoHardwareDecoder ? _self.videoHardwareDecoder : videoHardwareDecoder // ignore: cast_nullable_to_non_nullable
as String,floatPlay: null == floatPlay ? _self.floatPlay : floatPlay // ignore: cast_nullable_to_non_nullable
as bool,audioOnly: null == audioOnly ? _self.audioOnly : audioOnly // ignore: cast_nullable_to_non_nullable
as bool,useHardStopOnExit: null == useHardStopOnExit ? _self.useHardStopOnExit : useHardStopOnExit // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
