// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bilibili_user_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BilibiliUserInfo {

 int? get mid; String? get uname; String? get userid; String? get sign; String? get birthday; String? get sex;@JsonKey(name: 'nick_free') bool? get nickFree; String? get rank;
/// Create a copy of BilibiliUserInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BilibiliUserInfoCopyWith<BilibiliUserInfo> get copyWith => _$BilibiliUserInfoCopyWithImpl<BilibiliUserInfo>(this as BilibiliUserInfo, _$identity);

  /// Serializes this BilibiliUserInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BilibiliUserInfo&&(identical(other.mid, mid) || other.mid == mid)&&(identical(other.uname, uname) || other.uname == uname)&&(identical(other.userid, userid) || other.userid == userid)&&(identical(other.sign, sign) || other.sign == sign)&&(identical(other.birthday, birthday) || other.birthday == birthday)&&(identical(other.sex, sex) || other.sex == sex)&&(identical(other.nickFree, nickFree) || other.nickFree == nickFree)&&(identical(other.rank, rank) || other.rank == rank));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,mid,uname,userid,sign,birthday,sex,nickFree,rank);

@override
String toString() {
  return 'BilibiliUserInfo(mid: $mid, uname: $uname, userid: $userid, sign: $sign, birthday: $birthday, sex: $sex, nickFree: $nickFree, rank: $rank)';
}


}

/// @nodoc
abstract mixin class $BilibiliUserInfoCopyWith<$Res>  {
  factory $BilibiliUserInfoCopyWith(BilibiliUserInfo value, $Res Function(BilibiliUserInfo) _then) = _$BilibiliUserInfoCopyWithImpl;
@useResult
$Res call({
 int? mid, String? uname, String? userid, String? sign, String? birthday, String? sex,@JsonKey(name: 'nick_free') bool? nickFree, String? rank
});




}
/// @nodoc
class _$BilibiliUserInfoCopyWithImpl<$Res>
    implements $BilibiliUserInfoCopyWith<$Res> {
  _$BilibiliUserInfoCopyWithImpl(this._self, this._then);

  final BilibiliUserInfo _self;
  final $Res Function(BilibiliUserInfo) _then;

/// Create a copy of BilibiliUserInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? mid = freezed,Object? uname = freezed,Object? userid = freezed,Object? sign = freezed,Object? birthday = freezed,Object? sex = freezed,Object? nickFree = freezed,Object? rank = freezed,}) {
  return _then(_self.copyWith(
mid: freezed == mid ? _self.mid : mid // ignore: cast_nullable_to_non_nullable
as int?,uname: freezed == uname ? _self.uname : uname // ignore: cast_nullable_to_non_nullable
as String?,userid: freezed == userid ? _self.userid : userid // ignore: cast_nullable_to_non_nullable
as String?,sign: freezed == sign ? _self.sign : sign // ignore: cast_nullable_to_non_nullable
as String?,birthday: freezed == birthday ? _self.birthday : birthday // ignore: cast_nullable_to_non_nullable
as String?,sex: freezed == sex ? _self.sex : sex // ignore: cast_nullable_to_non_nullable
as String?,nickFree: freezed == nickFree ? _self.nickFree : nickFree // ignore: cast_nullable_to_non_nullable
as bool?,rank: freezed == rank ? _self.rank : rank // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [BilibiliUserInfo].
extension BilibiliUserInfoPatterns on BilibiliUserInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BilibiliUserInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BilibiliUserInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BilibiliUserInfo value)  $default,){
final _that = this;
switch (_that) {
case _BilibiliUserInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BilibiliUserInfo value)?  $default,){
final _that = this;
switch (_that) {
case _BilibiliUserInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? mid,  String? uname,  String? userid,  String? sign,  String? birthday,  String? sex, @JsonKey(name: 'nick_free')  bool? nickFree,  String? rank)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BilibiliUserInfo() when $default != null:
return $default(_that.mid,_that.uname,_that.userid,_that.sign,_that.birthday,_that.sex,_that.nickFree,_that.rank);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? mid,  String? uname,  String? userid,  String? sign,  String? birthday,  String? sex, @JsonKey(name: 'nick_free')  bool? nickFree,  String? rank)  $default,) {final _that = this;
switch (_that) {
case _BilibiliUserInfo():
return $default(_that.mid,_that.uname,_that.userid,_that.sign,_that.birthday,_that.sex,_that.nickFree,_that.rank);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? mid,  String? uname,  String? userid,  String? sign,  String? birthday,  String? sex, @JsonKey(name: 'nick_free')  bool? nickFree,  String? rank)?  $default,) {final _that = this;
switch (_that) {
case _BilibiliUserInfo() when $default != null:
return $default(_that.mid,_that.uname,_that.userid,_that.sign,_that.birthday,_that.sex,_that.nickFree,_that.rank);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BilibiliUserInfo implements BilibiliUserInfo {
  const _BilibiliUserInfo({this.mid, this.uname, this.userid, this.sign, this.birthday, this.sex, @JsonKey(name: 'nick_free') this.nickFree, this.rank});
  factory _BilibiliUserInfo.fromJson(Map<String, dynamic> json) => _$BilibiliUserInfoFromJson(json);

@override final  int? mid;
@override final  String? uname;
@override final  String? userid;
@override final  String? sign;
@override final  String? birthday;
@override final  String? sex;
@override@JsonKey(name: 'nick_free') final  bool? nickFree;
@override final  String? rank;

/// Create a copy of BilibiliUserInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BilibiliUserInfoCopyWith<_BilibiliUserInfo> get copyWith => __$BilibiliUserInfoCopyWithImpl<_BilibiliUserInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BilibiliUserInfoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BilibiliUserInfo&&(identical(other.mid, mid) || other.mid == mid)&&(identical(other.uname, uname) || other.uname == uname)&&(identical(other.userid, userid) || other.userid == userid)&&(identical(other.sign, sign) || other.sign == sign)&&(identical(other.birthday, birthday) || other.birthday == birthday)&&(identical(other.sex, sex) || other.sex == sex)&&(identical(other.nickFree, nickFree) || other.nickFree == nickFree)&&(identical(other.rank, rank) || other.rank == rank));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,mid,uname,userid,sign,birthday,sex,nickFree,rank);

@override
String toString() {
  return 'BilibiliUserInfo(mid: $mid, uname: $uname, userid: $userid, sign: $sign, birthday: $birthday, sex: $sex, nickFree: $nickFree, rank: $rank)';
}


}

/// @nodoc
abstract mixin class _$BilibiliUserInfoCopyWith<$Res> implements $BilibiliUserInfoCopyWith<$Res> {
  factory _$BilibiliUserInfoCopyWith(_BilibiliUserInfo value, $Res Function(_BilibiliUserInfo) _then) = __$BilibiliUserInfoCopyWithImpl;
@override @useResult
$Res call({
 int? mid, String? uname, String? userid, String? sign, String? birthday, String? sex,@JsonKey(name: 'nick_free') bool? nickFree, String? rank
});




}
/// @nodoc
class __$BilibiliUserInfoCopyWithImpl<$Res>
    implements _$BilibiliUserInfoCopyWith<$Res> {
  __$BilibiliUserInfoCopyWithImpl(this._self, this._then);

  final _BilibiliUserInfo _self;
  final $Res Function(_BilibiliUserInfo) _then;

/// Create a copy of BilibiliUserInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? mid = freezed,Object? uname = freezed,Object? userid = freezed,Object? sign = freezed,Object? birthday = freezed,Object? sex = freezed,Object? nickFree = freezed,Object? rank = freezed,}) {
  return _then(_BilibiliUserInfo(
mid: freezed == mid ? _self.mid : mid // ignore: cast_nullable_to_non_nullable
as int?,uname: freezed == uname ? _self.uname : uname // ignore: cast_nullable_to_non_nullable
as String?,userid: freezed == userid ? _self.userid : userid // ignore: cast_nullable_to_non_nullable
as String?,sign: freezed == sign ? _self.sign : sign // ignore: cast_nullable_to_non_nullable
as String?,birthday: freezed == birthday ? _self.birthday : birthday // ignore: cast_nullable_to_non_nullable
as String?,sex: freezed == sex ? _self.sex : sex // ignore: cast_nullable_to_non_nullable
as String?,nickFree: freezed == nickFree ? _self.nickFree : nickFree // ignore: cast_nullable_to_non_nullable
as bool?,rank: freezed == rank ? _self.rank : rank // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
