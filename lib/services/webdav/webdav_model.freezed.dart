// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'webdav_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WebDavModel {

 String get currentWebDavConfig; List<WebDAVConfig> get webDavConfigs;
/// Create a copy of WebDavModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WebDavModelCopyWith<WebDavModel> get copyWith => _$WebDavModelCopyWithImpl<WebDavModel>(this as WebDavModel, _$identity);

  /// Serializes this WebDavModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WebDavModel&&(identical(other.currentWebDavConfig, currentWebDavConfig) || other.currentWebDavConfig == currentWebDavConfig)&&const DeepCollectionEquality().equals(other.webDavConfigs, webDavConfigs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,currentWebDavConfig,const DeepCollectionEquality().hash(webDavConfigs));

@override
String toString() {
  return 'WebDavModel(currentWebDavConfig: $currentWebDavConfig, webDavConfigs: $webDavConfigs)';
}


}

/// @nodoc
abstract mixin class $WebDavModelCopyWith<$Res>  {
  factory $WebDavModelCopyWith(WebDavModel value, $Res Function(WebDavModel) _then) = _$WebDavModelCopyWithImpl;
@useResult
$Res call({
 String currentWebDavConfig, List<WebDAVConfig> webDavConfigs
});




}
/// @nodoc
class _$WebDavModelCopyWithImpl<$Res>
    implements $WebDavModelCopyWith<$Res> {
  _$WebDavModelCopyWithImpl(this._self, this._then);

  final WebDavModel _self;
  final $Res Function(WebDavModel) _then;

/// Create a copy of WebDavModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? currentWebDavConfig = null,Object? webDavConfigs = null,}) {
  return _then(_self.copyWith(
currentWebDavConfig: null == currentWebDavConfig ? _self.currentWebDavConfig : currentWebDavConfig // ignore: cast_nullable_to_non_nullable
as String,webDavConfigs: null == webDavConfigs ? _self.webDavConfigs : webDavConfigs // ignore: cast_nullable_to_non_nullable
as List<WebDAVConfig>,
  ));
}

}


/// Adds pattern-matching-related methods to [WebDavModel].
extension WebDavModelPatterns on WebDavModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WebDavModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WebDavModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WebDavModel value)  $default,){
final _that = this;
switch (_that) {
case _WebDavModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WebDavModel value)?  $default,){
final _that = this;
switch (_that) {
case _WebDavModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String currentWebDavConfig,  List<WebDAVConfig> webDavConfigs)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WebDavModel() when $default != null:
return $default(_that.currentWebDavConfig,_that.webDavConfigs);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String currentWebDavConfig,  List<WebDAVConfig> webDavConfigs)  $default,) {final _that = this;
switch (_that) {
case _WebDavModel():
return $default(_that.currentWebDavConfig,_that.webDavConfigs);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String currentWebDavConfig,  List<WebDAVConfig> webDavConfigs)?  $default,) {final _that = this;
switch (_that) {
case _WebDavModel() when $default != null:
return $default(_that.currentWebDavConfig,_that.webDavConfigs);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WebDavModel implements WebDavModel {
  const _WebDavModel({this.currentWebDavConfig = '', final  List<WebDAVConfig> webDavConfigs = const []}): _webDavConfigs = webDavConfigs;
  factory _WebDavModel.fromJson(Map<String, dynamic> json) => _$WebDavModelFromJson(json);

@override@JsonKey() final  String currentWebDavConfig;
 final  List<WebDAVConfig> _webDavConfigs;
@override@JsonKey() List<WebDAVConfig> get webDavConfigs {
  if (_webDavConfigs is EqualUnmodifiableListView) return _webDavConfigs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_webDavConfigs);
}


/// Create a copy of WebDavModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WebDavModelCopyWith<_WebDavModel> get copyWith => __$WebDavModelCopyWithImpl<_WebDavModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WebDavModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WebDavModel&&(identical(other.currentWebDavConfig, currentWebDavConfig) || other.currentWebDavConfig == currentWebDavConfig)&&const DeepCollectionEquality().equals(other._webDavConfigs, _webDavConfigs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,currentWebDavConfig,const DeepCollectionEquality().hash(_webDavConfigs));

@override
String toString() {
  return 'WebDavModel(currentWebDavConfig: $currentWebDavConfig, webDavConfigs: $webDavConfigs)';
}


}

/// @nodoc
abstract mixin class _$WebDavModelCopyWith<$Res> implements $WebDavModelCopyWith<$Res> {
  factory _$WebDavModelCopyWith(_WebDavModel value, $Res Function(_WebDavModel) _then) = __$WebDavModelCopyWithImpl;
@override @useResult
$Res call({
 String currentWebDavConfig, List<WebDAVConfig> webDavConfigs
});




}
/// @nodoc
class __$WebDavModelCopyWithImpl<$Res>
    implements _$WebDavModelCopyWith<$Res> {
  __$WebDavModelCopyWithImpl(this._self, this._then);

  final _WebDavModel _self;
  final $Res Function(_WebDavModel) _then;

/// Create a copy of WebDavModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? currentWebDavConfig = null,Object? webDavConfigs = null,}) {
  return _then(_WebDavModel(
currentWebDavConfig: null == currentWebDavConfig ? _self.currentWebDavConfig : currentWebDavConfig // ignore: cast_nullable_to_non_nullable
as String,webDavConfigs: null == webDavConfigs ? _self._webDavConfigs : webDavConfigs // ignore: cast_nullable_to_non_nullable
as List<WebDAVConfig>,
  ));
}


}

// dart format on
