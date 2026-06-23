// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'refresh_config_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RefreshConfigModel {

 bool get autoRefreshFavorite; int get autoRefreshInterval; int get maxConcurrentRefresh;
/// Create a copy of RefreshConfigModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RefreshConfigModelCopyWith<RefreshConfigModel> get copyWith => _$RefreshConfigModelCopyWithImpl<RefreshConfigModel>(this as RefreshConfigModel, _$identity);

  /// Serializes this RefreshConfigModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RefreshConfigModel&&(identical(other.autoRefreshFavorite, autoRefreshFavorite) || other.autoRefreshFavorite == autoRefreshFavorite)&&(identical(other.autoRefreshInterval, autoRefreshInterval) || other.autoRefreshInterval == autoRefreshInterval)&&(identical(other.maxConcurrentRefresh, maxConcurrentRefresh) || other.maxConcurrentRefresh == maxConcurrentRefresh));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,autoRefreshFavorite,autoRefreshInterval,maxConcurrentRefresh);

@override
String toString() {
  return 'RefreshConfigModel(autoRefreshFavorite: $autoRefreshFavorite, autoRefreshInterval: $autoRefreshInterval, maxConcurrentRefresh: $maxConcurrentRefresh)';
}


}

/// @nodoc
abstract mixin class $RefreshConfigModelCopyWith<$Res>  {
  factory $RefreshConfigModelCopyWith(RefreshConfigModel value, $Res Function(RefreshConfigModel) _then) = _$RefreshConfigModelCopyWithImpl;
@useResult
$Res call({
 bool autoRefreshFavorite, int autoRefreshInterval, int maxConcurrentRefresh
});




}
/// @nodoc
class _$RefreshConfigModelCopyWithImpl<$Res>
    implements $RefreshConfigModelCopyWith<$Res> {
  _$RefreshConfigModelCopyWithImpl(this._self, this._then);

  final RefreshConfigModel _self;
  final $Res Function(RefreshConfigModel) _then;

/// Create a copy of RefreshConfigModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? autoRefreshFavorite = null,Object? autoRefreshInterval = null,Object? maxConcurrentRefresh = null,}) {
  return _then(_self.copyWith(
autoRefreshFavorite: null == autoRefreshFavorite ? _self.autoRefreshFavorite : autoRefreshFavorite // ignore: cast_nullable_to_non_nullable
as bool,autoRefreshInterval: null == autoRefreshInterval ? _self.autoRefreshInterval : autoRefreshInterval // ignore: cast_nullable_to_non_nullable
as int,maxConcurrentRefresh: null == maxConcurrentRefresh ? _self.maxConcurrentRefresh : maxConcurrentRefresh // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [RefreshConfigModel].
extension RefreshConfigModelPatterns on RefreshConfigModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RefreshConfigModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RefreshConfigModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RefreshConfigModel value)  $default,){
final _that = this;
switch (_that) {
case _RefreshConfigModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RefreshConfigModel value)?  $default,){
final _that = this;
switch (_that) {
case _RefreshConfigModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool autoRefreshFavorite,  int autoRefreshInterval,  int maxConcurrentRefresh)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RefreshConfigModel() when $default != null:
return $default(_that.autoRefreshFavorite,_that.autoRefreshInterval,_that.maxConcurrentRefresh);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool autoRefreshFavorite,  int autoRefreshInterval,  int maxConcurrentRefresh)  $default,) {final _that = this;
switch (_that) {
case _RefreshConfigModel():
return $default(_that.autoRefreshFavorite,_that.autoRefreshInterval,_that.maxConcurrentRefresh);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool autoRefreshFavorite,  int autoRefreshInterval,  int maxConcurrentRefresh)?  $default,) {final _that = this;
switch (_that) {
case _RefreshConfigModel() when $default != null:
return $default(_that.autoRefreshFavorite,_that.autoRefreshInterval,_that.maxConcurrentRefresh);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RefreshConfigModel implements RefreshConfigModel {
  const _RefreshConfigModel({this.autoRefreshFavorite = false, this.autoRefreshInterval = 30, this.maxConcurrentRefresh = 2});
  factory _RefreshConfigModel.fromJson(Map<String, dynamic> json) => _$RefreshConfigModelFromJson(json);

@override@JsonKey() final  bool autoRefreshFavorite;
@override@JsonKey() final  int autoRefreshInterval;
@override@JsonKey() final  int maxConcurrentRefresh;

/// Create a copy of RefreshConfigModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RefreshConfigModelCopyWith<_RefreshConfigModel> get copyWith => __$RefreshConfigModelCopyWithImpl<_RefreshConfigModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RefreshConfigModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RefreshConfigModel&&(identical(other.autoRefreshFavorite, autoRefreshFavorite) || other.autoRefreshFavorite == autoRefreshFavorite)&&(identical(other.autoRefreshInterval, autoRefreshInterval) || other.autoRefreshInterval == autoRefreshInterval)&&(identical(other.maxConcurrentRefresh, maxConcurrentRefresh) || other.maxConcurrentRefresh == maxConcurrentRefresh));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,autoRefreshFavorite,autoRefreshInterval,maxConcurrentRefresh);

@override
String toString() {
  return 'RefreshConfigModel(autoRefreshFavorite: $autoRefreshFavorite, autoRefreshInterval: $autoRefreshInterval, maxConcurrentRefresh: $maxConcurrentRefresh)';
}


}

/// @nodoc
abstract mixin class _$RefreshConfigModelCopyWith<$Res> implements $RefreshConfigModelCopyWith<$Res> {
  factory _$RefreshConfigModelCopyWith(_RefreshConfigModel value, $Res Function(_RefreshConfigModel) _then) = __$RefreshConfigModelCopyWithImpl;
@override @useResult
$Res call({
 bool autoRefreshFavorite, int autoRefreshInterval, int maxConcurrentRefresh
});




}
/// @nodoc
class __$RefreshConfigModelCopyWithImpl<$Res>
    implements _$RefreshConfigModelCopyWith<$Res> {
  __$RefreshConfigModelCopyWithImpl(this._self, this._then);

  final _RefreshConfigModel _self;
  final $Res Function(_RefreshConfigModel) _then;

/// Create a copy of RefreshConfigModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? autoRefreshFavorite = null,Object? autoRefreshInterval = null,Object? maxConcurrentRefresh = null,}) {
  return _then(_RefreshConfigModel(
autoRefreshFavorite: null == autoRefreshFavorite ? _self.autoRefreshFavorite : autoRefreshFavorite // ignore: cast_nullable_to_non_nullable
as bool,autoRefreshInterval: null == autoRefreshInterval ? _self.autoRefreshInterval : autoRefreshInterval // ignore: cast_nullable_to_non_nullable
as int,maxConcurrentRefresh: null == maxConcurrentRefresh ? _self.maxConcurrentRefresh : maxConcurrentRefresh // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
