// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'video_settings_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$VideoSettingsModel {

/// The rendition (B站 qn) the video player prefers on open. 0 = the play-url
/// answer's own pick.
 int get preferredQuality;/// Playback rate a video starts at when nothing was restored.
 double get defaultSpeed;/// Card tap opens the detail page first (newBV's 显示视频详情); off = straight
/// into the player.
 bool get showVideoDetail;/// newBV's persistent mini progress line on the player's bottom edge.
 bool get persistentProgress;/// The video section the sidebar lands on: index into [VideoSection.values].
 int get startSection;/// The video home's landing top tab: 0 动态 / 1 推荐 / 2 热门.
 int get homeTabIndex;/// The personal page's landing tab: index into its tab list.
 int get personalTabIndex;
/// Create a copy of VideoSettingsModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VideoSettingsModelCopyWith<VideoSettingsModel> get copyWith => _$VideoSettingsModelCopyWithImpl<VideoSettingsModel>(this as VideoSettingsModel, _$identity);

  /// Serializes this VideoSettingsModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as VideoSettingsModel;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VideoSettingsModel&&(identical(other.preferredQuality, _this.preferredQuality) || other.preferredQuality == _this.preferredQuality)&&(identical(other.defaultSpeed, _this.defaultSpeed) || other.defaultSpeed == _this.defaultSpeed)&&(identical(other.showVideoDetail, _this.showVideoDetail) || other.showVideoDetail == _this.showVideoDetail)&&(identical(other.persistentProgress, _this.persistentProgress) || other.persistentProgress == _this.persistentProgress)&&(identical(other.startSection, _this.startSection) || other.startSection == _this.startSection)&&(identical(other.homeTabIndex, _this.homeTabIndex) || other.homeTabIndex == _this.homeTabIndex)&&(identical(other.personalTabIndex, _this.personalTabIndex) || other.personalTabIndex == _this.personalTabIndex));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as VideoSettingsModel;
  return Object.hash(runtimeType,_this.preferredQuality,_this.defaultSpeed,_this.showVideoDetail,_this.persistentProgress,_this.startSection,_this.homeTabIndex,_this.personalTabIndex);
}

@override
String toString() {
  final _this = this as VideoSettingsModel;
  return 'VideoSettingsModel(preferredQuality: ${_this.preferredQuality}, defaultSpeed: ${_this.defaultSpeed}, showVideoDetail: ${_this.showVideoDetail}, persistentProgress: ${_this.persistentProgress}, startSection: ${_this.startSection}, homeTabIndex: ${_this.homeTabIndex}, personalTabIndex: ${_this.personalTabIndex})';
}


}

/// @nodoc
abstract mixin class $VideoSettingsModelCopyWith<$Res>  {
  factory $VideoSettingsModelCopyWith(VideoSettingsModel value, $Res Function(VideoSettingsModel) _then) = _$VideoSettingsModelCopyWithImpl;
@useResult
$Res call({
 int preferredQuality, double defaultSpeed, bool showVideoDetail, bool persistentProgress, int startSection, int homeTabIndex, int personalTabIndex
});




}
/// @nodoc
class _$VideoSettingsModelCopyWithImpl<$Res>
    implements $VideoSettingsModelCopyWith<$Res> {
  _$VideoSettingsModelCopyWithImpl(this._self, this._then);

  final VideoSettingsModel _self;
  final $Res Function(VideoSettingsModel) _then;

/// Create a copy of VideoSettingsModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? preferredQuality = null,Object? defaultSpeed = null,Object? showVideoDetail = null,Object? persistentProgress = null,Object? startSection = null,Object? homeTabIndex = null,Object? personalTabIndex = null,}) {
  return _then(VideoSettingsModel(
preferredQuality: null == preferredQuality ? _self.preferredQuality : preferredQuality // ignore: cast_nullable_to_non_nullable
as int,defaultSpeed: null == defaultSpeed ? _self.defaultSpeed : defaultSpeed // ignore: cast_nullable_to_non_nullable
as double,showVideoDetail: null == showVideoDetail ? _self.showVideoDetail : showVideoDetail // ignore: cast_nullable_to_non_nullable
as bool,persistentProgress: null == persistentProgress ? _self.persistentProgress : persistentProgress // ignore: cast_nullable_to_non_nullable
as bool,startSection: null == startSection ? _self.startSection : startSection // ignore: cast_nullable_to_non_nullable
as int,homeTabIndex: null == homeTabIndex ? _self.homeTabIndex : homeTabIndex // ignore: cast_nullable_to_non_nullable
as int,personalTabIndex: null == personalTabIndex ? _self.personalTabIndex : personalTabIndex // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [VideoSettingsModel].
extension VideoSettingsModelPatterns on VideoSettingsModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VideoSettingsModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VideoSettingsModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VideoSettingsModel value)  $default,){
final _that = this;
switch (_that) {
case _VideoSettingsModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VideoSettingsModel value)?  $default,){
final _that = this;
switch (_that) {
case _VideoSettingsModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int preferredQuality,  double defaultSpeed,  bool showVideoDetail,  bool persistentProgress,  int startSection,  int homeTabIndex,  int personalTabIndex)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VideoSettingsModel() when $default != null:
return $default(_that.preferredQuality,_that.defaultSpeed,_that.showVideoDetail,_that.persistentProgress,_that.startSection,_that.homeTabIndex,_that.personalTabIndex);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int preferredQuality,  double defaultSpeed,  bool showVideoDetail,  bool persistentProgress,  int startSection,  int homeTabIndex,  int personalTabIndex)  $default,) {final _that = this;
switch (_that) {
case _VideoSettingsModel():
return $default(_that.preferredQuality,_that.defaultSpeed,_that.showVideoDetail,_that.persistentProgress,_that.startSection,_that.homeTabIndex,_that.personalTabIndex);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int preferredQuality,  double defaultSpeed,  bool showVideoDetail,  bool persistentProgress,  int startSection,  int homeTabIndex,  int personalTabIndex)?  $default,) {final _that = this;
switch (_that) {
case _VideoSettingsModel() when $default != null:
return $default(_that.preferredQuality,_that.defaultSpeed,_that.showVideoDetail,_that.persistentProgress,_that.startSection,_that.homeTabIndex,_that.personalTabIndex);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VideoSettingsModel implements VideoSettingsModel {
  const _VideoSettingsModel({this.preferredQuality = 0, this.defaultSpeed = 1.0, this.showVideoDetail = true, this.persistentProgress = true, this.startSection = 0, this.homeTabIndex = 1, this.personalTabIndex = 0});
  factory _VideoSettingsModel.fromJson(Map<String, dynamic> json) => _$VideoSettingsModelFromJson(json);

/// The rendition (B站 qn) the video player prefers on open. 0 = the play-url
/// answer's own pick.
@override@JsonKey() final  int preferredQuality;
/// Playback rate a video starts at when nothing was restored.
@override@JsonKey() final  double defaultSpeed;
/// Card tap opens the detail page first (newBV's 显示视频详情); off = straight
/// into the player.
@override@JsonKey() final  bool showVideoDetail;
/// newBV's persistent mini progress line on the player's bottom edge.
@override@JsonKey() final  bool persistentProgress;
/// The video section the sidebar lands on: index into [VideoSection.values].
@override@JsonKey() final  int startSection;
/// The video home's landing top tab: 0 动态 / 1 推荐 / 2 热门.
@override@JsonKey() final  int homeTabIndex;
/// The personal page's landing tab: index into its tab list.
@override@JsonKey() final  int personalTabIndex;

/// Create a copy of VideoSettingsModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VideoSettingsModelCopyWith<_VideoSettingsModel> get copyWith => __$VideoSettingsModelCopyWithImpl<_VideoSettingsModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VideoSettingsModelToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _VideoSettingsModel&&(identical(other.preferredQuality, preferredQuality) || other.preferredQuality == preferredQuality)&&(identical(other.defaultSpeed, defaultSpeed) || other.defaultSpeed == defaultSpeed)&&(identical(other.showVideoDetail, showVideoDetail) || other.showVideoDetail == showVideoDetail)&&(identical(other.persistentProgress, persistentProgress) || other.persistentProgress == persistentProgress)&&(identical(other.startSection, startSection) || other.startSection == startSection)&&(identical(other.homeTabIndex, homeTabIndex) || other.homeTabIndex == homeTabIndex)&&(identical(other.personalTabIndex, personalTabIndex) || other.personalTabIndex == personalTabIndex));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,preferredQuality,defaultSpeed,showVideoDetail,persistentProgress,startSection,homeTabIndex,personalTabIndex);
}

@override
String toString() {
    return 'VideoSettingsModel(preferredQuality: $preferredQuality, defaultSpeed: $defaultSpeed, showVideoDetail: $showVideoDetail, persistentProgress: $persistentProgress, startSection: $startSection, homeTabIndex: $homeTabIndex, personalTabIndex: $personalTabIndex)';
}


}

/// @nodoc
abstract mixin class _$VideoSettingsModelCopyWith<$Res> implements $VideoSettingsModelCopyWith<$Res> {
  factory _$VideoSettingsModelCopyWith(_VideoSettingsModel value, $Res Function(_VideoSettingsModel) _then) = __$VideoSettingsModelCopyWithImpl;
@override @useResult
$Res call({
 int preferredQuality, double defaultSpeed, bool showVideoDetail, bool persistentProgress, int startSection, int homeTabIndex, int personalTabIndex
});




}
/// @nodoc
class __$VideoSettingsModelCopyWithImpl<$Res>
    implements _$VideoSettingsModelCopyWith<$Res> {
  __$VideoSettingsModelCopyWithImpl(this._self, this._then);

  final _VideoSettingsModel _self;
  final $Res Function(_VideoSettingsModel) _then;

/// Create a copy of VideoSettingsModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? preferredQuality = null,Object? defaultSpeed = null,Object? showVideoDetail = null,Object? persistentProgress = null,Object? startSection = null,Object? homeTabIndex = null,Object? personalTabIndex = null,}) {
  return _then(_VideoSettingsModel(
preferredQuality: null == preferredQuality ? _self.preferredQuality : preferredQuality // ignore: cast_nullable_to_non_nullable
as int,defaultSpeed: null == defaultSpeed ? _self.defaultSpeed : defaultSpeed // ignore: cast_nullable_to_non_nullable
as double,showVideoDetail: null == showVideoDetail ? _self.showVideoDetail : showVideoDetail // ignore: cast_nullable_to_non_nullable
as bool,persistentProgress: null == persistentProgress ? _self.persistentProgress : persistentProgress // ignore: cast_nullable_to_non_nullable
as bool,startSection: null == startSection ? _self.startSection : startSection // ignore: cast_nullable_to_non_nullable
as int,homeTabIndex: null == homeTabIndex ? _self.homeTabIndex : homeTabIndex // ignore: cast_nullable_to_non_nullable
as int,personalTabIndex: null == personalTabIndex ? _self.personalTabIndex : personalTabIndex // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
