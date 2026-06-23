// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'live_room.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LiveRoom {

 String get roomId; String get userId; String get link; String get title; String get nick; String get avatar; String get cover; String get area; String get watching; String get followers; String get platform; List<String> get tagIds; String get introduction; String get notice; bool get status; bool get isRecord; LiveStatus get liveStatus; String get epgId; String get currentProgramme; String get currentProgrammeDescription; String? get catchUpUrl; bool get isCatchUp; int? get catchUpStart; int? get catchUpEnd;@JsonKey(includeFromJson: false, includeToJson: false) dynamic get data;@JsonKey(includeFromJson: false, includeToJson: false) dynamic get danmakuData;
/// Create a copy of LiveRoom
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LiveRoomCopyWith<LiveRoom> get copyWith => _$LiveRoomCopyWithImpl<LiveRoom>(this as LiveRoom, _$identity);

  /// Serializes this LiveRoom to a JSON map.
  Map<String, dynamic> toJson();




@override
String toString() {
  return 'LiveRoom(roomId: $roomId, userId: $userId, link: $link, title: $title, nick: $nick, avatar: $avatar, cover: $cover, area: $area, watching: $watching, followers: $followers, platform: $platform, tagIds: $tagIds, introduction: $introduction, notice: $notice, status: $status, isRecord: $isRecord, liveStatus: $liveStatus, epgId: $epgId, currentProgramme: $currentProgramme, currentProgrammeDescription: $currentProgrammeDescription, catchUpUrl: $catchUpUrl, isCatchUp: $isCatchUp, catchUpStart: $catchUpStart, catchUpEnd: $catchUpEnd, data: $data, danmakuData: $danmakuData)';
}


}

/// @nodoc
abstract mixin class $LiveRoomCopyWith<$Res>  {
  factory $LiveRoomCopyWith(LiveRoom value, $Res Function(LiveRoom) _then) = _$LiveRoomCopyWithImpl;
@useResult
$Res call({
 String roomId, String userId, String link, String title, String nick, String avatar, String cover, String area, String watching, String followers, String platform, List<String> tagIds, String introduction, String notice, bool status, bool isRecord, LiveStatus liveStatus, String epgId, String currentProgramme, String currentProgrammeDescription, String? catchUpUrl, bool isCatchUp, int? catchUpStart, int? catchUpEnd,@JsonKey(includeFromJson: false, includeToJson: false) dynamic data,@JsonKey(includeFromJson: false, includeToJson: false) dynamic danmakuData
});




}
/// @nodoc
class _$LiveRoomCopyWithImpl<$Res>
    implements $LiveRoomCopyWith<$Res> {
  _$LiveRoomCopyWithImpl(this._self, this._then);

  final LiveRoom _self;
  final $Res Function(LiveRoom) _then;

/// Create a copy of LiveRoom
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? roomId = null,Object? userId = null,Object? link = null,Object? title = null,Object? nick = null,Object? avatar = null,Object? cover = null,Object? area = null,Object? watching = null,Object? followers = null,Object? platform = null,Object? tagIds = null,Object? introduction = null,Object? notice = null,Object? status = null,Object? isRecord = null,Object? liveStatus = null,Object? epgId = null,Object? currentProgramme = null,Object? currentProgrammeDescription = null,Object? catchUpUrl = freezed,Object? isCatchUp = null,Object? catchUpStart = freezed,Object? catchUpEnd = freezed,Object? data = freezed,Object? danmakuData = freezed,}) {
  return _then(_self.copyWith(
roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,link: null == link ? _self.link : link // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,nick: null == nick ? _self.nick : nick // ignore: cast_nullable_to_non_nullable
as String,avatar: null == avatar ? _self.avatar : avatar // ignore: cast_nullable_to_non_nullable
as String,cover: null == cover ? _self.cover : cover // ignore: cast_nullable_to_non_nullable
as String,area: null == area ? _self.area : area // ignore: cast_nullable_to_non_nullable
as String,watching: null == watching ? _self.watching : watching // ignore: cast_nullable_to_non_nullable
as String,followers: null == followers ? _self.followers : followers // ignore: cast_nullable_to_non_nullable
as String,platform: null == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as String,tagIds: null == tagIds ? _self.tagIds : tagIds // ignore: cast_nullable_to_non_nullable
as List<String>,introduction: null == introduction ? _self.introduction : introduction // ignore: cast_nullable_to_non_nullable
as String,notice: null == notice ? _self.notice : notice // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as bool,isRecord: null == isRecord ? _self.isRecord : isRecord // ignore: cast_nullable_to_non_nullable
as bool,liveStatus: null == liveStatus ? _self.liveStatus : liveStatus // ignore: cast_nullable_to_non_nullable
as LiveStatus,epgId: null == epgId ? _self.epgId : epgId // ignore: cast_nullable_to_non_nullable
as String,currentProgramme: null == currentProgramme ? _self.currentProgramme : currentProgramme // ignore: cast_nullable_to_non_nullable
as String,currentProgrammeDescription: null == currentProgrammeDescription ? _self.currentProgrammeDescription : currentProgrammeDescription // ignore: cast_nullable_to_non_nullable
as String,catchUpUrl: freezed == catchUpUrl ? _self.catchUpUrl : catchUpUrl // ignore: cast_nullable_to_non_nullable
as String?,isCatchUp: null == isCatchUp ? _self.isCatchUp : isCatchUp // ignore: cast_nullable_to_non_nullable
as bool,catchUpStart: freezed == catchUpStart ? _self.catchUpStart : catchUpStart // ignore: cast_nullable_to_non_nullable
as int?,catchUpEnd: freezed == catchUpEnd ? _self.catchUpEnd : catchUpEnd // ignore: cast_nullable_to_non_nullable
as int?,data: freezed == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as dynamic,danmakuData: freezed == danmakuData ? _self.danmakuData : danmakuData // ignore: cast_nullable_to_non_nullable
as dynamic,
  ));
}

}


/// Adds pattern-matching-related methods to [LiveRoom].
extension LiveRoomPatterns on LiveRoom {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LiveRoom value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LiveRoom() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LiveRoom value)  $default,){
final _that = this;
switch (_that) {
case _LiveRoom():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LiveRoom value)?  $default,){
final _that = this;
switch (_that) {
case _LiveRoom() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String roomId,  String userId,  String link,  String title,  String nick,  String avatar,  String cover,  String area,  String watching,  String followers,  String platform,  List<String> tagIds,  String introduction,  String notice,  bool status,  bool isRecord,  LiveStatus liveStatus,  String epgId,  String currentProgramme,  String currentProgrammeDescription,  String? catchUpUrl,  bool isCatchUp,  int? catchUpStart,  int? catchUpEnd, @JsonKey(includeFromJson: false, includeToJson: false)  dynamic data, @JsonKey(includeFromJson: false, includeToJson: false)  dynamic danmakuData)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LiveRoom() when $default != null:
return $default(_that.roomId,_that.userId,_that.link,_that.title,_that.nick,_that.avatar,_that.cover,_that.area,_that.watching,_that.followers,_that.platform,_that.tagIds,_that.introduction,_that.notice,_that.status,_that.isRecord,_that.liveStatus,_that.epgId,_that.currentProgramme,_that.currentProgrammeDescription,_that.catchUpUrl,_that.isCatchUp,_that.catchUpStart,_that.catchUpEnd,_that.data,_that.danmakuData);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String roomId,  String userId,  String link,  String title,  String nick,  String avatar,  String cover,  String area,  String watching,  String followers,  String platform,  List<String> tagIds,  String introduction,  String notice,  bool status,  bool isRecord,  LiveStatus liveStatus,  String epgId,  String currentProgramme,  String currentProgrammeDescription,  String? catchUpUrl,  bool isCatchUp,  int? catchUpStart,  int? catchUpEnd, @JsonKey(includeFromJson: false, includeToJson: false)  dynamic data, @JsonKey(includeFromJson: false, includeToJson: false)  dynamic danmakuData)  $default,) {final _that = this;
switch (_that) {
case _LiveRoom():
return $default(_that.roomId,_that.userId,_that.link,_that.title,_that.nick,_that.avatar,_that.cover,_that.area,_that.watching,_that.followers,_that.platform,_that.tagIds,_that.introduction,_that.notice,_that.status,_that.isRecord,_that.liveStatus,_that.epgId,_that.currentProgramme,_that.currentProgrammeDescription,_that.catchUpUrl,_that.isCatchUp,_that.catchUpStart,_that.catchUpEnd,_that.data,_that.danmakuData);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String roomId,  String userId,  String link,  String title,  String nick,  String avatar,  String cover,  String area,  String watching,  String followers,  String platform,  List<String> tagIds,  String introduction,  String notice,  bool status,  bool isRecord,  LiveStatus liveStatus,  String epgId,  String currentProgramme,  String currentProgrammeDescription,  String? catchUpUrl,  bool isCatchUp,  int? catchUpStart,  int? catchUpEnd, @JsonKey(includeFromJson: false, includeToJson: false)  dynamic data, @JsonKey(includeFromJson: false, includeToJson: false)  dynamic danmakuData)?  $default,) {final _that = this;
switch (_that) {
case _LiveRoom() when $default != null:
return $default(_that.roomId,_that.userId,_that.link,_that.title,_that.nick,_that.avatar,_that.cover,_that.area,_that.watching,_that.followers,_that.platform,_that.tagIds,_that.introduction,_that.notice,_that.status,_that.isRecord,_that.liveStatus,_that.epgId,_that.currentProgramme,_that.currentProgrammeDescription,_that.catchUpUrl,_that.isCatchUp,_that.catchUpStart,_that.catchUpEnd,_that.data,_that.danmakuData);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LiveRoom extends LiveRoom {
  const _LiveRoom({this.roomId = '', this.userId = '', this.link = '', this.title = '', this.nick = '', this.avatar = '', this.cover = '', this.area = '', this.watching = '0', this.followers = '0', this.platform = 'UNKNOWN', final  List<String> tagIds = const [], this.introduction = '', this.notice = '', this.status = false, this.isRecord = false, this.liveStatus = LiveStatus.offline, this.epgId = '', this.currentProgramme = '', this.currentProgrammeDescription = '', this.catchUpUrl, this.isCatchUp = false, this.catchUpStart, this.catchUpEnd, @JsonKey(includeFromJson: false, includeToJson: false) this.data, @JsonKey(includeFromJson: false, includeToJson: false) this.danmakuData}): _tagIds = tagIds,super._();
  factory _LiveRoom.fromJson(Map<String, dynamic> json) => _$LiveRoomFromJson(json);

@override@JsonKey() final  String roomId;
@override@JsonKey() final  String userId;
@override@JsonKey() final  String link;
@override@JsonKey() final  String title;
@override@JsonKey() final  String nick;
@override@JsonKey() final  String avatar;
@override@JsonKey() final  String cover;
@override@JsonKey() final  String area;
@override@JsonKey() final  String watching;
@override@JsonKey() final  String followers;
@override@JsonKey() final  String platform;
 final  List<String> _tagIds;
@override@JsonKey() List<String> get tagIds {
  if (_tagIds is EqualUnmodifiableListView) return _tagIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tagIds);
}

@override@JsonKey() final  String introduction;
@override@JsonKey() final  String notice;
@override@JsonKey() final  bool status;
@override@JsonKey() final  bool isRecord;
@override@JsonKey() final  LiveStatus liveStatus;
@override@JsonKey() final  String epgId;
@override@JsonKey() final  String currentProgramme;
@override@JsonKey() final  String currentProgrammeDescription;
@override final  String? catchUpUrl;
@override@JsonKey() final  bool isCatchUp;
@override final  int? catchUpStart;
@override final  int? catchUpEnd;
@override@JsonKey(includeFromJson: false, includeToJson: false) final  dynamic data;
@override@JsonKey(includeFromJson: false, includeToJson: false) final  dynamic danmakuData;

/// Create a copy of LiveRoom
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LiveRoomCopyWith<_LiveRoom> get copyWith => __$LiveRoomCopyWithImpl<_LiveRoom>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LiveRoomToJson(this, );
}



@override
String toString() {
  return 'LiveRoom(roomId: $roomId, userId: $userId, link: $link, title: $title, nick: $nick, avatar: $avatar, cover: $cover, area: $area, watching: $watching, followers: $followers, platform: $platform, tagIds: $tagIds, introduction: $introduction, notice: $notice, status: $status, isRecord: $isRecord, liveStatus: $liveStatus, epgId: $epgId, currentProgramme: $currentProgramme, currentProgrammeDescription: $currentProgrammeDescription, catchUpUrl: $catchUpUrl, isCatchUp: $isCatchUp, catchUpStart: $catchUpStart, catchUpEnd: $catchUpEnd, data: $data, danmakuData: $danmakuData)';
}


}

/// @nodoc
abstract mixin class _$LiveRoomCopyWith<$Res> implements $LiveRoomCopyWith<$Res> {
  factory _$LiveRoomCopyWith(_LiveRoom value, $Res Function(_LiveRoom) _then) = __$LiveRoomCopyWithImpl;
@override @useResult
$Res call({
 String roomId, String userId, String link, String title, String nick, String avatar, String cover, String area, String watching, String followers, String platform, List<String> tagIds, String introduction, String notice, bool status, bool isRecord, LiveStatus liveStatus, String epgId, String currentProgramme, String currentProgrammeDescription, String? catchUpUrl, bool isCatchUp, int? catchUpStart, int? catchUpEnd,@JsonKey(includeFromJson: false, includeToJson: false) dynamic data,@JsonKey(includeFromJson: false, includeToJson: false) dynamic danmakuData
});




}
/// @nodoc
class __$LiveRoomCopyWithImpl<$Res>
    implements _$LiveRoomCopyWith<$Res> {
  __$LiveRoomCopyWithImpl(this._self, this._then);

  final _LiveRoom _self;
  final $Res Function(_LiveRoom) _then;

/// Create a copy of LiveRoom
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? roomId = null,Object? userId = null,Object? link = null,Object? title = null,Object? nick = null,Object? avatar = null,Object? cover = null,Object? area = null,Object? watching = null,Object? followers = null,Object? platform = null,Object? tagIds = null,Object? introduction = null,Object? notice = null,Object? status = null,Object? isRecord = null,Object? liveStatus = null,Object? epgId = null,Object? currentProgramme = null,Object? currentProgrammeDescription = null,Object? catchUpUrl = freezed,Object? isCatchUp = null,Object? catchUpStart = freezed,Object? catchUpEnd = freezed,Object? data = freezed,Object? danmakuData = freezed,}) {
  return _then(_LiveRoom(
roomId: null == roomId ? _self.roomId : roomId // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,link: null == link ? _self.link : link // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,nick: null == nick ? _self.nick : nick // ignore: cast_nullable_to_non_nullable
as String,avatar: null == avatar ? _self.avatar : avatar // ignore: cast_nullable_to_non_nullable
as String,cover: null == cover ? _self.cover : cover // ignore: cast_nullable_to_non_nullable
as String,area: null == area ? _self.area : area // ignore: cast_nullable_to_non_nullable
as String,watching: null == watching ? _self.watching : watching // ignore: cast_nullable_to_non_nullable
as String,followers: null == followers ? _self.followers : followers // ignore: cast_nullable_to_non_nullable
as String,platform: null == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as String,tagIds: null == tagIds ? _self._tagIds : tagIds // ignore: cast_nullable_to_non_nullable
as List<String>,introduction: null == introduction ? _self.introduction : introduction // ignore: cast_nullable_to_non_nullable
as String,notice: null == notice ? _self.notice : notice // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as bool,isRecord: null == isRecord ? _self.isRecord : isRecord // ignore: cast_nullable_to_non_nullable
as bool,liveStatus: null == liveStatus ? _self.liveStatus : liveStatus // ignore: cast_nullable_to_non_nullable
as LiveStatus,epgId: null == epgId ? _self.epgId : epgId // ignore: cast_nullable_to_non_nullable
as String,currentProgramme: null == currentProgramme ? _self.currentProgramme : currentProgramme // ignore: cast_nullable_to_non_nullable
as String,currentProgrammeDescription: null == currentProgrammeDescription ? _self.currentProgrammeDescription : currentProgrammeDescription // ignore: cast_nullable_to_non_nullable
as String,catchUpUrl: freezed == catchUpUrl ? _self.catchUpUrl : catchUpUrl // ignore: cast_nullable_to_non_nullable
as String?,isCatchUp: null == isCatchUp ? _self.isCatchUp : isCatchUp // ignore: cast_nullable_to_non_nullable
as bool,catchUpStart: freezed == catchUpStart ? _self.catchUpStart : catchUpStart // ignore: cast_nullable_to_non_nullable
as int?,catchUpEnd: freezed == catchUpEnd ? _self.catchUpEnd : catchUpEnd // ignore: cast_nullable_to_non_nullable
as int?,data: freezed == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as dynamic,danmakuData: freezed == danmakuData ? _self.danmakuData : danmakuData // ignore: cast_nullable_to_non_nullable
as dynamic,
  ));
}


}

// dart format on
