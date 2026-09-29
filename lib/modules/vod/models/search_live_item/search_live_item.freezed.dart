// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'search_live_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SearchLiveItem {

@JsonKey(name: 'roomid', fromJson: lenientIntOf) int get roomId;@JsonKey(fromJson: stripHtmlOf) String get title;/// A room row carries its own cover; a live-search row falls back to the
/// uploader's.
@JsonKey(name: 'cover', readValue: _readCoverOrUserCover, fromJson: httpsUrlOf) String get cover;@JsonKey(fromJson: stripHtmlOf) String get uname;@JsonKey(fromJson: lenientIntOf) int get online;@JsonKey(name: 'live_status', fromJson: lenientIntOf) int get liveStatus;
/// Create a copy of SearchLiveItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchLiveItemCopyWith<SearchLiveItem> get copyWith => _$SearchLiveItemCopyWithImpl<SearchLiveItem>(this as SearchLiveItem, _$identity);

  /// Serializes this SearchLiveItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SearchLiveItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchLiveItem&&(identical(other.roomId, _this.roomId) || other.roomId == _this.roomId)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.cover, _this.cover) || other.cover == _this.cover)&&(identical(other.uname, _this.uname) || other.uname == _this.uname)&&(identical(other.online, _this.online) || other.online == _this.online)&&(identical(other.liveStatus, _this.liveStatus) || other.liveStatus == _this.liveStatus));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SearchLiveItem;
  return Object.hash(runtimeType,_this.roomId,_this.title,_this.cover,_this.uname,_this.online,_this.liveStatus);
}

@override
String toString() {
  final _this = this as SearchLiveItem;
  return 'SearchLiveItem(roomId: ${_this.roomId}, title: ${_this.title}, cover: ${_this.cover}, uname: ${_this.uname}, online: ${_this.online}, liveStatus: ${_this.liveStatus})';
}


}

/// @nodoc
abstract mixin class $SearchLiveItemCopyWith<$Res>  {
  factory $SearchLiveItemCopyWith(SearchLiveItem value, $Res Function(SearchLiveItem) _then) = _$SearchLiveItemCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'roomid', fromJson: lenientIntOf) int roomId,@JsonKey(fromJson: stripHtmlOf) String title,@JsonKey(name: 'cover', readValue: _readCoverOrUserCover, fromJson: httpsUrlOf) String cover,@JsonKey(fromJson: stripHtmlOf) String uname,@JsonKey(fromJson: lenientIntOf) int online,@JsonKey(name: 'live_status', fromJson: lenientIntOf) int liveStatus
});




}
/// @nodoc
class _$SearchLiveItemCopyWithImpl<$Res>
    implements $SearchLiveItemCopyWith<$Res> {
  _$SearchLiveItemCopyWithImpl(this._self, this._then);

  final SearchLiveItem _self;
  final $Res Function(SearchLiveItem) _then;

/// Create a copy of SearchLiveItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? roomId = null,Object? title = null,Object? cover = null,Object? uname = null,Object? online = null,Object? liveStatus = null,}) {
  return _then(SearchLiveItem(
roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,cover: null == cover ? _self.cover : cover // ignore: cast_nullable_to_non_nullable
as String,uname: null == uname ? _self.uname : uname // ignore: cast_nullable_to_non_nullable
as String,online: null == online ? _self.online : online // ignore: cast_nullable_to_non_nullable
as int,liveStatus: null == liveStatus ? _self.liveStatus : liveStatus // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [SearchLiveItem].
extension SearchLiveItemPatterns on SearchLiveItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SearchLiveItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SearchLiveItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SearchLiveItem value)  $default,){
final _that = this;
switch (_that) {
case _SearchLiveItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SearchLiveItem value)?  $default,){
final _that = this;
switch (_that) {
case _SearchLiveItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'roomid', fromJson: lenientIntOf)  int roomId, @JsonKey(fromJson: stripHtmlOf)  String title, @JsonKey(name: 'cover', readValue: _readCoverOrUserCover, fromJson: httpsUrlOf)  String cover, @JsonKey(fromJson: stripHtmlOf)  String uname, @JsonKey(fromJson: lenientIntOf)  int online, @JsonKey(name: 'live_status', fromJson: lenientIntOf)  int liveStatus)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SearchLiveItem() when $default != null:
return $default(_that.roomId,_that.title,_that.cover,_that.uname,_that.online,_that.liveStatus);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'roomid', fromJson: lenientIntOf)  int roomId, @JsonKey(fromJson: stripHtmlOf)  String title, @JsonKey(name: 'cover', readValue: _readCoverOrUserCover, fromJson: httpsUrlOf)  String cover, @JsonKey(fromJson: stripHtmlOf)  String uname, @JsonKey(fromJson: lenientIntOf)  int online, @JsonKey(name: 'live_status', fromJson: lenientIntOf)  int liveStatus)  $default,) {final _that = this;
switch (_that) {
case _SearchLiveItem():
return $default(_that.roomId,_that.title,_that.cover,_that.uname,_that.online,_that.liveStatus);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'roomid', fromJson: lenientIntOf)  int roomId, @JsonKey(fromJson: stripHtmlOf)  String title, @JsonKey(name: 'cover', readValue: _readCoverOrUserCover, fromJson: httpsUrlOf)  String cover, @JsonKey(fromJson: stripHtmlOf)  String uname, @JsonKey(fromJson: lenientIntOf)  int online, @JsonKey(name: 'live_status', fromJson: lenientIntOf)  int liveStatus)?  $default,) {final _that = this;
switch (_that) {
case _SearchLiveItem() when $default != null:
return $default(_that.roomId,_that.title,_that.cover,_that.uname,_that.online,_that.liveStatus);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SearchLiveItem implements SearchLiveItem {
  const _SearchLiveItem({@JsonKey(name: 'roomid', fromJson: lenientIntOf) this.roomId = 0, @JsonKey(fromJson: stripHtmlOf) this.title = '', @JsonKey(name: 'cover', readValue: _readCoverOrUserCover, fromJson: httpsUrlOf) this.cover = '', @JsonKey(fromJson: stripHtmlOf) this.uname = '', @JsonKey(fromJson: lenientIntOf) this.online = 0, @JsonKey(name: 'live_status', fromJson: lenientIntOf) this.liveStatus = 0});
  factory _SearchLiveItem.fromJson(Map<String, dynamic> json) => _$SearchLiveItemFromJson(json);

@override@JsonKey(name: 'roomid', fromJson: lenientIntOf) final  int roomId;
@override@JsonKey(fromJson: stripHtmlOf) final  String title;
/// A room row carries its own cover; a live-search row falls back to the
/// uploader's.
@override@JsonKey(name: 'cover', readValue: _readCoverOrUserCover, fromJson: httpsUrlOf) final  String cover;
@override@JsonKey(fromJson: stripHtmlOf) final  String uname;
@override@JsonKey(fromJson: lenientIntOf) final  int online;
@override@JsonKey(name: 'live_status', fromJson: lenientIntOf) final  int liveStatus;

/// Create a copy of SearchLiveItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SearchLiveItemCopyWith<_SearchLiveItem> get copyWith => __$SearchLiveItemCopyWithImpl<_SearchLiveItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SearchLiveItemToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SearchLiveItem&&(identical(other.roomId, roomId) || other.roomId == roomId)&&(identical(other.title, title) || other.title == title)&&(identical(other.cover, cover) || other.cover == cover)&&(identical(other.uname, uname) || other.uname == uname)&&(identical(other.online, online) || other.online == online)&&(identical(other.liveStatus, liveStatus) || other.liveStatus == liveStatus));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,roomId,title,cover,uname,online,liveStatus);
}

@override
String toString() {
    return 'SearchLiveItem(roomId: $roomId, title: $title, cover: $cover, uname: $uname, online: $online, liveStatus: $liveStatus)';
}


}

/// @nodoc
abstract mixin class _$SearchLiveItemCopyWith<$Res> implements $SearchLiveItemCopyWith<$Res> {
  factory _$SearchLiveItemCopyWith(_SearchLiveItem value, $Res Function(_SearchLiveItem) _then) = __$SearchLiveItemCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'roomid', fromJson: lenientIntOf) int roomId,@JsonKey(fromJson: stripHtmlOf) String title,@JsonKey(name: 'cover', readValue: _readCoverOrUserCover, fromJson: httpsUrlOf) String cover,@JsonKey(fromJson: stripHtmlOf) String uname,@JsonKey(fromJson: lenientIntOf) int online,@JsonKey(name: 'live_status', fromJson: lenientIntOf) int liveStatus
});




}
/// @nodoc
class __$SearchLiveItemCopyWithImpl<$Res>
    implements _$SearchLiveItemCopyWith<$Res> {
  __$SearchLiveItemCopyWithImpl(this._self, this._then);

  final _SearchLiveItem _self;
  final $Res Function(_SearchLiveItem) _then;

/// Create a copy of SearchLiveItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? roomId = null,Object? title = null,Object? cover = null,Object? uname = null,Object? online = null,Object? liveStatus = null,}) {
  return _then(_SearchLiveItem(
roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,cover: null == cover ? _self.cover : cover // ignore: cast_nullable_to_non_nullable
as String,uname: null == uname ? _self.uname : uname // ignore: cast_nullable_to_non_nullable
as String,online: null == online ? _self.online : online // ignore: cast_nullable_to_non_nullable
as int,liveStatus: null == liveStatus ? _self.liveStatus : liveStatus // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
