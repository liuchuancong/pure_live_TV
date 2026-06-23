// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'live_category.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LiveCategory {

 String get id; String get name; List<LiveArea> get children;
/// Create a copy of LiveCategory
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LiveCategoryCopyWith<LiveCategory> get copyWith => _$LiveCategoryCopyWithImpl<LiveCategory>(this as LiveCategory, _$identity);

  /// Serializes this LiveCategory to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LiveCategory&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.children, children));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,const DeepCollectionEquality().hash(children));

@override
String toString() {
  return 'LiveCategory(id: $id, name: $name, children: $children)';
}


}

/// @nodoc
abstract mixin class $LiveCategoryCopyWith<$Res>  {
  factory $LiveCategoryCopyWith(LiveCategory value, $Res Function(LiveCategory) _then) = _$LiveCategoryCopyWithImpl;
@useResult
$Res call({
 String id, String name, List<LiveArea> children
});




}
/// @nodoc
class _$LiveCategoryCopyWithImpl<$Res>
    implements $LiveCategoryCopyWith<$Res> {
  _$LiveCategoryCopyWithImpl(this._self, this._then);

  final LiveCategory _self;
  final $Res Function(LiveCategory) _then;

/// Create a copy of LiveCategory
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? children = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,children: null == children ? _self.children : children // ignore: cast_nullable_to_non_nullable
as List<LiveArea>,
  ));
}

}


/// Adds pattern-matching-related methods to [LiveCategory].
extension LiveCategoryPatterns on LiveCategory {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LiveCategory value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LiveCategory() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LiveCategory value)  $default,){
final _that = this;
switch (_that) {
case _LiveCategory():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LiveCategory value)?  $default,){
final _that = this;
switch (_that) {
case _LiveCategory() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  List<LiveArea> children)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LiveCategory() when $default != null:
return $default(_that.id,_that.name,_that.children);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  List<LiveArea> children)  $default,) {final _that = this;
switch (_that) {
case _LiveCategory():
return $default(_that.id,_that.name,_that.children);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  List<LiveArea> children)?  $default,) {final _that = this;
switch (_that) {
case _LiveCategory() when $default != null:
return $default(_that.id,_that.name,_that.children);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LiveCategory implements LiveCategory {
  const _LiveCategory({required this.id, required this.name, final  List<LiveArea> children = const []}): _children = children;
  factory _LiveCategory.fromJson(Map<String, dynamic> json) => _$LiveCategoryFromJson(json);

@override final  String id;
@override final  String name;
 final  List<LiveArea> _children;
@override@JsonKey() List<LiveArea> get children {
  if (_children is EqualUnmodifiableListView) return _children;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_children);
}


/// Create a copy of LiveCategory
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LiveCategoryCopyWith<_LiveCategory> get copyWith => __$LiveCategoryCopyWithImpl<_LiveCategory>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LiveCategoryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LiveCategory&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other._children, _children));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,const DeepCollectionEquality().hash(_children));

@override
String toString() {
  return 'LiveCategory(id: $id, name: $name, children: $children)';
}


}

/// @nodoc
abstract mixin class _$LiveCategoryCopyWith<$Res> implements $LiveCategoryCopyWith<$Res> {
  factory _$LiveCategoryCopyWith(_LiveCategory value, $Res Function(_LiveCategory) _then) = __$LiveCategoryCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, List<LiveArea> children
});




}
/// @nodoc
class __$LiveCategoryCopyWithImpl<$Res>
    implements _$LiveCategoryCopyWith<$Res> {
  __$LiveCategoryCopyWithImpl(this._self, this._then);

  final _LiveCategory _self;
  final $Res Function(_LiveCategory) _then;

/// Create a copy of LiveCategory
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? children = null,}) {
  return _then(_LiveCategory(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,children: null == children ? _self._children : children // ignore: cast_nullable_to_non_nullable
as List<LiveArea>,
  ));
}


}

// dart format on
