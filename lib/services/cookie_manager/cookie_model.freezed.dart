// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cookie_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CookieModel {

 String get bilibiliCookie; int get bilibiliUid; String get huyaCookie; String get douyinCookie; String get kuaishouCookie;
/// Create a copy of CookieModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CookieModelCopyWith<CookieModel> get copyWith => _$CookieModelCopyWithImpl<CookieModel>(this as CookieModel, _$identity);

  /// Serializes this CookieModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CookieModel&&(identical(other.bilibiliCookie, bilibiliCookie) || other.bilibiliCookie == bilibiliCookie)&&(identical(other.bilibiliUid, bilibiliUid) || other.bilibiliUid == bilibiliUid)&&(identical(other.huyaCookie, huyaCookie) || other.huyaCookie == huyaCookie)&&(identical(other.douyinCookie, douyinCookie) || other.douyinCookie == douyinCookie)&&(identical(other.kuaishouCookie, kuaishouCookie) || other.kuaishouCookie == kuaishouCookie));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,bilibiliCookie,bilibiliUid,huyaCookie,douyinCookie,kuaishouCookie);

@override
String toString() {
  return 'CookieModel(bilibiliCookie: $bilibiliCookie, bilibiliUid: $bilibiliUid, huyaCookie: $huyaCookie, douyinCookie: $douyinCookie, kuaishouCookie: $kuaishouCookie)';
}


}

/// @nodoc
abstract mixin class $CookieModelCopyWith<$Res>  {
  factory $CookieModelCopyWith(CookieModel value, $Res Function(CookieModel) _then) = _$CookieModelCopyWithImpl;
@useResult
$Res call({
 String bilibiliCookie, int bilibiliUid, String huyaCookie, String douyinCookie, String kuaishouCookie
});




}
/// @nodoc
class _$CookieModelCopyWithImpl<$Res>
    implements $CookieModelCopyWith<$Res> {
  _$CookieModelCopyWithImpl(this._self, this._then);

  final CookieModel _self;
  final $Res Function(CookieModel) _then;

/// Create a copy of CookieModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? bilibiliCookie = null,Object? bilibiliUid = null,Object? huyaCookie = null,Object? douyinCookie = null,Object? kuaishouCookie = null,}) {
  return _then(_self.copyWith(
bilibiliCookie: null == bilibiliCookie ? _self.bilibiliCookie : bilibiliCookie // ignore: cast_nullable_to_non_nullable
as String,bilibiliUid: null == bilibiliUid ? _self.bilibiliUid : bilibiliUid // ignore: cast_nullable_to_non_nullable
as int,huyaCookie: null == huyaCookie ? _self.huyaCookie : huyaCookie // ignore: cast_nullable_to_non_nullable
as String,douyinCookie: null == douyinCookie ? _self.douyinCookie : douyinCookie // ignore: cast_nullable_to_non_nullable
as String,kuaishouCookie: null == kuaishouCookie ? _self.kuaishouCookie : kuaishouCookie // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CookieModel].
extension CookieModelPatterns on CookieModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CookieModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CookieModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CookieModel value)  $default,){
final _that = this;
switch (_that) {
case _CookieModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CookieModel value)?  $default,){
final _that = this;
switch (_that) {
case _CookieModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String bilibiliCookie,  int bilibiliUid,  String huyaCookie,  String douyinCookie,  String kuaishouCookie)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CookieModel() when $default != null:
return $default(_that.bilibiliCookie,_that.bilibiliUid,_that.huyaCookie,_that.douyinCookie,_that.kuaishouCookie);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String bilibiliCookie,  int bilibiliUid,  String huyaCookie,  String douyinCookie,  String kuaishouCookie)  $default,) {final _that = this;
switch (_that) {
case _CookieModel():
return $default(_that.bilibiliCookie,_that.bilibiliUid,_that.huyaCookie,_that.douyinCookie,_that.kuaishouCookie);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String bilibiliCookie,  int bilibiliUid,  String huyaCookie,  String douyinCookie,  String kuaishouCookie)?  $default,) {final _that = this;
switch (_that) {
case _CookieModel() when $default != null:
return $default(_that.bilibiliCookie,_that.bilibiliUid,_that.huyaCookie,_that.douyinCookie,_that.kuaishouCookie);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CookieModel implements CookieModel {
  const _CookieModel({this.bilibiliCookie = '', this.bilibiliUid = 0, this.huyaCookie = '', this.douyinCookie = '', this.kuaishouCookie = ''});
  factory _CookieModel.fromJson(Map<String, dynamic> json) => _$CookieModelFromJson(json);

@override@JsonKey() final  String bilibiliCookie;
@override@JsonKey() final  int bilibiliUid;
@override@JsonKey() final  String huyaCookie;
@override@JsonKey() final  String douyinCookie;
@override@JsonKey() final  String kuaishouCookie;

/// Create a copy of CookieModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CookieModelCopyWith<_CookieModel> get copyWith => __$CookieModelCopyWithImpl<_CookieModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CookieModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CookieModel&&(identical(other.bilibiliCookie, bilibiliCookie) || other.bilibiliCookie == bilibiliCookie)&&(identical(other.bilibiliUid, bilibiliUid) || other.bilibiliUid == bilibiliUid)&&(identical(other.huyaCookie, huyaCookie) || other.huyaCookie == huyaCookie)&&(identical(other.douyinCookie, douyinCookie) || other.douyinCookie == douyinCookie)&&(identical(other.kuaishouCookie, kuaishouCookie) || other.kuaishouCookie == kuaishouCookie));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,bilibiliCookie,bilibiliUid,huyaCookie,douyinCookie,kuaishouCookie);

@override
String toString() {
  return 'CookieModel(bilibiliCookie: $bilibiliCookie, bilibiliUid: $bilibiliUid, huyaCookie: $huyaCookie, douyinCookie: $douyinCookie, kuaishouCookie: $kuaishouCookie)';
}


}

/// @nodoc
abstract mixin class _$CookieModelCopyWith<$Res> implements $CookieModelCopyWith<$Res> {
  factory _$CookieModelCopyWith(_CookieModel value, $Res Function(_CookieModel) _then) = __$CookieModelCopyWithImpl;
@override @useResult
$Res call({
 String bilibiliCookie, int bilibiliUid, String huyaCookie, String douyinCookie, String kuaishouCookie
});




}
/// @nodoc
class __$CookieModelCopyWithImpl<$Res>
    implements _$CookieModelCopyWith<$Res> {
  __$CookieModelCopyWithImpl(this._self, this._then);

  final _CookieModel _self;
  final $Res Function(_CookieModel) _then;

/// Create a copy of CookieModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? bilibiliCookie = null,Object? bilibiliUid = null,Object? huyaCookie = null,Object? douyinCookie = null,Object? kuaishouCookie = null,}) {
  return _then(_CookieModel(
bilibiliCookie: null == bilibiliCookie ? _self.bilibiliCookie : bilibiliCookie // ignore: cast_nullable_to_non_nullable
as String,bilibiliUid: null == bilibiliUid ? _self.bilibiliUid : bilibiliUid // ignore: cast_nullable_to_non_nullable
as int,huyaCookie: null == huyaCookie ? _self.huyaCookie : huyaCookie // ignore: cast_nullable_to_non_nullable
as String,douyinCookie: null == douyinCookie ? _self.douyinCookie : douyinCookie // ignore: cast_nullable_to_non_nullable
as String,kuaishouCookie: null == kuaishouCookie ? _self.kuaishouCookie : kuaishouCookie // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
