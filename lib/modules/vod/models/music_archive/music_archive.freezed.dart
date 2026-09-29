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

 int get aid; String get bvid; String get title; String get cover; String get upName; int get tid; int get upMid; String get upFace; int get duration; int get playCount; int get barrageCount; String get description; String get tname; String get publishDate; List<MusicPart> get parts;
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MusicArchive&&(identical(other.aid, _this.aid) || other.aid == _this.aid)&&(identical(other.bvid, _this.bvid) || other.bvid == _this.bvid)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.cover, _this.cover) || other.cover == _this.cover)&&(identical(other.upName, _this.upName) || other.upName == _this.upName)&&(identical(other.tid, _this.tid) || other.tid == _this.tid)&&(identical(other.upMid, _this.upMid) || other.upMid == _this.upMid)&&(identical(other.upFace, _this.upFace) || other.upFace == _this.upFace)&&(identical(other.duration, _this.duration) || other.duration == _this.duration)&&(identical(other.playCount, _this.playCount) || other.playCount == _this.playCount)&&(identical(other.barrageCount, _this.barrageCount) || other.barrageCount == _this.barrageCount)&&(identical(other.description, _this.description) || other.description == _this.description)&&(identical(other.tname, _this.tname) || other.tname == _this.tname)&&(identical(other.publishDate, _this.publishDate) || other.publishDate == _this.publishDate)&&const DeepCollectionEquality().equals(other.parts, _this.parts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as MusicArchive;
  return Object.hash(runtimeType,_this.aid,_this.bvid,_this.title,_this.cover,_this.upName,_this.tid,_this.upMid,_this.upFace,_this.duration,_this.playCount,_this.barrageCount,_this.description,_this.tname,_this.publishDate,const DeepCollectionEquality().hash(_this.parts));
}

@override
String toString() {
  final _this = this as MusicArchive;
  return 'MusicArchive(aid: ${_this.aid}, bvid: ${_this.bvid}, title: ${_this.title}, cover: ${_this.cover}, upName: ${_this.upName}, tid: ${_this.tid}, upMid: ${_this.upMid}, upFace: ${_this.upFace}, duration: ${_this.duration}, playCount: ${_this.playCount}, barrageCount: ${_this.barrageCount}, description: ${_this.description}, tname: ${_this.tname}, publishDate: ${_this.publishDate}, parts: ${_this.parts})';
}


}

/// @nodoc
abstract mixin class $MusicArchiveCopyWith<$Res>  {
  factory $MusicArchiveCopyWith(MusicArchive value, $Res Function(MusicArchive) _then) = _$MusicArchiveCopyWithImpl;
@useResult
$Res call({
 int aid, String bvid, String title, String cover, String upName, int tid, int upMid, String upFace, int duration, int playCount, int barrageCount, String description, String tname, String publishDate, List<MusicPart> parts
});




}
/// @nodoc
class _$MusicArchiveCopyWithImpl<$Res>
    implements $MusicArchiveCopyWith<$Res> {
  _$MusicArchiveCopyWithImpl(this._self, this._then);

  final MusicArchive _self;
  final $Res Function(MusicArchive) _then;

/// Create a copy of MusicArchive
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? aid = null,Object? bvid = null,Object? title = null,Object? cover = null,Object? upName = null,Object? tid = null,Object? upMid = null,Object? upFace = null,Object? duration = null,Object? playCount = null,Object? barrageCount = null,Object? description = null,Object? tname = null,Object? publishDate = null,Object? parts = null,}) {
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
as String,parts: null == parts ? _self.parts : parts // ignore: cast_nullable_to_non_nullable
as List<MusicPart>,
  ));
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int aid,  String bvid,  String title,  String cover,  String upName,  int tid,  int upMid,  String upFace,  int duration,  int playCount,  int barrageCount,  String description,  String tname,  String publishDate,  List<MusicPart> parts)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MusicArchive() when $default != null:
return $default(_that.aid,_that.bvid,_that.title,_that.cover,_that.upName,_that.tid,_that.upMid,_that.upFace,_that.duration,_that.playCount,_that.barrageCount,_that.description,_that.tname,_that.publishDate,_that.parts);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int aid,  String bvid,  String title,  String cover,  String upName,  int tid,  int upMid,  String upFace,  int duration,  int playCount,  int barrageCount,  String description,  String tname,  String publishDate,  List<MusicPart> parts)  $default,) {final _that = this;
switch (_that) {
case _MusicArchive():
return $default(_that.aid,_that.bvid,_that.title,_that.cover,_that.upName,_that.tid,_that.upMid,_that.upFace,_that.duration,_that.playCount,_that.barrageCount,_that.description,_that.tname,_that.publishDate,_that.parts);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int aid,  String bvid,  String title,  String cover,  String upName,  int tid,  int upMid,  String upFace,  int duration,  int playCount,  int barrageCount,  String description,  String tname,  String publishDate,  List<MusicPart> parts)?  $default,) {final _that = this;
switch (_that) {
case _MusicArchive() when $default != null:
return $default(_that.aid,_that.bvid,_that.title,_that.cover,_that.upName,_that.tid,_that.upMid,_that.upFace,_that.duration,_that.playCount,_that.barrageCount,_that.description,_that.tname,_that.publishDate,_that.parts);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MusicArchive extends MusicArchive {
  const _MusicArchive({this.aid = 0, this.bvid = '', this.title = '', this.cover = '', this.upName = '', this.tid = 0, this.upMid = 0, this.upFace = '', this.duration = 0, this.playCount = 0, this.barrageCount = 0, this.description = '', this.tname = '', this.publishDate = '',  List<MusicPart> parts = const []}): _parts = parts,super._();
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
 final  List<MusicPart> _parts;
@override@JsonKey() List<MusicPart> get parts {
  if (_parts is EqualUnmodifiableListView) return _parts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_parts);
}


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
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MusicArchive&&(identical(other.aid, aid) || other.aid == aid)&&(identical(other.bvid, bvid) || other.bvid == bvid)&&(identical(other.title, title) || other.title == title)&&(identical(other.cover, cover) || other.cover == cover)&&(identical(other.upName, upName) || other.upName == upName)&&(identical(other.tid, tid) || other.tid == tid)&&(identical(other.upMid, upMid) || other.upMid == upMid)&&(identical(other.upFace, upFace) || other.upFace == upFace)&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.playCount, playCount) || other.playCount == playCount)&&(identical(other.barrageCount, barrageCount) || other.barrageCount == barrageCount)&&(identical(other.description, description) || other.description == description)&&(identical(other.tname, tname) || other.tname == tname)&&(identical(other.publishDate, publishDate) || other.publishDate == publishDate)&&const DeepCollectionEquality().equals(other.parts, _parts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,aid,bvid,title,cover,upName,tid,upMid,upFace,duration,playCount,barrageCount,description,tname,publishDate,const DeepCollectionEquality().hash(_parts));
}

@override
String toString() {
    return 'MusicArchive(aid: $aid, bvid: $bvid, title: $title, cover: $cover, upName: $upName, tid: $tid, upMid: $upMid, upFace: $upFace, duration: $duration, playCount: $playCount, barrageCount: $barrageCount, description: $description, tname: $tname, publishDate: $publishDate, parts: $parts)';
}


}

/// @nodoc
abstract mixin class _$MusicArchiveCopyWith<$Res> implements $MusicArchiveCopyWith<$Res> {
  factory _$MusicArchiveCopyWith(_MusicArchive value, $Res Function(_MusicArchive) _then) = __$MusicArchiveCopyWithImpl;
@override @useResult
$Res call({
 int aid, String bvid, String title, String cover, String upName, int tid, int upMid, String upFace, int duration, int playCount, int barrageCount, String description, String tname, String publishDate, List<MusicPart> parts
});




}
/// @nodoc
class __$MusicArchiveCopyWithImpl<$Res>
    implements _$MusicArchiveCopyWith<$Res> {
  __$MusicArchiveCopyWithImpl(this._self, this._then);

  final _MusicArchive _self;
  final $Res Function(_MusicArchive) _then;

/// Create a copy of MusicArchive
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? aid = null,Object? bvid = null,Object? title = null,Object? cover = null,Object? upName = null,Object? tid = null,Object? upMid = null,Object? upFace = null,Object? duration = null,Object? playCount = null,Object? barrageCount = null,Object? description = null,Object? tname = null,Object? publishDate = null,Object? parts = null,}) {
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
as String,parts: null == parts ? _self._parts : parts // ignore: cast_nullable_to_non_nullable
as List<MusicPart>,
  ));
}


}

// dart format on
