// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'live_tag.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LiveTag {

 String get id; String get name; String get description; int get order;
/// Create a copy of LiveTag
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LiveTagCopyWith<LiveTag> get copyWith => _$LiveTagCopyWithImpl<LiveTag>(this as LiveTag, _$identity);

  /// Serializes this LiveTag to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LiveTag&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.order, order) || other.order == order));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,order);

@override
String toString() {
  return 'LiveTag(id: $id, name: $name, description: $description, order: $order)';
}


}

/// @nodoc
abstract mixin class $LiveTagCopyWith<$Res>  {
  factory $LiveTagCopyWith(LiveTag value, $Res Function(LiveTag) _then) = _$LiveTagCopyWithImpl;
@useResult
$Res call({
 String id, String name, String description, int order
});




}
/// @nodoc
class _$LiveTagCopyWithImpl<$Res>
    implements $LiveTagCopyWith<$Res> {
  _$LiveTagCopyWithImpl(this._self, this._then);

  final LiveTag _self;
  final $Res Function(LiveTag) _then;

/// Create a copy of LiveTag
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? description = null,Object? order = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [LiveTag].
extension LiveTagPatterns on LiveTag {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LiveTag value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LiveTag() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LiveTag value)  $default,){
final _that = this;
switch (_that) {
case _LiveTag():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LiveTag value)?  $default,){
final _that = this;
switch (_that) {
case _LiveTag() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String description,  int order)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LiveTag() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.order);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String description,  int order)  $default,) {final _that = this;
switch (_that) {
case _LiveTag():
return $default(_that.id,_that.name,_that.description,_that.order);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String description,  int order)?  $default,) {final _that = this;
switch (_that) {
case _LiveTag() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.order);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LiveTag implements LiveTag {
  const _LiveTag({required this.id, this.name = '', this.description = '', this.order = 0});
  factory _LiveTag.fromJson(Map<String, dynamic> json) => _$LiveTagFromJson(json);

@override final  String id;
@override@JsonKey() final  String name;
@override@JsonKey() final  String description;
@override@JsonKey() final  int order;

/// Create a copy of LiveTag
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LiveTagCopyWith<_LiveTag> get copyWith => __$LiveTagCopyWithImpl<_LiveTag>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LiveTagToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LiveTag&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.order, order) || other.order == order));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,order);

@override
String toString() {
  return 'LiveTag(id: $id, name: $name, description: $description, order: $order)';
}


}

/// @nodoc
abstract mixin class _$LiveTagCopyWith<$Res> implements $LiveTagCopyWith<$Res> {
  factory _$LiveTagCopyWith(_LiveTag value, $Res Function(_LiveTag) _then) = __$LiveTagCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String description, int order
});




}
/// @nodoc
class __$LiveTagCopyWithImpl<$Res>
    implements _$LiveTagCopyWith<$Res> {
  __$LiveTagCopyWithImpl(this._self, this._then);

  final _LiveTag _self;
  final $Res Function(_LiveTag) _then;

/// Create a copy of LiveTag
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? description = null,Object? order = null,}) {
  return _then(_LiveTag(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
