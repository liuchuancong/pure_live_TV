// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'search_user_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SearchUserItem {

@JsonKey(fromJson: lenientIntOf) int get mid;@JsonKey(fromJson: stripHtmlOf) String get uname;/// The WBI search row names the avatar `upic`; the relation shape says
/// `face` — accept either.
@JsonKey(name: 'face', readValue: _readUpicOrFace, fromJson: httpsUrlOf) String get face;@JsonKey(fromJson: stripHtmlOf) String get sign;@JsonKey(fromJson: lenientIntOf) int get fans;@JsonKey(name: 'videos', fromJson: lenientIntOf) int get videoCount;
/// Create a copy of SearchUserItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchUserItemCopyWith<SearchUserItem> get copyWith => _$SearchUserItemCopyWithImpl<SearchUserItem>(this as SearchUserItem, _$identity);

  /// Serializes this SearchUserItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SearchUserItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchUserItem&&(identical(other.mid, _this.mid) || other.mid == _this.mid)&&(identical(other.uname, _this.uname) || other.uname == _this.uname)&&(identical(other.face, _this.face) || other.face == _this.face)&&(identical(other.sign, _this.sign) || other.sign == _this.sign)&&(identical(other.fans, _this.fans) || other.fans == _this.fans)&&(identical(other.videoCount, _this.videoCount) || other.videoCount == _this.videoCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SearchUserItem;
  return Object.hash(runtimeType,_this.mid,_this.uname,_this.face,_this.sign,_this.fans,_this.videoCount);
}

@override
String toString() {
  final _this = this as SearchUserItem;
  return 'SearchUserItem(mid: ${_this.mid}, uname: ${_this.uname}, face: ${_this.face}, sign: ${_this.sign}, fans: ${_this.fans}, videoCount: ${_this.videoCount})';
}


}

/// @nodoc
abstract mixin class $SearchUserItemCopyWith<$Res>  {
  factory $SearchUserItemCopyWith(SearchUserItem value, $Res Function(SearchUserItem) _then) = _$SearchUserItemCopyWithImpl;
@useResult
$Res call({
@JsonKey(fromJson: lenientIntOf) int mid,@JsonKey(fromJson: stripHtmlOf) String uname,@JsonKey(name: 'face', readValue: _readUpicOrFace, fromJson: httpsUrlOf) String face,@JsonKey(fromJson: stripHtmlOf) String sign,@JsonKey(fromJson: lenientIntOf) int fans,@JsonKey(name: 'videos', fromJson: lenientIntOf) int videoCount
});




}
/// @nodoc
class _$SearchUserItemCopyWithImpl<$Res>
    implements $SearchUserItemCopyWith<$Res> {
  _$SearchUserItemCopyWithImpl(this._self, this._then);

  final SearchUserItem _self;
  final $Res Function(SearchUserItem) _then;

/// Create a copy of SearchUserItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? mid = null,Object? uname = null,Object? face = null,Object? sign = null,Object? fans = null,Object? videoCount = null,}) {
  return _then(SearchUserItem(
mid: null == mid ? _self.mid : mid // ignore: cast_nullable_to_non_nullable
as int,uname: null == uname ? _self.uname : uname // ignore: cast_nullable_to_non_nullable
as String,face: null == face ? _self.face : face // ignore: cast_nullable_to_non_nullable
as String,sign: null == sign ? _self.sign : sign // ignore: cast_nullable_to_non_nullable
as String,fans: null == fans ? _self.fans : fans // ignore: cast_nullable_to_non_nullable
as int,videoCount: null == videoCount ? _self.videoCount : videoCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [SearchUserItem].
extension SearchUserItemPatterns on SearchUserItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SearchUserItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SearchUserItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SearchUserItem value)  $default,){
final _that = this;
switch (_that) {
case _SearchUserItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SearchUserItem value)?  $default,){
final _that = this;
switch (_that) {
case _SearchUserItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(fromJson: lenientIntOf)  int mid, @JsonKey(fromJson: stripHtmlOf)  String uname, @JsonKey(name: 'face', readValue: _readUpicOrFace, fromJson: httpsUrlOf)  String face, @JsonKey(fromJson: stripHtmlOf)  String sign, @JsonKey(fromJson: lenientIntOf)  int fans, @JsonKey(name: 'videos', fromJson: lenientIntOf)  int videoCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SearchUserItem() when $default != null:
return $default(_that.mid,_that.uname,_that.face,_that.sign,_that.fans,_that.videoCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(fromJson: lenientIntOf)  int mid, @JsonKey(fromJson: stripHtmlOf)  String uname, @JsonKey(name: 'face', readValue: _readUpicOrFace, fromJson: httpsUrlOf)  String face, @JsonKey(fromJson: stripHtmlOf)  String sign, @JsonKey(fromJson: lenientIntOf)  int fans, @JsonKey(name: 'videos', fromJson: lenientIntOf)  int videoCount)  $default,) {final _that = this;
switch (_that) {
case _SearchUserItem():
return $default(_that.mid,_that.uname,_that.face,_that.sign,_that.fans,_that.videoCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(fromJson: lenientIntOf)  int mid, @JsonKey(fromJson: stripHtmlOf)  String uname, @JsonKey(name: 'face', readValue: _readUpicOrFace, fromJson: httpsUrlOf)  String face, @JsonKey(fromJson: stripHtmlOf)  String sign, @JsonKey(fromJson: lenientIntOf)  int fans, @JsonKey(name: 'videos', fromJson: lenientIntOf)  int videoCount)?  $default,) {final _that = this;
switch (_that) {
case _SearchUserItem() when $default != null:
return $default(_that.mid,_that.uname,_that.face,_that.sign,_that.fans,_that.videoCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SearchUserItem implements SearchUserItem {
  const _SearchUserItem({@JsonKey(fromJson: lenientIntOf) this.mid = 0, @JsonKey(fromJson: stripHtmlOf) this.uname = '', @JsonKey(name: 'face', readValue: _readUpicOrFace, fromJson: httpsUrlOf) this.face = '', @JsonKey(fromJson: stripHtmlOf) this.sign = '', @JsonKey(fromJson: lenientIntOf) this.fans = 0, @JsonKey(name: 'videos', fromJson: lenientIntOf) this.videoCount = 0});
  factory _SearchUserItem.fromJson(Map<String, dynamic> json) => _$SearchUserItemFromJson(json);

@override@JsonKey(fromJson: lenientIntOf) final  int mid;
@override@JsonKey(fromJson: stripHtmlOf) final  String uname;
/// The WBI search row names the avatar `upic`; the relation shape says
/// `face` — accept either.
@override@JsonKey(name: 'face', readValue: _readUpicOrFace, fromJson: httpsUrlOf) final  String face;
@override@JsonKey(fromJson: stripHtmlOf) final  String sign;
@override@JsonKey(fromJson: lenientIntOf) final  int fans;
@override@JsonKey(name: 'videos', fromJson: lenientIntOf) final  int videoCount;

/// Create a copy of SearchUserItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SearchUserItemCopyWith<_SearchUserItem> get copyWith => __$SearchUserItemCopyWithImpl<_SearchUserItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SearchUserItemToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SearchUserItem&&(identical(other.mid, mid) || other.mid == mid)&&(identical(other.uname, uname) || other.uname == uname)&&(identical(other.face, face) || other.face == face)&&(identical(other.sign, sign) || other.sign == sign)&&(identical(other.fans, fans) || other.fans == fans)&&(identical(other.videoCount, videoCount) || other.videoCount == videoCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,mid,uname,face,sign,fans,videoCount);
}

@override
String toString() {
    return 'SearchUserItem(mid: $mid, uname: $uname, face: $face, sign: $sign, fans: $fans, videoCount: $videoCount)';
}


}

/// @nodoc
abstract mixin class _$SearchUserItemCopyWith<$Res> implements $SearchUserItemCopyWith<$Res> {
  factory _$SearchUserItemCopyWith(_SearchUserItem value, $Res Function(_SearchUserItem) _then) = __$SearchUserItemCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(fromJson: lenientIntOf) int mid,@JsonKey(fromJson: stripHtmlOf) String uname,@JsonKey(name: 'face', readValue: _readUpicOrFace, fromJson: httpsUrlOf) String face,@JsonKey(fromJson: stripHtmlOf) String sign,@JsonKey(fromJson: lenientIntOf) int fans,@JsonKey(name: 'videos', fromJson: lenientIntOf) int videoCount
});




}
/// @nodoc
class __$SearchUserItemCopyWithImpl<$Res>
    implements _$SearchUserItemCopyWith<$Res> {
  __$SearchUserItemCopyWithImpl(this._self, this._then);

  final _SearchUserItem _self;
  final $Res Function(_SearchUserItem) _then;

/// Create a copy of SearchUserItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? mid = null,Object? uname = null,Object? face = null,Object? sign = null,Object? fans = null,Object? videoCount = null,}) {
  return _then(_SearchUserItem(
mid: null == mid ? _self.mid : mid // ignore: cast_nullable_to_non_nullable
as int,uname: null == uname ? _self.uname : uname // ignore: cast_nullable_to_non_nullable
as String,face: null == face ? _self.face : face // ignore: cast_nullable_to_non_nullable
as String,sign: null == sign ? _self.sign : sign // ignore: cast_nullable_to_non_nullable
as String,fans: null == fans ? _self.fans : fans // ignore: cast_nullable_to_non_nullable
as int,videoCount: null == videoCount ? _self.videoCount : videoCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
