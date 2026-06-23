// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cache_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CacheModel {

 double get cacheSizeMB; double get refreshTurns;
/// Create a copy of CacheModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CacheModelCopyWith<CacheModel> get copyWith => _$CacheModelCopyWithImpl<CacheModel>(this as CacheModel, _$identity);

  /// Serializes this CacheModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CacheModel&&(identical(other.cacheSizeMB, cacheSizeMB) || other.cacheSizeMB == cacheSizeMB)&&(identical(other.refreshTurns, refreshTurns) || other.refreshTurns == refreshTurns));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,cacheSizeMB,refreshTurns);

@override
String toString() {
  return 'CacheModel(cacheSizeMB: $cacheSizeMB, refreshTurns: $refreshTurns)';
}


}

/// @nodoc
abstract mixin class $CacheModelCopyWith<$Res>  {
  factory $CacheModelCopyWith(CacheModel value, $Res Function(CacheModel) _then) = _$CacheModelCopyWithImpl;
@useResult
$Res call({
 double cacheSizeMB, double refreshTurns
});




}
/// @nodoc
class _$CacheModelCopyWithImpl<$Res>
    implements $CacheModelCopyWith<$Res> {
  _$CacheModelCopyWithImpl(this._self, this._then);

  final CacheModel _self;
  final $Res Function(CacheModel) _then;

/// Create a copy of CacheModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? cacheSizeMB = null,Object? refreshTurns = null,}) {
  return _then(_self.copyWith(
cacheSizeMB: null == cacheSizeMB ? _self.cacheSizeMB : cacheSizeMB // ignore: cast_nullable_to_non_nullable
as double,refreshTurns: null == refreshTurns ? _self.refreshTurns : refreshTurns // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [CacheModel].
extension CacheModelPatterns on CacheModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CacheModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CacheModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CacheModel value)  $default,){
final _that = this;
switch (_that) {
case _CacheModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CacheModel value)?  $default,){
final _that = this;
switch (_that) {
case _CacheModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double cacheSizeMB,  double refreshTurns)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CacheModel() when $default != null:
return $default(_that.cacheSizeMB,_that.refreshTurns);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double cacheSizeMB,  double refreshTurns)  $default,) {final _that = this;
switch (_that) {
case _CacheModel():
return $default(_that.cacheSizeMB,_that.refreshTurns);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double cacheSizeMB,  double refreshTurns)?  $default,) {final _that = this;
switch (_that) {
case _CacheModel() when $default != null:
return $default(_that.cacheSizeMB,_that.refreshTurns);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CacheModel implements CacheModel {
  const _CacheModel({this.cacheSizeMB = 0.0, this.refreshTurns = 0.0});
  factory _CacheModel.fromJson(Map<String, dynamic> json) => _$CacheModelFromJson(json);

@override@JsonKey() final  double cacheSizeMB;
@override@JsonKey() final  double refreshTurns;

/// Create a copy of CacheModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CacheModelCopyWith<_CacheModel> get copyWith => __$CacheModelCopyWithImpl<_CacheModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CacheModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CacheModel&&(identical(other.cacheSizeMB, cacheSizeMB) || other.cacheSizeMB == cacheSizeMB)&&(identical(other.refreshTurns, refreshTurns) || other.refreshTurns == refreshTurns));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,cacheSizeMB,refreshTurns);

@override
String toString() {
  return 'CacheModel(cacheSizeMB: $cacheSizeMB, refreshTurns: $refreshTurns)';
}


}

/// @nodoc
abstract mixin class _$CacheModelCopyWith<$Res> implements $CacheModelCopyWith<$Res> {
  factory _$CacheModelCopyWith(_CacheModel value, $Res Function(_CacheModel) _then) = __$CacheModelCopyWithImpl;
@override @useResult
$Res call({
 double cacheSizeMB, double refreshTurns
});




}
/// @nodoc
class __$CacheModelCopyWithImpl<$Res>
    implements _$CacheModelCopyWith<$Res> {
  __$CacheModelCopyWithImpl(this._self, this._then);

  final _CacheModel _self;
  final $Res Function(_CacheModel) _then;

/// Create a copy of CacheModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? cacheSizeMB = null,Object? refreshTurns = null,}) {
  return _then(_CacheModel(
cacheSizeMB: null == cacheSizeMB ? _self.cacheSizeMB : cacheSizeMB // ignore: cast_nullable_to_non_nullable
as double,refreshTurns: null == refreshTurns ? _self.refreshTurns : refreshTurns // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
