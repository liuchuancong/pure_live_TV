// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'background_config_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BackgroundConfigModel {

 BackgroundSource get source; BoxFit get boxFit; double get maskOpacity;/// 背景模糊度（高斯 sigma），0 表示不模糊。
 double get blur;/// 是否按 [autoSwitchIntervalHours] 自动更换壁纸（仅对随机网图源有意义）。
 bool get autoSwitch;/// 自动更换间隔（小时）。
 int get autoSwitchIntervalHours;@HexColorConverter() Color get solidColor;@HexColorListConverter() List<Color> get gradientColors; String? get assetImagePath; String? get localImagePath; String? get networkImageUrl; String get currentBoxImageBase64; String? get assetVideoPath; String? get localVideoPath; String? get networkVideoUrl;/// 当前在线壁纸的图片直链。
///
/// `currentBoxImageBase64` 才是真正渲染的那份（本机/内置/在线三种图片源都走它），
/// 这里额外留一份直链是为了「下载壁纸」「记住上次换壁纸时间」这类操作，
/// 不必再从 base64 还原。
 String get currentImageUrl;/// 上一次更换在线壁纸的时间。
///
/// 自动换壁纸的定时器已经由后台任务调度器接管，判断「该不该换」需要跨启动
/// 的时间戳，所以必须持久化（对应 iTab 的 `wallpaper.time`）。
 DateTime? get lastSwitchAt;/// 最近换过的在线壁纸直链（去重，新的在前），供「上一张」翻回去。
 List<String> get recentImageUrls;/// 用户手填的图片直链（iTab「自定义壁纸 → 使用在线图片链接」）。
///
/// 与 [networkImageUrl] 的区别：那个存的是刚下载成功的地址，这个是用户输入框
/// 里的原文。分开存才能在拉取失败时把用户输的地址留在输入框里，不用重敲。
 String get customImageUrl;/// 用户手填的在线视频直链（动态壁纸）。
 String get customVideoUrl;/// 在线动态壁纸接口返回的封面图，`TvScaffold` 的占位/预览用得上。
 String? get networkVideoCover;/// 上一次用过的在线视频图源下标（[BackgroundVideoSources]）。
 int get videoSourceIndex;/// 上一次用过的在线视频分类下标。
 int get videoTagIndex;/// 用户自定义的动态壁纸接口地址（支持 `{page}` `{tag}` `{random}` 占位符）。
///
/// 内置公开接口的 CDN 很不稳定，这条是让用户接自己后端的口子：
/// 只要响应里有 `url`/`video` 字段就被认成视频，`cover`/`thumb` 被认成封面。
 String get customVideoApiUrl;
/// Create a copy of BackgroundConfigModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BackgroundConfigModelCopyWith<BackgroundConfigModel> get copyWith => _$BackgroundConfigModelCopyWithImpl<BackgroundConfigModel>(this as BackgroundConfigModel, _$identity);

  /// Serializes this BackgroundConfigModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BackgroundConfigModel&&(identical(other.source, source) || other.source == source)&&(identical(other.boxFit, boxFit) || other.boxFit == boxFit)&&(identical(other.maskOpacity, maskOpacity) || other.maskOpacity == maskOpacity)&&(identical(other.blur, blur) || other.blur == blur)&&(identical(other.autoSwitch, autoSwitch) || other.autoSwitch == autoSwitch)&&(identical(other.autoSwitchIntervalHours, autoSwitchIntervalHours) || other.autoSwitchIntervalHours == autoSwitchIntervalHours)&&(identical(other.solidColor, solidColor) || other.solidColor == solidColor)&&const DeepCollectionEquality().equals(other.gradientColors, gradientColors)&&(identical(other.assetImagePath, assetImagePath) || other.assetImagePath == assetImagePath)&&(identical(other.localImagePath, localImagePath) || other.localImagePath == localImagePath)&&(identical(other.networkImageUrl, networkImageUrl) || other.networkImageUrl == networkImageUrl)&&(identical(other.currentBoxImageBase64, currentBoxImageBase64) || other.currentBoxImageBase64 == currentBoxImageBase64)&&(identical(other.assetVideoPath, assetVideoPath) || other.assetVideoPath == assetVideoPath)&&(identical(other.localVideoPath, localVideoPath) || other.localVideoPath == localVideoPath)&&(identical(other.networkVideoUrl, networkVideoUrl) || other.networkVideoUrl == networkVideoUrl)&&(identical(other.currentImageUrl, currentImageUrl) || other.currentImageUrl == currentImageUrl)&&(identical(other.lastSwitchAt, lastSwitchAt) || other.lastSwitchAt == lastSwitchAt)&&const DeepCollectionEquality().equals(other.recentImageUrls, recentImageUrls)&&(identical(other.customImageUrl, customImageUrl) || other.customImageUrl == customImageUrl)&&(identical(other.customVideoUrl, customVideoUrl) || other.customVideoUrl == customVideoUrl)&&(identical(other.networkVideoCover, networkVideoCover) || other.networkVideoCover == networkVideoCover)&&(identical(other.videoSourceIndex, videoSourceIndex) || other.videoSourceIndex == videoSourceIndex)&&(identical(other.videoTagIndex, videoTagIndex) || other.videoTagIndex == videoTagIndex)&&(identical(other.customVideoApiUrl, customVideoApiUrl) || other.customVideoApiUrl == customVideoApiUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,source,boxFit,maskOpacity,blur,autoSwitch,autoSwitchIntervalHours,solidColor,const DeepCollectionEquality().hash(gradientColors),assetImagePath,localImagePath,networkImageUrl,currentBoxImageBase64,assetVideoPath,localVideoPath,networkVideoUrl,currentImageUrl,lastSwitchAt,const DeepCollectionEquality().hash(recentImageUrls),customImageUrl,customVideoUrl,networkVideoCover,videoSourceIndex,videoTagIndex,customVideoApiUrl]);

@override
String toString() {
  return 'BackgroundConfigModel(source: $source, boxFit: $boxFit, maskOpacity: $maskOpacity, blur: $blur, autoSwitch: $autoSwitch, autoSwitchIntervalHours: $autoSwitchIntervalHours, solidColor: $solidColor, gradientColors: $gradientColors, assetImagePath: $assetImagePath, localImagePath: $localImagePath, networkImageUrl: $networkImageUrl, currentBoxImageBase64: $currentBoxImageBase64, assetVideoPath: $assetVideoPath, localVideoPath: $localVideoPath, networkVideoUrl: $networkVideoUrl, currentImageUrl: $currentImageUrl, lastSwitchAt: $lastSwitchAt, recentImageUrls: $recentImageUrls, customImageUrl: $customImageUrl, customVideoUrl: $customVideoUrl, networkVideoCover: $networkVideoCover, videoSourceIndex: $videoSourceIndex, videoTagIndex: $videoTagIndex, customVideoApiUrl: $customVideoApiUrl)';
}


}

/// @nodoc
abstract mixin class $BackgroundConfigModelCopyWith<$Res>  {
  factory $BackgroundConfigModelCopyWith(BackgroundConfigModel value, $Res Function(BackgroundConfigModel) _then) = _$BackgroundConfigModelCopyWithImpl;
@useResult
$Res call({
 BackgroundSource source, BoxFit boxFit, double maskOpacity, double blur, bool autoSwitch, int autoSwitchIntervalHours,@HexColorConverter() Color solidColor,@HexColorListConverter() List<Color> gradientColors, String? assetImagePath, String? localImagePath, String? networkImageUrl, String currentBoxImageBase64, String? assetVideoPath, String? localVideoPath, String? networkVideoUrl, String currentImageUrl, DateTime? lastSwitchAt, List<String> recentImageUrls, String customImageUrl, String customVideoUrl, String? networkVideoCover, int videoSourceIndex, int videoTagIndex, String customVideoApiUrl
});




}
/// @nodoc
class _$BackgroundConfigModelCopyWithImpl<$Res>
    implements $BackgroundConfigModelCopyWith<$Res> {
  _$BackgroundConfigModelCopyWithImpl(this._self, this._then);

  final BackgroundConfigModel _self;
  final $Res Function(BackgroundConfigModel) _then;

/// Create a copy of BackgroundConfigModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? source = null,Object? boxFit = null,Object? maskOpacity = null,Object? blur = null,Object? autoSwitch = null,Object? autoSwitchIntervalHours = null,Object? solidColor = null,Object? gradientColors = null,Object? assetImagePath = freezed,Object? localImagePath = freezed,Object? networkImageUrl = freezed,Object? currentBoxImageBase64 = null,Object? assetVideoPath = freezed,Object? localVideoPath = freezed,Object? networkVideoUrl = freezed,Object? currentImageUrl = null,Object? lastSwitchAt = freezed,Object? recentImageUrls = null,Object? customImageUrl = null,Object? customVideoUrl = null,Object? networkVideoCover = freezed,Object? videoSourceIndex = null,Object? videoTagIndex = null,Object? customVideoApiUrl = null,}) {
  return _then(_self.copyWith(
source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as BackgroundSource,boxFit: null == boxFit ? _self.boxFit : boxFit // ignore: cast_nullable_to_non_nullable
as BoxFit,maskOpacity: null == maskOpacity ? _self.maskOpacity : maskOpacity // ignore: cast_nullable_to_non_nullable
as double,blur: null == blur ? _self.blur : blur // ignore: cast_nullable_to_non_nullable
as double,autoSwitch: null == autoSwitch ? _self.autoSwitch : autoSwitch // ignore: cast_nullable_to_non_nullable
as bool,autoSwitchIntervalHours: null == autoSwitchIntervalHours ? _self.autoSwitchIntervalHours : autoSwitchIntervalHours // ignore: cast_nullable_to_non_nullable
as int,solidColor: null == solidColor ? _self.solidColor : solidColor // ignore: cast_nullable_to_non_nullable
as Color,gradientColors: null == gradientColors ? _self.gradientColors : gradientColors // ignore: cast_nullable_to_non_nullable
as List<Color>,assetImagePath: freezed == assetImagePath ? _self.assetImagePath : assetImagePath // ignore: cast_nullable_to_non_nullable
as String?,localImagePath: freezed == localImagePath ? _self.localImagePath : localImagePath // ignore: cast_nullable_to_non_nullable
as String?,networkImageUrl: freezed == networkImageUrl ? _self.networkImageUrl : networkImageUrl // ignore: cast_nullable_to_non_nullable
as String?,currentBoxImageBase64: null == currentBoxImageBase64 ? _self.currentBoxImageBase64 : currentBoxImageBase64 // ignore: cast_nullable_to_non_nullable
as String,assetVideoPath: freezed == assetVideoPath ? _self.assetVideoPath : assetVideoPath // ignore: cast_nullable_to_non_nullable
as String?,localVideoPath: freezed == localVideoPath ? _self.localVideoPath : localVideoPath // ignore: cast_nullable_to_non_nullable
as String?,networkVideoUrl: freezed == networkVideoUrl ? _self.networkVideoUrl : networkVideoUrl // ignore: cast_nullable_to_non_nullable
as String?,currentImageUrl: null == currentImageUrl ? _self.currentImageUrl : currentImageUrl // ignore: cast_nullable_to_non_nullable
as String,lastSwitchAt: freezed == lastSwitchAt ? _self.lastSwitchAt : lastSwitchAt // ignore: cast_nullable_to_non_nullable
as DateTime?,recentImageUrls: null == recentImageUrls ? _self.recentImageUrls : recentImageUrls // ignore: cast_nullable_to_non_nullable
as List<String>,customImageUrl: null == customImageUrl ? _self.customImageUrl : customImageUrl // ignore: cast_nullable_to_non_nullable
as String,customVideoUrl: null == customVideoUrl ? _self.customVideoUrl : customVideoUrl // ignore: cast_nullable_to_non_nullable
as String,networkVideoCover: freezed == networkVideoCover ? _self.networkVideoCover : networkVideoCover // ignore: cast_nullable_to_non_nullable
as String?,videoSourceIndex: null == videoSourceIndex ? _self.videoSourceIndex : videoSourceIndex // ignore: cast_nullable_to_non_nullable
as int,videoTagIndex: null == videoTagIndex ? _self.videoTagIndex : videoTagIndex // ignore: cast_nullable_to_non_nullable
as int,customVideoApiUrl: null == customVideoApiUrl ? _self.customVideoApiUrl : customVideoApiUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [BackgroundConfigModel].
extension BackgroundConfigModelPatterns on BackgroundConfigModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BackgroundConfigModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BackgroundConfigModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BackgroundConfigModel value)  $default,){
final _that = this;
switch (_that) {
case _BackgroundConfigModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BackgroundConfigModel value)?  $default,){
final _that = this;
switch (_that) {
case _BackgroundConfigModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BackgroundSource source,  BoxFit boxFit,  double maskOpacity,  double blur,  bool autoSwitch,  int autoSwitchIntervalHours, @HexColorConverter()  Color solidColor, @HexColorListConverter()  List<Color> gradientColors,  String? assetImagePath,  String? localImagePath,  String? networkImageUrl,  String currentBoxImageBase64,  String? assetVideoPath,  String? localVideoPath,  String? networkVideoUrl,  String currentImageUrl,  DateTime? lastSwitchAt,  List<String> recentImageUrls,  String customImageUrl,  String customVideoUrl,  String? networkVideoCover,  int videoSourceIndex,  int videoTagIndex,  String customVideoApiUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BackgroundConfigModel() when $default != null:
return $default(_that.source,_that.boxFit,_that.maskOpacity,_that.blur,_that.autoSwitch,_that.autoSwitchIntervalHours,_that.solidColor,_that.gradientColors,_that.assetImagePath,_that.localImagePath,_that.networkImageUrl,_that.currentBoxImageBase64,_that.assetVideoPath,_that.localVideoPath,_that.networkVideoUrl,_that.currentImageUrl,_that.lastSwitchAt,_that.recentImageUrls,_that.customImageUrl,_that.customVideoUrl,_that.networkVideoCover,_that.videoSourceIndex,_that.videoTagIndex,_that.customVideoApiUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BackgroundSource source,  BoxFit boxFit,  double maskOpacity,  double blur,  bool autoSwitch,  int autoSwitchIntervalHours, @HexColorConverter()  Color solidColor, @HexColorListConverter()  List<Color> gradientColors,  String? assetImagePath,  String? localImagePath,  String? networkImageUrl,  String currentBoxImageBase64,  String? assetVideoPath,  String? localVideoPath,  String? networkVideoUrl,  String currentImageUrl,  DateTime? lastSwitchAt,  List<String> recentImageUrls,  String customImageUrl,  String customVideoUrl,  String? networkVideoCover,  int videoSourceIndex,  int videoTagIndex,  String customVideoApiUrl)  $default,) {final _that = this;
switch (_that) {
case _BackgroundConfigModel():
return $default(_that.source,_that.boxFit,_that.maskOpacity,_that.blur,_that.autoSwitch,_that.autoSwitchIntervalHours,_that.solidColor,_that.gradientColors,_that.assetImagePath,_that.localImagePath,_that.networkImageUrl,_that.currentBoxImageBase64,_that.assetVideoPath,_that.localVideoPath,_that.networkVideoUrl,_that.currentImageUrl,_that.lastSwitchAt,_that.recentImageUrls,_that.customImageUrl,_that.customVideoUrl,_that.networkVideoCover,_that.videoSourceIndex,_that.videoTagIndex,_that.customVideoApiUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BackgroundSource source,  BoxFit boxFit,  double maskOpacity,  double blur,  bool autoSwitch,  int autoSwitchIntervalHours, @HexColorConverter()  Color solidColor, @HexColorListConverter()  List<Color> gradientColors,  String? assetImagePath,  String? localImagePath,  String? networkImageUrl,  String currentBoxImageBase64,  String? assetVideoPath,  String? localVideoPath,  String? networkVideoUrl,  String currentImageUrl,  DateTime? lastSwitchAt,  List<String> recentImageUrls,  String customImageUrl,  String customVideoUrl,  String? networkVideoCover,  int videoSourceIndex,  int videoTagIndex,  String customVideoApiUrl)?  $default,) {final _that = this;
switch (_that) {
case _BackgroundConfigModel() when $default != null:
return $default(_that.source,_that.boxFit,_that.maskOpacity,_that.blur,_that.autoSwitch,_that.autoSwitchIntervalHours,_that.solidColor,_that.gradientColors,_that.assetImagePath,_that.localImagePath,_that.networkImageUrl,_that.currentBoxImageBase64,_that.assetVideoPath,_that.localVideoPath,_that.networkVideoUrl,_that.currentImageUrl,_that.lastSwitchAt,_that.recentImageUrls,_that.customImageUrl,_that.customVideoUrl,_that.networkVideoCover,_that.videoSourceIndex,_that.videoTagIndex,_that.customVideoApiUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BackgroundConfigModel implements BackgroundConfigModel {
  const _BackgroundConfigModel({this.source = BackgroundSource.none, this.boxFit = BoxFit.cover, this.maskOpacity = 0.35, this.blur = 0.0, this.autoSwitch = false, this.autoSwitchIntervalHours = 6, @HexColorConverter() this.solidColor = const Color(0xFF141e30), @HexColorListConverter() final  List<Color> gradientColors = const [Color(0xFF141e30), Color(0xFF243b55), Color(0xFF141e30)], this.assetImagePath, this.localImagePath, this.networkImageUrl, this.currentBoxImageBase64 = '', this.assetVideoPath, this.localVideoPath, this.networkVideoUrl, this.currentImageUrl = '', this.lastSwitchAt, final  List<String> recentImageUrls = const <String>[], this.customImageUrl = '', this.customVideoUrl = '', this.networkVideoCover, this.videoSourceIndex = 0, this.videoTagIndex = 0, this.customVideoApiUrl = ''}): _gradientColors = gradientColors,_recentImageUrls = recentImageUrls;
  factory _BackgroundConfigModel.fromJson(Map<String, dynamic> json) => _$BackgroundConfigModelFromJson(json);

@override@JsonKey() final  BackgroundSource source;
@override@JsonKey() final  BoxFit boxFit;
@override@JsonKey() final  double maskOpacity;
/// 背景模糊度（高斯 sigma），0 表示不模糊。
@override@JsonKey() final  double blur;
/// 是否按 [autoSwitchIntervalHours] 自动更换壁纸（仅对随机网图源有意义）。
@override@JsonKey() final  bool autoSwitch;
/// 自动更换间隔（小时）。
@override@JsonKey() final  int autoSwitchIntervalHours;
@override@JsonKey()@HexColorConverter() final  Color solidColor;
 final  List<Color> _gradientColors;
@override@JsonKey()@HexColorListConverter() List<Color> get gradientColors {
  if (_gradientColors is EqualUnmodifiableListView) return _gradientColors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_gradientColors);
}

@override final  String? assetImagePath;
@override final  String? localImagePath;
@override final  String? networkImageUrl;
@override@JsonKey() final  String currentBoxImageBase64;
@override final  String? assetVideoPath;
@override final  String? localVideoPath;
@override final  String? networkVideoUrl;
/// 当前在线壁纸的图片直链。
///
/// `currentBoxImageBase64` 才是真正渲染的那份（本机/内置/在线三种图片源都走它），
/// 这里额外留一份直链是为了「下载壁纸」「记住上次换壁纸时间」这类操作，
/// 不必再从 base64 还原。
@override@JsonKey() final  String currentImageUrl;
/// 上一次更换在线壁纸的时间。
///
/// 自动换壁纸的定时器已经由后台任务调度器接管，判断「该不该换」需要跨启动
/// 的时间戳，所以必须持久化（对应 iTab 的 `wallpaper.time`）。
@override final  DateTime? lastSwitchAt;
/// 最近换过的在线壁纸直链（去重，新的在前），供「上一张」翻回去。
 final  List<String> _recentImageUrls;
/// 最近换过的在线壁纸直链（去重，新的在前），供「上一张」翻回去。
@override@JsonKey() List<String> get recentImageUrls {
  if (_recentImageUrls is EqualUnmodifiableListView) return _recentImageUrls;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_recentImageUrls);
}

/// 用户手填的图片直链（iTab「自定义壁纸 → 使用在线图片链接」）。
///
/// 与 [networkImageUrl] 的区别：那个存的是刚下载成功的地址，这个是用户输入框
/// 里的原文。分开存才能在拉取失败时把用户输的地址留在输入框里，不用重敲。
@override@JsonKey() final  String customImageUrl;
/// 用户手填的在线视频直链（动态壁纸）。
@override@JsonKey() final  String customVideoUrl;
/// 在线动态壁纸接口返回的封面图，`TvScaffold` 的占位/预览用得上。
@override final  String? networkVideoCover;
/// 上一次用过的在线视频图源下标（[BackgroundVideoSources]）。
@override@JsonKey() final  int videoSourceIndex;
/// 上一次用过的在线视频分类下标。
@override@JsonKey() final  int videoTagIndex;
/// 用户自定义的动态壁纸接口地址（支持 `{page}` `{tag}` `{random}` 占位符）。
///
/// 内置公开接口的 CDN 很不稳定，这条是让用户接自己后端的口子：
/// 只要响应里有 `url`/`video` 字段就被认成视频，`cover`/`thumb` 被认成封面。
@override@JsonKey() final  String customVideoApiUrl;

/// Create a copy of BackgroundConfigModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BackgroundConfigModelCopyWith<_BackgroundConfigModel> get copyWith => __$BackgroundConfigModelCopyWithImpl<_BackgroundConfigModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BackgroundConfigModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BackgroundConfigModel&&(identical(other.source, source) || other.source == source)&&(identical(other.boxFit, boxFit) || other.boxFit == boxFit)&&(identical(other.maskOpacity, maskOpacity) || other.maskOpacity == maskOpacity)&&(identical(other.blur, blur) || other.blur == blur)&&(identical(other.autoSwitch, autoSwitch) || other.autoSwitch == autoSwitch)&&(identical(other.autoSwitchIntervalHours, autoSwitchIntervalHours) || other.autoSwitchIntervalHours == autoSwitchIntervalHours)&&(identical(other.solidColor, solidColor) || other.solidColor == solidColor)&&const DeepCollectionEquality().equals(other._gradientColors, _gradientColors)&&(identical(other.assetImagePath, assetImagePath) || other.assetImagePath == assetImagePath)&&(identical(other.localImagePath, localImagePath) || other.localImagePath == localImagePath)&&(identical(other.networkImageUrl, networkImageUrl) || other.networkImageUrl == networkImageUrl)&&(identical(other.currentBoxImageBase64, currentBoxImageBase64) || other.currentBoxImageBase64 == currentBoxImageBase64)&&(identical(other.assetVideoPath, assetVideoPath) || other.assetVideoPath == assetVideoPath)&&(identical(other.localVideoPath, localVideoPath) || other.localVideoPath == localVideoPath)&&(identical(other.networkVideoUrl, networkVideoUrl) || other.networkVideoUrl == networkVideoUrl)&&(identical(other.currentImageUrl, currentImageUrl) || other.currentImageUrl == currentImageUrl)&&(identical(other.lastSwitchAt, lastSwitchAt) || other.lastSwitchAt == lastSwitchAt)&&const DeepCollectionEquality().equals(other._recentImageUrls, _recentImageUrls)&&(identical(other.customImageUrl, customImageUrl) || other.customImageUrl == customImageUrl)&&(identical(other.customVideoUrl, customVideoUrl) || other.customVideoUrl == customVideoUrl)&&(identical(other.networkVideoCover, networkVideoCover) || other.networkVideoCover == networkVideoCover)&&(identical(other.videoSourceIndex, videoSourceIndex) || other.videoSourceIndex == videoSourceIndex)&&(identical(other.videoTagIndex, videoTagIndex) || other.videoTagIndex == videoTagIndex)&&(identical(other.customVideoApiUrl, customVideoApiUrl) || other.customVideoApiUrl == customVideoApiUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,source,boxFit,maskOpacity,blur,autoSwitch,autoSwitchIntervalHours,solidColor,const DeepCollectionEquality().hash(_gradientColors),assetImagePath,localImagePath,networkImageUrl,currentBoxImageBase64,assetVideoPath,localVideoPath,networkVideoUrl,currentImageUrl,lastSwitchAt,const DeepCollectionEquality().hash(_recentImageUrls),customImageUrl,customVideoUrl,networkVideoCover,videoSourceIndex,videoTagIndex,customVideoApiUrl]);

@override
String toString() {
  return 'BackgroundConfigModel(source: $source, boxFit: $boxFit, maskOpacity: $maskOpacity, blur: $blur, autoSwitch: $autoSwitch, autoSwitchIntervalHours: $autoSwitchIntervalHours, solidColor: $solidColor, gradientColors: $gradientColors, assetImagePath: $assetImagePath, localImagePath: $localImagePath, networkImageUrl: $networkImageUrl, currentBoxImageBase64: $currentBoxImageBase64, assetVideoPath: $assetVideoPath, localVideoPath: $localVideoPath, networkVideoUrl: $networkVideoUrl, currentImageUrl: $currentImageUrl, lastSwitchAt: $lastSwitchAt, recentImageUrls: $recentImageUrls, customImageUrl: $customImageUrl, customVideoUrl: $customVideoUrl, networkVideoCover: $networkVideoCover, videoSourceIndex: $videoSourceIndex, videoTagIndex: $videoTagIndex, customVideoApiUrl: $customVideoApiUrl)';
}


}

/// @nodoc
abstract mixin class _$BackgroundConfigModelCopyWith<$Res> implements $BackgroundConfigModelCopyWith<$Res> {
  factory _$BackgroundConfigModelCopyWith(_BackgroundConfigModel value, $Res Function(_BackgroundConfigModel) _then) = __$BackgroundConfigModelCopyWithImpl;
@override @useResult
$Res call({
 BackgroundSource source, BoxFit boxFit, double maskOpacity, double blur, bool autoSwitch, int autoSwitchIntervalHours,@HexColorConverter() Color solidColor,@HexColorListConverter() List<Color> gradientColors, String? assetImagePath, String? localImagePath, String? networkImageUrl, String currentBoxImageBase64, String? assetVideoPath, String? localVideoPath, String? networkVideoUrl, String currentImageUrl, DateTime? lastSwitchAt, List<String> recentImageUrls, String customImageUrl, String customVideoUrl, String? networkVideoCover, int videoSourceIndex, int videoTagIndex, String customVideoApiUrl
});




}
/// @nodoc
class __$BackgroundConfigModelCopyWithImpl<$Res>
    implements _$BackgroundConfigModelCopyWith<$Res> {
  __$BackgroundConfigModelCopyWithImpl(this._self, this._then);

  final _BackgroundConfigModel _self;
  final $Res Function(_BackgroundConfigModel) _then;

/// Create a copy of BackgroundConfigModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? source = null,Object? boxFit = null,Object? maskOpacity = null,Object? blur = null,Object? autoSwitch = null,Object? autoSwitchIntervalHours = null,Object? solidColor = null,Object? gradientColors = null,Object? assetImagePath = freezed,Object? localImagePath = freezed,Object? networkImageUrl = freezed,Object? currentBoxImageBase64 = null,Object? assetVideoPath = freezed,Object? localVideoPath = freezed,Object? networkVideoUrl = freezed,Object? currentImageUrl = null,Object? lastSwitchAt = freezed,Object? recentImageUrls = null,Object? customImageUrl = null,Object? customVideoUrl = null,Object? networkVideoCover = freezed,Object? videoSourceIndex = null,Object? videoTagIndex = null,Object? customVideoApiUrl = null,}) {
  return _then(_BackgroundConfigModel(
source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as BackgroundSource,boxFit: null == boxFit ? _self.boxFit : boxFit // ignore: cast_nullable_to_non_nullable
as BoxFit,maskOpacity: null == maskOpacity ? _self.maskOpacity : maskOpacity // ignore: cast_nullable_to_non_nullable
as double,blur: null == blur ? _self.blur : blur // ignore: cast_nullable_to_non_nullable
as double,autoSwitch: null == autoSwitch ? _self.autoSwitch : autoSwitch // ignore: cast_nullable_to_non_nullable
as bool,autoSwitchIntervalHours: null == autoSwitchIntervalHours ? _self.autoSwitchIntervalHours : autoSwitchIntervalHours // ignore: cast_nullable_to_non_nullable
as int,solidColor: null == solidColor ? _self.solidColor : solidColor // ignore: cast_nullable_to_non_nullable
as Color,gradientColors: null == gradientColors ? _self._gradientColors : gradientColors // ignore: cast_nullable_to_non_nullable
as List<Color>,assetImagePath: freezed == assetImagePath ? _self.assetImagePath : assetImagePath // ignore: cast_nullable_to_non_nullable
as String?,localImagePath: freezed == localImagePath ? _self.localImagePath : localImagePath // ignore: cast_nullable_to_non_nullable
as String?,networkImageUrl: freezed == networkImageUrl ? _self.networkImageUrl : networkImageUrl // ignore: cast_nullable_to_non_nullable
as String?,currentBoxImageBase64: null == currentBoxImageBase64 ? _self.currentBoxImageBase64 : currentBoxImageBase64 // ignore: cast_nullable_to_non_nullable
as String,assetVideoPath: freezed == assetVideoPath ? _self.assetVideoPath : assetVideoPath // ignore: cast_nullable_to_non_nullable
as String?,localVideoPath: freezed == localVideoPath ? _self.localVideoPath : localVideoPath // ignore: cast_nullable_to_non_nullable
as String?,networkVideoUrl: freezed == networkVideoUrl ? _self.networkVideoUrl : networkVideoUrl // ignore: cast_nullable_to_non_nullable
as String?,currentImageUrl: null == currentImageUrl ? _self.currentImageUrl : currentImageUrl // ignore: cast_nullable_to_non_nullable
as String,lastSwitchAt: freezed == lastSwitchAt ? _self.lastSwitchAt : lastSwitchAt // ignore: cast_nullable_to_non_nullable
as DateTime?,recentImageUrls: null == recentImageUrls ? _self._recentImageUrls : recentImageUrls // ignore: cast_nullable_to_non_nullable
as List<String>,customImageUrl: null == customImageUrl ? _self.customImageUrl : customImageUrl // ignore: cast_nullable_to_non_nullable
as String,customVideoUrl: null == customVideoUrl ? _self.customVideoUrl : customVideoUrl // ignore: cast_nullable_to_non_nullable
as String,networkVideoCover: freezed == networkVideoCover ? _self.networkVideoCover : networkVideoCover // ignore: cast_nullable_to_non_nullable
as String?,videoSourceIndex: null == videoSourceIndex ? _self.videoSourceIndex : videoSourceIndex // ignore: cast_nullable_to_non_nullable
as int,videoTagIndex: null == videoTagIndex ? _self.videoTagIndex : videoTagIndex // ignore: cast_nullable_to_non_nullable
as int,customVideoApiUrl: null == customVideoApiUrl ? _self.customVideoApiUrl : customVideoApiUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
