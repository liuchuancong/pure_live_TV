// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'back_ground_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BackgroundConfigModel {

 BackgroundSource get source; BoxFit get boxFit; double get maskOpacity; Color get solidColor; List<Color> get gradientColors; String? get assetImagePath; String? get localImagePath; String? get networkImageUrl; String get currentBoxImageBase64; String? get assetVideoPath; String? get localVideoPath; String? get networkVideoUrl;
/// Create a copy of BackgroundConfigModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BackgroundConfigModelCopyWith<BackgroundConfigModel> get copyWith => _$BackgroundConfigModelCopyWithImpl<BackgroundConfigModel>(this as BackgroundConfigModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BackgroundConfigModel&&(identical(other.source, source) || other.source == source)&&(identical(other.boxFit, boxFit) || other.boxFit == boxFit)&&(identical(other.maskOpacity, maskOpacity) || other.maskOpacity == maskOpacity)&&(identical(other.solidColor, solidColor) || other.solidColor == solidColor)&&const DeepCollectionEquality().equals(other.gradientColors, gradientColors)&&(identical(other.assetImagePath, assetImagePath) || other.assetImagePath == assetImagePath)&&(identical(other.localImagePath, localImagePath) || other.localImagePath == localImagePath)&&(identical(other.networkImageUrl, networkImageUrl) || other.networkImageUrl == networkImageUrl)&&(identical(other.currentBoxImageBase64, currentBoxImageBase64) || other.currentBoxImageBase64 == currentBoxImageBase64)&&(identical(other.assetVideoPath, assetVideoPath) || other.assetVideoPath == assetVideoPath)&&(identical(other.localVideoPath, localVideoPath) || other.localVideoPath == localVideoPath)&&(identical(other.networkVideoUrl, networkVideoUrl) || other.networkVideoUrl == networkVideoUrl));
}


@override
int get hashCode => Object.hash(runtimeType,source,boxFit,maskOpacity,solidColor,const DeepCollectionEquality().hash(gradientColors),assetImagePath,localImagePath,networkImageUrl,currentBoxImageBase64,assetVideoPath,localVideoPath,networkVideoUrl);

@override
String toString() {
  return 'BackgroundConfigModel(source: $source, boxFit: $boxFit, maskOpacity: $maskOpacity, solidColor: $solidColor, gradientColors: $gradientColors, assetImagePath: $assetImagePath, localImagePath: $localImagePath, networkImageUrl: $networkImageUrl, currentBoxImageBase64: $currentBoxImageBase64, assetVideoPath: $assetVideoPath, localVideoPath: $localVideoPath, networkVideoUrl: $networkVideoUrl)';
}


}

/// @nodoc
abstract mixin class $BackgroundConfigModelCopyWith<$Res>  {
  factory $BackgroundConfigModelCopyWith(BackgroundConfigModel value, $Res Function(BackgroundConfigModel) _then) = _$BackgroundConfigModelCopyWithImpl;
@useResult
$Res call({
 BackgroundSource source, BoxFit boxFit, double maskOpacity, Color solidColor, List<Color> gradientColors, String? assetImagePath, String? localImagePath, String? networkImageUrl, String currentBoxImageBase64, String? assetVideoPath, String? localVideoPath, String? networkVideoUrl
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
@pragma('vm:prefer-inline') @override $Res call({Object? source = null,Object? boxFit = null,Object? maskOpacity = null,Object? solidColor = null,Object? gradientColors = null,Object? assetImagePath = freezed,Object? localImagePath = freezed,Object? networkImageUrl = freezed,Object? currentBoxImageBase64 = null,Object? assetVideoPath = freezed,Object? localVideoPath = freezed,Object? networkVideoUrl = freezed,}) {
  return _then(_self.copyWith(
source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as BackgroundSource,boxFit: null == boxFit ? _self.boxFit : boxFit // ignore: cast_nullable_to_non_nullable
as BoxFit,maskOpacity: null == maskOpacity ? _self.maskOpacity : maskOpacity // ignore: cast_nullable_to_non_nullable
as double,solidColor: null == solidColor ? _self.solidColor : solidColor // ignore: cast_nullable_to_non_nullable
as Color,gradientColors: null == gradientColors ? _self.gradientColors : gradientColors // ignore: cast_nullable_to_non_nullable
as List<Color>,assetImagePath: freezed == assetImagePath ? _self.assetImagePath : assetImagePath // ignore: cast_nullable_to_non_nullable
as String?,localImagePath: freezed == localImagePath ? _self.localImagePath : localImagePath // ignore: cast_nullable_to_non_nullable
as String?,networkImageUrl: freezed == networkImageUrl ? _self.networkImageUrl : networkImageUrl // ignore: cast_nullable_to_non_nullable
as String?,currentBoxImageBase64: null == currentBoxImageBase64 ? _self.currentBoxImageBase64 : currentBoxImageBase64 // ignore: cast_nullable_to_non_nullable
as String,assetVideoPath: freezed == assetVideoPath ? _self.assetVideoPath : assetVideoPath // ignore: cast_nullable_to_non_nullable
as String?,localVideoPath: freezed == localVideoPath ? _self.localVideoPath : localVideoPath // ignore: cast_nullable_to_non_nullable
as String?,networkVideoUrl: freezed == networkVideoUrl ? _self.networkVideoUrl : networkVideoUrl // ignore: cast_nullable_to_non_nullable
as String?,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( BackgroundSource source,  BoxFit boxFit,  double maskOpacity,  Color solidColor,  List<Color> gradientColors,  String? assetImagePath,  String? localImagePath,  String? networkImageUrl,  String currentBoxImageBase64,  String? assetVideoPath,  String? localVideoPath,  String? networkVideoUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BackgroundConfigModel() when $default != null:
return $default(_that.source,_that.boxFit,_that.maskOpacity,_that.solidColor,_that.gradientColors,_that.assetImagePath,_that.localImagePath,_that.networkImageUrl,_that.currentBoxImageBase64,_that.assetVideoPath,_that.localVideoPath,_that.networkVideoUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( BackgroundSource source,  BoxFit boxFit,  double maskOpacity,  Color solidColor,  List<Color> gradientColors,  String? assetImagePath,  String? localImagePath,  String? networkImageUrl,  String currentBoxImageBase64,  String? assetVideoPath,  String? localVideoPath,  String? networkVideoUrl)  $default,) {final _that = this;
switch (_that) {
case _BackgroundConfigModel():
return $default(_that.source,_that.boxFit,_that.maskOpacity,_that.solidColor,_that.gradientColors,_that.assetImagePath,_that.localImagePath,_that.networkImageUrl,_that.currentBoxImageBase64,_that.assetVideoPath,_that.localVideoPath,_that.networkVideoUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( BackgroundSource source,  BoxFit boxFit,  double maskOpacity,  Color solidColor,  List<Color> gradientColors,  String? assetImagePath,  String? localImagePath,  String? networkImageUrl,  String currentBoxImageBase64,  String? assetVideoPath,  String? localVideoPath,  String? networkVideoUrl)?  $default,) {final _that = this;
switch (_that) {
case _BackgroundConfigModel() when $default != null:
return $default(_that.source,_that.boxFit,_that.maskOpacity,_that.solidColor,_that.gradientColors,_that.assetImagePath,_that.localImagePath,_that.networkImageUrl,_that.currentBoxImageBase64,_that.assetVideoPath,_that.localVideoPath,_that.networkVideoUrl);case _:
  return null;

}
}

}

/// @nodoc


class _BackgroundConfigModel implements BackgroundConfigModel {
  const _BackgroundConfigModel({required this.source, required this.boxFit, required this.maskOpacity, required this.solidColor, required final  List<Color> gradientColors, this.assetImagePath, this.localImagePath, this.networkImageUrl, required this.currentBoxImageBase64, this.assetVideoPath, this.localVideoPath, this.networkVideoUrl}): _gradientColors = gradientColors;
  

@override final  BackgroundSource source;
@override final  BoxFit boxFit;
@override final  double maskOpacity;
@override final  Color solidColor;
 final  List<Color> _gradientColors;
@override List<Color> get gradientColors {
  if (_gradientColors is EqualUnmodifiableListView) return _gradientColors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_gradientColors);
}

@override final  String? assetImagePath;
@override final  String? localImagePath;
@override final  String? networkImageUrl;
@override final  String currentBoxImageBase64;
@override final  String? assetVideoPath;
@override final  String? localVideoPath;
@override final  String? networkVideoUrl;

/// Create a copy of BackgroundConfigModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BackgroundConfigModelCopyWith<_BackgroundConfigModel> get copyWith => __$BackgroundConfigModelCopyWithImpl<_BackgroundConfigModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BackgroundConfigModel&&(identical(other.source, source) || other.source == source)&&(identical(other.boxFit, boxFit) || other.boxFit == boxFit)&&(identical(other.maskOpacity, maskOpacity) || other.maskOpacity == maskOpacity)&&(identical(other.solidColor, solidColor) || other.solidColor == solidColor)&&const DeepCollectionEquality().equals(other._gradientColors, _gradientColors)&&(identical(other.assetImagePath, assetImagePath) || other.assetImagePath == assetImagePath)&&(identical(other.localImagePath, localImagePath) || other.localImagePath == localImagePath)&&(identical(other.networkImageUrl, networkImageUrl) || other.networkImageUrl == networkImageUrl)&&(identical(other.currentBoxImageBase64, currentBoxImageBase64) || other.currentBoxImageBase64 == currentBoxImageBase64)&&(identical(other.assetVideoPath, assetVideoPath) || other.assetVideoPath == assetVideoPath)&&(identical(other.localVideoPath, localVideoPath) || other.localVideoPath == localVideoPath)&&(identical(other.networkVideoUrl, networkVideoUrl) || other.networkVideoUrl == networkVideoUrl));
}


@override
int get hashCode => Object.hash(runtimeType,source,boxFit,maskOpacity,solidColor,const DeepCollectionEquality().hash(_gradientColors),assetImagePath,localImagePath,networkImageUrl,currentBoxImageBase64,assetVideoPath,localVideoPath,networkVideoUrl);

@override
String toString() {
  return 'BackgroundConfigModel(source: $source, boxFit: $boxFit, maskOpacity: $maskOpacity, solidColor: $solidColor, gradientColors: $gradientColors, assetImagePath: $assetImagePath, localImagePath: $localImagePath, networkImageUrl: $networkImageUrl, currentBoxImageBase64: $currentBoxImageBase64, assetVideoPath: $assetVideoPath, localVideoPath: $localVideoPath, networkVideoUrl: $networkVideoUrl)';
}


}

/// @nodoc
abstract mixin class _$BackgroundConfigModelCopyWith<$Res> implements $BackgroundConfigModelCopyWith<$Res> {
  factory _$BackgroundConfigModelCopyWith(_BackgroundConfigModel value, $Res Function(_BackgroundConfigModel) _then) = __$BackgroundConfigModelCopyWithImpl;
@override @useResult
$Res call({
 BackgroundSource source, BoxFit boxFit, double maskOpacity, Color solidColor, List<Color> gradientColors, String? assetImagePath, String? localImagePath, String? networkImageUrl, String currentBoxImageBase64, String? assetVideoPath, String? localVideoPath, String? networkVideoUrl
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
@override @pragma('vm:prefer-inline') $Res call({Object? source = null,Object? boxFit = null,Object? maskOpacity = null,Object? solidColor = null,Object? gradientColors = null,Object? assetImagePath = freezed,Object? localImagePath = freezed,Object? networkImageUrl = freezed,Object? currentBoxImageBase64 = null,Object? assetVideoPath = freezed,Object? localVideoPath = freezed,Object? networkVideoUrl = freezed,}) {
  return _then(_BackgroundConfigModel(
source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as BackgroundSource,boxFit: null == boxFit ? _self.boxFit : boxFit // ignore: cast_nullable_to_non_nullable
as BoxFit,maskOpacity: null == maskOpacity ? _self.maskOpacity : maskOpacity // ignore: cast_nullable_to_non_nullable
as double,solidColor: null == solidColor ? _self.solidColor : solidColor // ignore: cast_nullable_to_non_nullable
as Color,gradientColors: null == gradientColors ? _self._gradientColors : gradientColors // ignore: cast_nullable_to_non_nullable
as List<Color>,assetImagePath: freezed == assetImagePath ? _self.assetImagePath : assetImagePath // ignore: cast_nullable_to_non_nullable
as String?,localImagePath: freezed == localImagePath ? _self.localImagePath : localImagePath // ignore: cast_nullable_to_non_nullable
as String?,networkImageUrl: freezed == networkImageUrl ? _self.networkImageUrl : networkImageUrl // ignore: cast_nullable_to_non_nullable
as String?,currentBoxImageBase64: null == currentBoxImageBase64 ? _self.currentBoxImageBase64 : currentBoxImageBase64 // ignore: cast_nullable_to_non_nullable
as String,assetVideoPath: freezed == assetVideoPath ? _self.assetVideoPath : assetVideoPath // ignore: cast_nullable_to_non_nullable
as String?,localVideoPath: freezed == localVideoPath ? _self.localVideoPath : localVideoPath // ignore: cast_nullable_to_non_nullable
as String?,networkVideoUrl: freezed == networkVideoUrl ? _self.networkVideoUrl : networkVideoUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
