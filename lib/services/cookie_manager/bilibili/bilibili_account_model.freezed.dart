// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bilibili_account_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BilibiliAccountModel {

 bool get isLogined; String get name; int get uid;
/// Create a copy of BilibiliAccountModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BilibiliAccountModelCopyWith<BilibiliAccountModel> get copyWith => _$BilibiliAccountModelCopyWithImpl<BilibiliAccountModel>(this as BilibiliAccountModel, _$identity);

  /// Serializes this BilibiliAccountModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BilibiliAccountModel&&(identical(other.isLogined, isLogined) || other.isLogined == isLogined)&&(identical(other.name, name) || other.name == name)&&(identical(other.uid, uid) || other.uid == uid));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,isLogined,name,uid);

@override
String toString() {
  return 'BilibiliAccountModel(isLogined: $isLogined, name: $name, uid: $uid)';
}


}

/// @nodoc
abstract mixin class $BilibiliAccountModelCopyWith<$Res>  {
  factory $BilibiliAccountModelCopyWith(BilibiliAccountModel value, $Res Function(BilibiliAccountModel) _then) = _$BilibiliAccountModelCopyWithImpl;
@useResult
$Res call({
 bool isLogined, String name, int uid
});




}
/// @nodoc
class _$BilibiliAccountModelCopyWithImpl<$Res>
    implements $BilibiliAccountModelCopyWith<$Res> {
  _$BilibiliAccountModelCopyWithImpl(this._self, this._then);

  final BilibiliAccountModel _self;
  final $Res Function(BilibiliAccountModel) _then;

/// Create a copy of BilibiliAccountModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isLogined = null,Object? name = null,Object? uid = null,}) {
  return _then(_self.copyWith(
isLogined: null == isLogined ? _self.isLogined : isLogined // ignore: cast_nullable_to_non_nullable
as bool,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [BilibiliAccountModel].
extension BilibiliAccountModelPatterns on BilibiliAccountModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BilibiliAccountModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BilibiliAccountModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BilibiliAccountModel value)  $default,){
final _that = this;
switch (_that) {
case _BilibiliAccountModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BilibiliAccountModel value)?  $default,){
final _that = this;
switch (_that) {
case _BilibiliAccountModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isLogined,  String name,  int uid)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BilibiliAccountModel() when $default != null:
return $default(_that.isLogined,_that.name,_that.uid);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isLogined,  String name,  int uid)  $default,) {final _that = this;
switch (_that) {
case _BilibiliAccountModel():
return $default(_that.isLogined,_that.name,_that.uid);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isLogined,  String name,  int uid)?  $default,) {final _that = this;
switch (_that) {
case _BilibiliAccountModel() when $default != null:
return $default(_that.isLogined,_that.name,_that.uid);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BilibiliAccountModel implements BilibiliAccountModel {
  const _BilibiliAccountModel({this.isLogined = false, this.name = '', this.uid = 0});
  factory _BilibiliAccountModel.fromJson(Map<String, dynamic> json) => _$BilibiliAccountModelFromJson(json);

@override@JsonKey() final  bool isLogined;
@override@JsonKey() final  String name;
@override@JsonKey() final  int uid;

/// Create a copy of BilibiliAccountModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BilibiliAccountModelCopyWith<_BilibiliAccountModel> get copyWith => __$BilibiliAccountModelCopyWithImpl<_BilibiliAccountModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BilibiliAccountModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BilibiliAccountModel&&(identical(other.isLogined, isLogined) || other.isLogined == isLogined)&&(identical(other.name, name) || other.name == name)&&(identical(other.uid, uid) || other.uid == uid));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,isLogined,name,uid);

@override
String toString() {
  return 'BilibiliAccountModel(isLogined: $isLogined, name: $name, uid: $uid)';
}


}

/// @nodoc
abstract mixin class _$BilibiliAccountModelCopyWith<$Res> implements $BilibiliAccountModelCopyWith<$Res> {
  factory _$BilibiliAccountModelCopyWith(_BilibiliAccountModel value, $Res Function(_BilibiliAccountModel) _then) = __$BilibiliAccountModelCopyWithImpl;
@override @useResult
$Res call({
 bool isLogined, String name, int uid
});




}
/// @nodoc
class __$BilibiliAccountModelCopyWithImpl<$Res>
    implements _$BilibiliAccountModelCopyWith<$Res> {
  __$BilibiliAccountModelCopyWithImpl(this._self, this._then);

  final _BilibiliAccountModel _self;
  final $Res Function(_BilibiliAccountModel) _then;

/// Create a copy of BilibiliAccountModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isLogined = null,Object? name = null,Object? uid = null,}) {
  return _then(_BilibiliAccountModel(
isLogined: null == isLogined ? _self.isLogined : isLogined // ignore: cast_nullable_to_non_nullable
as bool,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
