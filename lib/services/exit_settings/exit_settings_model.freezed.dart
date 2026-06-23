// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'exit_settings_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ExitSettingsModel {

 bool get dontAskExit; String get exitChoose; int get autoShutDownTime; bool get enableAutoShutDownTime;
/// Create a copy of ExitSettingsModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExitSettingsModelCopyWith<ExitSettingsModel> get copyWith => _$ExitSettingsModelCopyWithImpl<ExitSettingsModel>(this as ExitSettingsModel, _$identity);

  /// Serializes this ExitSettingsModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExitSettingsModel&&(identical(other.dontAskExit, dontAskExit) || other.dontAskExit == dontAskExit)&&(identical(other.exitChoose, exitChoose) || other.exitChoose == exitChoose)&&(identical(other.autoShutDownTime, autoShutDownTime) || other.autoShutDownTime == autoShutDownTime)&&(identical(other.enableAutoShutDownTime, enableAutoShutDownTime) || other.enableAutoShutDownTime == enableAutoShutDownTime));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,dontAskExit,exitChoose,autoShutDownTime,enableAutoShutDownTime);

@override
String toString() {
  return 'ExitSettingsModel(dontAskExit: $dontAskExit, exitChoose: $exitChoose, autoShutDownTime: $autoShutDownTime, enableAutoShutDownTime: $enableAutoShutDownTime)';
}


}

/// @nodoc
abstract mixin class $ExitSettingsModelCopyWith<$Res>  {
  factory $ExitSettingsModelCopyWith(ExitSettingsModel value, $Res Function(ExitSettingsModel) _then) = _$ExitSettingsModelCopyWithImpl;
@useResult
$Res call({
 bool dontAskExit, String exitChoose, int autoShutDownTime, bool enableAutoShutDownTime
});




}
/// @nodoc
class _$ExitSettingsModelCopyWithImpl<$Res>
    implements $ExitSettingsModelCopyWith<$Res> {
  _$ExitSettingsModelCopyWithImpl(this._self, this._then);

  final ExitSettingsModel _self;
  final $Res Function(ExitSettingsModel) _then;

/// Create a copy of ExitSettingsModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? dontAskExit = null,Object? exitChoose = null,Object? autoShutDownTime = null,Object? enableAutoShutDownTime = null,}) {
  return _then(_self.copyWith(
dontAskExit: null == dontAskExit ? _self.dontAskExit : dontAskExit // ignore: cast_nullable_to_non_nullable
as bool,exitChoose: null == exitChoose ? _self.exitChoose : exitChoose // ignore: cast_nullable_to_non_nullable
as String,autoShutDownTime: null == autoShutDownTime ? _self.autoShutDownTime : autoShutDownTime // ignore: cast_nullable_to_non_nullable
as int,enableAutoShutDownTime: null == enableAutoShutDownTime ? _self.enableAutoShutDownTime : enableAutoShutDownTime // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ExitSettingsModel].
extension ExitSettingsModelPatterns on ExitSettingsModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExitSettingsModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExitSettingsModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExitSettingsModel value)  $default,){
final _that = this;
switch (_that) {
case _ExitSettingsModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExitSettingsModel value)?  $default,){
final _that = this;
switch (_that) {
case _ExitSettingsModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool dontAskExit,  String exitChoose,  int autoShutDownTime,  bool enableAutoShutDownTime)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExitSettingsModel() when $default != null:
return $default(_that.dontAskExit,_that.exitChoose,_that.autoShutDownTime,_that.enableAutoShutDownTime);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool dontAskExit,  String exitChoose,  int autoShutDownTime,  bool enableAutoShutDownTime)  $default,) {final _that = this;
switch (_that) {
case _ExitSettingsModel():
return $default(_that.dontAskExit,_that.exitChoose,_that.autoShutDownTime,_that.enableAutoShutDownTime);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool dontAskExit,  String exitChoose,  int autoShutDownTime,  bool enableAutoShutDownTime)?  $default,) {final _that = this;
switch (_that) {
case _ExitSettingsModel() when $default != null:
return $default(_that.dontAskExit,_that.exitChoose,_that.autoShutDownTime,_that.enableAutoShutDownTime);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ExitSettingsModel implements ExitSettingsModel {
  const _ExitSettingsModel({this.dontAskExit = false, this.exitChoose = '', this.autoShutDownTime = 120, this.enableAutoShutDownTime = false});
  factory _ExitSettingsModel.fromJson(Map<String, dynamic> json) => _$ExitSettingsModelFromJson(json);

@override@JsonKey() final  bool dontAskExit;
@override@JsonKey() final  String exitChoose;
@override@JsonKey() final  int autoShutDownTime;
@override@JsonKey() final  bool enableAutoShutDownTime;

/// Create a copy of ExitSettingsModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExitSettingsModelCopyWith<_ExitSettingsModel> get copyWith => __$ExitSettingsModelCopyWithImpl<_ExitSettingsModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ExitSettingsModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExitSettingsModel&&(identical(other.dontAskExit, dontAskExit) || other.dontAskExit == dontAskExit)&&(identical(other.exitChoose, exitChoose) || other.exitChoose == exitChoose)&&(identical(other.autoShutDownTime, autoShutDownTime) || other.autoShutDownTime == autoShutDownTime)&&(identical(other.enableAutoShutDownTime, enableAutoShutDownTime) || other.enableAutoShutDownTime == enableAutoShutDownTime));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,dontAskExit,exitChoose,autoShutDownTime,enableAutoShutDownTime);

@override
String toString() {
  return 'ExitSettingsModel(dontAskExit: $dontAskExit, exitChoose: $exitChoose, autoShutDownTime: $autoShutDownTime, enableAutoShutDownTime: $enableAutoShutDownTime)';
}


}

/// @nodoc
abstract mixin class _$ExitSettingsModelCopyWith<$Res> implements $ExitSettingsModelCopyWith<$Res> {
  factory _$ExitSettingsModelCopyWith(_ExitSettingsModel value, $Res Function(_ExitSettingsModel) _then) = __$ExitSettingsModelCopyWithImpl;
@override @useResult
$Res call({
 bool dontAskExit, String exitChoose, int autoShutDownTime, bool enableAutoShutDownTime
});




}
/// @nodoc
class __$ExitSettingsModelCopyWithImpl<$Res>
    implements _$ExitSettingsModelCopyWith<$Res> {
  __$ExitSettingsModelCopyWithImpl(this._self, this._then);

  final _ExitSettingsModel _self;
  final $Res Function(_ExitSettingsModel) _then;

/// Create a copy of ExitSettingsModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? dontAskExit = null,Object? exitChoose = null,Object? autoShutDownTime = null,Object? enableAutoShutDownTime = null,}) {
  return _then(_ExitSettingsModel(
dontAskExit: null == dontAskExit ? _self.dontAskExit : dontAskExit // ignore: cast_nullable_to_non_nullable
as bool,exitChoose: null == exitChoose ? _self.exitChoose : exitChoose // ignore: cast_nullable_to_non_nullable
as String,autoShutDownTime: null == autoShutDownTime ? _self.autoShutDownTime : autoShutDownTime // ignore: cast_nullable_to_non_nullable
as int,enableAutoShutDownTime: null == enableAutoShutDownTime ? _self.enableAutoShutDownTime : enableAutoShutDownTime // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
