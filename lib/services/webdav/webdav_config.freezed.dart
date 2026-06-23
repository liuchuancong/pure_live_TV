// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'webdav_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WebDAVConfig {

 String get name; String get address; String get username; String get password;
/// Create a copy of WebDAVConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WebDAVConfigCopyWith<WebDAVConfig> get copyWith => _$WebDAVConfigCopyWithImpl<WebDAVConfig>(this as WebDAVConfig, _$identity);

  /// Serializes this WebDAVConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WebDAVConfig&&(identical(other.name, name) || other.name == name)&&(identical(other.address, address) || other.address == address)&&(identical(other.username, username) || other.username == username)&&(identical(other.password, password) || other.password == password));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,address,username,password);

@override
String toString() {
  return 'WebDAVConfig(name: $name, address: $address, username: $username, password: $password)';
}


}

/// @nodoc
abstract mixin class $WebDAVConfigCopyWith<$Res>  {
  factory $WebDAVConfigCopyWith(WebDAVConfig value, $Res Function(WebDAVConfig) _then) = _$WebDAVConfigCopyWithImpl;
@useResult
$Res call({
 String name, String address, String username, String password
});




}
/// @nodoc
class _$WebDAVConfigCopyWithImpl<$Res>
    implements $WebDAVConfigCopyWith<$Res> {
  _$WebDAVConfigCopyWithImpl(this._self, this._then);

  final WebDAVConfig _self;
  final $Res Function(WebDAVConfig) _then;

/// Create a copy of WebDAVConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? address = null,Object? username = null,Object? password = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [WebDAVConfig].
extension WebDAVConfigPatterns on WebDAVConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WebDAVConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WebDAVConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WebDAVConfig value)  $default,){
final _that = this;
switch (_that) {
case _WebDAVConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WebDAVConfig value)?  $default,){
final _that = this;
switch (_that) {
case _WebDAVConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String address,  String username,  String password)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WebDAVConfig() when $default != null:
return $default(_that.name,_that.address,_that.username,_that.password);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String address,  String username,  String password)  $default,) {final _that = this;
switch (_that) {
case _WebDAVConfig():
return $default(_that.name,_that.address,_that.username,_that.password);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String address,  String username,  String password)?  $default,) {final _that = this;
switch (_that) {
case _WebDAVConfig() when $default != null:
return $default(_that.name,_that.address,_that.username,_that.password);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WebDAVConfig extends WebDAVConfig {
  const _WebDAVConfig({this.name = '', this.address = '', this.username = '', this.password = ''}): super._();
  factory _WebDAVConfig.fromJson(Map<String, dynamic> json) => _$WebDAVConfigFromJson(json);

@override@JsonKey() final  String name;
@override@JsonKey() final  String address;
@override@JsonKey() final  String username;
@override@JsonKey() final  String password;

/// Create a copy of WebDAVConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WebDAVConfigCopyWith<_WebDAVConfig> get copyWith => __$WebDAVConfigCopyWithImpl<_WebDAVConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WebDAVConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WebDAVConfig&&(identical(other.name, name) || other.name == name)&&(identical(other.address, address) || other.address == address)&&(identical(other.username, username) || other.username == username)&&(identical(other.password, password) || other.password == password));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,address,username,password);

@override
String toString() {
  return 'WebDAVConfig(name: $name, address: $address, username: $username, password: $password)';
}


}

/// @nodoc
abstract mixin class _$WebDAVConfigCopyWith<$Res> implements $WebDAVConfigCopyWith<$Res> {
  factory _$WebDAVConfigCopyWith(_WebDAVConfig value, $Res Function(_WebDAVConfig) _then) = __$WebDAVConfigCopyWithImpl;
@override @useResult
$Res call({
 String name, String address, String username, String password
});




}
/// @nodoc
class __$WebDAVConfigCopyWithImpl<$Res>
    implements _$WebDAVConfigCopyWith<$Res> {
  __$WebDAVConfigCopyWithImpl(this._self, this._then);

  final _WebDAVConfig _self;
  final $Res Function(_WebDAVConfig) _then;

/// Create a copy of WebDAVConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? address = null,Object? username = null,Object? password = null,}) {
  return _then(_WebDAVConfig(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
