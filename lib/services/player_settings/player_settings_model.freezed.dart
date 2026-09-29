// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'player_settings_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PlayerSettingsModel {

 int get videoFitIndex; String get videoPlayerKey; String get preferResolution; String get preferResolutionCellular; bool get enableCodec; bool get playerCompatMode; bool get customPlayerOutput; String get videoOutputDriver; String get audioOutputDriver; String get videoHardwareDecoder; bool get floatPlay; bool get audioOnly; bool get useHardStopOnExit; bool get windowsPipAlwaysOnTop; bool get enableRtxVsr; bool get enablePortraitStreamAdaptation; bool get portraitAdaptiveHeight; String get portraitLayoutModeName; String get portraitFullscreenPolicyName; String get portraitFullscreenDisplayModeName; bool get portraitPipFollowSource; String get portraitDanmakuModeName; bool get rememberPortraitRoomOverride; bool get showPortraitDiagnostics; Map<String, String> get portraitRoomOverrides;
/// Create a copy of PlayerSettingsModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlayerSettingsModelCopyWith<PlayerSettingsModel> get copyWith => _$PlayerSettingsModelCopyWithImpl<PlayerSettingsModel>(this as PlayerSettingsModel, _$identity);

  /// Serializes this PlayerSettingsModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PlayerSettingsModel;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlayerSettingsModel&&(identical(other.videoFitIndex, _this.videoFitIndex) || other.videoFitIndex == _this.videoFitIndex)&&(identical(other.videoPlayerKey, _this.videoPlayerKey) || other.videoPlayerKey == _this.videoPlayerKey)&&(identical(other.preferResolution, _this.preferResolution) || other.preferResolution == _this.preferResolution)&&(identical(other.preferResolutionCellular, _this.preferResolutionCellular) || other.preferResolutionCellular == _this.preferResolutionCellular)&&(identical(other.enableCodec, _this.enableCodec) || other.enableCodec == _this.enableCodec)&&(identical(other.playerCompatMode, _this.playerCompatMode) || other.playerCompatMode == _this.playerCompatMode)&&(identical(other.customPlayerOutput, _this.customPlayerOutput) || other.customPlayerOutput == _this.customPlayerOutput)&&(identical(other.videoOutputDriver, _this.videoOutputDriver) || other.videoOutputDriver == _this.videoOutputDriver)&&(identical(other.audioOutputDriver, _this.audioOutputDriver) || other.audioOutputDriver == _this.audioOutputDriver)&&(identical(other.videoHardwareDecoder, _this.videoHardwareDecoder) || other.videoHardwareDecoder == _this.videoHardwareDecoder)&&(identical(other.floatPlay, _this.floatPlay) || other.floatPlay == _this.floatPlay)&&(identical(other.audioOnly, _this.audioOnly) || other.audioOnly == _this.audioOnly)&&(identical(other.useHardStopOnExit, _this.useHardStopOnExit) || other.useHardStopOnExit == _this.useHardStopOnExit)&&(identical(other.windowsPipAlwaysOnTop, _this.windowsPipAlwaysOnTop) || other.windowsPipAlwaysOnTop == _this.windowsPipAlwaysOnTop)&&(identical(other.enableRtxVsr, _this.enableRtxVsr) || other.enableRtxVsr == _this.enableRtxVsr)&&(identical(other.enablePortraitStreamAdaptation, _this.enablePortraitStreamAdaptation) || other.enablePortraitStreamAdaptation == _this.enablePortraitStreamAdaptation)&&(identical(other.portraitAdaptiveHeight, _this.portraitAdaptiveHeight) || other.portraitAdaptiveHeight == _this.portraitAdaptiveHeight)&&(identical(other.portraitLayoutModeName, _this.portraitLayoutModeName) || other.portraitLayoutModeName == _this.portraitLayoutModeName)&&(identical(other.portraitFullscreenPolicyName, _this.portraitFullscreenPolicyName) || other.portraitFullscreenPolicyName == _this.portraitFullscreenPolicyName)&&(identical(other.portraitFullscreenDisplayModeName, _this.portraitFullscreenDisplayModeName) || other.portraitFullscreenDisplayModeName == _this.portraitFullscreenDisplayModeName)&&(identical(other.portraitPipFollowSource, _this.portraitPipFollowSource) || other.portraitPipFollowSource == _this.portraitPipFollowSource)&&(identical(other.portraitDanmakuModeName, _this.portraitDanmakuModeName) || other.portraitDanmakuModeName == _this.portraitDanmakuModeName)&&(identical(other.rememberPortraitRoomOverride, _this.rememberPortraitRoomOverride) || other.rememberPortraitRoomOverride == _this.rememberPortraitRoomOverride)&&(identical(other.showPortraitDiagnostics, _this.showPortraitDiagnostics) || other.showPortraitDiagnostics == _this.showPortraitDiagnostics)&&const DeepCollectionEquality().equals(other.portraitRoomOverrides, _this.portraitRoomOverrides));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PlayerSettingsModel;
  return Object.hashAll([runtimeType,_this.videoFitIndex,_this.videoPlayerKey,_this.preferResolution,_this.preferResolutionCellular,_this.enableCodec,_this.playerCompatMode,_this.customPlayerOutput,_this.videoOutputDriver,_this.audioOutputDriver,_this.videoHardwareDecoder,_this.floatPlay,_this.audioOnly,_this.useHardStopOnExit,_this.windowsPipAlwaysOnTop,_this.enableRtxVsr,_this.enablePortraitStreamAdaptation,_this.portraitAdaptiveHeight,_this.portraitLayoutModeName,_this.portraitFullscreenPolicyName,_this.portraitFullscreenDisplayModeName,_this.portraitPipFollowSource,_this.portraitDanmakuModeName,_this.rememberPortraitRoomOverride,_this.showPortraitDiagnostics,const DeepCollectionEquality().hash(_this.portraitRoomOverrides)]);
}

@override
String toString() {
  final _this = this as PlayerSettingsModel;
  return 'PlayerSettingsModel(videoFitIndex: ${_this.videoFitIndex}, videoPlayerKey: ${_this.videoPlayerKey}, preferResolution: ${_this.preferResolution}, preferResolutionCellular: ${_this.preferResolutionCellular}, enableCodec: ${_this.enableCodec}, playerCompatMode: ${_this.playerCompatMode}, customPlayerOutput: ${_this.customPlayerOutput}, videoOutputDriver: ${_this.videoOutputDriver}, audioOutputDriver: ${_this.audioOutputDriver}, videoHardwareDecoder: ${_this.videoHardwareDecoder}, floatPlay: ${_this.floatPlay}, audioOnly: ${_this.audioOnly}, useHardStopOnExit: ${_this.useHardStopOnExit}, windowsPipAlwaysOnTop: ${_this.windowsPipAlwaysOnTop}, enableRtxVsr: ${_this.enableRtxVsr}, enablePortraitStreamAdaptation: ${_this.enablePortraitStreamAdaptation}, portraitAdaptiveHeight: ${_this.portraitAdaptiveHeight}, portraitLayoutModeName: ${_this.portraitLayoutModeName}, portraitFullscreenPolicyName: ${_this.portraitFullscreenPolicyName}, portraitFullscreenDisplayModeName: ${_this.portraitFullscreenDisplayModeName}, portraitPipFollowSource: ${_this.portraitPipFollowSource}, portraitDanmakuModeName: ${_this.portraitDanmakuModeName}, rememberPortraitRoomOverride: ${_this.rememberPortraitRoomOverride}, showPortraitDiagnostics: ${_this.showPortraitDiagnostics}, portraitRoomOverrides: ${_this.portraitRoomOverrides})';
}


}

/// @nodoc
abstract mixin class $PlayerSettingsModelCopyWith<$Res>  {
  factory $PlayerSettingsModelCopyWith(PlayerSettingsModel value, $Res Function(PlayerSettingsModel) _then) = _$PlayerSettingsModelCopyWithImpl;
@useResult
$Res call({
 int videoFitIndex, String videoPlayerKey, String preferResolution, String preferResolutionCellular, bool enableCodec, bool playerCompatMode, bool customPlayerOutput, String videoOutputDriver, String audioOutputDriver, String videoHardwareDecoder, bool floatPlay, bool audioOnly, bool useHardStopOnExit, bool windowsPipAlwaysOnTop, bool enableRtxVsr, bool enablePortraitStreamAdaptation, bool portraitAdaptiveHeight, String portraitLayoutModeName, String portraitFullscreenPolicyName, String portraitFullscreenDisplayModeName, bool portraitPipFollowSource, String portraitDanmakuModeName, bool rememberPortraitRoomOverride, bool showPortraitDiagnostics, Map<String, String> portraitRoomOverrides
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
@pragma('vm:prefer-inline') @override $Res call({Object? videoFitIndex = null,Object? videoPlayerKey = null,Object? preferResolution = null,Object? preferResolutionCellular = null,Object? enableCodec = null,Object? playerCompatMode = null,Object? customPlayerOutput = null,Object? videoOutputDriver = null,Object? audioOutputDriver = null,Object? videoHardwareDecoder = null,Object? floatPlay = null,Object? audioOnly = null,Object? useHardStopOnExit = null,Object? windowsPipAlwaysOnTop = null,Object? enableRtxVsr = null,Object? enablePortraitStreamAdaptation = null,Object? portraitAdaptiveHeight = null,Object? portraitLayoutModeName = null,Object? portraitFullscreenPolicyName = null,Object? portraitFullscreenDisplayModeName = null,Object? portraitPipFollowSource = null,Object? portraitDanmakuModeName = null,Object? rememberPortraitRoomOverride = null,Object? showPortraitDiagnostics = null,Object? portraitRoomOverrides = null,}) {
  return _then(PlayerSettingsModel(
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
as bool,windowsPipAlwaysOnTop: null == windowsPipAlwaysOnTop ? _self.windowsPipAlwaysOnTop : windowsPipAlwaysOnTop // ignore: cast_nullable_to_non_nullable
as bool,enableRtxVsr: null == enableRtxVsr ? _self.enableRtxVsr : enableRtxVsr // ignore: cast_nullable_to_non_nullable
as bool,enablePortraitStreamAdaptation: null == enablePortraitStreamAdaptation ? _self.enablePortraitStreamAdaptation : enablePortraitStreamAdaptation // ignore: cast_nullable_to_non_nullable
as bool,portraitAdaptiveHeight: null == portraitAdaptiveHeight ? _self.portraitAdaptiveHeight : portraitAdaptiveHeight // ignore: cast_nullable_to_non_nullable
as bool,portraitLayoutModeName: null == portraitLayoutModeName ? _self.portraitLayoutModeName : portraitLayoutModeName // ignore: cast_nullable_to_non_nullable
as String,portraitFullscreenPolicyName: null == portraitFullscreenPolicyName ? _self.portraitFullscreenPolicyName : portraitFullscreenPolicyName // ignore: cast_nullable_to_non_nullable
as String,portraitFullscreenDisplayModeName: null == portraitFullscreenDisplayModeName ? _self.portraitFullscreenDisplayModeName : portraitFullscreenDisplayModeName // ignore: cast_nullable_to_non_nullable
as String,portraitPipFollowSource: null == portraitPipFollowSource ? _self.portraitPipFollowSource : portraitPipFollowSource // ignore: cast_nullable_to_non_nullable
as bool,portraitDanmakuModeName: null == portraitDanmakuModeName ? _self.portraitDanmakuModeName : portraitDanmakuModeName // ignore: cast_nullable_to_non_nullable
as String,rememberPortraitRoomOverride: null == rememberPortraitRoomOverride ? _self.rememberPortraitRoomOverride : rememberPortraitRoomOverride // ignore: cast_nullable_to_non_nullable
as bool,showPortraitDiagnostics: null == showPortraitDiagnostics ? _self.showPortraitDiagnostics : showPortraitDiagnostics // ignore: cast_nullable_to_non_nullable
as bool,portraitRoomOverrides: null == portraitRoomOverrides ? _self.portraitRoomOverrides : portraitRoomOverrides // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int videoFitIndex,  String videoPlayerKey,  String preferResolution,  String preferResolutionCellular,  bool enableCodec,  bool playerCompatMode,  bool customPlayerOutput,  String videoOutputDriver,  String audioOutputDriver,  String videoHardwareDecoder,  bool floatPlay,  bool audioOnly,  bool useHardStopOnExit,  bool windowsPipAlwaysOnTop,  bool enableRtxVsr,  bool enablePortraitStreamAdaptation,  bool portraitAdaptiveHeight,  String portraitLayoutModeName,  String portraitFullscreenPolicyName,  String portraitFullscreenDisplayModeName,  bool portraitPipFollowSource,  String portraitDanmakuModeName,  bool rememberPortraitRoomOverride,  bool showPortraitDiagnostics,  Map<String, String> portraitRoomOverrides)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlayerSettingsModel() when $default != null:
return $default(_that.videoFitIndex,_that.videoPlayerKey,_that.preferResolution,_that.preferResolutionCellular,_that.enableCodec,_that.playerCompatMode,_that.customPlayerOutput,_that.videoOutputDriver,_that.audioOutputDriver,_that.videoHardwareDecoder,_that.floatPlay,_that.audioOnly,_that.useHardStopOnExit,_that.windowsPipAlwaysOnTop,_that.enableRtxVsr,_that.enablePortraitStreamAdaptation,_that.portraitAdaptiveHeight,_that.portraitLayoutModeName,_that.portraitFullscreenPolicyName,_that.portraitFullscreenDisplayModeName,_that.portraitPipFollowSource,_that.portraitDanmakuModeName,_that.rememberPortraitRoomOverride,_that.showPortraitDiagnostics,_that.portraitRoomOverrides);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int videoFitIndex,  String videoPlayerKey,  String preferResolution,  String preferResolutionCellular,  bool enableCodec,  bool playerCompatMode,  bool customPlayerOutput,  String videoOutputDriver,  String audioOutputDriver,  String videoHardwareDecoder,  bool floatPlay,  bool audioOnly,  bool useHardStopOnExit,  bool windowsPipAlwaysOnTop,  bool enableRtxVsr,  bool enablePortraitStreamAdaptation,  bool portraitAdaptiveHeight,  String portraitLayoutModeName,  String portraitFullscreenPolicyName,  String portraitFullscreenDisplayModeName,  bool portraitPipFollowSource,  String portraitDanmakuModeName,  bool rememberPortraitRoomOverride,  bool showPortraitDiagnostics,  Map<String, String> portraitRoomOverrides)  $default,) {final _that = this;
switch (_that) {
case _PlayerSettingsModel():
return $default(_that.videoFitIndex,_that.videoPlayerKey,_that.preferResolution,_that.preferResolutionCellular,_that.enableCodec,_that.playerCompatMode,_that.customPlayerOutput,_that.videoOutputDriver,_that.audioOutputDriver,_that.videoHardwareDecoder,_that.floatPlay,_that.audioOnly,_that.useHardStopOnExit,_that.windowsPipAlwaysOnTop,_that.enableRtxVsr,_that.enablePortraitStreamAdaptation,_that.portraitAdaptiveHeight,_that.portraitLayoutModeName,_that.portraitFullscreenPolicyName,_that.portraitFullscreenDisplayModeName,_that.portraitPipFollowSource,_that.portraitDanmakuModeName,_that.rememberPortraitRoomOverride,_that.showPortraitDiagnostics,_that.portraitRoomOverrides);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int videoFitIndex,  String videoPlayerKey,  String preferResolution,  String preferResolutionCellular,  bool enableCodec,  bool playerCompatMode,  bool customPlayerOutput,  String videoOutputDriver,  String audioOutputDriver,  String videoHardwareDecoder,  bool floatPlay,  bool audioOnly,  bool useHardStopOnExit,  bool windowsPipAlwaysOnTop,  bool enableRtxVsr,  bool enablePortraitStreamAdaptation,  bool portraitAdaptiveHeight,  String portraitLayoutModeName,  String portraitFullscreenPolicyName,  String portraitFullscreenDisplayModeName,  bool portraitPipFollowSource,  String portraitDanmakuModeName,  bool rememberPortraitRoomOverride,  bool showPortraitDiagnostics,  Map<String, String> portraitRoomOverrides)?  $default,) {final _that = this;
switch (_that) {
case _PlayerSettingsModel() when $default != null:
return $default(_that.videoFitIndex,_that.videoPlayerKey,_that.preferResolution,_that.preferResolutionCellular,_that.enableCodec,_that.playerCompatMode,_that.customPlayerOutput,_that.videoOutputDriver,_that.audioOutputDriver,_that.videoHardwareDecoder,_that.floatPlay,_that.audioOnly,_that.useHardStopOnExit,_that.windowsPipAlwaysOnTop,_that.enableRtxVsr,_that.enablePortraitStreamAdaptation,_that.portraitAdaptiveHeight,_that.portraitLayoutModeName,_that.portraitFullscreenPolicyName,_that.portraitFullscreenDisplayModeName,_that.portraitPipFollowSource,_that.portraitDanmakuModeName,_that.rememberPortraitRoomOverride,_that.showPortraitDiagnostics,_that.portraitRoomOverrides);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlayerSettingsModel implements PlayerSettingsModel {
  const _PlayerSettingsModel({this.videoFitIndex = 0, this.videoPlayerKey = 'mpv', this.preferResolution = '', this.preferResolutionCellular = '', this.enableCodec = true, this.playerCompatMode = false, this.customPlayerOutput = false, this.videoOutputDriver = 'gpu', this.audioOutputDriver = 'auto', this.videoHardwareDecoder = 'auto', this.floatPlay = false, this.audioOnly = false, this.useHardStopOnExit = false, this.windowsPipAlwaysOnTop = false, this.enableRtxVsr = false, this.enablePortraitStreamAdaptation = true, this.portraitAdaptiveHeight = true, this.portraitLayoutModeName = 'balanced', this.portraitFullscreenPolicyName = '', this.portraitFullscreenDisplayModeName = '', this.portraitPipFollowSource = true, this.portraitDanmakuModeName = 'followGlobal', this.rememberPortraitRoomOverride = true, this.showPortraitDiagnostics = false,  Map<String, String> portraitRoomOverrides = const {}}): _portraitRoomOverrides = portraitRoomOverrides;
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
@override@JsonKey() final  bool windowsPipAlwaysOnTop;
@override@JsonKey() final  bool enableRtxVsr;
@override@JsonKey() final  bool enablePortraitStreamAdaptation;
@override@JsonKey() final  bool portraitAdaptiveHeight;
@override@JsonKey() final  String portraitLayoutModeName;
@override@JsonKey() final  String portraitFullscreenPolicyName;
@override@JsonKey() final  String portraitFullscreenDisplayModeName;
@override@JsonKey() final  bool portraitPipFollowSource;
@override@JsonKey() final  String portraitDanmakuModeName;
@override@JsonKey() final  bool rememberPortraitRoomOverride;
@override@JsonKey() final  bool showPortraitDiagnostics;
 final  Map<String, String> _portraitRoomOverrides;
@override@JsonKey() Map<String, String> get portraitRoomOverrides {
  if (_portraitRoomOverrides is EqualUnmodifiableMapView) return _portraitRoomOverrides;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_portraitRoomOverrides);
}


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
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlayerSettingsModel&&(identical(other.videoFitIndex, videoFitIndex) || other.videoFitIndex == videoFitIndex)&&(identical(other.videoPlayerKey, videoPlayerKey) || other.videoPlayerKey == videoPlayerKey)&&(identical(other.preferResolution, preferResolution) || other.preferResolution == preferResolution)&&(identical(other.preferResolutionCellular, preferResolutionCellular) || other.preferResolutionCellular == preferResolutionCellular)&&(identical(other.enableCodec, enableCodec) || other.enableCodec == enableCodec)&&(identical(other.playerCompatMode, playerCompatMode) || other.playerCompatMode == playerCompatMode)&&(identical(other.customPlayerOutput, customPlayerOutput) || other.customPlayerOutput == customPlayerOutput)&&(identical(other.videoOutputDriver, videoOutputDriver) || other.videoOutputDriver == videoOutputDriver)&&(identical(other.audioOutputDriver, audioOutputDriver) || other.audioOutputDriver == audioOutputDriver)&&(identical(other.videoHardwareDecoder, videoHardwareDecoder) || other.videoHardwareDecoder == videoHardwareDecoder)&&(identical(other.floatPlay, floatPlay) || other.floatPlay == floatPlay)&&(identical(other.audioOnly, audioOnly) || other.audioOnly == audioOnly)&&(identical(other.useHardStopOnExit, useHardStopOnExit) || other.useHardStopOnExit == useHardStopOnExit)&&(identical(other.windowsPipAlwaysOnTop, windowsPipAlwaysOnTop) || other.windowsPipAlwaysOnTop == windowsPipAlwaysOnTop)&&(identical(other.enableRtxVsr, enableRtxVsr) || other.enableRtxVsr == enableRtxVsr)&&(identical(other.enablePortraitStreamAdaptation, enablePortraitStreamAdaptation) || other.enablePortraitStreamAdaptation == enablePortraitStreamAdaptation)&&(identical(other.portraitAdaptiveHeight, portraitAdaptiveHeight) || other.portraitAdaptiveHeight == portraitAdaptiveHeight)&&(identical(other.portraitLayoutModeName, portraitLayoutModeName) || other.portraitLayoutModeName == portraitLayoutModeName)&&(identical(other.portraitFullscreenPolicyName, portraitFullscreenPolicyName) || other.portraitFullscreenPolicyName == portraitFullscreenPolicyName)&&(identical(other.portraitFullscreenDisplayModeName, portraitFullscreenDisplayModeName) || other.portraitFullscreenDisplayModeName == portraitFullscreenDisplayModeName)&&(identical(other.portraitPipFollowSource, portraitPipFollowSource) || other.portraitPipFollowSource == portraitPipFollowSource)&&(identical(other.portraitDanmakuModeName, portraitDanmakuModeName) || other.portraitDanmakuModeName == portraitDanmakuModeName)&&(identical(other.rememberPortraitRoomOverride, rememberPortraitRoomOverride) || other.rememberPortraitRoomOverride == rememberPortraitRoomOverride)&&(identical(other.showPortraitDiagnostics, showPortraitDiagnostics) || other.showPortraitDiagnostics == showPortraitDiagnostics)&&const DeepCollectionEquality().equals(other.portraitRoomOverrides, _portraitRoomOverrides));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hashAll([runtimeType,videoFitIndex,videoPlayerKey,preferResolution,preferResolutionCellular,enableCodec,playerCompatMode,customPlayerOutput,videoOutputDriver,audioOutputDriver,videoHardwareDecoder,floatPlay,audioOnly,useHardStopOnExit,windowsPipAlwaysOnTop,enableRtxVsr,enablePortraitStreamAdaptation,portraitAdaptiveHeight,portraitLayoutModeName,portraitFullscreenPolicyName,portraitFullscreenDisplayModeName,portraitPipFollowSource,portraitDanmakuModeName,rememberPortraitRoomOverride,showPortraitDiagnostics,const DeepCollectionEquality().hash(_portraitRoomOverrides)]);
}

@override
String toString() {
    return 'PlayerSettingsModel(videoFitIndex: $videoFitIndex, videoPlayerKey: $videoPlayerKey, preferResolution: $preferResolution, preferResolutionCellular: $preferResolutionCellular, enableCodec: $enableCodec, playerCompatMode: $playerCompatMode, customPlayerOutput: $customPlayerOutput, videoOutputDriver: $videoOutputDriver, audioOutputDriver: $audioOutputDriver, videoHardwareDecoder: $videoHardwareDecoder, floatPlay: $floatPlay, audioOnly: $audioOnly, useHardStopOnExit: $useHardStopOnExit, windowsPipAlwaysOnTop: $windowsPipAlwaysOnTop, enableRtxVsr: $enableRtxVsr, enablePortraitStreamAdaptation: $enablePortraitStreamAdaptation, portraitAdaptiveHeight: $portraitAdaptiveHeight, portraitLayoutModeName: $portraitLayoutModeName, portraitFullscreenPolicyName: $portraitFullscreenPolicyName, portraitFullscreenDisplayModeName: $portraitFullscreenDisplayModeName, portraitPipFollowSource: $portraitPipFollowSource, portraitDanmakuModeName: $portraitDanmakuModeName, rememberPortraitRoomOverride: $rememberPortraitRoomOverride, showPortraitDiagnostics: $showPortraitDiagnostics, portraitRoomOverrides: $portraitRoomOverrides)';
}


}

/// @nodoc
abstract mixin class _$PlayerSettingsModelCopyWith<$Res> implements $PlayerSettingsModelCopyWith<$Res> {
  factory _$PlayerSettingsModelCopyWith(_PlayerSettingsModel value, $Res Function(_PlayerSettingsModel) _then) = __$PlayerSettingsModelCopyWithImpl;
@override @useResult
$Res call({
 int videoFitIndex, String videoPlayerKey, String preferResolution, String preferResolutionCellular, bool enableCodec, bool playerCompatMode, bool customPlayerOutput, String videoOutputDriver, String audioOutputDriver, String videoHardwareDecoder, bool floatPlay, bool audioOnly, bool useHardStopOnExit, bool windowsPipAlwaysOnTop, bool enableRtxVsr, bool enablePortraitStreamAdaptation, bool portraitAdaptiveHeight, String portraitLayoutModeName, String portraitFullscreenPolicyName, String portraitFullscreenDisplayModeName, bool portraitPipFollowSource, String portraitDanmakuModeName, bool rememberPortraitRoomOverride, bool showPortraitDiagnostics, Map<String, String> portraitRoomOverrides
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
@override @pragma('vm:prefer-inline') $Res call({Object? videoFitIndex = null,Object? videoPlayerKey = null,Object? preferResolution = null,Object? preferResolutionCellular = null,Object? enableCodec = null,Object? playerCompatMode = null,Object? customPlayerOutput = null,Object? videoOutputDriver = null,Object? audioOutputDriver = null,Object? videoHardwareDecoder = null,Object? floatPlay = null,Object? audioOnly = null,Object? useHardStopOnExit = null,Object? windowsPipAlwaysOnTop = null,Object? enableRtxVsr = null,Object? enablePortraitStreamAdaptation = null,Object? portraitAdaptiveHeight = null,Object? portraitLayoutModeName = null,Object? portraitFullscreenPolicyName = null,Object? portraitFullscreenDisplayModeName = null,Object? portraitPipFollowSource = null,Object? portraitDanmakuModeName = null,Object? rememberPortraitRoomOverride = null,Object? showPortraitDiagnostics = null,Object? portraitRoomOverrides = null,}) {
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
as bool,windowsPipAlwaysOnTop: null == windowsPipAlwaysOnTop ? _self.windowsPipAlwaysOnTop : windowsPipAlwaysOnTop // ignore: cast_nullable_to_non_nullable
as bool,enableRtxVsr: null == enableRtxVsr ? _self.enableRtxVsr : enableRtxVsr // ignore: cast_nullable_to_non_nullable
as bool,enablePortraitStreamAdaptation: null == enablePortraitStreamAdaptation ? _self.enablePortraitStreamAdaptation : enablePortraitStreamAdaptation // ignore: cast_nullable_to_non_nullable
as bool,portraitAdaptiveHeight: null == portraitAdaptiveHeight ? _self.portraitAdaptiveHeight : portraitAdaptiveHeight // ignore: cast_nullable_to_non_nullable
as bool,portraitLayoutModeName: null == portraitLayoutModeName ? _self.portraitLayoutModeName : portraitLayoutModeName // ignore: cast_nullable_to_non_nullable
as String,portraitFullscreenPolicyName: null == portraitFullscreenPolicyName ? _self.portraitFullscreenPolicyName : portraitFullscreenPolicyName // ignore: cast_nullable_to_non_nullable
as String,portraitFullscreenDisplayModeName: null == portraitFullscreenDisplayModeName ? _self.portraitFullscreenDisplayModeName : portraitFullscreenDisplayModeName // ignore: cast_nullable_to_non_nullable
as String,portraitPipFollowSource: null == portraitPipFollowSource ? _self.portraitPipFollowSource : portraitPipFollowSource // ignore: cast_nullable_to_non_nullable
as bool,portraitDanmakuModeName: null == portraitDanmakuModeName ? _self.portraitDanmakuModeName : portraitDanmakuModeName // ignore: cast_nullable_to_non_nullable
as String,rememberPortraitRoomOverride: null == rememberPortraitRoomOverride ? _self.rememberPortraitRoomOverride : rememberPortraitRoomOverride // ignore: cast_nullable_to_non_nullable
as bool,showPortraitDiagnostics: null == showPortraitDiagnostics ? _self.showPortraitDiagnostics : showPortraitDiagnostics // ignore: cast_nullable_to_non_nullable
as bool,portraitRoomOverrides: null == portraitRoomOverrides ? _self._portraitRoomOverrides : portraitRoomOverrides // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}


}

// dart format on
