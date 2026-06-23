// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'live_anchor_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LiveAnchorItem {

 String get roomId; String get avatar; String get userName; bool get liveStatus;
/// Create a copy of LiveAnchorItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LiveAnchorItemCopyWith<LiveAnchorItem> get copyWith => _$LiveAnchorItemCopyWithImpl<LiveAnchorItem>(this as LiveAnchorItem, _$identity);

  /// Serializes this LiveAnchorItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LiveAnchorItem&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.avatar, avatar) || other.avatar == avatar)&&(identical(other.userName, userName) || other.userName == userName)&&(identical(other.liveStatus, liveStatus) || other.liveStatus == liveStatus));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,roomId,avatar,userName,liveStatus);

@override
String toString() {
  return 'LiveAnchorItem(roomId: $roomId, avatar: $avatar, userName: $userName, liveStatus: $liveStatus)';
}


}

/// @nodoc
abstract mixin class $LiveAnchorItemCopyWith<$Res>  {
  factory $LiveAnchorItemCopyWith(LiveAnchorItem value, $Res Function(LiveAnchorItem) _then) = _$LiveAnchorItemCopyWithImpl;
@useResult
$Res call({
 String roomId, String avatar, String userName, bool liveStatus
});




}
/// @nodoc
class _$LiveAnchorItemCopyWithImpl<$Res>
    implements $LiveAnchorItemCopyWith<$Res> {
  _$LiveAnchorItemCopyWithImpl(this._self, this._then);

  final LiveAnchorItem _self;
  final $Res Function(LiveAnchorItem) _then;

/// Create a copy of LiveAnchorItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? roomId = null,Object? avatar = null,Object? userName = null,Object? liveStatus = null,}) {
  return _then(_self.copyWith(
roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as String,avatar: null == avatar ? _self.avatar : avatar // ignore: cast_nullable_to_non_nullable
as String,userName: null == userName ? _self.userName : userName // ignore: cast_nullable_to_non_nullable
as String,liveStatus: null == liveStatus ? _self.liveStatus : liveStatus // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [LiveAnchorItem].
extension LiveAnchorItemPatterns on LiveAnchorItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LiveAnchorItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LiveAnchorItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LiveAnchorItem value)  $default,){
final _that = this;
switch (_that) {
case _LiveAnchorItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LiveAnchorItem value)?  $default,){
final _that = this;
switch (_that) {
case _LiveAnchorItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String roomId,  String avatar,  String userName,  bool liveStatus)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LiveAnchorItem() when $default != null:
return $default(_that.roomId,_that.avatar,_that.userName,_that.liveStatus);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String roomId,  String avatar,  String userName,  bool liveStatus)  $default,) {final _that = this;
switch (_that) {
case _LiveAnchorItem():
return $default(_that.roomId,_that.avatar,_that.userName,_that.liveStatus);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String roomId,  String avatar,  String userName,  bool liveStatus)?  $default,) {final _that = this;
switch (_that) {
case _LiveAnchorItem() when $default != null:
return $default(_that.roomId,_that.avatar,_that.userName,_that.liveStatus);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LiveAnchorItem implements LiveAnchorItem {
  const _LiveAnchorItem({required this.roomId, required this.avatar, required this.userName, required this.liveStatus});
  factory _LiveAnchorItem.fromJson(Map<String, dynamic> json) => _$LiveAnchorItemFromJson(json);

@override final  String roomId;
@override final  String avatar;
@override final  String userName;
@override final  bool liveStatus;

/// Create a copy of LiveAnchorItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LiveAnchorItemCopyWith<_LiveAnchorItem> get copyWith => __$LiveAnchorItemCopyWithImpl<_LiveAnchorItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LiveAnchorItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LiveAnchorItem&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.avatar, avatar) || other.avatar == avatar)&&(identical(other.userName, userName) || other.userName == userName)&&(identical(other.liveStatus, liveStatus) || other.liveStatus == liveStatus));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,roomId,avatar,userName,liveStatus);

@override
String toString() {
  return 'LiveAnchorItem(roomId: $roomId, avatar: $avatar, userName: $userName, liveStatus: $liveStatus)';
}


}

/// @nodoc
abstract mixin class _$LiveAnchorItemCopyWith<$Res> implements $LiveAnchorItemCopyWith<$Res> {
  factory _$LiveAnchorItemCopyWith(_LiveAnchorItem value, $Res Function(_LiveAnchorItem) _then) = __$LiveAnchorItemCopyWithImpl;
@override @useResult
$Res call({
 String roomId, String avatar, String userName, bool liveStatus
});




}
/// @nodoc
class __$LiveAnchorItemCopyWithImpl<$Res>
    implements _$LiveAnchorItemCopyWith<$Res> {
  __$LiveAnchorItemCopyWithImpl(this._self, this._then);

  final _LiveAnchorItem _self;
  final $Res Function(_LiveAnchorItem) _then;

/// Create a copy of LiveAnchorItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? roomId = null,Object? avatar = null,Object? userName = null,Object? liveStatus = null,}) {
  return _then(_LiveAnchorItem(
roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as String,avatar: null == avatar ? _self.avatar : avatar // ignore: cast_nullable_to_non_nullable
as String,userName: null == userName ? _self.userName : userName // ignore: cast_nullable_to_non_nullable
as String,liveStatus: null == liveStatus ? _self.liveStatus : liveStatus // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
