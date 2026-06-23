// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'proxy_settings_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProxySettingsModel {

 bool get enableProxy; String get proxyHost; int get proxyPort; bool get enableAppProxy; String get appProxyHost; int get appProxyPort;
/// Create a copy of ProxySettingsModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProxySettingsModelCopyWith<ProxySettingsModel> get copyWith => _$ProxySettingsModelCopyWithImpl<ProxySettingsModel>(this as ProxySettingsModel, _$identity);

  /// Serializes this ProxySettingsModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProxySettingsModel&&(identical(other.enableProxy, enableProxy) || other.enableProxy == enableProxy)&&(identical(other.proxyHost, proxyHost) || other.proxyHost == proxyHost)&&(identical(other.proxyPort, proxyPort) || other.proxyPort == proxyPort)&&(identical(other.enableAppProxy, enableAppProxy) || other.enableAppProxy == enableAppProxy)&&(identical(other.appProxyHost, appProxyHost) || other.appProxyHost == appProxyHost)&&(identical(other.appProxyPort, appProxyPort) || other.appProxyPort == appProxyPort));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,enableProxy,proxyHost,proxyPort,enableAppProxy,appProxyHost,appProxyPort);

@override
String toString() {
  return 'ProxySettingsModel(enableProxy: $enableProxy, proxyHost: $proxyHost, proxyPort: $proxyPort, enableAppProxy: $enableAppProxy, appProxyHost: $appProxyHost, appProxyPort: $appProxyPort)';
}


}

/// @nodoc
abstract mixin class $ProxySettingsModelCopyWith<$Res>  {
  factory $ProxySettingsModelCopyWith(ProxySettingsModel value, $Res Function(ProxySettingsModel) _then) = _$ProxySettingsModelCopyWithImpl;
@useResult
$Res call({
 bool enableProxy, String proxyHost, int proxyPort, bool enableAppProxy, String appProxyHost, int appProxyPort
});




}
/// @nodoc
class _$ProxySettingsModelCopyWithImpl<$Res>
    implements $ProxySettingsModelCopyWith<$Res> {
  _$ProxySettingsModelCopyWithImpl(this._self, this._then);

  final ProxySettingsModel _self;
  final $Res Function(ProxySettingsModel) _then;

/// Create a copy of ProxySettingsModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? enableProxy = null,Object? proxyHost = null,Object? proxyPort = null,Object? enableAppProxy = null,Object? appProxyHost = null,Object? appProxyPort = null,}) {
  return _then(_self.copyWith(
enableProxy: null == enableProxy ? _self.enableProxy : enableProxy // ignore: cast_nullable_to_non_nullable
as bool,proxyHost: null == proxyHost ? _self.proxyHost : proxyHost // ignore: cast_nullable_to_non_nullable
as String,proxyPort: null == proxyPort ? _self.proxyPort : proxyPort // ignore: cast_nullable_to_non_nullable
as int,enableAppProxy: null == enableAppProxy ? _self.enableAppProxy : enableAppProxy // ignore: cast_nullable_to_non_nullable
as bool,appProxyHost: null == appProxyHost ? _self.appProxyHost : appProxyHost // ignore: cast_nullable_to_non_nullable
as String,appProxyPort: null == appProxyPort ? _self.appProxyPort : appProxyPort // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ProxySettingsModel].
extension ProxySettingsModelPatterns on ProxySettingsModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProxySettingsModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProxySettingsModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProxySettingsModel value)  $default,){
final _that = this;
switch (_that) {
case _ProxySettingsModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProxySettingsModel value)?  $default,){
final _that = this;
switch (_that) {
case _ProxySettingsModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool enableProxy,  String proxyHost,  int proxyPort,  bool enableAppProxy,  String appProxyHost,  int appProxyPort)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProxySettingsModel() when $default != null:
return $default(_that.enableProxy,_that.proxyHost,_that.proxyPort,_that.enableAppProxy,_that.appProxyHost,_that.appProxyPort);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool enableProxy,  String proxyHost,  int proxyPort,  bool enableAppProxy,  String appProxyHost,  int appProxyPort)  $default,) {final _that = this;
switch (_that) {
case _ProxySettingsModel():
return $default(_that.enableProxy,_that.proxyHost,_that.proxyPort,_that.enableAppProxy,_that.appProxyHost,_that.appProxyPort);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool enableProxy,  String proxyHost,  int proxyPort,  bool enableAppProxy,  String appProxyHost,  int appProxyPort)?  $default,) {final _that = this;
switch (_that) {
case _ProxySettingsModel() when $default != null:
return $default(_that.enableProxy,_that.proxyHost,_that.proxyPort,_that.enableAppProxy,_that.appProxyHost,_that.appProxyPort);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProxySettingsModel implements ProxySettingsModel {
  const _ProxySettingsModel({this.enableProxy = false, this.proxyHost = '', this.proxyPort = 7897, this.enableAppProxy = false, this.appProxyHost = '', this.appProxyPort = 7897});
  factory _ProxySettingsModel.fromJson(Map<String, dynamic> json) => _$ProxySettingsModelFromJson(json);

@override@JsonKey() final  bool enableProxy;
@override@JsonKey() final  String proxyHost;
@override@JsonKey() final  int proxyPort;
@override@JsonKey() final  bool enableAppProxy;
@override@JsonKey() final  String appProxyHost;
@override@JsonKey() final  int appProxyPort;

/// Create a copy of ProxySettingsModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProxySettingsModelCopyWith<_ProxySettingsModel> get copyWith => __$ProxySettingsModelCopyWithImpl<_ProxySettingsModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProxySettingsModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProxySettingsModel&&(identical(other.enableProxy, enableProxy) || other.enableProxy == enableProxy)&&(identical(other.proxyHost, proxyHost) || other.proxyHost == proxyHost)&&(identical(other.proxyPort, proxyPort) || other.proxyPort == proxyPort)&&(identical(other.enableAppProxy, enableAppProxy) || other.enableAppProxy == enableAppProxy)&&(identical(other.appProxyHost, appProxyHost) || other.appProxyHost == appProxyHost)&&(identical(other.appProxyPort, appProxyPort) || other.appProxyPort == appProxyPort));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,enableProxy,proxyHost,proxyPort,enableAppProxy,appProxyHost,appProxyPort);

@override
String toString() {
  return 'ProxySettingsModel(enableProxy: $enableProxy, proxyHost: $proxyHost, proxyPort: $proxyPort, enableAppProxy: $enableAppProxy, appProxyHost: $appProxyHost, appProxyPort: $appProxyPort)';
}


}

/// @nodoc
abstract mixin class _$ProxySettingsModelCopyWith<$Res> implements $ProxySettingsModelCopyWith<$Res> {
  factory _$ProxySettingsModelCopyWith(_ProxySettingsModel value, $Res Function(_ProxySettingsModel) _then) = __$ProxySettingsModelCopyWithImpl;
@override @useResult
$Res call({
 bool enableProxy, String proxyHost, int proxyPort, bool enableAppProxy, String appProxyHost, int appProxyPort
});




}
/// @nodoc
class __$ProxySettingsModelCopyWithImpl<$Res>
    implements _$ProxySettingsModelCopyWith<$Res> {
  __$ProxySettingsModelCopyWithImpl(this._self, this._then);

  final _ProxySettingsModel _self;
  final $Res Function(_ProxySettingsModel) _then;

/// Create a copy of ProxySettingsModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? enableProxy = null,Object? proxyHost = null,Object? proxyPort = null,Object? enableAppProxy = null,Object? appProxyHost = null,Object? appProxyPort = null,}) {
  return _then(_ProxySettingsModel(
enableProxy: null == enableProxy ? _self.enableProxy : enableProxy // ignore: cast_nullable_to_non_nullable
as bool,proxyHost: null == proxyHost ? _self.proxyHost : proxyHost // ignore: cast_nullable_to_non_nullable
as String,proxyPort: null == proxyPort ? _self.proxyPort : proxyPort // ignore: cast_nullable_to_non_nullable
as int,enableAppProxy: null == enableAppProxy ? _self.enableAppProxy : enableAppProxy // ignore: cast_nullable_to_non_nullable
as bool,appProxyHost: null == appProxyHost ? _self.appProxyHost : appProxyHost // ignore: cast_nullable_to_non_nullable
as String,appProxyPort: null == appProxyPort ? _self.appProxyPort : appProxyPort // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
