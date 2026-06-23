// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'theme_settings_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ThemeSettingsModel {

 String get themeModeName; bool get enableDynamicTheme;@HexColorConverter() Color get themeColor; String get languageName; double get crossAxisSpacing; double get mainAxisSpacing; String get loadingStyle;@HexColorConverter() Color? get loadingStyleColor;
/// Create a copy of ThemeSettingsModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ThemeSettingsModelCopyWith<ThemeSettingsModel> get copyWith => _$ThemeSettingsModelCopyWithImpl<ThemeSettingsModel>(this as ThemeSettingsModel, _$identity);

  /// Serializes this ThemeSettingsModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ThemeSettingsModel&&(identical(other.themeModeName, themeModeName) || other.themeModeName == themeModeName)&&(identical(other.enableDynamicTheme, enableDynamicTheme) || other.enableDynamicTheme == enableDynamicTheme)&&(identical(other.themeColor, themeColor) || other.themeColor == themeColor)&&(identical(other.languageName, languageName) || other.languageName == languageName)&&(identical(other.crossAxisSpacing, crossAxisSpacing) || other.crossAxisSpacing == crossAxisSpacing)&&(identical(other.mainAxisSpacing, mainAxisSpacing) || other.mainAxisSpacing == mainAxisSpacing)&&(identical(other.loadingStyle, loadingStyle) || other.loadingStyle == loadingStyle)&&(identical(other.loadingStyleColor, loadingStyleColor) || other.loadingStyleColor == loadingStyleColor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,themeModeName,enableDynamicTheme,themeColor,languageName,crossAxisSpacing,mainAxisSpacing,loadingStyle,loadingStyleColor);

@override
String toString() {
  return 'ThemeSettingsModel(themeModeName: $themeModeName, enableDynamicTheme: $enableDynamicTheme, themeColor: $themeColor, languageName: $languageName, crossAxisSpacing: $crossAxisSpacing, mainAxisSpacing: $mainAxisSpacing, loadingStyle: $loadingStyle, loadingStyleColor: $loadingStyleColor)';
}


}

/// @nodoc
abstract mixin class $ThemeSettingsModelCopyWith<$Res>  {
  factory $ThemeSettingsModelCopyWith(ThemeSettingsModel value, $Res Function(ThemeSettingsModel) _then) = _$ThemeSettingsModelCopyWithImpl;
@useResult
$Res call({
 String themeModeName, bool enableDynamicTheme,@HexColorConverter() Color themeColor, String languageName, double crossAxisSpacing, double mainAxisSpacing, String loadingStyle,@HexColorConverter() Color? loadingStyleColor
});




}
/// @nodoc
class _$ThemeSettingsModelCopyWithImpl<$Res>
    implements $ThemeSettingsModelCopyWith<$Res> {
  _$ThemeSettingsModelCopyWithImpl(this._self, this._then);

  final ThemeSettingsModel _self;
  final $Res Function(ThemeSettingsModel) _then;

/// Create a copy of ThemeSettingsModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? themeModeName = null,Object? enableDynamicTheme = null,Object? themeColor = null,Object? languageName = null,Object? crossAxisSpacing = null,Object? mainAxisSpacing = null,Object? loadingStyle = null,Object? loadingStyleColor = freezed,}) {
  return _then(_self.copyWith(
themeModeName: null == themeModeName ? _self.themeModeName : themeModeName // ignore: cast_nullable_to_non_nullable
as String,enableDynamicTheme: null == enableDynamicTheme ? _self.enableDynamicTheme : enableDynamicTheme // ignore: cast_nullable_to_non_nullable
as bool,themeColor: null == themeColor ? _self.themeColor : themeColor // ignore: cast_nullable_to_non_nullable
as Color,languageName: null == languageName ? _self.languageName : languageName // ignore: cast_nullable_to_non_nullable
as String,crossAxisSpacing: null == crossAxisSpacing ? _self.crossAxisSpacing : crossAxisSpacing // ignore: cast_nullable_to_non_nullable
as double,mainAxisSpacing: null == mainAxisSpacing ? _self.mainAxisSpacing : mainAxisSpacing // ignore: cast_nullable_to_non_nullable
as double,loadingStyle: null == loadingStyle ? _self.loadingStyle : loadingStyle // ignore: cast_nullable_to_non_nullable
as String,loadingStyleColor: freezed == loadingStyleColor ? _self.loadingStyleColor : loadingStyleColor // ignore: cast_nullable_to_non_nullable
as Color?,
  ));
}

}


/// Adds pattern-matching-related methods to [ThemeSettingsModel].
extension ThemeSettingsModelPatterns on ThemeSettingsModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ThemeSettingsModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ThemeSettingsModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ThemeSettingsModel value)  $default,){
final _that = this;
switch (_that) {
case _ThemeSettingsModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ThemeSettingsModel value)?  $default,){
final _that = this;
switch (_that) {
case _ThemeSettingsModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String themeModeName,  bool enableDynamicTheme, @HexColorConverter()  Color themeColor,  String languageName,  double crossAxisSpacing,  double mainAxisSpacing,  String loadingStyle, @HexColorConverter()  Color? loadingStyleColor)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ThemeSettingsModel() when $default != null:
return $default(_that.themeModeName,_that.enableDynamicTheme,_that.themeColor,_that.languageName,_that.crossAxisSpacing,_that.mainAxisSpacing,_that.loadingStyle,_that.loadingStyleColor);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String themeModeName,  bool enableDynamicTheme, @HexColorConverter()  Color themeColor,  String languageName,  double crossAxisSpacing,  double mainAxisSpacing,  String loadingStyle, @HexColorConverter()  Color? loadingStyleColor)  $default,) {final _that = this;
switch (_that) {
case _ThemeSettingsModel():
return $default(_that.themeModeName,_that.enableDynamicTheme,_that.themeColor,_that.languageName,_that.crossAxisSpacing,_that.mainAxisSpacing,_that.loadingStyle,_that.loadingStyleColor);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String themeModeName,  bool enableDynamicTheme, @HexColorConverter()  Color themeColor,  String languageName,  double crossAxisSpacing,  double mainAxisSpacing,  String loadingStyle, @HexColorConverter()  Color? loadingStyleColor)?  $default,) {final _that = this;
switch (_that) {
case _ThemeSettingsModel() when $default != null:
return $default(_that.themeModeName,_that.enableDynamicTheme,_that.themeColor,_that.languageName,_that.crossAxisSpacing,_that.mainAxisSpacing,_that.loadingStyle,_that.loadingStyleColor);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ThemeSettingsModel implements ThemeSettingsModel {
  const _ThemeSettingsModel({this.themeModeName = "System", this.enableDynamicTheme = false, @HexColorConverter() this.themeColor = Colors.blue, this.languageName = "简体中文", this.crossAxisSpacing = 6.0, this.mainAxisSpacing = 6.0, this.loadingStyle = "default", @HexColorConverter() this.loadingStyleColor});
  factory _ThemeSettingsModel.fromJson(Map<String, dynamic> json) => _$ThemeSettingsModelFromJson(json);

@override@JsonKey() final  String themeModeName;
@override@JsonKey() final  bool enableDynamicTheme;
@override@JsonKey()@HexColorConverter() final  Color themeColor;
@override@JsonKey() final  String languageName;
@override@JsonKey() final  double crossAxisSpacing;
@override@JsonKey() final  double mainAxisSpacing;
@override@JsonKey() final  String loadingStyle;
@override@HexColorConverter() final  Color? loadingStyleColor;

/// Create a copy of ThemeSettingsModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ThemeSettingsModelCopyWith<_ThemeSettingsModel> get copyWith => __$ThemeSettingsModelCopyWithImpl<_ThemeSettingsModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ThemeSettingsModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ThemeSettingsModel&&(identical(other.themeModeName, themeModeName) || other.themeModeName == themeModeName)&&(identical(other.enableDynamicTheme, enableDynamicTheme) || other.enableDynamicTheme == enableDynamicTheme)&&(identical(other.themeColor, themeColor) || other.themeColor == themeColor)&&(identical(other.languageName, languageName) || other.languageName == languageName)&&(identical(other.crossAxisSpacing, crossAxisSpacing) || other.crossAxisSpacing == crossAxisSpacing)&&(identical(other.mainAxisSpacing, mainAxisSpacing) || other.mainAxisSpacing == mainAxisSpacing)&&(identical(other.loadingStyle, loadingStyle) || other.loadingStyle == loadingStyle)&&(identical(other.loadingStyleColor, loadingStyleColor) || other.loadingStyleColor == loadingStyleColor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,themeModeName,enableDynamicTheme,themeColor,languageName,crossAxisSpacing,mainAxisSpacing,loadingStyle,loadingStyleColor);

@override
String toString() {
  return 'ThemeSettingsModel(themeModeName: $themeModeName, enableDynamicTheme: $enableDynamicTheme, themeColor: $themeColor, languageName: $languageName, crossAxisSpacing: $crossAxisSpacing, mainAxisSpacing: $mainAxisSpacing, loadingStyle: $loadingStyle, loadingStyleColor: $loadingStyleColor)';
}


}

/// @nodoc
abstract mixin class _$ThemeSettingsModelCopyWith<$Res> implements $ThemeSettingsModelCopyWith<$Res> {
  factory _$ThemeSettingsModelCopyWith(_ThemeSettingsModel value, $Res Function(_ThemeSettingsModel) _then) = __$ThemeSettingsModelCopyWithImpl;
@override @useResult
$Res call({
 String themeModeName, bool enableDynamicTheme,@HexColorConverter() Color themeColor, String languageName, double crossAxisSpacing, double mainAxisSpacing, String loadingStyle,@HexColorConverter() Color? loadingStyleColor
});




}
/// @nodoc
class __$ThemeSettingsModelCopyWithImpl<$Res>
    implements _$ThemeSettingsModelCopyWith<$Res> {
  __$ThemeSettingsModelCopyWithImpl(this._self, this._then);

  final _ThemeSettingsModel _self;
  final $Res Function(_ThemeSettingsModel) _then;

/// Create a copy of ThemeSettingsModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? themeModeName = null,Object? enableDynamicTheme = null,Object? themeColor = null,Object? languageName = null,Object? crossAxisSpacing = null,Object? mainAxisSpacing = null,Object? loadingStyle = null,Object? loadingStyleColor = freezed,}) {
  return _then(_ThemeSettingsModel(
themeModeName: null == themeModeName ? _self.themeModeName : themeModeName // ignore: cast_nullable_to_non_nullable
as String,enableDynamicTheme: null == enableDynamicTheme ? _self.enableDynamicTheme : enableDynamicTheme // ignore: cast_nullable_to_non_nullable
as bool,themeColor: null == themeColor ? _self.themeColor : themeColor // ignore: cast_nullable_to_non_nullable
as Color,languageName: null == languageName ? _self.languageName : languageName // ignore: cast_nullable_to_non_nullable
as String,crossAxisSpacing: null == crossAxisSpacing ? _self.crossAxisSpacing : crossAxisSpacing // ignore: cast_nullable_to_non_nullable
as double,mainAxisSpacing: null == mainAxisSpacing ? _self.mainAxisSpacing : mainAxisSpacing // ignore: cast_nullable_to_non_nullable
as double,loadingStyle: null == loadingStyle ? _self.loadingStyle : loadingStyle // ignore: cast_nullable_to_non_nullable
as String,loadingStyleColor: freezed == loadingStyleColor ? _self.loadingStyleColor : loadingStyleColor // ignore: cast_nullable_to_non_nullable
as Color?,
  ));
}


}

// dart format on
