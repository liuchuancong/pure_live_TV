// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'subtitle_cue.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SubtitleCue {

@JsonKey(fromJson: lenientDoubleOf) double get from;@JsonKey(fromJson: lenientDoubleOf) double get to; String get text;
/// Create a copy of SubtitleCue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubtitleCueCopyWith<SubtitleCue> get copyWith => _$SubtitleCueCopyWithImpl<SubtitleCue>(this as SubtitleCue, _$identity);

  /// Serializes this SubtitleCue to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SubtitleCue;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubtitleCue&&(identical(other.from, _this.from) || other.from == _this.from)&&(identical(other.to, _this.to) || other.to == _this.to)&&(identical(other.text, _this.text) || other.text == _this.text));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SubtitleCue;
  return Object.hash(runtimeType,_this.from,_this.to,_this.text);
}

@override
String toString() {
  final _this = this as SubtitleCue;
  return 'SubtitleCue(from: ${_this.from}, to: ${_this.to}, text: ${_this.text})';
}


}

/// @nodoc
abstract mixin class $SubtitleCueCopyWith<$Res>  {
  factory $SubtitleCueCopyWith(SubtitleCue value, $Res Function(SubtitleCue) _then) = _$SubtitleCueCopyWithImpl;
@useResult
$Res call({
@JsonKey(fromJson: lenientDoubleOf) double from,@JsonKey(fromJson: lenientDoubleOf) double to, String text
});




}
/// @nodoc
class _$SubtitleCueCopyWithImpl<$Res>
    implements $SubtitleCueCopyWith<$Res> {
  _$SubtitleCueCopyWithImpl(this._self, this._then);

  final SubtitleCue _self;
  final $Res Function(SubtitleCue) _then;

/// Create a copy of SubtitleCue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? from = null,Object? to = null,Object? text = null,}) {
  return _then(SubtitleCue(
from: null == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as double,to: null == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as double,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SubtitleCue].
extension SubtitleCuePatterns on SubtitleCue {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubtitleCue value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubtitleCue() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubtitleCue value)  $default,){
final _that = this;
switch (_that) {
case _SubtitleCue():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubtitleCue value)?  $default,){
final _that = this;
switch (_that) {
case _SubtitleCue() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(fromJson: lenientDoubleOf)  double from, @JsonKey(fromJson: lenientDoubleOf)  double to,  String text)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubtitleCue() when $default != null:
return $default(_that.from,_that.to,_that.text);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(fromJson: lenientDoubleOf)  double from, @JsonKey(fromJson: lenientDoubleOf)  double to,  String text)  $default,) {final _that = this;
switch (_that) {
case _SubtitleCue():
return $default(_that.from,_that.to,_that.text);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(fromJson: lenientDoubleOf)  double from, @JsonKey(fromJson: lenientDoubleOf)  double to,  String text)?  $default,) {final _that = this;
switch (_that) {
case _SubtitleCue() when $default != null:
return $default(_that.from,_that.to,_that.text);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SubtitleCue implements SubtitleCue {
  const _SubtitleCue({@JsonKey(fromJson: lenientDoubleOf) this.from = 0, @JsonKey(fromJson: lenientDoubleOf) this.to = 0, this.text = ''});
  factory _SubtitleCue.fromJson(Map<String, dynamic> json) => _$SubtitleCueFromJson(json);

@override@JsonKey(fromJson: lenientDoubleOf) final  double from;
@override@JsonKey(fromJson: lenientDoubleOf) final  double to;
@override@JsonKey() final  String text;

/// Create a copy of SubtitleCue
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubtitleCueCopyWith<_SubtitleCue> get copyWith => __$SubtitleCueCopyWithImpl<_SubtitleCue>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubtitleCueToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubtitleCue&&(identical(other.from, from) || other.from == from)&&(identical(other.to, to) || other.to == to)&&(identical(other.text, text) || other.text == text));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,from,to,text);
}

@override
String toString() {
    return 'SubtitleCue(from: $from, to: $to, text: $text)';
}


}

/// @nodoc
abstract mixin class _$SubtitleCueCopyWith<$Res> implements $SubtitleCueCopyWith<$Res> {
  factory _$SubtitleCueCopyWith(_SubtitleCue value, $Res Function(_SubtitleCue) _then) = __$SubtitleCueCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(fromJson: lenientDoubleOf) double from,@JsonKey(fromJson: lenientDoubleOf) double to, String text
});




}
/// @nodoc
class __$SubtitleCueCopyWithImpl<$Res>
    implements _$SubtitleCueCopyWith<$Res> {
  __$SubtitleCueCopyWithImpl(this._self, this._then);

  final _SubtitleCue _self;
  final $Res Function(_SubtitleCue) _then;

/// Create a copy of SubtitleCue
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? from = null,Object? to = null,Object? text = null,}) {
  return _then(_SubtitleCue(
from: null == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as double,to: null == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as double,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
