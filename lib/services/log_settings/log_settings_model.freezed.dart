// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'log_settings_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LogSettingsModel {

 String get serverAddress; int get serverPort; bool get storedEnableLog;
/// Create a copy of LogSettingsModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LogSettingsModelCopyWith<LogSettingsModel> get copyWith => _$LogSettingsModelCopyWithImpl<LogSettingsModel>(this as LogSettingsModel, _$identity);

  /// Serializes this LogSettingsModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LogSettingsModel&&(identical(other.serverAddress, serverAddress) || other.serverAddress == serverAddress)&&(identical(other.serverPort, serverPort) || other.serverPort == serverPort)&&(identical(other.storedEnableLog, storedEnableLog) || other.storedEnableLog == storedEnableLog));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,serverAddress,serverPort,storedEnableLog);

@override
String toString() {
  return 'LogSettingsModel(serverAddress: $serverAddress, serverPort: $serverPort, storedEnableLog: $storedEnableLog)';
}


}

/// @nodoc
abstract mixin class $LogSettingsModelCopyWith<$Res>  {
  factory $LogSettingsModelCopyWith(LogSettingsModel value, $Res Function(LogSettingsModel) _then) = _$LogSettingsModelCopyWithImpl;
@useResult
$Res call({
 String serverAddress, int serverPort, bool storedEnableLog
});




}
/// @nodoc
class _$LogSettingsModelCopyWithImpl<$Res>
    implements $LogSettingsModelCopyWith<$Res> {
  _$LogSettingsModelCopyWithImpl(this._self, this._then);

  final LogSettingsModel _self;
  final $Res Function(LogSettingsModel) _then;

/// Create a copy of LogSettingsModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? serverAddress = null,Object? serverPort = null,Object? storedEnableLog = null,}) {
  return _then(_self.copyWith(
serverAddress: null == serverAddress ? _self.serverAddress : serverAddress // ignore: cast_nullable_to_non_nullable
as String,serverPort: null == serverPort ? _self.serverPort : serverPort // ignore: cast_nullable_to_non_nullable
as int,storedEnableLog: null == storedEnableLog ? _self.storedEnableLog : storedEnableLog // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [LogSettingsModel].
extension LogSettingsModelPatterns on LogSettingsModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LogSettingsModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LogSettingsModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LogSettingsModel value)  $default,){
final _that = this;
switch (_that) {
case _LogSettingsModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LogSettingsModel value)?  $default,){
final _that = this;
switch (_that) {
case _LogSettingsModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String serverAddress,  int serverPort,  bool storedEnableLog)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LogSettingsModel() when $default != null:
return $default(_that.serverAddress,_that.serverPort,_that.storedEnableLog);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String serverAddress,  int serverPort,  bool storedEnableLog)  $default,) {final _that = this;
switch (_that) {
case _LogSettingsModel():
return $default(_that.serverAddress,_that.serverPort,_that.storedEnableLog);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String serverAddress,  int serverPort,  bool storedEnableLog)?  $default,) {final _that = this;
switch (_that) {
case _LogSettingsModel() when $default != null:
return $default(_that.serverAddress,_that.serverPort,_that.storedEnableLog);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LogSettingsModel implements LogSettingsModel {
  const _LogSettingsModel({this.serverAddress = '', this.serverPort = 7890, this.storedEnableLog = false});
  factory _LogSettingsModel.fromJson(Map<String, dynamic> json) => _$LogSettingsModelFromJson(json);

@override@JsonKey() final  String serverAddress;
@override@JsonKey() final  int serverPort;
@override@JsonKey() final  bool storedEnableLog;

/// Create a copy of LogSettingsModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LogSettingsModelCopyWith<_LogSettingsModel> get copyWith => __$LogSettingsModelCopyWithImpl<_LogSettingsModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LogSettingsModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LogSettingsModel&&(identical(other.serverAddress, serverAddress) || other.serverAddress == serverAddress)&&(identical(other.serverPort, serverPort) || other.serverPort == serverPort)&&(identical(other.storedEnableLog, storedEnableLog) || other.storedEnableLog == storedEnableLog));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,serverAddress,serverPort,storedEnableLog);

@override
String toString() {
  return 'LogSettingsModel(serverAddress: $serverAddress, serverPort: $serverPort, storedEnableLog: $storedEnableLog)';
}


}

/// @nodoc
abstract mixin class _$LogSettingsModelCopyWith<$Res> implements $LogSettingsModelCopyWith<$Res> {
  factory _$LogSettingsModelCopyWith(_LogSettingsModel value, $Res Function(_LogSettingsModel) _then) = __$LogSettingsModelCopyWithImpl;
@override @useResult
$Res call({
 String serverAddress, int serverPort, bool storedEnableLog
});




}
/// @nodoc
class __$LogSettingsModelCopyWithImpl<$Res>
    implements _$LogSettingsModelCopyWith<$Res> {
  __$LogSettingsModelCopyWithImpl(this._self, this._then);

  final _LogSettingsModel _self;
  final $Res Function(_LogSettingsModel) _then;

/// Create a copy of LogSettingsModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? serverAddress = null,Object? serverPort = null,Object? storedEnableLog = null,}) {
  return _then(_LogSettingsModel(
serverAddress: null == serverAddress ? _self.serverAddress : serverAddress // ignore: cast_nullable_to_non_nullable
as String,serverPort: null == serverPort ? _self.serverPort : serverPort // ignore: cast_nullable_to_non_nullable
as int,storedEnableLog: null == storedEnableLog ? _self.storedEnableLog : storedEnableLog // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
