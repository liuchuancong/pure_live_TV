// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'music_archive.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MusicArchive {

 int get aid; String get bvid; String get title; String get cover; String get upName; int get tid; int get upMid; String get upFace; int get duration; int get playCount; int get barrageCount; String get description; String get tname; String get publishDate; int get likeCount; int get coinCount; int get favCount; int get replyCount; List<MusicPart> get parts; MusicSeason? get season;
/// Create a copy of MusicArchive
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MusicArchiveCopyWith<MusicArchive> get copyWith => _$MusicArchiveCopyWithImpl<MusicArchive>(this as MusicArchive, _$identity);

  /// Serializes this MusicArchive to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as MusicArchive;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MusicArchive&&(identical(other.aid, _this.aid) || other.aid == _this.aid)&&(identical(other.bvid, _this.bvid) || other.bvid == _this.bvid)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.cover, _this.cover) || other.cover == _this.cover)&&(identical(other.upName, _this.upName) || other.upName == _this.upName)&&(identical(other.tid, _this.tid) || other.tid == _this.tid)&&(identical(other.upMid, _this.upMid) || other.upMid == _this.upMid)&&(identical(other.upFace, _this.upFace) || other.upFace == _this.upFace)&&(identical(other.duration, _this.duration) || other.duration == _this.duration)&&(identical(other.playCount, _this.playCount) || other.playCount == _this.playCount)&&(identical(other.barrageCount, _this.barrageCount) || other.barrageCount == _this.barrageCount)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.tname, _this.tname) || other.tname == _this.tname)&&(identical(other.publishDate, _this.publishDate) || other.publishDate == _this.publishDate)&&(identical(other.likeCount, _this.likeCount) || other.likeCount == _this.likeCount)&&(identical(other.coinCount, _this.coinCount) || other.coinCount == _this.coinCount)&&(identical(other.favCount, _this.favCount) || other.favCount == _this.favCount)&&(identical(other.replyCount, _this.replyCount) || other.replyCount == _this.replyCount)&&const DeepCollectionEquality().equals(other.parts, _this.parts)&&(identical(other.season, _this.season) || other.season == _this.season));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as MusicArchive;
  return Object.hashAll([runtimeType,_this.aid,_this.bvid,_this.title,_this.cover,_this.upName,_this.tid,_this.upMid,_this.upFace,_this.duration,_this.playCount,_this.barrageCount,_this.description,_this.tname,_this.publishDate,_this.likeCount,_this.coinCount,_this.favCount,_this.replyCount,const DeepCollectionEquality().hash(_this.parts),_this.season]);
}

@override
String toString() {
  final _this = this as MusicArchive;
  return 'MusicArchive(aid: ${_this.aid}, bvid: ${_this.bvid}, title: ${_this.title}, cover: ${_this.cover}, upName: ${_this.upName}, tid: ${_this.tid}, upMid: ${_this.upMid}, upFace: ${_this.upFace}, duration: ${_this.duration}, playCount: ${_this.playCount}, barrageCount: ${_this.barrageCount}, description: ${_this.description}, tname: ${_this.tname}, publishDate: ${_this.publishDate}, likeCount: ${_this.likeCount}, coinCount: ${_this.coinCount}, favCount: ${_this.favCount}, replyCount: ${_this.replyCount}, parts: ${_this.parts}, season: ${_this.season})';
}


}

/// @nodoc
abstract mixin class $MusicArchiveCopyWith<$Res>  {
  factory $MusicArchiveCopyWith(MusicArchive value, $Res Function(MusicArchive) _then) = _$MusicArchiveCopyWithImpl;
@useResult
$Res call({
 int aid, String bvid, String title, String cover, String upName, int tid, int upMid, String upFace, int duration, int playCount, int barrageCount, String description, String tname, String publishDate, int likeCount, int coinCount, int favCount, int replyCount, List<MusicPart> parts, MusicSeason? season
});


$MusicSeasonCopyWith<$Res>? get season;

}
/// @nodoc
class _$MusicArchiveCopyWithImpl<$Res>
    implements $MusicArchiveCopyWith<$Res> {
  _$MusicArchiveCopyWithImpl(this._self, this._then);

  final MusicArchive _self;
  final $Res Function(MusicArchive) _then;

/// Create a copy of MusicArchive
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? aid = null,Object? bvid = null,Object? title = null,Object? cover = null,Object? upName = null,Object? tid = null,Object? upMid = null,Object? upFace = null,Object? duration = null,Object? playCount = null,Object? barrageCount = null,Object? description = null,Object? tname = null,Object? publishDate = null,Object? likeCount = null,Object? coinCount = null,Object? favCount = null,Object? replyCount = null,Object? parts = null,Object? season = freezed,}) {
  return _then(MusicArchive(
aid: null == aid ? _self.aid : aid // ignore: cast_nullable_to_non_nullable
as int,bvid: null == bvid ? _self.bvid : bvid // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,cover: null == cover ? _self.cover : cover // ignore: cast_nullable_to_non_nullable
as String,upName: null == upName ? _self.upName : upName // ignore: cast_nullable_to_non_nullable
as String,tid: null == tid ? _self.tid : tid // ignore: cast_nullable_to_non_nullable
as int,upMid: null == upMid ? _self.upMid : upMid // ignore: cast_nullable_to_non_nullable
as int,upFace: null == upFace ? _self.upFace : upFace // ignore: cast_nullable_to_non_nullable
as String,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as int,playCount: null == playCount ? _self.playCount : playCount // ignore: cast_nullable_to_non_nullable
as int,barrageCount: null == barrageCount ? _self.barrageCount : barrageCount // ignore: cast_nullable_to_non_nullable
as int,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,tname: null == tname ? _self.tname : tname // ignore: cast_nullable_to_non_nullable
as String,publishDate: null == publishDate ? _self.publishDate : publishDate // ignore: cast_nullable_to_non_nullable
as String,likeCount: null == likeCount ? _self.likeCount : likeCount // ignore: cast_nullable_to_non_nullable
as int,coinCount: null == coinCount ? _self.coinCount : coinCount // ignore: cast_nullable_to_non_nullable
as int,favCount: null == favCount ? _self.favCount : favCount // ignore: cast_nullable_to_non_nullable
as int,replyCount: null == replyCount ? _self.replyCount : replyCount // ignore: cast_nullable_to_non_nullable
as int,parts: null == parts ? _self.parts : parts // ignore: cast_nullable_to_non_nullable
as List<MusicPart>,season: freezed == season ? _self.season : season // ignore: cast_nullable_to_non_nullable
as MusicSeason?,
  ));
}
/// Create a copy of MusicArchive
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MusicSeasonCopyWith<$Res>? get season {
    if (_self.season == null) {
    return null;
  }

  return $MusicSeasonCopyWith<$Res>(_self.season!, (value) {
    return _then(_self.copyWith(season: value));
  });
}
}


/// Adds pattern-matching-related methods to [MusicArchive].
extension MusicArchivePatterns on MusicArchive {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MusicArchive value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MusicArchive() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MusicArchive value)  $default,){
final _that = this;
switch (_that) {
case _MusicArchive():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MusicArchive value)?  $default,){
final _that = this;
switch (_that) {
case _MusicArchive() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int aid,  String bvid,  String title,  String cover,  String upName,  int tid,  int upMid,  String upFace,  int duration,  int playCount,  int barrageCount,  String description,  String tname,  String publishDate,  int likeCount,  int coinCount,  int favCount,  int replyCount,  List<MusicPart> parts,  MusicSeason? season)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MusicArchive() when $default != null:
return $default(_that.aid,_that.bvid,_that.title,_that.cover,_that.upName,_that.tid,_that.upMid,_that.upFace,_that.duration,_that.playCount,_that.barrageCount,_that.description,_that.tname,_that.publishDate,_that.likeCount,_that.coinCount,_that.favCount,_that.replyCount,_that.parts,_that.season);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int aid,  String bvid,  String title,  String cover,  String upName,  int tid,  int upMid,  String upFace,  int duration,  int playCount,  int barrageCount,  String description,  String tname,  String publishDate,  int likeCount,  int coinCount,  int favCount,  int replyCount,  List<MusicPart> parts,  MusicSeason? season)  $default,) {final _that = this;
switch (_that) {
case _MusicArchive():
return $default(_that.aid,_that.bvid,_that.title,_that.cover,_that.upName,_that.tid,_that.upMid,_that.upFace,_that.duration,_that.playCount,_that.barrageCount,_that.description,_that.tname,_that.publishDate,_that.likeCount,_that.coinCount,_that.favCount,_that.replyCount,_that.parts,_that.season);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int aid,  String bvid,  String title,  String cover,  String upName,  int tid,  int upMid,  String upFace,  int duration,  int playCount,  int barrageCount,  String description,  String tname,  String publishDate,  int likeCount,  int coinCount,  int favCount,  int replyCount,  List<MusicPart> parts,  MusicSeason? season)?  $default,) {final _that = this;
switch (_that) {
case _MusicArchive() when $default != null:
return $default(_that.aid,_that.bvid,_that.title,_that.cover,_that.upName,_that.tid,_that.upMid,_that.upFace,_that.duration,_that.playCount,_that.barrageCount,_that.description,_that.tname,_that.publishDate,_that.likeCount,_that.coinCount,_that.favCount,_that.replyCount,_that.parts,_that.season);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MusicArchive extends MusicArchive {
  const _MusicArchive({this.aid = 0, this.bvid = '', this.title = '', this.cover = '', this.upName = '', this.tid = 0, this.upMid = 0, this.upFace = '', this.duration = 0, this.playCount = 0, this.barrageCount = 0, this.description = '', this.tname = '', this.publishDate = '', this.likeCount = 0, this.coinCount = 0, this.favCount = 0, this.replyCount = 0,  List<MusicPart> parts = const [], this.season}): _parts = parts,super._();
  factory _MusicArchive.fromJson(Map<String, dynamic> json) => _$MusicArchiveFromJson(json);

@override@JsonKey() final  int aid;
@override@JsonKey() final  String bvid;
@override@JsonKey() final  String title;
@override@JsonKey() final  String cover;
@override@JsonKey() final  String upName;
@override@JsonKey() final  int tid;
@override@JsonKey() final  int upMid;
@override@JsonKey() final  String upFace;
@override@JsonKey() final  int duration;
@override@JsonKey() final  int playCount;
@override@JsonKey() final  int barrageCount;
@override@JsonKey() final  String description;
@override@JsonKey() final  String tname;
@override@JsonKey() final  String publishDate;
@override@JsonKey() final  int likeCount;
@override@JsonKey() final  int coinCount;
@override@JsonKey() final  int favCount;
@override@JsonKey() final  int replyCount;
 final  List<MusicPart> _parts;
@override@JsonKey() List<MusicPart> get parts {
  if (_parts is EqualUnmodifiableListView) return _parts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_parts);
}

@override final  MusicSeason? season;

/// Create a copy of MusicArchive
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MusicArchiveCopyWith<_MusicArchive> get copyWith => __$MusicArchiveCopyWithImpl<_MusicArchive>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MusicArchiveToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MusicArchive&&(identical(other.aid, aid) || other.aid == aid)&&(identical(other.bvid, bvid) || other.bvid == bvid)&&(identical(other.title, title) || other.title == title)&&(identical(other.cover, cover) || other.cover == cover)&&(identical(other.upName, upName) || other.upName == upName)&&(identical(other.tid, tid) || other.tid == tid)&&(identical(other.upMid, upMid) || other.upMid == upMid)&&(identical(other.upFace, upFace) || other.upFace == upFace)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.playCount, playCount) || other.playCount == playCount)&&(identical(other.barrageCount, barrageCount) || other.barrageCount == barrageCount)&&(identical(other.description, description) || other.description == description)&&(identical(other.tname, tname) || other.tname == tname)&&(identical(other.publishDate, publishDate) || other.publishDate == publishDate)&&(identical(other.likeCount, likeCount) || other.likeCount == likeCount)&&(identical(other.coinCount, coinCount) || other.coinCount == coinCount)&&(identical(other.favCount, favCount) || other.favCount == favCount)&&(identical(other.replyCount, replyCount) || other.replyCount == replyCount)&&const DeepCollectionEquality().equals(other.parts, _parts)&&(identical(other.season, season) || other.season == season));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hashAll([runtimeType,aid,bvid,title,cover,upName,tid,upMid,upFace,duration,playCount,barrageCount,description,tname,publishDate,likeCount,coinCount,favCount,replyCount,const DeepCollectionEquality().hash(_parts),season]);
}

@override
String toString() {
    return 'MusicArchive(aid: $aid, bvid: $bvid, title: $title, cover: $cover, upName: $upName, tid: $tid, upMid: $upMid, upFace: $upFace, duration: $duration, playCount: $playCount, barrageCount: $barrageCount, description: $description, tname: $tname, publishDate: $publishDate, likeCount: $likeCount, coinCount: $coinCount, favCount: $favCount, replyCount: $replyCount, parts: $parts, season: $season)';
}


}

/// @nodoc
abstract mixin class _$MusicArchiveCopyWith<$Res> implements $MusicArchiveCopyWith<$Res> {
  factory _$MusicArchiveCopyWith(_MusicArchive value, $Res Function(_MusicArchive) _then) = __$MusicArchiveCopyWithImpl;
@override @useResult
$Res call({
 int aid, String bvid, String title, String cover, String upName, int tid, int upMid, String upFace, int duration, int playCount, int barrageCount, String description, String tname, String publishDate, int likeCount, int coinCount, int favCount, int replyCount, List<MusicPart> parts, MusicSeason? season
});


@override $MusicSeasonCopyWith<$Res>? get season;

}
/// @nodoc
class __$MusicArchiveCopyWithImpl<$Res>
    implements _$MusicArchiveCopyWith<$Res> {
  __$MusicArchiveCopyWithImpl(this._self, this._then);

  final _MusicArchive _self;
  final $Res Function(_MusicArchive) _then;

/// Create a copy of MusicArchive
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? aid = null,Object? bvid = null,Object? title = null,Object? cover = null,Object? upName = null,Object? tid = null,Object? upMid = null,Object? upFace = null,Object? duration = null,Object? playCount = null,Object? barrageCount = null,Object? description = null,Object? tname = null,Object? publishDate = null,Object? likeCount = null,Object? coinCount = null,Object? favCount = null,Object? replyCount = null,Object? parts = null,Object? season = freezed,}) {
  return _then(_MusicArchive(
aid: null == aid ? _self.aid : aid // ignore: cast_nullable_to_non_nullable
as int,bvid: null == bvid ? _self.bvid : bvid // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,cover: null == cover ? _self.cover : cover // ignore: cast_nullable_to_non_nullable
as String,upName: null == upName ? _self.upName : upName // ignore: cast_nullable_to_non_nullable
as String,tid: null == tid ? _self.tid : tid // ignore: cast_nullable_to_non_nullable
as int,upMid: null == upMid ? _self.upMid : upMid // ignore: cast_nullable_to_non_nullable
as int,upFace: null == upFace ? _self.upFace : upFace // ignore: cast_nullable_to_non_nullable
as String,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as int,playCount: null == playCount ? _self.playCount : playCount // ignore: cast_nullable_to_non_nullable
as int,barrageCount: null == barrageCount ? _self.barrageCount : barrageCount // ignore: cast_nullable_to_non_nullable
as int,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,tname: null == tname ? _self.tname : tname // ignore: cast_nullable_to_non_nullable
as String,publishDate: null == publishDate ? _self.publishDate : publishDate // ignore: cast_nullable_to_non_nullable
as String,likeCount: null == likeCount ? _self.likeCount : likeCount // ignore: cast_nullable_to_non_nullable
as int,coinCount: null == coinCount ? _self.coinCount : coinCount // ignore: cast_nullable_to_non_nullable
as int,favCount: null == favCount ? _self.favCount : favCount // ignore: cast_nullable_to_non_nullable
as int,replyCount: null == replyCount ? _self.replyCount : replyCount // ignore: cast_nullable_to_non_nullable
as int,parts: null == parts ? _self._parts : parts // ignore: cast_nullable_to_non_nullable
as List<MusicPart>,season: freezed == season ? _self.season : season // ignore: cast_nullable_to_non_nullable
as MusicSeason?,
  ));
}

/// Create a copy of MusicArchive
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MusicSeasonCopyWith<$Res>? get season {
    if (_self.season == null) {
    return null;
  }

  return $MusicSeasonCopyWith<$Res>(_self.season!, (value) {
    return _then(_self.copyWith(season: value));
  });
}
}


/// @nodoc
mixin _$MusicSeason {

 int get id; String get title; List<MusicSeasonSection> get sections;
/// Create a copy of MusicSeason
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MusicSeasonCopyWith<MusicSeason> get copyWith => _$MusicSeasonCopyWithImpl<MusicSeason>(this as MusicSeason, _$identity);

  /// Serializes this MusicSeason to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as MusicSeason;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MusicSeason&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.title, _this.title) || other.title == _this.title)&&const DeepCollectionEquality().equals(other.sections, _this.sections));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as MusicSeason;
  return Object.hash(runtimeType,_this.id,_this.title,const DeepCollectionEquality().hash(_this.sections));
}

@override
String toString() {
  final _this = this as MusicSeason;
  return 'MusicSeason(id: ${_this.id}, title: ${_this.title}, sections: ${_this.sections})';
}


}

/// @nodoc
abstract mixin class $MusicSeasonCopyWith<$Res>  {
  factory $MusicSeasonCopyWith(MusicSeason value, $Res Function(MusicSeason) _then) = _$MusicSeasonCopyWithImpl;
@useResult
$Res call({
 int id, String title, List<MusicSeasonSection> sections
});




}
/// @nodoc
class _$MusicSeasonCopyWithImpl<$Res>
    implements $MusicSeasonCopyWith<$Res> {
  _$MusicSeasonCopyWithImpl(this._self, this._then);

  final MusicSeason _self;
  final $Res Function(MusicSeason) _then;

/// Create a copy of MusicSeason
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? sections = null,}) {
  return _then(MusicSeason(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,sections: null == sections ? _self.sections : sections // ignore: cast_nullable_to_non_nullable
as List<MusicSeasonSection>,
  ));
}

}


/// Adds pattern-matching-related methods to [MusicSeason].
extension MusicSeasonPatterns on MusicSeason {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MusicSeason value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MusicSeason() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MusicSeason value)  $default,){
final _that = this;
switch (_that) {
case _MusicSeason():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MusicSeason value)?  $default,){
final _that = this;
switch (_that) {
case _MusicSeason() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String title,  List<MusicSeasonSection> sections)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MusicSeason() when $default != null:
return $default(_that.id,_that.title,_that.sections);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String title,  List<MusicSeasonSection> sections)  $default,) {final _that = this;
switch (_that) {
case _MusicSeason():
return $default(_that.id,_that.title,_that.sections);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String title,  List<MusicSeasonSection> sections)?  $default,) {final _that = this;
switch (_that) {
case _MusicSeason() when $default != null:
return $default(_that.id,_that.title,_that.sections);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MusicSeason implements MusicSeason {
  const _MusicSeason({this.id = 0, this.title = '',  List<MusicSeasonSection> sections = const []}): _sections = sections;
  factory _MusicSeason.fromJson(Map<String, dynamic> json) => _$MusicSeasonFromJson(json);

@override@JsonKey() final  int id;
@override@JsonKey() final  String title;
 final  List<MusicSeasonSection> _sections;
@override@JsonKey() List<MusicSeasonSection> get sections {
  if (_sections is EqualUnmodifiableListView) return _sections;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sections);
}


/// Create a copy of MusicSeason
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MusicSeasonCopyWith<_MusicSeason> get copyWith => __$MusicSeasonCopyWithImpl<_MusicSeason>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MusicSeasonToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MusicSeason&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other.sections, _sections));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,title,const DeepCollectionEquality().hash(_sections));
}

@override
String toString() {
    return 'MusicSeason(id: $id, title: $title, sections: $sections)';
}


}

/// @nodoc
abstract mixin class _$MusicSeasonCopyWith<$Res> implements $MusicSeasonCopyWith<$Res> {
  factory _$MusicSeasonCopyWith(_MusicSeason value, $Res Function(_MusicSeason) _then) = __$MusicSeasonCopyWithImpl;
@override @useResult
$Res call({
 int id, String title, List<MusicSeasonSection> sections
});




}
/// @nodoc
class __$MusicSeasonCopyWithImpl<$Res>
    implements _$MusicSeasonCopyWith<$Res> {
  __$MusicSeasonCopyWithImpl(this._self, this._then);

  final _MusicSeason _self;
  final $Res Function(_MusicSeason) _then;

/// Create a copy of MusicSeason
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? sections = null,}) {
  return _then(_MusicSeason(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,sections: null == sections ? _self._sections : sections // ignore: cast_nullable_to_non_nullable
as List<MusicSeasonSection>,
  ));
}


}


/// @nodoc
mixin _$MusicSeasonSection {

 String get title; List<MusicArchive> get episodes;
/// Create a copy of MusicSeasonSection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MusicSeasonSectionCopyWith<MusicSeasonSection> get copyWith => _$MusicSeasonSectionCopyWithImpl<MusicSeasonSection>(this as MusicSeasonSection, _$identity);

  /// Serializes this MusicSeasonSection to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as MusicSeasonSection;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MusicSeasonSection&&(identical(other.title, _this.title) || other.title == _this.title)&&const DeepCollectionEquality().equals(other.episodes, _this.episodes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as MusicSeasonSection;
  return Object.hash(runtimeType,_this.title,const DeepCollectionEquality().hash(_this.episodes));
}

@override
String toString() {
  final _this = this as MusicSeasonSection;
  return 'MusicSeasonSection(title: ${_this.title}, episodes: ${_this.episodes})';
}


}

/// @nodoc
abstract mixin class $MusicSeasonSectionCopyWith<$Res>  {
  factory $MusicSeasonSectionCopyWith(MusicSeasonSection value, $Res Function(MusicSeasonSection) _then) = _$MusicSeasonSectionCopyWithImpl;
@useResult
$Res call({
 String title, List<MusicArchive> episodes
});




}
/// @nodoc
class _$MusicSeasonSectionCopyWithImpl<$Res>
    implements $MusicSeasonSectionCopyWith<$Res> {
  _$MusicSeasonSectionCopyWithImpl(this._self, this._then);

  final MusicSeasonSection _self;
  final $Res Function(MusicSeasonSection) _then;

/// Create a copy of MusicSeasonSection
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? episodes = null,}) {
  return _then(MusicSeasonSection(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,episodes: null == episodes ? _self.episodes : episodes // ignore: cast_nullable_to_non_nullable
as List<MusicArchive>,
  ));
}

}


/// Adds pattern-matching-related methods to [MusicSeasonSection].
extension MusicSeasonSectionPatterns on MusicSeasonSection {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MusicSeasonSection value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MusicSeasonSection() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MusicSeasonSection value)  $default,){
final _that = this;
switch (_that) {
case _MusicSeasonSection():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MusicSeasonSection value)?  $default,){
final _that = this;
switch (_that) {
case _MusicSeasonSection() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  List<MusicArchive> episodes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MusicSeasonSection() when $default != null:
return $default(_that.title,_that.episodes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  List<MusicArchive> episodes)  $default,) {final _that = this;
switch (_that) {
case _MusicSeasonSection():
return $default(_that.title,_that.episodes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  List<MusicArchive> episodes)?  $default,) {final _that = this;
switch (_that) {
case _MusicSeasonSection() when $default != null:
return $default(_that.title,_that.episodes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MusicSeasonSection implements MusicSeasonSection {
  const _MusicSeasonSection({this.title = '',  List<MusicArchive> episodes = const []}): _episodes = episodes;
  factory _MusicSeasonSection.fromJson(Map<String, dynamic> json) => _$MusicSeasonSectionFromJson(json);

@override@JsonKey() final  String title;
 final  List<MusicArchive> _episodes;
@override@JsonKey() List<MusicArchive> get episodes {
  if (_episodes is EqualUnmodifiableListView) return _episodes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_episodes);
}


/// Create a copy of MusicSeasonSection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MusicSeasonSectionCopyWith<_MusicSeasonSection> get copyWith => __$MusicSeasonSectionCopyWithImpl<_MusicSeasonSection>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MusicSeasonSectionToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MusicSeasonSection&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other.episodes, _episodes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,title,const DeepCollectionEquality().hash(_episodes));
}

@override
String toString() {
    return 'MusicSeasonSection(title: $title, episodes: $episodes)';
}


}

/// @nodoc
abstract mixin class _$MusicSeasonSectionCopyWith<$Res> implements $MusicSeasonSectionCopyWith<$Res> {
  factory _$MusicSeasonSectionCopyWith(_MusicSeasonSection value, $Res Function(_MusicSeasonSection) _then) = __$MusicSeasonSectionCopyWithImpl;
@override @useResult
$Res call({
 String title, List<MusicArchive> episodes
});




}
/// @nodoc
class __$MusicSeasonSectionCopyWithImpl<$Res>
    implements _$MusicSeasonSectionCopyWith<$Res> {
  __$MusicSeasonSectionCopyWithImpl(this._self, this._then);

  final _MusicSeasonSection _self;
  final $Res Function(_MusicSeasonSection) _then;

/// Create a copy of MusicSeasonSection
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? episodes = null,}) {
  return _then(_MusicSeasonSection(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,episodes: null == episodes ? _self._episodes : episodes // ignore: cast_nullable_to_non_nullable
as List<MusicArchive>,
  ));
}


}

// dart format on
