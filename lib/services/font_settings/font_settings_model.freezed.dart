// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'font_settings_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FontSettingsModel {

 double get textScaleFactor; String get fontFamilyName;
/// Create a copy of FontSettingsModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FontSettingsModelCopyWith<FontSettingsModel> get copyWith => _$FontSettingsModelCopyWithImpl<FontSettingsModel>(this as FontSettingsModel, _$identity);

  /// Serializes this FontSettingsModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as FontSettingsModel;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FontSettingsModel&&(identical(other.textScaleFactor, _this.textScaleFactor) || other.textScaleFactor == _this.textScaleFactor)&&(identical(other.fontFamilyName, _this.fontFamilyName) || other.fontFamilyName == _this.fontFamilyName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as FontSettingsModel;
  return Object.hash(runtimeType,_this.textScaleFactor,_this.fontFamilyName);
}

@override
String toString() {
  final _this = this as FontSettingsModel;
  return 'FontSettingsModel(textScaleFactor: ${_this.textScaleFactor}, fontFamilyName: ${_this.fontFamilyName})';
}


}

/// @nodoc
abstract mixin class $FontSettingsModelCopyWith<$Res>  {
  factory $FontSettingsModelCopyWith(FontSettingsModel value, $Res Function(FontSettingsModel) _then) = _$FontSettingsModelCopyWithImpl;
@useResult
$Res call({
 double textScaleFactor, String fontFamilyName
});




}
/// @nodoc
class _$FontSettingsModelCopyWithImpl<$Res>
    implements $FontSettingsModelCopyWith<$Res> {
  _$FontSettingsModelCopyWithImpl(this._self, this._then);

  final FontSettingsModel _self;
  final $Res Function(FontSettingsModel) _then;

/// Create a copy of FontSettingsModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? textScaleFactor = null,Object? fontFamilyName = null,}) {
  return _then(FontSettingsModel(
textScaleFactor: null == textScaleFactor ? _self.textScaleFactor : textScaleFactor // ignore: cast_nullable_to_non_nullable
as double,fontFamilyName: null == fontFamilyName ? _self.fontFamilyName : fontFamilyName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [FontSettingsModel].
extension FontSettingsModelPatterns on FontSettingsModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FontSettingsModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FontSettingsModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FontSettingsModel value)  $default,){
final _that = this;
switch (_that) {
case _FontSettingsModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FontSettingsModel value)?  $default,){
final _that = this;
switch (_that) {
case _FontSettingsModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double textScaleFactor,  String fontFamilyName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FontSettingsModel() when $default != null:
return $default(_that.textScaleFactor,_that.fontFamilyName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double textScaleFactor,  String fontFamilyName)  $default,) {final _that = this;
switch (_that) {
case _FontSettingsModel():
return $default(_that.textScaleFactor,_that.fontFamilyName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double textScaleFactor,  String fontFamilyName)?  $default,) {final _that = this;
switch (_that) {
case _FontSettingsModel() when $default != null:
return $default(_that.textScaleFactor,_that.fontFamilyName);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FontSettingsModel implements FontSettingsModel {
  const _FontSettingsModel({this.textScaleFactor = 1.0, this.fontFamilyName = 'Default'});
  factory _FontSettingsModel.fromJson(Map<String, dynamic> json) => _$FontSettingsModelFromJson(json);

@override@JsonKey() final  double textScaleFactor;
@override@JsonKey() final  String fontFamilyName;

/// Create a copy of FontSettingsModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FontSettingsModelCopyWith<_FontSettingsModel> get copyWith => __$FontSettingsModelCopyWithImpl<_FontSettingsModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FontSettingsModelToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _FontSettingsModel&&(identical(other.textScaleFactor, textScaleFactor) || other.textScaleFactor == textScaleFactor)&&(identical(other.fontFamilyName, fontFamilyName) || other.fontFamilyName == fontFamilyName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,textScaleFactor,fontFamilyName);
}

@override
String toString() {
    return 'FontSettingsModel(textScaleFactor: $textScaleFactor, fontFamilyName: $fontFamilyName)';
}


}

/// @nodoc
abstract mixin class _$FontSettingsModelCopyWith<$Res> implements $FontSettingsModelCopyWith<$Res> {
  factory _$FontSettingsModelCopyWith(_FontSettingsModel value, $Res Function(_FontSettingsModel) _then) = __$FontSettingsModelCopyWithImpl;
@override @useResult
$Res call({
 double textScaleFactor, String fontFamilyName
});




}
/// @nodoc
class __$FontSettingsModelCopyWithImpl<$Res>
    implements _$FontSettingsModelCopyWith<$Res> {
  __$FontSettingsModelCopyWithImpl(this._self, this._then);

  final _FontSettingsModel _self;
  final $Res Function(_FontSettingsModel) _then;

/// Create a copy of FontSettingsModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? textScaleFactor = null,Object? fontFamilyName = null,}) {
  return _then(_FontSettingsModel(
textScaleFactor: null == textScaleFactor ? _self.textScaleFactor : textScaleFactor // ignore: cast_nullable_to_non_nullable
as double,fontFamilyName: null == fontFamilyName ? _self.fontFamilyName : fontFamilyName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
