// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tag_management_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TagManagementModel {

 List<LiveTag> get tags; Map<String, List<String>> get roomTagsMap;
/// Create a copy of TagManagementModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TagManagementModelCopyWith<TagManagementModel> get copyWith => _$TagManagementModelCopyWithImpl<TagManagementModel>(this as TagManagementModel, _$identity);

  /// Serializes this TagManagementModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TagManagementModel&&const DeepCollectionEquality().equals(other.tags, tags)&&const DeepCollectionEquality().equals(other.roomTagsMap, roomTagsMap));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(tags),const DeepCollectionEquality().hash(roomTagsMap));

@override
String toString() {
  return 'TagManagementModel(tags: $tags, roomTagsMap: $roomTagsMap)';
}


}

/// @nodoc
abstract mixin class $TagManagementModelCopyWith<$Res>  {
  factory $TagManagementModelCopyWith(TagManagementModel value, $Res Function(TagManagementModel) _then) = _$TagManagementModelCopyWithImpl;
@useResult
$Res call({
 List<LiveTag> tags, Map<String, List<String>> roomTagsMap
});




}
/// @nodoc
class _$TagManagementModelCopyWithImpl<$Res>
    implements $TagManagementModelCopyWith<$Res> {
  _$TagManagementModelCopyWithImpl(this._self, this._then);

  final TagManagementModel _self;
  final $Res Function(TagManagementModel) _then;

/// Create a copy of TagManagementModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tags = null,Object? roomTagsMap = null,}) {
  return _then(_self.copyWith(
tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<LiveTag>,roomTagsMap: null == roomTagsMap ? _self.roomTagsMap : roomTagsMap // ignore: cast_nullable_to_non_nullable
as Map<String, List<String>>,
  ));
}

}


/// Adds pattern-matching-related methods to [TagManagementModel].
extension TagManagementModelPatterns on TagManagementModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TagManagementModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TagManagementModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TagManagementModel value)  $default,){
final _that = this;
switch (_that) {
case _TagManagementModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TagManagementModel value)?  $default,){
final _that = this;
switch (_that) {
case _TagManagementModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<LiveTag> tags,  Map<String, List<String>> roomTagsMap)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TagManagementModel() when $default != null:
return $default(_that.tags,_that.roomTagsMap);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<LiveTag> tags,  Map<String, List<String>> roomTagsMap)  $default,) {final _that = this;
switch (_that) {
case _TagManagementModel():
return $default(_that.tags,_that.roomTagsMap);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<LiveTag> tags,  Map<String, List<String>> roomTagsMap)?  $default,) {final _that = this;
switch (_that) {
case _TagManagementModel() when $default != null:
return $default(_that.tags,_that.roomTagsMap);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TagManagementModel implements TagManagementModel {
  const _TagManagementModel({final  List<LiveTag> tags = const [], final  Map<String, List<String>> roomTagsMap = const {}}): _tags = tags,_roomTagsMap = roomTagsMap;
  factory _TagManagementModel.fromJson(Map<String, dynamic> json) => _$TagManagementModelFromJson(json);

 final  List<LiveTag> _tags;
@override@JsonKey() List<LiveTag> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

 final  Map<String, List<String>> _roomTagsMap;
@override@JsonKey() Map<String, List<String>> get roomTagsMap {
  if (_roomTagsMap is EqualUnmodifiableMapView) return _roomTagsMap;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_roomTagsMap);
}


/// Create a copy of TagManagementModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TagManagementModelCopyWith<_TagManagementModel> get copyWith => __$TagManagementModelCopyWithImpl<_TagManagementModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TagManagementModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TagManagementModel&&const DeepCollectionEquality().equals(other._tags, _tags)&&const DeepCollectionEquality().equals(other._roomTagsMap, _roomTagsMap));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_tags),const DeepCollectionEquality().hash(_roomTagsMap));

@override
String toString() {
  return 'TagManagementModel(tags: $tags, roomTagsMap: $roomTagsMap)';
}


}

/// @nodoc
abstract mixin class _$TagManagementModelCopyWith<$Res> implements $TagManagementModelCopyWith<$Res> {
  factory _$TagManagementModelCopyWith(_TagManagementModel value, $Res Function(_TagManagementModel) _then) = __$TagManagementModelCopyWithImpl;
@override @useResult
$Res call({
 List<LiveTag> tags, Map<String, List<String>> roomTagsMap
});




}
/// @nodoc
class __$TagManagementModelCopyWithImpl<$Res>
    implements _$TagManagementModelCopyWith<$Res> {
  __$TagManagementModelCopyWithImpl(this._self, this._then);

  final _TagManagementModel _self;
  final $Res Function(_TagManagementModel) _then;

/// Create a copy of TagManagementModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tags = null,Object? roomTagsMap = null,}) {
  return _then(_TagManagementModel(
tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<LiveTag>,roomTagsMap: null == roomTagsMap ? _self._roomTagsMap : roomTagsMap // ignore: cast_nullable_to_non_nullable
as Map<String, List<String>>,
  ));
}


}

// dart format on
