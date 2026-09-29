// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'music_up.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MusicUp {

 int get mid; String get name; String get face;
/// Create a copy of MusicUp
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MusicUpCopyWith<MusicUp> get copyWith => _$MusicUpCopyWithImpl<MusicUp>(this as MusicUp, _$identity);

  /// Serializes this MusicUp to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as MusicUp;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MusicUp&&(identical(other.mid, _this.mid) || other.mid == _this.mid)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.face, _this.face) || other.face == _this.face));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as MusicUp;
  return Object.hash(runtimeType,_this.mid,_this.name,_this.face);
}

@override
String toString() {
  final _this = this as MusicUp;
  return 'MusicUp(mid: ${_this.mid}, name: ${_this.name}, face: ${_this.face})';
}


}

/// @nodoc
abstract mixin class $MusicUpCopyWith<$Res>  {
  factory $MusicUpCopyWith(MusicUp value, $Res Function(MusicUp) _then) = _$MusicUpCopyWithImpl;
@useResult
$Res call({
 int mid, String name, String face
});




}
/// @nodoc
class _$MusicUpCopyWithImpl<$Res>
    implements $MusicUpCopyWith<$Res> {
  _$MusicUpCopyWithImpl(this._self, this._then);

  final MusicUp _self;
  final $Res Function(MusicUp) _then;

/// Create a copy of MusicUp
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? mid = null,Object? name = null,Object? face = null,}) {
  return _then(MusicUp(
mid: null == mid ? _self.mid : mid // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,face: null == face ? _self.face : face // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [MusicUp].
extension MusicUpPatterns on MusicUp {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MusicUp value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MusicUp() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MusicUp value)  $default,){
final _that = this;
switch (_that) {
case _MusicUp():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MusicUp value)?  $default,){
final _that = this;
switch (_that) {
case _MusicUp() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int mid,  String name,  String face)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MusicUp() when $default != null:
return $default(_that.mid,_that.name,_that.face);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int mid,  String name,  String face)  $default,) {final _that = this;
switch (_that) {
case _MusicUp():
return $default(_that.mid,_that.name,_that.face);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int mid,  String name,  String face)?  $default,) {final _that = this;
switch (_that) {
case _MusicUp() when $default != null:
return $default(_that.mid,_that.name,_that.face);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MusicUp implements MusicUp {
  const _MusicUp({this.mid = 0, this.name = '', this.face = ''});
  factory _MusicUp.fromJson(Map<String, dynamic> json) => _$MusicUpFromJson(json);

@override@JsonKey() final  int mid;
@override@JsonKey() final  String name;
@override@JsonKey() final  String face;

/// Create a copy of MusicUp
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MusicUpCopyWith<_MusicUp> get copyWith => __$MusicUpCopyWithImpl<_MusicUp>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MusicUpToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MusicUp&&(identical(other.mid, mid) || other.mid == mid)&&(identical(other.name, name) || other.name == name)&&(identical(other.face, face) || other.face == face));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,mid,name,face);
}

@override
String toString() {
    return 'MusicUp(mid: $mid, name: $name, face: $face)';
}


}

/// @nodoc
abstract mixin class _$MusicUpCopyWith<$Res> implements $MusicUpCopyWith<$Res> {
  factory _$MusicUpCopyWith(_MusicUp value, $Res Function(_MusicUp) _then) = __$MusicUpCopyWithImpl;
@override @useResult
$Res call({
 int mid, String name, String face
});




}
/// @nodoc
class __$MusicUpCopyWithImpl<$Res>
    implements _$MusicUpCopyWith<$Res> {
  __$MusicUpCopyWithImpl(this._self, this._then);

  final _MusicUp _self;
  final $Res Function(_MusicUp) _then;

/// Create a copy of MusicUp
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? mid = null,Object? name = null,Object? face = null,}) {
  return _then(_MusicUp(
mid: null == mid ? _self.mid : mid // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,face: null == face ? _self.face : face // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
