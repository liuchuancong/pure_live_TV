// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'live_search_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LiveSearchRoomResult {

 bool get hasMore; List<LiveRoom> get items;
/// Create a copy of LiveSearchRoomResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LiveSearchRoomResultCopyWith<LiveSearchRoomResult> get copyWith => _$LiveSearchRoomResultCopyWithImpl<LiveSearchRoomResult>(this as LiveSearchRoomResult, _$identity);

  /// Serializes this LiveSearchRoomResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LiveSearchRoomResult&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore)&&const DeepCollectionEquality().equals(other.items, items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,hasMore,const DeepCollectionEquality().hash(items));

@override
String toString() {
  return 'LiveSearchRoomResult(hasMore: $hasMore, items: $items)';
}


}

/// @nodoc
abstract mixin class $LiveSearchRoomResultCopyWith<$Res>  {
  factory $LiveSearchRoomResultCopyWith(LiveSearchRoomResult value, $Res Function(LiveSearchRoomResult) _then) = _$LiveSearchRoomResultCopyWithImpl;
@useResult
$Res call({
 bool hasMore, List<LiveRoom> items
});




}
/// @nodoc
class _$LiveSearchRoomResultCopyWithImpl<$Res>
    implements $LiveSearchRoomResultCopyWith<$Res> {
  _$LiveSearchRoomResultCopyWithImpl(this._self, this._then);

  final LiveSearchRoomResult _self;
  final $Res Function(LiveSearchRoomResult) _then;

/// Create a copy of LiveSearchRoomResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? hasMore = null,Object? items = null,}) {
  return _then(_self.copyWith(
hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<LiveRoom>,
  ));
}

}


/// Adds pattern-matching-related methods to [LiveSearchRoomResult].
extension LiveSearchRoomResultPatterns on LiveSearchRoomResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LiveSearchRoomResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LiveSearchRoomResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LiveSearchRoomResult value)  $default,){
final _that = this;
switch (_that) {
case _LiveSearchRoomResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LiveSearchRoomResult value)?  $default,){
final _that = this;
switch (_that) {
case _LiveSearchRoomResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool hasMore,  List<LiveRoom> items)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LiveSearchRoomResult() when $default != null:
return $default(_that.hasMore,_that.items);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool hasMore,  List<LiveRoom> items)  $default,) {final _that = this;
switch (_that) {
case _LiveSearchRoomResult():
return $default(_that.hasMore,_that.items);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool hasMore,  List<LiveRoom> items)?  $default,) {final _that = this;
switch (_that) {
case _LiveSearchRoomResult() when $default != null:
return $default(_that.hasMore,_that.items);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LiveSearchRoomResult implements LiveSearchRoomResult {
  const _LiveSearchRoomResult({this.hasMore = false, final  List<LiveRoom> items = const []}): _items = items;
  factory _LiveSearchRoomResult.fromJson(Map<String, dynamic> json) => _$LiveSearchRoomResultFromJson(json);

@override@JsonKey() final  bool hasMore;
 final  List<LiveRoom> _items;
@override@JsonKey() List<LiveRoom> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of LiveSearchRoomResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LiveSearchRoomResultCopyWith<_LiveSearchRoomResult> get copyWith => __$LiveSearchRoomResultCopyWithImpl<_LiveSearchRoomResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LiveSearchRoomResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LiveSearchRoomResult&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore)&&const DeepCollectionEquality().equals(other._items, _items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,hasMore,const DeepCollectionEquality().hash(_items));

@override
String toString() {
  return 'LiveSearchRoomResult(hasMore: $hasMore, items: $items)';
}


}

/// @nodoc
abstract mixin class _$LiveSearchRoomResultCopyWith<$Res> implements $LiveSearchRoomResultCopyWith<$Res> {
  factory _$LiveSearchRoomResultCopyWith(_LiveSearchRoomResult value, $Res Function(_LiveSearchRoomResult) _then) = __$LiveSearchRoomResultCopyWithImpl;
@override @useResult
$Res call({
 bool hasMore, List<LiveRoom> items
});




}
/// @nodoc
class __$LiveSearchRoomResultCopyWithImpl<$Res>
    implements _$LiveSearchRoomResultCopyWith<$Res> {
  __$LiveSearchRoomResultCopyWithImpl(this._self, this._then);

  final _LiveSearchRoomResult _self;
  final $Res Function(_LiveSearchRoomResult) _then;

/// Create a copy of LiveSearchRoomResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? hasMore = null,Object? items = null,}) {
  return _then(_LiveSearchRoomResult(
hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<LiveRoom>,
  ));
}


}


/// @nodoc
mixin _$LiveSearchAnchorResult {

 bool get hasMore; List<LiveAnchorItem> get items;
/// Create a copy of LiveSearchAnchorResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LiveSearchAnchorResultCopyWith<LiveSearchAnchorResult> get copyWith => _$LiveSearchAnchorResultCopyWithImpl<LiveSearchAnchorResult>(this as LiveSearchAnchorResult, _$identity);

  /// Serializes this LiveSearchAnchorResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LiveSearchAnchorResult&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore)&&const DeepCollectionEquality().equals(other.items, items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,hasMore,const DeepCollectionEquality().hash(items));

@override
String toString() {
  return 'LiveSearchAnchorResult(hasMore: $hasMore, items: $items)';
}


}

/// @nodoc
abstract mixin class $LiveSearchAnchorResultCopyWith<$Res>  {
  factory $LiveSearchAnchorResultCopyWith(LiveSearchAnchorResult value, $Res Function(LiveSearchAnchorResult) _then) = _$LiveSearchAnchorResultCopyWithImpl;
@useResult
$Res call({
 bool hasMore, List<LiveAnchorItem> items
});




}
/// @nodoc
class _$LiveSearchAnchorResultCopyWithImpl<$Res>
    implements $LiveSearchAnchorResultCopyWith<$Res> {
  _$LiveSearchAnchorResultCopyWithImpl(this._self, this._then);

  final LiveSearchAnchorResult _self;
  final $Res Function(LiveSearchAnchorResult) _then;

/// Create a copy of LiveSearchAnchorResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? hasMore = null,Object? items = null,}) {
  return _then(_self.copyWith(
hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<LiveAnchorItem>,
  ));
}

}


/// Adds pattern-matching-related methods to [LiveSearchAnchorResult].
extension LiveSearchAnchorResultPatterns on LiveSearchAnchorResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LiveSearchAnchorResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LiveSearchAnchorResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LiveSearchAnchorResult value)  $default,){
final _that = this;
switch (_that) {
case _LiveSearchAnchorResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LiveSearchAnchorResult value)?  $default,){
final _that = this;
switch (_that) {
case _LiveSearchAnchorResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool hasMore,  List<LiveAnchorItem> items)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LiveSearchAnchorResult() when $default != null:
return $default(_that.hasMore,_that.items);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool hasMore,  List<LiveAnchorItem> items)  $default,) {final _that = this;
switch (_that) {
case _LiveSearchAnchorResult():
return $default(_that.hasMore,_that.items);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool hasMore,  List<LiveAnchorItem> items)?  $default,) {final _that = this;
switch (_that) {
case _LiveSearchAnchorResult() when $default != null:
return $default(_that.hasMore,_that.items);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LiveSearchAnchorResult implements LiveSearchAnchorResult {
  const _LiveSearchAnchorResult({this.hasMore = false, final  List<LiveAnchorItem> items = const []}): _items = items;
  factory _LiveSearchAnchorResult.fromJson(Map<String, dynamic> json) => _$LiveSearchAnchorResultFromJson(json);

@override@JsonKey() final  bool hasMore;
 final  List<LiveAnchorItem> _items;
@override@JsonKey() List<LiveAnchorItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of LiveSearchAnchorResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LiveSearchAnchorResultCopyWith<_LiveSearchAnchorResult> get copyWith => __$LiveSearchAnchorResultCopyWithImpl<_LiveSearchAnchorResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LiveSearchAnchorResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LiveSearchAnchorResult&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore)&&const DeepCollectionEquality().equals(other._items, _items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,hasMore,const DeepCollectionEquality().hash(_items));

@override
String toString() {
  return 'LiveSearchAnchorResult(hasMore: $hasMore, items: $items)';
}


}

/// @nodoc
abstract mixin class _$LiveSearchAnchorResultCopyWith<$Res> implements $LiveSearchAnchorResultCopyWith<$Res> {
  factory _$LiveSearchAnchorResultCopyWith(_LiveSearchAnchorResult value, $Res Function(_LiveSearchAnchorResult) _then) = __$LiveSearchAnchorResultCopyWithImpl;
@override @useResult
$Res call({
 bool hasMore, List<LiveAnchorItem> items
});




}
/// @nodoc
class __$LiveSearchAnchorResultCopyWithImpl<$Res>
    implements _$LiveSearchAnchorResultCopyWith<$Res> {
  __$LiveSearchAnchorResultCopyWithImpl(this._self, this._then);

  final _LiveSearchAnchorResult _self;
  final $Res Function(_LiveSearchAnchorResult) _then;

/// Create a copy of LiveSearchAnchorResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? hasMore = null,Object? items = null,}) {
  return _then(_LiveSearchAnchorResult(
hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<LiveAnchorItem>,
  ));
}


}

// dart format on
