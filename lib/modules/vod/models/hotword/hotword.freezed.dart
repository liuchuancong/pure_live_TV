// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'hotword.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Hotword {

 String get keyword; String get icon; int get hotValue;
/// Create a copy of Hotword
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HotwordCopyWith<Hotword> get copyWith => _$HotwordCopyWithImpl<Hotword>(this as Hotword, _$identity);

  /// Serializes this Hotword to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Hotword;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Hotword&&(identical(other.keyword, _this.keyword) || other.keyword == _this.keyword)&&(identical(other.icon, _this.icon) || other.icon == _this.icon)&&(identical(other.hotValue, _this.hotValue) || other.hotValue == _this.hotValue));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Hotword;
  return Object.hash(runtimeType,_this.keyword,_this.icon,_this.hotValue);
}

@override
String toString() {
  final _this = this as Hotword;
  return 'Hotword(keyword: ${_this.keyword}, icon: ${_this.icon}, hotValue: ${_this.hotValue})';
}


}

/// @nodoc
abstract mixin class $HotwordCopyWith<$Res>  {
  factory $HotwordCopyWith(Hotword value, $Res Function(Hotword) _then) = _$HotwordCopyWithImpl;
@useResult
$Res call({
 String keyword, String icon, int hotValue
});




}
/// @nodoc
class _$HotwordCopyWithImpl<$Res>
    implements $HotwordCopyWith<$Res> {
  _$HotwordCopyWithImpl(this._self, this._then);

  final Hotword _self;
  final $Res Function(Hotword) _then;

/// Create a copy of Hotword
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? keyword = null,Object? icon = null,Object? hotValue = null,}) {
  return _then(Hotword(
keyword: null == keyword ? _self.keyword : keyword // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,hotValue: null == hotValue ? _self.hotValue : hotValue // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [Hotword].
extension HotwordPatterns on Hotword {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Hotword value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Hotword() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Hotword value)  $default,){
final _that = this;
switch (_that) {
case _Hotword():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Hotword value)?  $default,){
final _that = this;
switch (_that) {
case _Hotword() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String keyword,  String icon,  int hotValue)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Hotword() when $default != null:
return $default(_that.keyword,_that.icon,_that.hotValue);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String keyword,  String icon,  int hotValue)  $default,) {final _that = this;
switch (_that) {
case _Hotword():
return $default(_that.keyword,_that.icon,_that.hotValue);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String keyword,  String icon,  int hotValue)?  $default,) {final _that = this;
switch (_that) {
case _Hotword() when $default != null:
return $default(_that.keyword,_that.icon,_that.hotValue);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Hotword implements Hotword {
  const _Hotword({this.keyword = '', this.icon = '', this.hotValue = 0});
  factory _Hotword.fromJson(Map<String, dynamic> json) => _$HotwordFromJson(json);

@override@JsonKey() final  String keyword;
@override@JsonKey() final  String icon;
@override@JsonKey() final  int hotValue;

/// Create a copy of Hotword
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HotwordCopyWith<_Hotword> get copyWith => __$HotwordCopyWithImpl<_Hotword>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HotwordToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Hotword&&(identical(other.keyword, keyword) || other.keyword == keyword)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.hotValue, hotValue) || other.hotValue == hotValue));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,keyword,icon,hotValue);
}

@override
String toString() {
    return 'Hotword(keyword: $keyword, icon: $icon, hotValue: $hotValue)';
}


}

/// @nodoc
abstract mixin class _$HotwordCopyWith<$Res> implements $HotwordCopyWith<$Res> {
  factory _$HotwordCopyWith(_Hotword value, $Res Function(_Hotword) _then) = __$HotwordCopyWithImpl;
@override @useResult
$Res call({
 String keyword, String icon, int hotValue
});




}
/// @nodoc
class __$HotwordCopyWithImpl<$Res>
    implements _$HotwordCopyWith<$Res> {
  __$HotwordCopyWithImpl(this._self, this._then);

  final _Hotword _self;
  final $Res Function(_Hotword) _then;

/// Create a copy of Hotword
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? keyword = null,Object? icon = null,Object? hotValue = null,}) {
  return _then(_Hotword(
keyword: null == keyword ? _self.keyword : keyword // ignore: cast_nullable_to_non_nullable
as String,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,hotValue: null == hotValue ? _self.hotValue : hotValue // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
