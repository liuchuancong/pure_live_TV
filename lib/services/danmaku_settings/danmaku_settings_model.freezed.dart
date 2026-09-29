// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'danmaku_settings_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DanmakuSettingsModel {

 bool get hideDanmaku; bool get noEmojiMode; double get danmakuTopArea; double get danmakuArea; double get danmakuBottomArea; double get danmakuSpeed; double get danmakuFontSize; int get danmakuFontWeight; double get danmakuFontBorder; double get danmakuOpacity; bool get enableDanmakuDisplay; bool get enableDanmakuStroke;/// Burst dispatch: bypass `emitInterval` pacing and flush the waiting
/// queue every logic frame (`BarrageConfig.realtimeMode`). On = lowest
/// latency during floods, denser screen; off = paced, calmer.
 bool get danmakuRealtimeMode;/// Paragraph shadow under the text (`BarrageConfig.showShadow`).
 bool get danmakuShowShadow;/// Shadow blur radius in logical pixels (`BarrageConfig.shadowBlur`).
 double get danmakuShadowBlur;/// Extra glyph spacing in logical pixels (`BarrageConfig.letterSpacing`).
 double get danmakuLetterSpacing;/// Dwell time of pinned (top/bottom) danmaku, in seconds
/// (`BarrageConfig.fixedDuration`).
 int get danmakuFixedDuration;/// Minimum clearance between consecutive danmaku in one lane, in logical
/// pixels (`BarrageConfig.overlapSafeGap`).
 double get danmakuOverlapSafeGap;/// Queue cap before the oldest waiting message is dropped
/// (`BarrageConfig.maxPendingCount`).
 int get danmakuMaxPendingCount;/// Age in seconds after which a waiting message is dropped instead of
/// shown (`BarrageConfig.maxPendingAge`).
 int get danmakuMaxPendingAge; int get danmakuFps;/// Auto frame rate: follow the display's refresh rate instead of [danmakuFps].
///
/// The stored default is on (see DanmakuSettingsController.build) — a panel
/// the engine can keep up with is the whole budget it has, and a fixed 60 on
/// a 120Hz panel is a loss of smoothness for nothing. This factory default
/// stays off for documents that predate the field, so an imported backup or
/// a peer keeps the choice it was saved with.
 bool get danmakuAutoFps; bool get enableDanmakuTapInteraction; bool get enableDanmakuLongPressInteraction; bool get collapseRepeatedDanmaku; int get repeatedDanmakuWindowSeconds; int get danmakuInteractionMigration; String get savedDanmakuTemplate; String get danmakuFontFamilyName; bool get enablePipDanmaku; bool get pipDanmakuAutoScale; bool get pipDanmakuNoEmojiMode; bool get pipDanmakuUseOriginalColor; int get pipDanmakuColor; double get pipDanmakuFontSize; int get pipDanmakuFontWeight; double get pipDanmakuSpeed; double get pipDanmakuOpacity; double get pipDanmakuArea; int get pipDanmakuMaxVisibleCount; double get pipDanmakuEmitInterval; int get pipDanmakuFps; bool get pipDanmakuAutoFps; bool get filterDouyuSuspectedAutomatedMessages; bool get enableDanmakuSimilarityFilter; int get danmakuSimilarityThreshold; int get danmakuSimilarityCacheDuration; int get danmakuSimilarityMaxCacheSize;
/// Create a copy of DanmakuSettingsModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DanmakuSettingsModelCopyWith<DanmakuSettingsModel> get copyWith => _$DanmakuSettingsModelCopyWithImpl<DanmakuSettingsModel>(this as DanmakuSettingsModel, _$identity);

  /// Serializes this DanmakuSettingsModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as DanmakuSettingsModel;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DanmakuSettingsModel&&(identical(other.hideDanmaku, _this.hideDanmaku) || other.hideDanmaku == _this.hideDanmaku)&&(identical(other.noEmojiMode, _this.noEmojiMode) || other.noEmojiMode == _this.noEmojiMode)&&(identical(other.danmakuTopArea, _this.danmakuTopArea) || other.danmakuTopArea == _this.danmakuTopArea)&&(identical(other.danmakuArea, _this.danmakuArea) || other.danmakuArea == _this.danmakuArea)&&(identical(other.danmakuBottomArea, _this.danmakuBottomArea) || other.danmakuBottomArea == _this.danmakuBottomArea)&&(identical(other.danmakuSpeed, _this.danmakuSpeed) || other.danmakuSpeed == _this.danmakuSpeed)&&(identical(other.danmakuFontSize, _this.danmakuFontSize) || other.danmakuFontSize == _this.danmakuFontSize)&&(identical(other.danmakuFontWeight, _this.danmakuFontWeight) || other.danmakuFontWeight == _this.danmakuFontWeight)&&(identical(other.danmakuFontBorder, _this.danmakuFontBorder) || other.danmakuFontBorder == _this.danmakuFontBorder)&&(identical(other.danmakuOpacity, _this.danmakuOpacity) || other.danmakuOpacity == _this.danmakuOpacity)&&(identical(other.enableDanmakuDisplay, _this.enableDanmakuDisplay) || other.enableDanmakuDisplay == _this.enableDanmakuDisplay)&&(identical(other.enableDanmakuStroke, _this.enableDanmakuStroke) || other.enableDanmakuStroke == _this.enableDanmakuStroke)&&(identical(other.danmakuRealtimeMode, _this.danmakuRealtimeMode) || other.danmakuRealtimeMode == _this.danmakuRealtimeMode)&&(identical(other.danmakuShowShadow, _this.danmakuShowShadow) || other.danmakuShowShadow == _this.danmakuShowShadow)&&(identical(other.danmakuShadowBlur, _this.danmakuShadowBlur) || other.danmakuShadowBlur == _this.danmakuShadowBlur)&&(identical(other.danmakuLetterSpacing, _this.danmakuLetterSpacing) || other.danmakuLetterSpacing == _this.danmakuLetterSpacing)&&(identical(other.danmakuFixedDuration, _this.danmakuFixedDuration) || other.danmakuFixedDuration == _this.danmakuFixedDuration)&&(identical(other.danmakuOverlapSafeGap, _this.danmakuOverlapSafeGap) || other.danmakuOverlapSafeGap == _this.danmakuOverlapSafeGap)&&(identical(other.danmakuMaxPendingCount, _this.danmakuMaxPendingCount) || other.danmakuMaxPendingCount == _this.danmakuMaxPendingCount)&&(identical(other.danmakuMaxPendingAge, _this.danmakuMaxPendingAge) || other.danmakuMaxPendingAge == _this.danmakuMaxPendingAge)&&(identical(other.danmakuFps, _this.danmakuFps) || other.danmakuFps == _this.danmakuFps)&&(identical(other.danmakuAutoFps, _this.danmakuAutoFps) || other.danmakuAutoFps == _this.danmakuAutoFps)&&(identical(other.enableDanmakuTapInteraction, _this.enableDanmakuTapInteraction) || other.enableDanmakuTapInteraction == _this.enableDanmakuTapInteraction)&&(identical(other.enableDanmakuLongPressInteraction, _this.enableDanmakuLongPressInteraction) || other.enableDanmakuLongPressInteraction == _this.enableDanmakuLongPressInteraction)&&(identical(other.collapseRepeatedDanmaku, _this.collapseRepeatedDanmaku) || other.collapseRepeatedDanmaku == _this.collapseRepeatedDanmaku)&&(identical(other.repeatedDanmakuWindowSeconds, _this.repeatedDanmakuWindowSeconds) || other.repeatedDanmakuWindowSeconds == _this.repeatedDanmakuWindowSeconds)&&(identical(other.danmakuInteractionMigration, _this.danmakuInteractionMigration) || other.danmakuInteractionMigration == _this.danmakuInteractionMigration)&&(identical(other.savedDanmakuTemplate, _this.savedDanmakuTemplate) || other.savedDanmakuTemplate == _this.savedDanmakuTemplate)&&(identical(other.danmakuFontFamilyName, _this.danmakuFontFamilyName) || other.danmakuFontFamilyName == _this.danmakuFontFamilyName)&&(identical(other.enablePipDanmaku, _this.enablePipDanmaku) || other.enablePipDanmaku == _this.enablePipDanmaku)&&(identical(other.pipDanmakuAutoScale, _this.pipDanmakuAutoScale) || other.pipDanmakuAutoScale == _this.pipDanmakuAutoScale)&&(identical(other.pipDanmakuNoEmojiMode, _this.pipDanmakuNoEmojiMode) || other.pipDanmakuNoEmojiMode == _this.pipDanmakuNoEmojiMode)&&(identical(other.pipDanmakuUseOriginalColor, _this.pipDanmakuUseOriginalColor) || other.pipDanmakuUseOriginalColor == _this.pipDanmakuUseOriginalColor)&&(identical(other.pipDanmakuColor, _this.pipDanmakuColor) || other.pipDanmakuColor == _this.pipDanmakuColor)&&(identical(other.pipDanmakuFontSize, _this.pipDanmakuFontSize) || other.pipDanmakuFontSize == _this.pipDanmakuFontSize)&&(identical(other.pipDanmakuFontWeight, _this.pipDanmakuFontWeight) || other.pipDanmakuFontWeight == _this.pipDanmakuFontWeight)&&(identical(other.pipDanmakuSpeed, _this.pipDanmakuSpeed) || other.pipDanmakuSpeed == _this.pipDanmakuSpeed)&&(identical(other.pipDanmakuOpacity, _this.pipDanmakuOpacity) || other.pipDanmakuOpacity == _this.pipDanmakuOpacity)&&(identical(other.pipDanmakuArea, _this.pipDanmakuArea) || other.pipDanmakuArea == _this.pipDanmakuArea)&&(identical(other.pipDanmakuMaxVisibleCount, _this.pipDanmakuMaxVisibleCount) || other.pipDanmakuMaxVisibleCount == _this.pipDanmakuMaxVisibleCount)&&(identical(other.pipDanmakuEmitInterval, _this.pipDanmakuEmitInterval) || other.pipDanmakuEmitInterval == _this.pipDanmakuEmitInterval)&&(identical(other.pipDanmakuFps, _this.pipDanmakuFps) || other.pipDanmakuFps == _this.pipDanmakuFps)&&(identical(other.pipDanmakuAutoFps, _this.pipDanmakuAutoFps) || other.pipDanmakuAutoFps == _this.pipDanmakuAutoFps)&&(identical(other.filterDouyuSuspectedAutomatedMessages, _this.filterDouyuSuspectedAutomatedMessages) || other.filterDouyuSuspectedAutomatedMessages == _this.filterDouyuSuspectedAutomatedMessages)&&(identical(other.enableDanmakuSimilarityFilter, _this.enableDanmakuSimilarityFilter) || other.enableDanmakuSimilarityFilter == _this.enableDanmakuSimilarityFilter)&&(identical(other.danmakuSimilarityThreshold, _this.danmakuSimilarityThreshold) || other.danmakuSimilarityThreshold == _this.danmakuSimilarityThreshold)&&(identical(other.danmakuSimilarityCacheDuration, _this.danmakuSimilarityCacheDuration) || other.danmakuSimilarityCacheDuration == _this.danmakuSimilarityCacheDuration)&&(identical(other.danmakuSimilarityMaxCacheSize, _this.danmakuSimilarityMaxCacheSize) || other.danmakuSimilarityMaxCacheSize == _this.danmakuSimilarityMaxCacheSize));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as DanmakuSettingsModel;
  return Object.hashAll([runtimeType,_this.hideDanmaku,_this.noEmojiMode,_this.danmakuTopArea,_this.danmakuArea,_this.danmakuBottomArea,_this.danmakuSpeed,_this.danmakuFontSize,_this.danmakuFontWeight,_this.danmakuFontBorder,_this.danmakuOpacity,_this.enableDanmakuDisplay,_this.enableDanmakuStroke,_this.danmakuRealtimeMode,_this.danmakuShowShadow,_this.danmakuShadowBlur,_this.danmakuLetterSpacing,_this.danmakuFixedDuration,_this.danmakuOverlapSafeGap,_this.danmakuMaxPendingCount,_this.danmakuMaxPendingAge,_this.danmakuFps,_this.danmakuAutoFps,_this.enableDanmakuTapInteraction,_this.enableDanmakuLongPressInteraction,_this.collapseRepeatedDanmaku,_this.repeatedDanmakuWindowSeconds,_this.danmakuInteractionMigration,_this.savedDanmakuTemplate,_this.danmakuFontFamilyName,_this.enablePipDanmaku,_this.pipDanmakuAutoScale,_this.pipDanmakuNoEmojiMode,_this.pipDanmakuUseOriginalColor,_this.pipDanmakuColor,_this.pipDanmakuFontSize,_this.pipDanmakuFontWeight,_this.pipDanmakuSpeed,_this.pipDanmakuOpacity,_this.pipDanmakuArea,_this.pipDanmakuMaxVisibleCount,_this.pipDanmakuEmitInterval,_this.pipDanmakuFps,_this.pipDanmakuAutoFps,_this.filterDouyuSuspectedAutomatedMessages,_this.enableDanmakuSimilarityFilter,_this.danmakuSimilarityThreshold,_this.danmakuSimilarityCacheDuration,_this.danmakuSimilarityMaxCacheSize]);
}

@override
String toString() {
  final _this = this as DanmakuSettingsModel;
  return 'DanmakuSettingsModel(hideDanmaku: ${_this.hideDanmaku}, noEmojiMode: ${_this.noEmojiMode}, danmakuTopArea: ${_this.danmakuTopArea}, danmakuArea: ${_this.danmakuArea}, danmakuBottomArea: ${_this.danmakuBottomArea}, danmakuSpeed: ${_this.danmakuSpeed}, danmakuFontSize: ${_this.danmakuFontSize}, danmakuFontWeight: ${_this.danmakuFontWeight}, danmakuFontBorder: ${_this.danmakuFontBorder}, danmakuOpacity: ${_this.danmakuOpacity}, enableDanmakuDisplay: ${_this.enableDanmakuDisplay}, enableDanmakuStroke: ${_this.enableDanmakuStroke}, danmakuRealtimeMode: ${_this.danmakuRealtimeMode}, danmakuShowShadow: ${_this.danmakuShowShadow}, danmakuShadowBlur: ${_this.danmakuShadowBlur}, danmakuLetterSpacing: ${_this.danmakuLetterSpacing}, danmakuFixedDuration: ${_this.danmakuFixedDuration}, danmakuOverlapSafeGap: ${_this.danmakuOverlapSafeGap}, danmakuMaxPendingCount: ${_this.danmakuMaxPendingCount}, danmakuMaxPendingAge: ${_this.danmakuMaxPendingAge}, danmakuFps: ${_this.danmakuFps}, danmakuAutoFps: ${_this.danmakuAutoFps}, enableDanmakuTapInteraction: ${_this.enableDanmakuTapInteraction}, enableDanmakuLongPressInteraction: ${_this.enableDanmakuLongPressInteraction}, collapseRepeatedDanmaku: ${_this.collapseRepeatedDanmaku}, repeatedDanmakuWindowSeconds: ${_this.repeatedDanmakuWindowSeconds}, danmakuInteractionMigration: ${_this.danmakuInteractionMigration}, savedDanmakuTemplate: ${_this.savedDanmakuTemplate}, danmakuFontFamilyName: ${_this.danmakuFontFamilyName}, enablePipDanmaku: ${_this.enablePipDanmaku}, pipDanmakuAutoScale: ${_this.pipDanmakuAutoScale}, pipDanmakuNoEmojiMode: ${_this.pipDanmakuNoEmojiMode}, pipDanmakuUseOriginalColor: ${_this.pipDanmakuUseOriginalColor}, pipDanmakuColor: ${_this.pipDanmakuColor}, pipDanmakuFontSize: ${_this.pipDanmakuFontSize}, pipDanmakuFontWeight: ${_this.pipDanmakuFontWeight}, pipDanmakuSpeed: ${_this.pipDanmakuSpeed}, pipDanmakuOpacity: ${_this.pipDanmakuOpacity}, pipDanmakuArea: ${_this.pipDanmakuArea}, pipDanmakuMaxVisibleCount: ${_this.pipDanmakuMaxVisibleCount}, pipDanmakuEmitInterval: ${_this.pipDanmakuEmitInterval}, pipDanmakuFps: ${_this.pipDanmakuFps}, pipDanmakuAutoFps: ${_this.pipDanmakuAutoFps}, filterDouyuSuspectedAutomatedMessages: ${_this.filterDouyuSuspectedAutomatedMessages}, enableDanmakuSimilarityFilter: ${_this.enableDanmakuSimilarityFilter}, danmakuSimilarityThreshold: ${_this.danmakuSimilarityThreshold}, danmakuSimilarityCacheDuration: ${_this.danmakuSimilarityCacheDuration}, danmakuSimilarityMaxCacheSize: ${_this.danmakuSimilarityMaxCacheSize})';
}


}

/// @nodoc
abstract mixin class $DanmakuSettingsModelCopyWith<$Res>  {
  factory $DanmakuSettingsModelCopyWith(DanmakuSettingsModel value, $Res Function(DanmakuSettingsModel) _then) = _$DanmakuSettingsModelCopyWithImpl;
@useResult
$Res call({
 bool hideDanmaku, bool noEmojiMode, double danmakuTopArea, double danmakuArea, double danmakuBottomArea, double danmakuSpeed, double danmakuFontSize, int danmakuFontWeight, double danmakuFontBorder, double danmakuOpacity, bool enableDanmakuDisplay, bool enableDanmakuStroke, bool danmakuRealtimeMode, bool danmakuShowShadow, double danmakuShadowBlur, double danmakuLetterSpacing, int danmakuFixedDuration, double danmakuOverlapSafeGap, int danmakuMaxPendingCount, int danmakuMaxPendingAge, int danmakuFps, bool danmakuAutoFps, bool enableDanmakuTapInteraction, bool enableDanmakuLongPressInteraction, bool collapseRepeatedDanmaku, int repeatedDanmakuWindowSeconds, int danmakuInteractionMigration, String savedDanmakuTemplate, String danmakuFontFamilyName, bool enablePipDanmaku, bool pipDanmakuAutoScale, bool pipDanmakuNoEmojiMode, bool pipDanmakuUseOriginalColor, int pipDanmakuColor, double pipDanmakuFontSize, int pipDanmakuFontWeight, double pipDanmakuSpeed, double pipDanmakuOpacity, double pipDanmakuArea, int pipDanmakuMaxVisibleCount, double pipDanmakuEmitInterval, int pipDanmakuFps, bool pipDanmakuAutoFps, bool filterDouyuSuspectedAutomatedMessages, bool enableDanmakuSimilarityFilter, int danmakuSimilarityThreshold, int danmakuSimilarityCacheDuration, int danmakuSimilarityMaxCacheSize
});




}
/// @nodoc
class _$DanmakuSettingsModelCopyWithImpl<$Res>
    implements $DanmakuSettingsModelCopyWith<$Res> {
  _$DanmakuSettingsModelCopyWithImpl(this._self, this._then);

  final DanmakuSettingsModel _self;
  final $Res Function(DanmakuSettingsModel) _then;

/// Create a copy of DanmakuSettingsModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? hideDanmaku = null,Object? noEmojiMode = null,Object? danmakuTopArea = null,Object? danmakuArea = null,Object? danmakuBottomArea = null,Object? danmakuSpeed = null,Object? danmakuFontSize = null,Object? danmakuFontWeight = null,Object? danmakuFontBorder = null,Object? danmakuOpacity = null,Object? enableDanmakuDisplay = null,Object? enableDanmakuStroke = null,Object? danmakuRealtimeMode = null,Object? danmakuShowShadow = null,Object? danmakuShadowBlur = null,Object? danmakuLetterSpacing = null,Object? danmakuFixedDuration = null,Object? danmakuOverlapSafeGap = null,Object? danmakuMaxPendingCount = null,Object? danmakuMaxPendingAge = null,Object? danmakuFps = null,Object? danmakuAutoFps = null,Object? enableDanmakuTapInteraction = null,Object? enableDanmakuLongPressInteraction = null,Object? collapseRepeatedDanmaku = null,Object? repeatedDanmakuWindowSeconds = null,Object? danmakuInteractionMigration = null,Object? savedDanmakuTemplate = null,Object? danmakuFontFamilyName = null,Object? enablePipDanmaku = null,Object? pipDanmakuAutoScale = null,Object? pipDanmakuNoEmojiMode = null,Object? pipDanmakuUseOriginalColor = null,Object? pipDanmakuColor = null,Object? pipDanmakuFontSize = null,Object? pipDanmakuFontWeight = null,Object? pipDanmakuSpeed = null,Object? pipDanmakuOpacity = null,Object? pipDanmakuArea = null,Object? pipDanmakuMaxVisibleCount = null,Object? pipDanmakuEmitInterval = null,Object? pipDanmakuFps = null,Object? pipDanmakuAutoFps = null,Object? filterDouyuSuspectedAutomatedMessages = null,Object? enableDanmakuSimilarityFilter = null,Object? danmakuSimilarityThreshold = null,Object? danmakuSimilarityCacheDuration = null,Object? danmakuSimilarityMaxCacheSize = null,}) {
  return _then(DanmakuSettingsModel(
hideDanmaku: null == hideDanmaku ? _self.hideDanmaku : hideDanmaku // ignore: cast_nullable_to_non_nullable
as bool,noEmojiMode: null == noEmojiMode ? _self.noEmojiMode : noEmojiMode // ignore: cast_nullable_to_non_nullable
as bool,danmakuTopArea: null == danmakuTopArea ? _self.danmakuTopArea : danmakuTopArea // ignore: cast_nullable_to_non_nullable
as double,danmakuArea: null == danmakuArea ? _self.danmakuArea : danmakuArea // ignore: cast_nullable_to_non_nullable
as double,danmakuBottomArea: null == danmakuBottomArea ? _self.danmakuBottomArea : danmakuBottomArea // ignore: cast_nullable_to_non_nullable
as double,danmakuSpeed: null == danmakuSpeed ? _self.danmakuSpeed : danmakuSpeed // ignore: cast_nullable_to_non_nullable
as double,danmakuFontSize: null == danmakuFontSize ? _self.danmakuFontSize : danmakuFontSize // ignore: cast_nullable_to_non_nullable
as double,danmakuFontWeight: null == danmakuFontWeight ? _self.danmakuFontWeight : danmakuFontWeight // ignore: cast_nullable_to_non_nullable
as int,danmakuFontBorder: null == danmakuFontBorder ? _self.danmakuFontBorder : danmakuFontBorder // ignore: cast_nullable_to_non_nullable
as double,danmakuOpacity: null == danmakuOpacity ? _self.danmakuOpacity : danmakuOpacity // ignore: cast_nullable_to_non_nullable
as double,enableDanmakuDisplay: null == enableDanmakuDisplay ? _self.enableDanmakuDisplay : enableDanmakuDisplay // ignore: cast_nullable_to_non_nullable
as bool,enableDanmakuStroke: null == enableDanmakuStroke ? _self.enableDanmakuStroke : enableDanmakuStroke // ignore: cast_nullable_to_non_nullable
as bool,danmakuRealtimeMode: null == danmakuRealtimeMode ? _self.danmakuRealtimeMode : danmakuRealtimeMode // ignore: cast_nullable_to_non_nullable
as bool,danmakuShowShadow: null == danmakuShowShadow ? _self.danmakuShowShadow : danmakuShowShadow // ignore: cast_nullable_to_non_nullable
as bool,danmakuShadowBlur: null == danmakuShadowBlur ? _self.danmakuShadowBlur : danmakuShadowBlur // ignore: cast_nullable_to_non_nullable
as double,danmakuLetterSpacing: null == danmakuLetterSpacing ? _self.danmakuLetterSpacing : danmakuLetterSpacing // ignore: cast_nullable_to_non_nullable
as double,danmakuFixedDuration: null == danmakuFixedDuration ? _self.danmakuFixedDuration : danmakuFixedDuration // ignore: cast_nullable_to_non_nullable
as int,danmakuOverlapSafeGap: null == danmakuOverlapSafeGap ? _self.danmakuOverlapSafeGap : danmakuOverlapSafeGap // ignore: cast_nullable_to_non_nullable
as double,danmakuMaxPendingCount: null == danmakuMaxPendingCount ? _self.danmakuMaxPendingCount : danmakuMaxPendingCount // ignore: cast_nullable_to_non_nullable
as int,danmakuMaxPendingAge: null == danmakuMaxPendingAge ? _self.danmakuMaxPendingAge : danmakuMaxPendingAge // ignore: cast_nullable_to_non_nullable
as int,danmakuFps: null == danmakuFps ? _self.danmakuFps : danmakuFps // ignore: cast_nullable_to_non_nullable
as int,danmakuAutoFps: null == danmakuAutoFps ? _self.danmakuAutoFps : danmakuAutoFps // ignore: cast_nullable_to_non_nullable
as bool,enableDanmakuTapInteraction: null == enableDanmakuTapInteraction ? _self.enableDanmakuTapInteraction : enableDanmakuTapInteraction // ignore: cast_nullable_to_non_nullable
as bool,enableDanmakuLongPressInteraction: null == enableDanmakuLongPressInteraction ? _self.enableDanmakuLongPressInteraction : enableDanmakuLongPressInteraction // ignore: cast_nullable_to_non_nullable
as bool,collapseRepeatedDanmaku: null == collapseRepeatedDanmaku ? _self.collapseRepeatedDanmaku : collapseRepeatedDanmaku // ignore: cast_nullable_to_non_nullable
as bool,repeatedDanmakuWindowSeconds: null == repeatedDanmakuWindowSeconds ? _self.repeatedDanmakuWindowSeconds : repeatedDanmakuWindowSeconds // ignore: cast_nullable_to_non_nullable
as int,danmakuInteractionMigration: null == danmakuInteractionMigration ? _self.danmakuInteractionMigration : danmakuInteractionMigration // ignore: cast_nullable_to_non_nullable
as int,savedDanmakuTemplate: null == savedDanmakuTemplate ? _self.savedDanmakuTemplate : savedDanmakuTemplate // ignore: cast_nullable_to_non_nullable
as String,danmakuFontFamilyName: null == danmakuFontFamilyName ? _self.danmakuFontFamilyName : danmakuFontFamilyName // ignore: cast_nullable_to_non_nullable
as String,enablePipDanmaku: null == enablePipDanmaku ? _self.enablePipDanmaku : enablePipDanmaku // ignore: cast_nullable_to_non_nullable
as bool,pipDanmakuAutoScale: null == pipDanmakuAutoScale ? _self.pipDanmakuAutoScale : pipDanmakuAutoScale // ignore: cast_nullable_to_non_nullable
as bool,pipDanmakuNoEmojiMode: null == pipDanmakuNoEmojiMode ? _self.pipDanmakuNoEmojiMode : pipDanmakuNoEmojiMode // ignore: cast_nullable_to_non_nullable
as bool,pipDanmakuUseOriginalColor: null == pipDanmakuUseOriginalColor ? _self.pipDanmakuUseOriginalColor : pipDanmakuUseOriginalColor // ignore: cast_nullable_to_non_nullable
as bool,pipDanmakuColor: null == pipDanmakuColor ? _self.pipDanmakuColor : pipDanmakuColor // ignore: cast_nullable_to_non_nullable
as int,pipDanmakuFontSize: null == pipDanmakuFontSize ? _self.pipDanmakuFontSize : pipDanmakuFontSize // ignore: cast_nullable_to_non_nullable
as double,pipDanmakuFontWeight: null == pipDanmakuFontWeight ? _self.pipDanmakuFontWeight : pipDanmakuFontWeight // ignore: cast_nullable_to_non_nullable
as int,pipDanmakuSpeed: null == pipDanmakuSpeed ? _self.pipDanmakuSpeed : pipDanmakuSpeed // ignore: cast_nullable_to_non_nullable
as double,pipDanmakuOpacity: null == pipDanmakuOpacity ? _self.pipDanmakuOpacity : pipDanmakuOpacity // ignore: cast_nullable_to_non_nullable
as double,pipDanmakuArea: null == pipDanmakuArea ? _self.pipDanmakuArea : pipDanmakuArea // ignore: cast_nullable_to_non_nullable
as double,pipDanmakuMaxVisibleCount: null == pipDanmakuMaxVisibleCount ? _self.pipDanmakuMaxVisibleCount : pipDanmakuMaxVisibleCount // ignore: cast_nullable_to_non_nullable
as int,pipDanmakuEmitInterval: null == pipDanmakuEmitInterval ? _self.pipDanmakuEmitInterval : pipDanmakuEmitInterval // ignore: cast_nullable_to_non_nullable
as double,pipDanmakuFps: null == pipDanmakuFps ? _self.pipDanmakuFps : pipDanmakuFps // ignore: cast_nullable_to_non_nullable
as int,pipDanmakuAutoFps: null == pipDanmakuAutoFps ? _self.pipDanmakuAutoFps : pipDanmakuAutoFps // ignore: cast_nullable_to_non_nullable
as bool,filterDouyuSuspectedAutomatedMessages: null == filterDouyuSuspectedAutomatedMessages ? _self.filterDouyuSuspectedAutomatedMessages : filterDouyuSuspectedAutomatedMessages // ignore: cast_nullable_to_non_nullable
as bool,enableDanmakuSimilarityFilter: null == enableDanmakuSimilarityFilter ? _self.enableDanmakuSimilarityFilter : enableDanmakuSimilarityFilter // ignore: cast_nullable_to_non_nullable
as bool,danmakuSimilarityThreshold: null == danmakuSimilarityThreshold ? _self.danmakuSimilarityThreshold : danmakuSimilarityThreshold // ignore: cast_nullable_to_non_nullable
as int,danmakuSimilarityCacheDuration: null == danmakuSimilarityCacheDuration ? _self.danmakuSimilarityCacheDuration : danmakuSimilarityCacheDuration // ignore: cast_nullable_to_non_nullable
as int,danmakuSimilarityMaxCacheSize: null == danmakuSimilarityMaxCacheSize ? _self.danmakuSimilarityMaxCacheSize : danmakuSimilarityMaxCacheSize // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [DanmakuSettingsModel].
extension DanmakuSettingsModelPatterns on DanmakuSettingsModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DanmakuSettingsModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DanmakuSettingsModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DanmakuSettingsModel value)  $default,){
final _that = this;
switch (_that) {
case _DanmakuSettingsModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DanmakuSettingsModel value)?  $default,){
final _that = this;
switch (_that) {
case _DanmakuSettingsModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool hideDanmaku,  bool noEmojiMode,  double danmakuTopArea,  double danmakuArea,  double danmakuBottomArea,  double danmakuSpeed,  double danmakuFontSize,  int danmakuFontWeight,  double danmakuFontBorder,  double danmakuOpacity,  bool enableDanmakuDisplay,  bool enableDanmakuStroke,  bool danmakuRealtimeMode,  bool danmakuShowShadow,  double danmakuShadowBlur,  double danmakuLetterSpacing,  int danmakuFixedDuration,  double danmakuOverlapSafeGap,  int danmakuMaxPendingCount,  int danmakuMaxPendingAge,  int danmakuFps,  bool danmakuAutoFps,  bool enableDanmakuTapInteraction,  bool enableDanmakuLongPressInteraction,  bool collapseRepeatedDanmaku,  int repeatedDanmakuWindowSeconds,  int danmakuInteractionMigration,  String savedDanmakuTemplate,  String danmakuFontFamilyName,  bool enablePipDanmaku,  bool pipDanmakuAutoScale,  bool pipDanmakuNoEmojiMode,  bool pipDanmakuUseOriginalColor,  int pipDanmakuColor,  double pipDanmakuFontSize,  int pipDanmakuFontWeight,  double pipDanmakuSpeed,  double pipDanmakuOpacity,  double pipDanmakuArea,  int pipDanmakuMaxVisibleCount,  double pipDanmakuEmitInterval,  int pipDanmakuFps,  bool pipDanmakuAutoFps,  bool filterDouyuSuspectedAutomatedMessages,  bool enableDanmakuSimilarityFilter,  int danmakuSimilarityThreshold,  int danmakuSimilarityCacheDuration,  int danmakuSimilarityMaxCacheSize)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DanmakuSettingsModel() when $default != null:
return $default(_that.hideDanmaku,_that.noEmojiMode,_that.danmakuTopArea,_that.danmakuArea,_that.danmakuBottomArea,_that.danmakuSpeed,_that.danmakuFontSize,_that.danmakuFontWeight,_that.danmakuFontBorder,_that.danmakuOpacity,_that.enableDanmakuDisplay,_that.enableDanmakuStroke,_that.danmakuRealtimeMode,_that.danmakuShowShadow,_that.danmakuShadowBlur,_that.danmakuLetterSpacing,_that.danmakuFixedDuration,_that.danmakuOverlapSafeGap,_that.danmakuMaxPendingCount,_that.danmakuMaxPendingAge,_that.danmakuFps,_that.danmakuAutoFps,_that.enableDanmakuTapInteraction,_that.enableDanmakuLongPressInteraction,_that.collapseRepeatedDanmaku,_that.repeatedDanmakuWindowSeconds,_that.danmakuInteractionMigration,_that.savedDanmakuTemplate,_that.danmakuFontFamilyName,_that.enablePipDanmaku,_that.pipDanmakuAutoScale,_that.pipDanmakuNoEmojiMode,_that.pipDanmakuUseOriginalColor,_that.pipDanmakuColor,_that.pipDanmakuFontSize,_that.pipDanmakuFontWeight,_that.pipDanmakuSpeed,_that.pipDanmakuOpacity,_that.pipDanmakuArea,_that.pipDanmakuMaxVisibleCount,_that.pipDanmakuEmitInterval,_that.pipDanmakuFps,_that.pipDanmakuAutoFps,_that.filterDouyuSuspectedAutomatedMessages,_that.enableDanmakuSimilarityFilter,_that.danmakuSimilarityThreshold,_that.danmakuSimilarityCacheDuration,_that.danmakuSimilarityMaxCacheSize);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool hideDanmaku,  bool noEmojiMode,  double danmakuTopArea,  double danmakuArea,  double danmakuBottomArea,  double danmakuSpeed,  double danmakuFontSize,  int danmakuFontWeight,  double danmakuFontBorder,  double danmakuOpacity,  bool enableDanmakuDisplay,  bool enableDanmakuStroke,  bool danmakuRealtimeMode,  bool danmakuShowShadow,  double danmakuShadowBlur,  double danmakuLetterSpacing,  int danmakuFixedDuration,  double danmakuOverlapSafeGap,  int danmakuMaxPendingCount,  int danmakuMaxPendingAge,  int danmakuFps,  bool danmakuAutoFps,  bool enableDanmakuTapInteraction,  bool enableDanmakuLongPressInteraction,  bool collapseRepeatedDanmaku,  int repeatedDanmakuWindowSeconds,  int danmakuInteractionMigration,  String savedDanmakuTemplate,  String danmakuFontFamilyName,  bool enablePipDanmaku,  bool pipDanmakuAutoScale,  bool pipDanmakuNoEmojiMode,  bool pipDanmakuUseOriginalColor,  int pipDanmakuColor,  double pipDanmakuFontSize,  int pipDanmakuFontWeight,  double pipDanmakuSpeed,  double pipDanmakuOpacity,  double pipDanmakuArea,  int pipDanmakuMaxVisibleCount,  double pipDanmakuEmitInterval,  int pipDanmakuFps,  bool pipDanmakuAutoFps,  bool filterDouyuSuspectedAutomatedMessages,  bool enableDanmakuSimilarityFilter,  int danmakuSimilarityThreshold,  int danmakuSimilarityCacheDuration,  int danmakuSimilarityMaxCacheSize)  $default,) {final _that = this;
switch (_that) {
case _DanmakuSettingsModel():
return $default(_that.hideDanmaku,_that.noEmojiMode,_that.danmakuTopArea,_that.danmakuArea,_that.danmakuBottomArea,_that.danmakuSpeed,_that.danmakuFontSize,_that.danmakuFontWeight,_that.danmakuFontBorder,_that.danmakuOpacity,_that.enableDanmakuDisplay,_that.enableDanmakuStroke,_that.danmakuRealtimeMode,_that.danmakuShowShadow,_that.danmakuShadowBlur,_that.danmakuLetterSpacing,_that.danmakuFixedDuration,_that.danmakuOverlapSafeGap,_that.danmakuMaxPendingCount,_that.danmakuMaxPendingAge,_that.danmakuFps,_that.danmakuAutoFps,_that.enableDanmakuTapInteraction,_that.enableDanmakuLongPressInteraction,_that.collapseRepeatedDanmaku,_that.repeatedDanmakuWindowSeconds,_that.danmakuInteractionMigration,_that.savedDanmakuTemplate,_that.danmakuFontFamilyName,_that.enablePipDanmaku,_that.pipDanmakuAutoScale,_that.pipDanmakuNoEmojiMode,_that.pipDanmakuUseOriginalColor,_that.pipDanmakuColor,_that.pipDanmakuFontSize,_that.pipDanmakuFontWeight,_that.pipDanmakuSpeed,_that.pipDanmakuOpacity,_that.pipDanmakuArea,_that.pipDanmakuMaxVisibleCount,_that.pipDanmakuEmitInterval,_that.pipDanmakuFps,_that.pipDanmakuAutoFps,_that.filterDouyuSuspectedAutomatedMessages,_that.enableDanmakuSimilarityFilter,_that.danmakuSimilarityThreshold,_that.danmakuSimilarityCacheDuration,_that.danmakuSimilarityMaxCacheSize);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool hideDanmaku,  bool noEmojiMode,  double danmakuTopArea,  double danmakuArea,  double danmakuBottomArea,  double danmakuSpeed,  double danmakuFontSize,  int danmakuFontWeight,  double danmakuFontBorder,  double danmakuOpacity,  bool enableDanmakuDisplay,  bool enableDanmakuStroke,  bool danmakuRealtimeMode,  bool danmakuShowShadow,  double danmakuShadowBlur,  double danmakuLetterSpacing,  int danmakuFixedDuration,  double danmakuOverlapSafeGap,  int danmakuMaxPendingCount,  int danmakuMaxPendingAge,  int danmakuFps,  bool danmakuAutoFps,  bool enableDanmakuTapInteraction,  bool enableDanmakuLongPressInteraction,  bool collapseRepeatedDanmaku,  int repeatedDanmakuWindowSeconds,  int danmakuInteractionMigration,  String savedDanmakuTemplate,  String danmakuFontFamilyName,  bool enablePipDanmaku,  bool pipDanmakuAutoScale,  bool pipDanmakuNoEmojiMode,  bool pipDanmakuUseOriginalColor,  int pipDanmakuColor,  double pipDanmakuFontSize,  int pipDanmakuFontWeight,  double pipDanmakuSpeed,  double pipDanmakuOpacity,  double pipDanmakuArea,  int pipDanmakuMaxVisibleCount,  double pipDanmakuEmitInterval,  int pipDanmakuFps,  bool pipDanmakuAutoFps,  bool filterDouyuSuspectedAutomatedMessages,  bool enableDanmakuSimilarityFilter,  int danmakuSimilarityThreshold,  int danmakuSimilarityCacheDuration,  int danmakuSimilarityMaxCacheSize)?  $default,) {final _that = this;
switch (_that) {
case _DanmakuSettingsModel() when $default != null:
return $default(_that.hideDanmaku,_that.noEmojiMode,_that.danmakuTopArea,_that.danmakuArea,_that.danmakuBottomArea,_that.danmakuSpeed,_that.danmakuFontSize,_that.danmakuFontWeight,_that.danmakuFontBorder,_that.danmakuOpacity,_that.enableDanmakuDisplay,_that.enableDanmakuStroke,_that.danmakuRealtimeMode,_that.danmakuShowShadow,_that.danmakuShadowBlur,_that.danmakuLetterSpacing,_that.danmakuFixedDuration,_that.danmakuOverlapSafeGap,_that.danmakuMaxPendingCount,_that.danmakuMaxPendingAge,_that.danmakuFps,_that.danmakuAutoFps,_that.enableDanmakuTapInteraction,_that.enableDanmakuLongPressInteraction,_that.collapseRepeatedDanmaku,_that.repeatedDanmakuWindowSeconds,_that.danmakuInteractionMigration,_that.savedDanmakuTemplate,_that.danmakuFontFamilyName,_that.enablePipDanmaku,_that.pipDanmakuAutoScale,_that.pipDanmakuNoEmojiMode,_that.pipDanmakuUseOriginalColor,_that.pipDanmakuColor,_that.pipDanmakuFontSize,_that.pipDanmakuFontWeight,_that.pipDanmakuSpeed,_that.pipDanmakuOpacity,_that.pipDanmakuArea,_that.pipDanmakuMaxVisibleCount,_that.pipDanmakuEmitInterval,_that.pipDanmakuFps,_that.pipDanmakuAutoFps,_that.filterDouyuSuspectedAutomatedMessages,_that.enableDanmakuSimilarityFilter,_that.danmakuSimilarityThreshold,_that.danmakuSimilarityCacheDuration,_that.danmakuSimilarityMaxCacheSize);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DanmakuSettingsModel implements DanmakuSettingsModel {
  const _DanmakuSettingsModel({this.hideDanmaku = false, this.noEmojiMode = false, this.danmakuTopArea = 0.0, this.danmakuArea = 1.0, this.danmakuBottomArea = 0.5, this.danmakuSpeed = 8.0, this.danmakuFontSize = 16.0, this.danmakuFontWeight = 500, this.danmakuFontBorder = 4.0, this.danmakuOpacity = 1.0, this.enableDanmakuDisplay = true, this.enableDanmakuStroke = true, this.danmakuRealtimeMode = false, this.danmakuShowShadow = false, this.danmakuShadowBlur = 2.0, this.danmakuLetterSpacing = 0.0, this.danmakuFixedDuration = 4, this.danmakuOverlapSafeGap = 40.0, this.danmakuMaxPendingCount = 120, this.danmakuMaxPendingAge = 5, this.danmakuFps = 60, this.danmakuAutoFps = false, this.enableDanmakuTapInteraction = true, this.enableDanmakuLongPressInteraction = true, this.collapseRepeatedDanmaku = false, this.repeatedDanmakuWindowSeconds = 5, this.danmakuInteractionMigration = 0, this.savedDanmakuTemplate = '', this.danmakuFontFamilyName = 'Default', this.enablePipDanmaku = true, this.pipDanmakuAutoScale = true, this.pipDanmakuNoEmojiMode = false, this.pipDanmakuUseOriginalColor = true, this.pipDanmakuColor = 0xFFFFFFFF, this.pipDanmakuFontSize = 12.0, this.pipDanmakuFontWeight = 500, this.pipDanmakuSpeed = 90.0, this.pipDanmakuOpacity = 0.9, this.pipDanmakuArea = 0.5, this.pipDanmakuMaxVisibleCount = 6, this.pipDanmakuEmitInterval = 0.35, this.pipDanmakuFps = 30, this.pipDanmakuAutoFps = true, this.filterDouyuSuspectedAutomatedMessages = true, this.enableDanmakuSimilarityFilter = false, this.danmakuSimilarityThreshold = 85, this.danmakuSimilarityCacheDuration = 3, this.danmakuSimilarityMaxCacheSize = 100});
  factory _DanmakuSettingsModel.fromJson(Map<String, dynamic> json) => _$DanmakuSettingsModelFromJson(json);

@override@JsonKey() final  bool hideDanmaku;
@override@JsonKey() final  bool noEmojiMode;
@override@JsonKey() final  double danmakuTopArea;
@override@JsonKey() final  double danmakuArea;
@override@JsonKey() final  double danmakuBottomArea;
@override@JsonKey() final  double danmakuSpeed;
@override@JsonKey() final  double danmakuFontSize;
@override@JsonKey() final  int danmakuFontWeight;
@override@JsonKey() final  double danmakuFontBorder;
@override@JsonKey() final  double danmakuOpacity;
@override@JsonKey() final  bool enableDanmakuDisplay;
@override@JsonKey() final  bool enableDanmakuStroke;
/// Burst dispatch: bypass `emitInterval` pacing and flush the waiting
/// queue every logic frame (`BarrageConfig.realtimeMode`). On = lowest
/// latency during floods, denser screen; off = paced, calmer.
@override@JsonKey() final  bool danmakuRealtimeMode;
/// Paragraph shadow under the text (`BarrageConfig.showShadow`).
@override@JsonKey() final  bool danmakuShowShadow;
/// Shadow blur radius in logical pixels (`BarrageConfig.shadowBlur`).
@override@JsonKey() final  double danmakuShadowBlur;
/// Extra glyph spacing in logical pixels (`BarrageConfig.letterSpacing`).
@override@JsonKey() final  double danmakuLetterSpacing;
/// Dwell time of pinned (top/bottom) danmaku, in seconds
/// (`BarrageConfig.fixedDuration`).
@override@JsonKey() final  int danmakuFixedDuration;
/// Minimum clearance between consecutive danmaku in one lane, in logical
/// pixels (`BarrageConfig.overlapSafeGap`).
@override@JsonKey() final  double danmakuOverlapSafeGap;
/// Queue cap before the oldest waiting message is dropped
/// (`BarrageConfig.maxPendingCount`).
@override@JsonKey() final  int danmakuMaxPendingCount;
/// Age in seconds after which a waiting message is dropped instead of
/// shown (`BarrageConfig.maxPendingAge`).
@override@JsonKey() final  int danmakuMaxPendingAge;
@override@JsonKey() final  int danmakuFps;
/// Auto frame rate: follow the display's refresh rate instead of [danmakuFps].
///
/// The stored default is on (see DanmakuSettingsController.build) — a panel
/// the engine can keep up with is the whole budget it has, and a fixed 60 on
/// a 120Hz panel is a loss of smoothness for nothing. This factory default
/// stays off for documents that predate the field, so an imported backup or
/// a peer keeps the choice it was saved with.
@override@JsonKey() final  bool danmakuAutoFps;
@override@JsonKey() final  bool enableDanmakuTapInteraction;
@override@JsonKey() final  bool enableDanmakuLongPressInteraction;
@override@JsonKey() final  bool collapseRepeatedDanmaku;
@override@JsonKey() final  int repeatedDanmakuWindowSeconds;
@override@JsonKey() final  int danmakuInteractionMigration;
@override@JsonKey() final  String savedDanmakuTemplate;
@override@JsonKey() final  String danmakuFontFamilyName;
@override@JsonKey() final  bool enablePipDanmaku;
@override@JsonKey() final  bool pipDanmakuAutoScale;
@override@JsonKey() final  bool pipDanmakuNoEmojiMode;
@override@JsonKey() final  bool pipDanmakuUseOriginalColor;
@override@JsonKey() final  int pipDanmakuColor;
@override@JsonKey() final  double pipDanmakuFontSize;
@override@JsonKey() final  int pipDanmakuFontWeight;
@override@JsonKey() final  double pipDanmakuSpeed;
@override@JsonKey() final  double pipDanmakuOpacity;
@override@JsonKey() final  double pipDanmakuArea;
@override@JsonKey() final  int pipDanmakuMaxVisibleCount;
@override@JsonKey() final  double pipDanmakuEmitInterval;
@override@JsonKey() final  int pipDanmakuFps;
@override@JsonKey() final  bool pipDanmakuAutoFps;
@override@JsonKey() final  bool filterDouyuSuspectedAutomatedMessages;
@override@JsonKey() final  bool enableDanmakuSimilarityFilter;
@override@JsonKey() final  int danmakuSimilarityThreshold;
@override@JsonKey() final  int danmakuSimilarityCacheDuration;
@override@JsonKey() final  int danmakuSimilarityMaxCacheSize;

/// Create a copy of DanmakuSettingsModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DanmakuSettingsModelCopyWith<_DanmakuSettingsModel> get copyWith => __$DanmakuSettingsModelCopyWithImpl<_DanmakuSettingsModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DanmakuSettingsModelToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DanmakuSettingsModel&&(identical(other.hideDanmaku, hideDanmaku) || other.hideDanmaku == hideDanmaku)&&(identical(other.noEmojiMode, noEmojiMode) || other.noEmojiMode == noEmojiMode)&&(identical(other.danmakuTopArea, danmakuTopArea) || other.danmakuTopArea == danmakuTopArea)&&(identical(other.danmakuArea, danmakuArea) || other.danmakuArea == danmakuArea)&&(identical(other.danmakuBottomArea, danmakuBottomArea) || other.danmakuBottomArea == danmakuBottomArea)&&(identical(other.danmakuSpeed, danmakuSpeed) || other.danmakuSpeed == danmakuSpeed)&&(identical(other.danmakuFontSize, danmakuFontSize) || other.danmakuFontSize == danmakuFontSize)&&(identical(other.danmakuFontWeight, danmakuFontWeight) || other.danmakuFontWeight == danmakuFontWeight)&&(identical(other.danmakuFontBorder, danmakuFontBorder) || other.danmakuFontBorder == danmakuFontBorder)&&(identical(other.danmakuOpacity, danmakuOpacity) || other.danmakuOpacity == danmakuOpacity)&&(identical(other.enableDanmakuDisplay, enableDanmakuDisplay) || other.enableDanmakuDisplay == enableDanmakuDisplay)&&(identical(other.enableDanmakuStroke, enableDanmakuStroke) || other.enableDanmakuStroke == enableDanmakuStroke)&&(identical(other.danmakuRealtimeMode, danmakuRealtimeMode) || other.danmakuRealtimeMode == danmakuRealtimeMode)&&(identical(other.danmakuShowShadow, danmakuShowShadow) || other.danmakuShowShadow == danmakuShowShadow)&&(identical(other.danmakuShadowBlur, danmakuShadowBlur) || other.danmakuShadowBlur == danmakuShadowBlur)&&(identical(other.danmakuLetterSpacing, danmakuLetterSpacing) || other.danmakuLetterSpacing == danmakuLetterSpacing)&&(identical(other.danmakuFixedDuration, danmakuFixedDuration) || other.danmakuFixedDuration == danmakuFixedDuration)&&(identical(other.danmakuOverlapSafeGap, danmakuOverlapSafeGap) || other.danmakuOverlapSafeGap == danmakuOverlapSafeGap)&&(identical(other.danmakuMaxPendingCount, danmakuMaxPendingCount) || other.danmakuMaxPendingCount == danmakuMaxPendingCount)&&(identical(other.danmakuMaxPendingAge, danmakuMaxPendingAge) || other.danmakuMaxPendingAge == danmakuMaxPendingAge)&&(identical(other.danmakuFps, danmakuFps) || other.danmakuFps == danmakuFps)&&(identical(other.danmakuAutoFps, danmakuAutoFps) || other.danmakuAutoFps == danmakuAutoFps)&&(identical(other.enableDanmakuTapInteraction, enableDanmakuTapInteraction) || other.enableDanmakuTapInteraction == enableDanmakuTapInteraction)&&(identical(other.enableDanmakuLongPressInteraction, enableDanmakuLongPressInteraction) || other.enableDanmakuLongPressInteraction == enableDanmakuLongPressInteraction)&&(identical(other.collapseRepeatedDanmaku, collapseRepeatedDanmaku) || other.collapseRepeatedDanmaku == collapseRepeatedDanmaku)&&(identical(other.repeatedDanmakuWindowSeconds, repeatedDanmakuWindowSeconds) || other.repeatedDanmakuWindowSeconds == repeatedDanmakuWindowSeconds)&&(identical(other.danmakuInteractionMigration, danmakuInteractionMigration) || other.danmakuInteractionMigration == danmakuInteractionMigration)&&(identical(other.savedDanmakuTemplate, savedDanmakuTemplate) || other.savedDanmakuTemplate == savedDanmakuTemplate)&&(identical(other.danmakuFontFamilyName, danmakuFontFamilyName) || other.danmakuFontFamilyName == danmakuFontFamilyName)&&(identical(other.enablePipDanmaku, enablePipDanmaku) || other.enablePipDanmaku == enablePipDanmaku)&&(identical(other.pipDanmakuAutoScale, pipDanmakuAutoScale) || other.pipDanmakuAutoScale == pipDanmakuAutoScale)&&(identical(other.pipDanmakuNoEmojiMode, pipDanmakuNoEmojiMode) || other.pipDanmakuNoEmojiMode == pipDanmakuNoEmojiMode)&&(identical(other.pipDanmakuUseOriginalColor, pipDanmakuUseOriginalColor) || other.pipDanmakuUseOriginalColor == pipDanmakuUseOriginalColor)&&(identical(other.pipDanmakuColor, pipDanmakuColor) || other.pipDanmakuColor == pipDanmakuColor)&&(identical(other.pipDanmakuFontSize, pipDanmakuFontSize) || other.pipDanmakuFontSize == pipDanmakuFontSize)&&(identical(other.pipDanmakuFontWeight, pipDanmakuFontWeight) || other.pipDanmakuFontWeight == pipDanmakuFontWeight)&&(identical(other.pipDanmakuSpeed, pipDanmakuSpeed) || other.pipDanmakuSpeed == pipDanmakuSpeed)&&(identical(other.pipDanmakuOpacity, pipDanmakuOpacity) || other.pipDanmakuOpacity == pipDanmakuOpacity)&&(identical(other.pipDanmakuArea, pipDanmakuArea) || other.pipDanmakuArea == pipDanmakuArea)&&(identical(other.pipDanmakuMaxVisibleCount, pipDanmakuMaxVisibleCount) || other.pipDanmakuMaxVisibleCount == pipDanmakuMaxVisibleCount)&&(identical(other.pipDanmakuEmitInterval, pipDanmakuEmitInterval) || other.pipDanmakuEmitInterval == pipDanmakuEmitInterval)&&(identical(other.pipDanmakuFps, pipDanmakuFps) || other.pipDanmakuFps == pipDanmakuFps)&&(identical(other.pipDanmakuAutoFps, pipDanmakuAutoFps) || other.pipDanmakuAutoFps == pipDanmakuAutoFps)&&(identical(other.filterDouyuSuspectedAutomatedMessages, filterDouyuSuspectedAutomatedMessages) || other.filterDouyuSuspectedAutomatedMessages == filterDouyuSuspectedAutomatedMessages)&&(identical(other.enableDanmakuSimilarityFilter, enableDanmakuSimilarityFilter) || other.enableDanmakuSimilarityFilter == enableDanmakuSimilarityFilter)&&(identical(other.danmakuSimilarityThreshold, danmakuSimilarityThreshold) || other.danmakuSimilarityThreshold == danmakuSimilarityThreshold)&&(identical(other.danmakuSimilarityCacheDuration, danmakuSimilarityCacheDuration) || other.danmakuSimilarityCacheDuration == danmakuSimilarityCacheDuration)&&(identical(other.danmakuSimilarityMaxCacheSize, danmakuSimilarityMaxCacheSize) || other.danmakuSimilarityMaxCacheSize == danmakuSimilarityMaxCacheSize));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hashAll([runtimeType,hideDanmaku,noEmojiMode,danmakuTopArea,danmakuArea,danmakuBottomArea,danmakuSpeed,danmakuFontSize,danmakuFontWeight,danmakuFontBorder,danmakuOpacity,enableDanmakuDisplay,enableDanmakuStroke,danmakuRealtimeMode,danmakuShowShadow,danmakuShadowBlur,danmakuLetterSpacing,danmakuFixedDuration,danmakuOverlapSafeGap,danmakuMaxPendingCount,danmakuMaxPendingAge,danmakuFps,danmakuAutoFps,enableDanmakuTapInteraction,enableDanmakuLongPressInteraction,collapseRepeatedDanmaku,repeatedDanmakuWindowSeconds,danmakuInteractionMigration,savedDanmakuTemplate,danmakuFontFamilyName,enablePipDanmaku,pipDanmakuAutoScale,pipDanmakuNoEmojiMode,pipDanmakuUseOriginalColor,pipDanmakuColor,pipDanmakuFontSize,pipDanmakuFontWeight,pipDanmakuSpeed,pipDanmakuOpacity,pipDanmakuArea,pipDanmakuMaxVisibleCount,pipDanmakuEmitInterval,pipDanmakuFps,pipDanmakuAutoFps,filterDouyuSuspectedAutomatedMessages,enableDanmakuSimilarityFilter,danmakuSimilarityThreshold,danmakuSimilarityCacheDuration,danmakuSimilarityMaxCacheSize]);
}

@override
String toString() {
    return 'DanmakuSettingsModel(hideDanmaku: $hideDanmaku, noEmojiMode: $noEmojiMode, danmakuTopArea: $danmakuTopArea, danmakuArea: $danmakuArea, danmakuBottomArea: $danmakuBottomArea, danmakuSpeed: $danmakuSpeed, danmakuFontSize: $danmakuFontSize, danmakuFontWeight: $danmakuFontWeight, danmakuFontBorder: $danmakuFontBorder, danmakuOpacity: $danmakuOpacity, enableDanmakuDisplay: $enableDanmakuDisplay, enableDanmakuStroke: $enableDanmakuStroke, danmakuRealtimeMode: $danmakuRealtimeMode, danmakuShowShadow: $danmakuShowShadow, danmakuShadowBlur: $danmakuShadowBlur, danmakuLetterSpacing: $danmakuLetterSpacing, danmakuFixedDuration: $danmakuFixedDuration, danmakuOverlapSafeGap: $danmakuOverlapSafeGap, danmakuMaxPendingCount: $danmakuMaxPendingCount, danmakuMaxPendingAge: $danmakuMaxPendingAge, danmakuFps: $danmakuFps, danmakuAutoFps: $danmakuAutoFps, enableDanmakuTapInteraction: $enableDanmakuTapInteraction, enableDanmakuLongPressInteraction: $enableDanmakuLongPressInteraction, collapseRepeatedDanmaku: $collapseRepeatedDanmaku, repeatedDanmakuWindowSeconds: $repeatedDanmakuWindowSeconds, danmakuInteractionMigration: $danmakuInteractionMigration, savedDanmakuTemplate: $savedDanmakuTemplate, danmakuFontFamilyName: $danmakuFontFamilyName, enablePipDanmaku: $enablePipDanmaku, pipDanmakuAutoScale: $pipDanmakuAutoScale, pipDanmakuNoEmojiMode: $pipDanmakuNoEmojiMode, pipDanmakuUseOriginalColor: $pipDanmakuUseOriginalColor, pipDanmakuColor: $pipDanmakuColor, pipDanmakuFontSize: $pipDanmakuFontSize, pipDanmakuFontWeight: $pipDanmakuFontWeight, pipDanmakuSpeed: $pipDanmakuSpeed, pipDanmakuOpacity: $pipDanmakuOpacity, pipDanmakuArea: $pipDanmakuArea, pipDanmakuMaxVisibleCount: $pipDanmakuMaxVisibleCount, pipDanmakuEmitInterval: $pipDanmakuEmitInterval, pipDanmakuFps: $pipDanmakuFps, pipDanmakuAutoFps: $pipDanmakuAutoFps, filterDouyuSuspectedAutomatedMessages: $filterDouyuSuspectedAutomatedMessages, enableDanmakuSimilarityFilter: $enableDanmakuSimilarityFilter, danmakuSimilarityThreshold: $danmakuSimilarityThreshold, danmakuSimilarityCacheDuration: $danmakuSimilarityCacheDuration, danmakuSimilarityMaxCacheSize: $danmakuSimilarityMaxCacheSize)';
}


}

/// @nodoc
abstract mixin class _$DanmakuSettingsModelCopyWith<$Res> implements $DanmakuSettingsModelCopyWith<$Res> {
  factory _$DanmakuSettingsModelCopyWith(_DanmakuSettingsModel value, $Res Function(_DanmakuSettingsModel) _then) = __$DanmakuSettingsModelCopyWithImpl;
@override @useResult
$Res call({
 bool hideDanmaku, bool noEmojiMode, double danmakuTopArea, double danmakuArea, double danmakuBottomArea, double danmakuSpeed, double danmakuFontSize, int danmakuFontWeight, double danmakuFontBorder, double danmakuOpacity, bool enableDanmakuDisplay, bool enableDanmakuStroke, bool danmakuRealtimeMode, bool danmakuShowShadow, double danmakuShadowBlur, double danmakuLetterSpacing, int danmakuFixedDuration, double danmakuOverlapSafeGap, int danmakuMaxPendingCount, int danmakuMaxPendingAge, int danmakuFps, bool danmakuAutoFps, bool enableDanmakuTapInteraction, bool enableDanmakuLongPressInteraction, bool collapseRepeatedDanmaku, int repeatedDanmakuWindowSeconds, int danmakuInteractionMigration, String savedDanmakuTemplate, String danmakuFontFamilyName, bool enablePipDanmaku, bool pipDanmakuAutoScale, bool pipDanmakuNoEmojiMode, bool pipDanmakuUseOriginalColor, int pipDanmakuColor, double pipDanmakuFontSize, int pipDanmakuFontWeight, double pipDanmakuSpeed, double pipDanmakuOpacity, double pipDanmakuArea, int pipDanmakuMaxVisibleCount, double pipDanmakuEmitInterval, int pipDanmakuFps, bool pipDanmakuAutoFps, bool filterDouyuSuspectedAutomatedMessages, bool enableDanmakuSimilarityFilter, int danmakuSimilarityThreshold, int danmakuSimilarityCacheDuration, int danmakuSimilarityMaxCacheSize
});




}
/// @nodoc
class __$DanmakuSettingsModelCopyWithImpl<$Res>
    implements _$DanmakuSettingsModelCopyWith<$Res> {
  __$DanmakuSettingsModelCopyWithImpl(this._self, this._then);

  final _DanmakuSettingsModel _self;
  final $Res Function(_DanmakuSettingsModel) _then;

/// Create a copy of DanmakuSettingsModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? hideDanmaku = null,Object? noEmojiMode = null,Object? danmakuTopArea = null,Object? danmakuArea = null,Object? danmakuBottomArea = null,Object? danmakuSpeed = null,Object? danmakuFontSize = null,Object? danmakuFontWeight = null,Object? danmakuFontBorder = null,Object? danmakuOpacity = null,Object? enableDanmakuDisplay = null,Object? enableDanmakuStroke = null,Object? danmakuRealtimeMode = null,Object? danmakuShowShadow = null,Object? danmakuShadowBlur = null,Object? danmakuLetterSpacing = null,Object? danmakuFixedDuration = null,Object? danmakuOverlapSafeGap = null,Object? danmakuMaxPendingCount = null,Object? danmakuMaxPendingAge = null,Object? danmakuFps = null,Object? danmakuAutoFps = null,Object? enableDanmakuTapInteraction = null,Object? enableDanmakuLongPressInteraction = null,Object? collapseRepeatedDanmaku = null,Object? repeatedDanmakuWindowSeconds = null,Object? danmakuInteractionMigration = null,Object? savedDanmakuTemplate = null,Object? danmakuFontFamilyName = null,Object? enablePipDanmaku = null,Object? pipDanmakuAutoScale = null,Object? pipDanmakuNoEmojiMode = null,Object? pipDanmakuUseOriginalColor = null,Object? pipDanmakuColor = null,Object? pipDanmakuFontSize = null,Object? pipDanmakuFontWeight = null,Object? pipDanmakuSpeed = null,Object? pipDanmakuOpacity = null,Object? pipDanmakuArea = null,Object? pipDanmakuMaxVisibleCount = null,Object? pipDanmakuEmitInterval = null,Object? pipDanmakuFps = null,Object? pipDanmakuAutoFps = null,Object? filterDouyuSuspectedAutomatedMessages = null,Object? enableDanmakuSimilarityFilter = null,Object? danmakuSimilarityThreshold = null,Object? danmakuSimilarityCacheDuration = null,Object? danmakuSimilarityMaxCacheSize = null,}) {
  return _then(_DanmakuSettingsModel(
hideDanmaku: null == hideDanmaku ? _self.hideDanmaku : hideDanmaku // ignore: cast_nullable_to_non_nullable
as bool,noEmojiMode: null == noEmojiMode ? _self.noEmojiMode : noEmojiMode // ignore: cast_nullable_to_non_nullable
as bool,danmakuTopArea: null == danmakuTopArea ? _self.danmakuTopArea : danmakuTopArea // ignore: cast_nullable_to_non_nullable
as double,danmakuArea: null == danmakuArea ? _self.danmakuArea : danmakuArea // ignore: cast_nullable_to_non_nullable
as double,danmakuBottomArea: null == danmakuBottomArea ? _self.danmakuBottomArea : danmakuBottomArea // ignore: cast_nullable_to_non_nullable
as double,danmakuSpeed: null == danmakuSpeed ? _self.danmakuSpeed : danmakuSpeed // ignore: cast_nullable_to_non_nullable
as double,danmakuFontSize: null == danmakuFontSize ? _self.danmakuFontSize : danmakuFontSize // ignore: cast_nullable_to_non_nullable
as double,danmakuFontWeight: null == danmakuFontWeight ? _self.danmakuFontWeight : danmakuFontWeight // ignore: cast_nullable_to_non_nullable
as int,danmakuFontBorder: null == danmakuFontBorder ? _self.danmakuFontBorder : danmakuFontBorder // ignore: cast_nullable_to_non_nullable
as double,danmakuOpacity: null == danmakuOpacity ? _self.danmakuOpacity : danmakuOpacity // ignore: cast_nullable_to_non_nullable
as double,enableDanmakuDisplay: null == enableDanmakuDisplay ? _self.enableDanmakuDisplay : enableDanmakuDisplay // ignore: cast_nullable_to_non_nullable
as bool,enableDanmakuStroke: null == enableDanmakuStroke ? _self.enableDanmakuStroke : enableDanmakuStroke // ignore: cast_nullable_to_non_nullable
as bool,danmakuRealtimeMode: null == danmakuRealtimeMode ? _self.danmakuRealtimeMode : danmakuRealtimeMode // ignore: cast_nullable_to_non_nullable
as bool,danmakuShowShadow: null == danmakuShowShadow ? _self.danmakuShowShadow : danmakuShowShadow // ignore: cast_nullable_to_non_nullable
as bool,danmakuShadowBlur: null == danmakuShadowBlur ? _self.danmakuShadowBlur : danmakuShadowBlur // ignore: cast_nullable_to_non_nullable
as double,danmakuLetterSpacing: null == danmakuLetterSpacing ? _self.danmakuLetterSpacing : danmakuLetterSpacing // ignore: cast_nullable_to_non_nullable
as double,danmakuFixedDuration: null == danmakuFixedDuration ? _self.danmakuFixedDuration : danmakuFixedDuration // ignore: cast_nullable_to_non_nullable
as int,danmakuOverlapSafeGap: null == danmakuOverlapSafeGap ? _self.danmakuOverlapSafeGap : danmakuOverlapSafeGap // ignore: cast_nullable_to_non_nullable
as double,danmakuMaxPendingCount: null == danmakuMaxPendingCount ? _self.danmakuMaxPendingCount : danmakuMaxPendingCount // ignore: cast_nullable_to_non_nullable
as int,danmakuMaxPendingAge: null == danmakuMaxPendingAge ? _self.danmakuMaxPendingAge : danmakuMaxPendingAge // ignore: cast_nullable_to_non_nullable
as int,danmakuFps: null == danmakuFps ? _self.danmakuFps : danmakuFps // ignore: cast_nullable_to_non_nullable
as int,danmakuAutoFps: null == danmakuAutoFps ? _self.danmakuAutoFps : danmakuAutoFps // ignore: cast_nullable_to_non_nullable
as bool,enableDanmakuTapInteraction: null == enableDanmakuTapInteraction ? _self.enableDanmakuTapInteraction : enableDanmakuTapInteraction // ignore: cast_nullable_to_non_nullable
as bool,enableDanmakuLongPressInteraction: null == enableDanmakuLongPressInteraction ? _self.enableDanmakuLongPressInteraction : enableDanmakuLongPressInteraction // ignore: cast_nullable_to_non_nullable
as bool,collapseRepeatedDanmaku: null == collapseRepeatedDanmaku ? _self.collapseRepeatedDanmaku : collapseRepeatedDanmaku // ignore: cast_nullable_to_non_nullable
as bool,repeatedDanmakuWindowSeconds: null == repeatedDanmakuWindowSeconds ? _self.repeatedDanmakuWindowSeconds : repeatedDanmakuWindowSeconds // ignore: cast_nullable_to_non_nullable
as int,danmakuInteractionMigration: null == danmakuInteractionMigration ? _self.danmakuInteractionMigration : danmakuInteractionMigration // ignore: cast_nullable_to_non_nullable
as int,savedDanmakuTemplate: null == savedDanmakuTemplate ? _self.savedDanmakuTemplate : savedDanmakuTemplate // ignore: cast_nullable_to_non_nullable
as String,danmakuFontFamilyName: null == danmakuFontFamilyName ? _self.danmakuFontFamilyName : danmakuFontFamilyName // ignore: cast_nullable_to_non_nullable
as String,enablePipDanmaku: null == enablePipDanmaku ? _self.enablePipDanmaku : enablePipDanmaku // ignore: cast_nullable_to_non_nullable
as bool,pipDanmakuAutoScale: null == pipDanmakuAutoScale ? _self.pipDanmakuAutoScale : pipDanmakuAutoScale // ignore: cast_nullable_to_non_nullable
as bool,pipDanmakuNoEmojiMode: null == pipDanmakuNoEmojiMode ? _self.pipDanmakuNoEmojiMode : pipDanmakuNoEmojiMode // ignore: cast_nullable_to_non_nullable
as bool,pipDanmakuUseOriginalColor: null == pipDanmakuUseOriginalColor ? _self.pipDanmakuUseOriginalColor : pipDanmakuUseOriginalColor // ignore: cast_nullable_to_non_nullable
as bool,pipDanmakuColor: null == pipDanmakuColor ? _self.pipDanmakuColor : pipDanmakuColor // ignore: cast_nullable_to_non_nullable
as int,pipDanmakuFontSize: null == pipDanmakuFontSize ? _self.pipDanmakuFontSize : pipDanmakuFontSize // ignore: cast_nullable_to_non_nullable
as double,pipDanmakuFontWeight: null == pipDanmakuFontWeight ? _self.pipDanmakuFontWeight : pipDanmakuFontWeight // ignore: cast_nullable_to_non_nullable
as int,pipDanmakuSpeed: null == pipDanmakuSpeed ? _self.pipDanmakuSpeed : pipDanmakuSpeed // ignore: cast_nullable_to_non_nullable
as double,pipDanmakuOpacity: null == pipDanmakuOpacity ? _self.pipDanmakuOpacity : pipDanmakuOpacity // ignore: cast_nullable_to_non_nullable
as double,pipDanmakuArea: null == pipDanmakuArea ? _self.pipDanmakuArea : pipDanmakuArea // ignore: cast_nullable_to_non_nullable
as double,pipDanmakuMaxVisibleCount: null == pipDanmakuMaxVisibleCount ? _self.pipDanmakuMaxVisibleCount : pipDanmakuMaxVisibleCount // ignore: cast_nullable_to_non_nullable
as int,pipDanmakuEmitInterval: null == pipDanmakuEmitInterval ? _self.pipDanmakuEmitInterval : pipDanmakuEmitInterval // ignore: cast_nullable_to_non_nullable
as double,pipDanmakuFps: null == pipDanmakuFps ? _self.pipDanmakuFps : pipDanmakuFps // ignore: cast_nullable_to_non_nullable
as int,pipDanmakuAutoFps: null == pipDanmakuAutoFps ? _self.pipDanmakuAutoFps : pipDanmakuAutoFps // ignore: cast_nullable_to_non_nullable
as bool,filterDouyuSuspectedAutomatedMessages: null == filterDouyuSuspectedAutomatedMessages ? _self.filterDouyuSuspectedAutomatedMessages : filterDouyuSuspectedAutomatedMessages // ignore: cast_nullable_to_non_nullable
as bool,enableDanmakuSimilarityFilter: null == enableDanmakuSimilarityFilter ? _self.enableDanmakuSimilarityFilter : enableDanmakuSimilarityFilter // ignore: cast_nullable_to_non_nullable
as bool,danmakuSimilarityThreshold: null == danmakuSimilarityThreshold ? _self.danmakuSimilarityThreshold : danmakuSimilarityThreshold // ignore: cast_nullable_to_non_nullable
as int,danmakuSimilarityCacheDuration: null == danmakuSimilarityCacheDuration ? _self.danmakuSimilarityCacheDuration : danmakuSimilarityCacheDuration // ignore: cast_nullable_to_non_nullable
as int,danmakuSimilarityMaxCacheSize: null == danmakuSimilarityMaxCacheSize ? _self.danmakuSimilarityMaxCacheSize : danmakuSimilarityMaxCacheSize // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
